#!/usr/bin/env python3
"""Create the synthetic credit-report fixture used by the Mosaic iPhone demo."""

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "output" / "pdf" / "mosaic-synthetic-credit-report.pdf"

INK = colors.HexColor("#171738")
PURPLE = colors.HexColor("#3423A6")
MUTED = colors.HexColor("#7180B9")
PALE = colors.HexColor("#F8F5F1")
MINT = colors.HexColor("#DFF3E4")
LINE = colors.HexColor("#DDD9E8")
RED = colors.HexColor("#C94A58")


def paragraph(text: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(text, style)


styles = getSampleStyleSheet()
styles.add(
    ParagraphStyle(
        name="CoverTitle",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=24,
        leading=29,
        textColor=INK,
        alignment=TA_CENTER,
        spaceAfter=8,
    )
)
styles.add(
    ParagraphStyle(
        name="PageTitle",
        parent=styles["Heading1"],
        fontName="Helvetica-Bold",
        fontSize=18,
        leading=22,
        textColor=INK,
        spaceAfter=10,
    )
)
styles.add(
    ParagraphStyle(
        name="Section",
        parent=styles["Heading2"],
        fontName="Helvetica-Bold",
        fontSize=11,
        leading=14,
        textColor=PURPLE,
        spaceBefore=9,
        spaceAfter=5,
    )
)
styles.add(
    ParagraphStyle(
        name="BodyMosaic",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=9.5,
        leading=14,
        textColor=INK,
        spaceAfter=4,
    )
)
styles.add(
    ParagraphStyle(
        name="SmallMosaic",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=8,
        leading=11,
        textColor=MUTED,
        spaceAfter=3,
    )
)
styles.add(
    ParagraphStyle(
        name="Notice",
        parent=styles["BodyText"],
        fontName="Helvetica-Bold",
        fontSize=9,
        leading=13,
        textColor=PURPLE,
        alignment=TA_CENTER,
    )
)
styles.add(
    ParagraphStyle(
        name="TableText",
        parent=styles["BodyText"],
        fontName="Helvetica",
        fontSize=8,
        leading=10,
        textColor=INK,
    )
)
styles.add(
    ParagraphStyle(
        name="TableHead",
        parent=styles["BodyText"],
        fontName="Helvetica-Bold",
        fontSize=8,
        leading=10,
        textColor=colors.white,
    )
)


def P(text: str, style: str = "BodyMosaic") -> Paragraph:
    return paragraph(text, styles[style])


def cell(text: str, header: bool = False) -> Paragraph:
    return P(text, "TableHead" if header else "TableText")


def table(data, widths, header=True):
    table = Table(data, colWidths=widths, repeatRows=1 if header else 0, hAlign="LEFT")
    commands = [
        ("GRID", (0, 0), (-1, -1), 0.45, LINE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 7),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]
    if header:
        commands += [
            ("BACKGROUND", (0, 0), (-1, 0), PURPLE),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ]
        start = 1
    else:
        start = 0
    for row in range(start, len(data)):
        if (row - start) % 2 == 0:
            commands.append(("BACKGROUND", (0, row), (-1, row), colors.white))
        else:
            commands.append(("BACKGROUND", (0, row), (-1, row), colors.HexColor("#F4F1FA")))
    table.setStyle(TableStyle(commands))
    return table


def key_value(rows):
    data = [[P(key, "SmallMosaic"), P(value, "BodyMosaic")] for key, value in rows]
    result = Table(data, colWidths=[1.65 * inch, 4.75 * inch], hAlign="LEFT")
    result.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LINEBELOW", (0, 0), (-1, -1), 0.35, LINE),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 8),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return result


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(LINE)
    canvas.line(0.65 * inch, 0.48 * inch, 7.85 * inch, 0.48 * inch)
    canvas.setFont("Helvetica", 7.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(0.65 * inch, 0.28 * inch, "Mosaic Credit Health · synthetic demo fixture · not a real credit report")
    canvas.drawRightString(7.85 * inch, 0.28 * inch, f"Page {doc.page}")
    canvas.restoreState()


def build():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUTPUT),
        pagesize=letter,
        rightMargin=0.65 * inch,
        leftMargin=0.65 * inch,
        topMargin=0.62 * inch,
        bottomMargin=0.68 * inch,
        title="Mosaic Synthetic Credit Report",
        author="Mosaic Credit Health",
        subject="Synthetic report fixture for the Mosaic iPhone demo",
    )

    story = []

    # Page 1: overview and identity context.
    story += [
        Spacer(1, 0.18 * inch),
        P("MOSAIC CREDIT HEALTH", "SmallMosaic"),
        P("Synthetic Credit Report", "CoverTitle"),
        P("Detailed demo fixture for the report-import, review, and Harbor letter workflow", "SmallMosaic"),
        Spacer(1, 0.18 * inch),
        Table(
            [[P("SYNTHETIC DEMO DATA — NOT A REAL CREDIT REPORT", "Notice")]],
            colWidths=[7.2 * inch],
            style=TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, -1), MINT),
                    ("BOX", (0, 0), (-1, -1), 0.7, colors.HexColor("#A7D8B8")),
                    ("LEFTPADDING", (0, 0), (-1, -1), 12),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 12),
                    ("TOPPADDING", (0, 0), (-1, -1), 11),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 11),
                ]
            ),
        ),
        P("Consumer profile", "Section"),
        key_value(
            [
                ("Name", "Maya Rivera (fictional demo consumer)"),
                ("Date of birth", "April 17, 1996"),
                ("Report date", "March 15, 2026"),
                ("Report reference", "DEMO-2026-0919-01"),
                ("Current address", "44 Example Lane, Atlanta, GA 30303"),
                ("Prior address", "100 Peachtree Demo Ave, Atlanta, GA 30303 · reported April 15, 2023"),
            ]
        ),
        P("Report snapshot", "Section"),
        table(
            [
                [cell("Metric", True), cell("Synthetic value", True), cell("What Mosaic can review", True)],
                [cell("Total accounts"), cell("4 reported accounts"), cell("New accounts, balance changes, and status changes")],
                [cell("Total reported balance"), cell("$12,840"), cell("Net debt added or reduced between report snapshots")],
                [cell("Collections"), cell("1 account · $2,140"), cell("Harbor Recovery Collections ending 9812")],
                [cell("Hard inquiries"), cell("1 in the last 24 months"), cell("Northstar Lending inquiry dated February 14, 2026")],
                [cell("Synthetic scores"), cell("Equifax 642 · Experian 638 · TransUnion 645"), cell("Displayed as sample context only")],
            ],
            [1.55 * inch, 2.15 * inch, 3.5 * inch],
        ),
        Spacer(1, 0.1 * inch),
        P("This fixture contains masked identifiers and fictional names. It is safe for a product demo, but it must not be used to make a real dispute, lending, or identity decision.", "SmallMosaic"),
        PageBreak(),
    ]

    # Page 2: account details matching SyntheticDataService.swift.
    story += [
        P("Current account records", "PageTitle"),
        P("These entries are intentionally detailed so the import flow has enough report text to extract and the review card has a clear Harbor change to show.", "BodyMosaic"),
        P("Revolving and installment accounts", "Section"),
        table(
            [
                [cell("Furnisher / account", True), cell("Type & opened", True), cell("Balance", True), cell("Status", True)],
                [cell("First National Bank Card<br/>Account ending 4421"), cell("Revolving<br/>Opened Apr 15, 2023"), cell("$8,700<br/>High credit $10,000"), cell("Open · Past due 30 days<br/>Joint account")],
                [cell("Oakline Auto Finance<br/>Account ending 7744"), cell("Installment<br/>Opened Aug 02, 2024"), cell("$2,940<br/>Original $18,400"), cell("Open · Paid as agreed<br/>Individual")],
                [cell("Pioneer Credit Union<br/>Account ending 1288"), cell("Revolving<br/>Opened Nov 19, 2022"), cell("$1,200<br/>Limit $3,500"), cell("Open · Paid as agreed<br/>Individual")],
            ],
            [2.05 * inch, 1.6 * inch, 1.35 * inch, 2.2 * inch],
        ),
        P("Collection account", "Section"),
        table(
            [
                [cell("Agency / reference", True), cell("Reported details", True), cell("Current status", True)],
                [cell("Harbor Recovery Collections<br/>Reference ending 9812"), cell("Original creditor: Lakeside Medical Center<br/>Assigned Feb 01, 2026<br/>Date first delinquent: Dec 18, 2025"), cell("Active collection<br/>Balance $2,140<br/>Account newly reported")],
            ],
            [2.15 * inch, 2.75 * inch, 2.3 * inch],
        ),
        P("Account-level source fields", "Section"),
        key_value(
            [
                ("Payment history", "First National Bank Card: 30-day late in January 2026; prior months paid as agreed."),
                ("Responsibility", "First National Bank Card changed from Individual to Joint between the prior and current snapshots."),
                ("Balances", "All balances are fictional and intentionally consistent with the report snapshot totals used in the demo."),
                ("Masked identifiers", "Only last four digits are present; no SSN, full account number, or real contact information is included."),
            ]
        ),
        PageBreak(),
    ]

    # Page 3: change history drives the Review deck.
    story += [
        P("Recent changes since December 10, 2025", "PageTitle"),
        P("Mosaic compares the prior and current snapshots, then asks the user to recognize, not recognize, or defer each change.", "BodyMosaic"),
        table(
            [
                [cell("Change", True), cell("Prior snapshot", True), cell("Current snapshot", True), cell("Review cue", True)],
                [cell("Balance increase · account 4421"), cell("$1,200"), cell("$8,700"), cell("Compare with statements; note any amount you cannot explain.")],
                [cell("Joint responsibility · account 4421"), cell("Individual"), cell("Joint account"), cell("Confirm whether the joint designation is accurate.")],
                [cell("New collection · account 9812"), cell("Not present"), cell("Harbor Recovery Collections · $2,140"), cell("Review the source page and gather records before drafting anything.")],
                [cell("New hard inquiry"), cell("None"), cell("Northstar Lending · Feb 14, 2026"), cell("Decide whether you recognize the inquiry.")],
                [cell("New address"), cell("100 Peachtree Demo Ave"), cell("44 Example Lane"), cell("Confirm the address belongs on the file.")],
            ],
            [1.6 * inch, 1.3 * inch, 2.15 * inch, 2.15 * inch],
        ),
        P("Hard inquiries", "Section"),
        table(
            [
                [cell("Inquirer", True), cell("Date", True), cell("Purpose", True), cell("Source", True)],
                [cell("Northstar Lending"), cell("February 14, 2026"), cell("Credit application"), cell("Page 3 · synthetic record")],
            ],
            [2.1 * inch, 1.35 * inch, 1.75 * inch, 2.0 * inch],
        ),
        P("How this powers the demo", "Section"),
        P("The app’s PDF reader extracts the pages locally. Because this fixture is clearly labeled synthetic and includes the Harbor and Northstar markers, Mosaic loads the matching prior/current demo snapshots so the Review deck, follow-up tasks, Gemini overview, and Harbor letter are populated consistently.", "BodyMosaic"),
        PageBreak(),
    ]

    # Page 4: supporting fields and guardrails.
    story += [
        P("Additional report information", "PageTitle"),
        P("Supporting sections make the file feel like a complete report while keeping every value fictional and masked.", "BodyMosaic"),
        P("Public-record and identity sections", "Section"),
        table(
            [
                [cell("Section", True), cell("Result", True)],
                [cell("Bankruptcies"), cell("None reported" )],
                [cell("Civil judgments"), cell("None reported")],
                [cell("Tax liens"), cell("None reported")],
                [cell("Foreclosures"), cell("None reported")],
                [cell("Employers"), cell("Peachtree Design Studio · reported January 2024")],
                [cell("Consumer statement"), cell("No statement on file")],
            ],
            [2.1 * inch, 5.1 * inch],
        ),
        P("Parser test notes", "Section"),
        key_value(
            [
                ("Expected report marker", "SYNTHETIC DEMO DATA — NOT A REAL CREDIT REPORT"),
                ("Expected account marker", "Harbor Recovery Collections · reference ending 9812"),
                ("Expected inquiry marker", "Northstar Lending · February 14, 2026"),
                ("Expected page count", "4 pages"),
                ("Sensitive-data policy", "No real SSNs, full account numbers, bank credentials, or real recipient addresses are included."),
            ]
        ),
        Spacer(1, 0.14 * inch),
        Table(
            [[P("Demo guardrail: Mosaic prepares a draft for review. It does not submit a dispute or send an email automatically.", "Notice")]],
            colWidths=[7.2 * inch],
            style=TableStyle(
                [
                    ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F8E6EA")),
                    ("BOX", (0, 0), (-1, -1), 0.7, RED),
                    ("LEFTPADDING", (0, 0), (-1, -1), 12),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 12),
                    ("TOPPADDING", (0, 0), (-1, -1), 11),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 11),
                ]
            ),
        ),
    ]

    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    print(OUTPUT)


if __name__ == "__main__":
    build()
