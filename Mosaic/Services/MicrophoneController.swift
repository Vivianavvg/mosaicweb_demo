import AVFoundation
import Combine
import Foundation
import Speech
import SwiftUI

@MainActor
final class MicrophoneController: ObservableObject {
    enum MicState: String {
        case idle
        case live
        case denied
    }

    @Published var state: MicState = .idle
    @Published var level: CGFloat = 0
    @Published var transcript: String = ""
    @Published var errorMessage: String?

    var onFinalTranscript: ((String) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var smoothed: CGFloat = 0
    private let attack: CGFloat = 0.45
    private let release: CGFloat = 0.14
    private let threshold: CGFloat = 0.02
    private let sensitivity: CGFloat = 7.5

    func toggle() {
        if state == .live {
            stop()
        } else {
            start()
        }
    }

    func start() {
        errorMessage = nil
        Task { await begin() }
    }

    func stop() {
        let spoken = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        teardownAudio()
        state = .idle
        level = 0
        smoothed = 0
        if !spoken.isEmpty {
            onFinalTranscript?(spoken)
        }
        transcript = ""
    }

    private func begin() async {
        let micOK = await requestMicrophone()
        guard micOK else {
            state = .denied
            errorMessage = "Microphone access is off. You can still type."
            return
        }

        let speechOK = await requestSpeech()
        guard speechOK else {
            state = .denied
            errorMessage = "Speech recognition is off. You can still type."
            return
        }

        do {
            try configureSession()
            try startEngine()
            state = .live
        } catch {
            errorMessage = "Mosaic could not start listening. Try typing instead."
            teardownAudio()
            state = .idle
        }
    }

    private func requestMicrophone() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func requestSpeech() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func startEngine() throws {
        teardownEngineOnly()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.updateLevel(from: buffer)
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let text = result?.bestTranscription.formattedString {
                    self.transcript = text
                }
                if error != nil || (result?.isFinal ?? false) {
                    if self.state == .live, let error {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    nonisolated private func updateLevel(from buffer: AVAudioPCMBuffer) {
        guard let channel = buffer.floatChannelData?[0] else { return }
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return }
        var sum: Float = 0
        for i in 0..<frames {
            let sample = channel[i]
            sum += sample * sample
        }
        let rms = CGFloat(sqrt(sum / Float(frames)))
        Task { @MainActor in
            let gated = max(0, rms - self.threshold) * self.sensitivity
            let target = min(1, gated)
            let coeff = target > self.smoothed ? self.attack : self.release
            self.smoothed += (target - self.smoothed) * coeff
            self.level = min(1, max(0, self.smoothed))
        }
    }

    private func teardownAudio() {
        teardownEngineOnly()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func teardownEngineOnly() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
}
