"""Generate A4 vertical multi-page skills catalog PDF (System Atlas).

Regenerate after updating skills一覧.md:
    python scripts/generate_skills_catalog_pdf.py
    # or:  .\\scripts\\update-skills-catalog.ps1
"""
import os
import re
import tempfile
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas

ROOT = Path(__file__).resolve().parent.parent
MD_PATH = ROOT / "skills一覧.md"
FONTS_DIR = ROOT / "skills-pack" / "canvas-design" / "canvas-fonts"
OUT_PDF = ROOT / "catalog" / "skills-catalog-system-atlas.pdf"

W, H = A4
MARGIN = 18 * mm
CONTENT_W = W - 2 * MARGIN

# Print-oriented: pure white page, subtle grid/card contrast
PAPER = colors.white
CARD_BG = colors.HexColor("#F7F7F7")
INK = colors.HexColor("#1A2B3C")
INK_LIGHT = colors.HexColor("#5A6570")
GRID = colors.HexColor("#E0E0E0")
MANUAL = colors.HexColor("#C45B3C")

# Typography: min 10pt (print). Body 10–11pt; commands 12pt; page titles ≤17pt.
FS = {
    "cover_title": 34,
    "cover_sub": 14,
    "cover_meta": 11,
    "cover_bar": 10,
    "cover_legend": 11,
    "footer": 10,
    "index_title": 17,
    "index_sub": 11,
    "index_cell_no": 10,
    "index_cell_title": 12,
    "index_cell_count": 10,
    "index_note": 10,
    "card_ref": 10,
    "card_cmd": 12,
    "card_manual": 10,
    "card_desc": 11,
    "card_usage": 10,
    "cat_no": 10,
    "cat_title": 13,
    "cat_note": 10,
    "sub_title": 11,
    "cont": 10,
    "play_title": 17,
    "play_sub": 10,
    "play_cmd": 12,
    "play_flow": 10,
    "play_usage": 10,
    "back_title": 20,
    "back_body": 11,
    "back_tag": 10,
}
CAT_COLORS = [
    colors.HexColor("#2D4A6F"),
    colors.HexColor("#4A6741"),
    colors.HexColor("#3B6EA5"),
    colors.HexColor("#6B4C8A"),
    colors.HexColor("#3D5A80"),
    colors.HexColor("#C45B3C"),
    colors.HexColor("#7D6B5D"),
    colors.HexColor("#5C4033"),
    colors.HexColor("#8B3A62"),
]

CAT_SHORT = [
    "Orchestrator",
    "Document",
    "GWS",
    "Superpowers",
    "Development",
    "Design",
    "Knowledge",
    "Git",
    "Marketing",
]


def register_fonts():
    pdfmetrics.registerFont(TTFont("YuGothic", r"C:\Windows\Fonts\YuGothM.ttc", subfontIndex=0))
    pdfmetrics.registerFont(TTFont("YuGothic-Bold", r"C:\Windows\Fonts\YuGothB.ttc", subfontIndex=0))
    pdfmetrics.registerFont(TTFont("Bricolage", str(FONTS_DIR / "BricolageGrotesque-Bold.ttf")))
    pdfmetrics.registerFont(TTFont("Instrument", str(FONTS_DIR / "InstrumentSerif-Regular.ttf")))
    pdfmetrics.registerFont(TTFont("Mono", str(FONTS_DIR / "JetBrainsMono-Regular.ttf")))
    pdfmetrics.registerFont(TTFont("MonoBold", str(FONTS_DIR / "JetBrainsMono-Bold.ttf")))


def parse_markdown(text: str):
    sections = []
    current_section = None
    current_subsection = None
    in_table = False
    section_note = ""

    for line in text.splitlines():
        if m := re.match(r"^## (\d+)\.\s+(.+)$", line):
            current_section = {
                "no": int(m.group(1)),
                "title": m.group(2),
                "note": "",
                "subsections": [],
                "rows": [],
            }
            current_subsection = None
            section_note = ""
            sections.append(current_section)
            in_table = False
            continue

        if current_section and line.startswith("**") and not line.startswith("|"):
            clean = re.sub(r"\*+", "", line).strip()
            if clean and "手動のみ" in clean or "前提" in clean or "すべて" in clean:
                current_section["note"] = clean

        if m := re.match(r"^### (.+)$", line):
            if current_section is not None:
                current_subsection = m.group(1)
                current_section["subsections"].append({"title": current_subsection, "rows": []})
            in_table = False
            continue

        if line.strip().startswith("|") and "---" not in line:
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            if not in_table:
                in_table = True
                continue
            if len(cells) < 3:
                continue
            cmd, desc, usage = cells[0], cells[1], cells[2]
            if usage.strip() == "—":
                continue
            manual = "手動のみ" in cmd
            cmd_clean = cmd.replace("（手動のみ）", "").strip().strip("`")
            if not cmd_clean.startswith("/"):
                cmd_clean = "/" + cmd_clean.lstrip("/")
            row = {
                "command": cmd_clean,
                "description": re.sub(r"`+", "", desc),
                "usage": usage,
                "manual_only": manual,
            }
            if current_section is not None:
                if current_subsection and current_section["subsections"]:
                    current_section["subsections"][-1]["rows"].append(row)
                else:
                    current_section["rows"].append(row)
            continue

        if not line.strip().startswith("|"):
            in_table = False

    return sections


def wrap_text(text, font, size, max_width, c):
    if not text:
        return []
    words = list(text)
    lines, current = [], ""
    for ch in words:
        test = current + ch
        if pdfmetrics.stringWidth(test, font, size) <= max_width:
            current = test
        else:
            if current:
                lines.append(current)
            current = ch
    if current:
        lines.append(current)
    return lines


def draw_page_accent(c, color, height=1.2 * mm):
    c.setFillColor(color)
    c.rect(0, H - height, W, height, fill=1, stroke=0)


def extract_meta(md_text: str) -> dict:
    date = "—"
    for line in md_text.splitlines():
        if line.startswith("取得日:"):
            date = line.split(":", 1)[1].strip()
            break
    m = re.search(r"全(\d+)件", md_text)
    total_label = m.group(1) if m else "?"
    return {"date": date, "total_label": total_label}


def draw_page_footer(c, page_num, total, label=""):
    c.setStrokeColor(GRID)
    c.setLineWidth(0.4)
    c.line(MARGIN, 14 * mm, W - MARGIN, 14 * mm)
    c.setFillColor(INK_LIGHT)
    c.setFont("Mono", FS["footer"])
    c.drawString(MARGIN, 10 * mm, label or "SYSTEM ATLAS · CURSOR GLOBAL SKILLS")
    c.drawRightString(W - MARGIN, 10 * mm, f"{page_num:02d} / {total:02d}")


def draw_cover(c, sections, total_pages, meta):
    c.setFillColor(PAPER)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    draw_page_accent(c, INK, 2 * mm)

    c.setFillColor(INK)
    c.setFont("Instrument", FS["cover_title"])
    c.drawString(MARGIN, H - 55 * mm, "System")
    c.drawString(MARGIN, H - 72 * mm, "Atlas")

    c.setFont("YuGothic", FS["cover_sub"])
    c.setFillColor(INK_LIGHT)
    c.drawString(MARGIN, H - 88 * mm, "Cursor グローバルスキル · カタログ")

    total_skills = sum(
        len(s["rows"]) + sum(len(sub["rows"]) for sub in s["subsections"])
        for s in sections
    )
    c.setFont("Mono", FS["cover_meta"])
    c.drawString(
        MARGIN,
        H - 98 * mm,
        f"SPECIMEN COUNT: {total_skills}  ·  CATEGORIES: {len(sections)}  ·  {meta['date']}",
    )

    bar_x = MARGIN
    bar_y = H - 130 * mm
    bar_h = 6 * mm
    max_count = max(
        len(s["rows"]) + sum(len(sub["rows"]) for sub in s["subsections"])
        for s in sections
    )
    gap = 2 * mm
    for i, sec in enumerate(sections):
        count = len(sec["rows"]) + sum(len(sub["rows"]) for sub in sec["subsections"])
        bw = (count / max_count) * (CONTENT_W * 0.85)
        c.setFillColor(CAT_COLORS[i])
        c.rect(bar_x, bar_y - i * (bar_h + gap), bw, bar_h, fill=1, stroke=0)
        c.setFillColor(INK_LIGHT)
        c.setFont("Mono", FS["cover_bar"])
        c.drawString(bar_x + bw + 3 * mm, bar_y - i * (bar_h + gap) + 1.5 * mm, f"§{sec['no']:02d}  {count}")

    c.setFillColor(INK)
    c.setFont("YuGothic", FS["cover_legend"])
    c.drawString(MARGIN, 28 * mm, "凡例 — コマンド / 説明 / 使いどころ")
    c.setFillColor(MANUAL)
    c.rect(MARGIN, 22 * mm, 3 * mm, 3 * mm, fill=1, stroke=0)
    c.setFillColor(INK_LIGHT)
    c.drawString(MARGIN + 5 * mm, 22.5 * mm, "手動のみ（明示呼び出し）")

    draw_page_footer(c, 1, total_pages, "COVER · FOLIO I")


def draw_overview(c, sections, page_num, total_pages):
    c.setFillColor(PAPER)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    draw_page_accent(c, INK)

    c.setFillColor(INK)
    c.setFont("Bricolage", FS["index_title"])
    c.drawString(MARGIN, H - 32 * mm, "INDEX")

    c.setFont("YuGothic", FS["index_sub"])
    c.setFillColor(INK_LIGHT)
    c.drawString(MARGIN, H - 40 * mm, "9カテゴリ · 縦断カタログ — 各章は独立 folio")

    y = H - 52 * mm
    col_w = CONTENT_W / 3 - 4 * mm
    for i, sec in enumerate(sections):
        col = i % 3
        row = i // 3
        x = MARGIN + col * (col_w + 6 * mm)
        cy = y - row * 38 * mm

        c.setFillColor(CAT_COLORS[i])
        c.rect(x, cy - 28 * mm, col_w, 28 * mm, fill=1, stroke=0)

        c.setFillColor(colors.white)
        c.setFont("Mono", FS["index_cell_no"])
        c.drawString(x + 3 * mm, cy - 6 * mm, f"§{sec['no']:02d}")

        c.setFont("YuGothic-Bold", FS["index_cell_title"])
        title = sec["title"].split("（")[0][:18]
        c.drawString(x + 3 * mm, cy - 14 * mm, title)

        count = len(sec["rows"]) + sum(len(sub["rows"]) for sub in sec["subsections"])
        c.setFont("Mono", FS["index_cell_count"])
        c.drawString(x + 3 * mm, cy - 22 * mm, f"{count} skills")

    c.setFillColor(INK)
    c.setFont("YuGothic", FS["index_note"])
    notes = [
        "運用: ~/.cursor/skills/ にグローバル配置",
        "Playbook = 複数スキルの進行台本（手動のみ）",
        "マーケ46件 = product-marketing.md を先に確認",
    ]
    ny = 45 * mm
    for note in notes:
        c.drawString(MARGIN, ny, f"· {note}")
        ny -= 5 * mm

    draw_page_footer(c, page_num, total_pages, "INDEX · FOLIO II")


def estimate_card_height(c, row, width):
    desc_lines = wrap_text(row["description"], "YuGothic", FS["card_desc"], width - 8 * mm, c)
    usage_lines = wrap_text(row["usage"], "YuGothic", FS["card_usage"], width - 8 * mm, c)
    lh_desc = 4.5 * mm
    lh_usage = 4.2 * mm
    return 18 * mm + len(desc_lines) * lh_desc + len(usage_lines) * lh_usage + 4 * mm


def draw_skill_card(c, x, y, w, row, cat_color, ref):
    h = estimate_card_height(c, row, w)
    c.setFillColor(CARD_BG)
    c.setStrokeColor(GRID)
    c.setLineWidth(0.4)
    c.roundRect(x, y - h, w, h, 2, fill=1, stroke=1)

    c.setFillColor(cat_color)
    c.rect(x, y - h, 2.5 * mm, h, fill=1, stroke=0)

    c.setFillColor(INK_LIGHT)
    c.setFont("Mono", FS["card_ref"])
    c.drawString(x + 5 * mm, y - 5 * mm, ref)

    cmd = row["command"]
    c.setFillColor(INK)
    c.setFont("MonoBold", FS["card_cmd"])
    c.drawString(x + 5 * mm, y - 13 * mm, cmd[:42])

    if row["manual_only"]:
        c.setFillColor(MANUAL)
        c.setFont("Mono", FS["card_manual"])
        c.drawRightString(x + w - 3 * mm, y - 5 * mm, "MANUAL")

    ty = y - 19 * mm
    c.setFillColor(INK)
    c.setFont("YuGothic", FS["card_desc"])
    for line in wrap_text(row["description"], "YuGothic", FS["card_desc"], w - 8 * mm, c)[:3]:
        c.drawString(x + 5 * mm, ty, line)
        ty -= 4.5 * mm

    c.setFillColor(INK_LIGHT)
    c.setFont("YuGothic", FS["card_usage"])
    for line in wrap_text(row["usage"], "YuGothic", FS["card_usage"], w - 8 * mm, c)[:2]:
        c.drawString(x + 5 * mm, ty, line)
        ty -= 4.2 * mm

    return h


def draw_category_header(c, sec, cat_idx, y):
    hdr_h = 16 * mm if sec.get("note") else 14 * mm
    c.setFillColor(CAT_COLORS[cat_idx])
    c.rect(MARGIN, y - hdr_h, CONTENT_W, hdr_h, fill=1, stroke=0)
    c.setFillColor(colors.white)
    c.setFont("Mono", FS["cat_no"])
    c.drawString(MARGIN + 4 * mm, y - 7 * mm, f"§{sec['no']:02d}")
    c.setFont("YuGothic-Bold", FS["cat_title"])
    title = sec["title"][:40]
    c.drawString(MARGIN + 18 * mm, y - 9 * mm, title)
    if sec.get("note"):
        c.setFont("YuGothic", FS["cat_note"])
        c.drawString(MARGIN + 4 * mm, y - 13.5 * mm, sec["note"][:80])
    return y - hdr_h - 4 * mm


def draw_subsection_header(c, title, y, cat_color):
    c.setFillColor(cat_color)
    c.setFillAlpha(0.12)
    c.rect(MARGIN, y - 9 * mm, CONTENT_W, 9 * mm, fill=1, stroke=0)
    c.setFillAlpha(1)
    c.setFillColor(INK)
    c.setFont("YuGothic-Bold", FS["sub_title"])
    c.drawString(MARGIN + 3 * mm, y - 6 * mm, title)
    return y - 13 * mm


def paginate_sections(sections):
    """Split categories into pages using estimated card heights."""
    tmp = tempfile.NamedTemporaryFile(suffix=".pdf", delete=False)
    tmp.close()
    dummy = canvas.Canvas(tmp.name, pagesize=A4)

    pages = []
    for cat_idx, sec in enumerate(sections):
        items = []
        ref = 0
        for row in sec["rows"]:
            ref += 1
            items.append({"kind": "row", "row": row, "ref": ref})
        for sub in sec["subsections"]:
            if sub["rows"]:
                items.append({"kind": "subheader", "title": sub["title"]})
                for row in sub["rows"]:
                    ref += 1
                    items.append({"kind": "row", "row": row, "ref": ref})

        chunk = []
        y_budget = H - 52 * mm
        is_continuation = False

        for item in items:
            need = 14 * mm if item["kind"] == "subheader" else estimate_card_height(dummy, item["row"], CONTENT_W) + 3 * mm
            if chunk and y_budget - need < 26 * mm:
                pages.append({"sec": sec, "cat_idx": cat_idx, "items": chunk, "cont": is_continuation})
                chunk = []
                y_budget = H - 30 * mm
                is_continuation = True
            chunk.append(item)
            y_budget -= need

        if chunk:
            pages.append({"sec": sec, "cat_idx": cat_idx, "items": chunk, "cont": is_continuation})

    dummy.save()
    os.unlink(tmp.name)
    return pages


def draw_category_page(c, page_data, page_num, total_pages):
    sec = page_data["sec"]
    cat_idx = page_data["cat_idx"]
    cat_color = CAT_COLORS[cat_idx]

    c.setFillColor(PAPER)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    draw_page_accent(c, cat_color)

    y = H - 22 * mm
    if not page_data.get("cont"):
        y = draw_category_header(c, sec, cat_idx, y)
    else:
        c.setFillColor(cat_color)
        c.setFont("Mono", FS["cat_no"])
        c.drawString(MARGIN, y, f"§{sec['no']:02d}")
        c.setFillColor(INK_LIGHT)
        c.setFont("YuGothic", FS["cont"])
        c.drawString(MARGIN + 12 * mm, y, "— continued")
        y -= 10 * mm

    for item in page_data["items"]:
        if item["kind"] == "subheader":
            y = draw_subsection_header(c, item["title"], y, cat_color)
            continue
        ref = f"§{sec['no']:02d}.{item['ref']:02d}"
        h = draw_skill_card(c, MARGIN, y, CONTENT_W, item["row"], cat_color, ref)
        y -= h + 3 * mm

    draw_page_footer(c, page_num, total_pages, f"§{sec['no']:02d} · {CAT_SHORT[cat_idx]}")


def draw_playbook_flow(c, sections, page_num, total_pages):
    sec = sections[0]
    c.setFillColor(PAPER)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    draw_page_accent(c, CAT_COLORS[0])

    c.setFillColor(INK)
    c.setFont("Bricolage", FS["play_title"])
    c.drawString(MARGIN, H - 30 * mm, "PLAYBOOK ROUTES")

    c.setFont("YuGothic", FS["play_sub"])
    c.setFillColor(INK_LIGHT)
    c.drawString(MARGIN, H - 38 * mm, "進行台本 — 矢印は推奨実行順序")

    block_h = 26 * mm
    y = H - 46 * mm
    for i, row in enumerate(sec["rows"]):
        c.setFillColor(CAT_COLORS[0])
        c.setFillAlpha(0.15)
        c.roundRect(MARGIN, y - block_h, CONTENT_W, block_h, 3, fill=1, stroke=0)
        c.setFillAlpha(1)

        c.setFillColor(INK)
        c.setFont("MonoBold", FS["play_cmd"])
        c.drawString(MARGIN + 4 * mm, y - 8 * mm, row["command"])

        flow = row["description"].split("。")[0][:85]
        c.setFont("Mono", FS["play_flow"])
        c.setFillColor(INK_LIGHT)
        c.drawString(MARGIN + 4 * mm, y - 15 * mm, flow)

        c.setFont("YuGothic", FS["play_usage"])
        usage = row["usage"][:50]
        c.drawString(MARGIN + 4 * mm, y - 21 * mm, usage)

        if i < len(sec["rows"]) - 1:
            c.setStrokeColor(CAT_COLORS[0])
            c.setLineWidth(0.8)
            cx = W / 2
            c.line(cx, y - block_h - 1 * mm, cx, y - block_h - 4 * mm)
            c.line(cx - 2, y - block_h - 3 * mm, cx, y - block_h - 4 * mm)
            c.line(cx + 2, y - block_h - 3 * mm, cx, y - block_h - 4 * mm)

        y -= block_h + 4 * mm

    draw_page_footer(c, page_num, total_pages, "PLAYBOOKS · §01")


def draw_back(c, page_num, total_pages):
    c.setFillColor(PAPER)
    c.rect(0, 0, W, H, fill=1, stroke=0)
    draw_page_accent(c, INK)

    c.setFillColor(INK)
    c.setFont("Instrument", FS["back_title"])
    c.drawString(MARGIN, H - 40 * mm, "Colophon")

    c.setFont("YuGothic", FS["back_body"])
    c.setFillColor(INK_LIGHT)
    lines = [
        "出典: skills一覧.md · skills-pack/MANIFEST.json",
        "配布: skills-pack/ 一式 → ~/.cursor/skills/",
        "重複回避: skills-pack/skills重複処理.md",
        "GWS連携: PCごとに gws auth login が必要",
        "skills-cursor/ は本カタログ対象外",
    ]
    y = H - 55 * mm
    for line in lines:
        c.drawString(MARGIN, y, line)
        y -= 7 * mm

    c.setFillColor(CAT_COLORS[0])
    c.rect(MARGIN, 35 * mm, CONTENT_W, 0.5 * mm, fill=1, stroke=0)
    c.setFont("Mono", FS["back_tag"])
    c.setFillColor(INK_LIGHT)
    c.drawString(MARGIN, 28 * mm, "SYSTEM ATLAS · meticulously crafted catalog")

    draw_page_footer(c, page_num, total_pages, "COLOPHON")


def main():
    register_fonts()
    md_text = MD_PATH.read_text(encoding="utf-8")
    meta = extract_meta(md_text)
    sections = parse_markdown(md_text)

    cat_pages = paginate_sections(sections)
    total_pages = 2 + 1 + len(cat_pages) + 1

    c = canvas.Canvas(str(OUT_PDF), pagesize=A4)
    c.setTitle("System Atlas — Cursor Global Skills Catalog")
    c.setAuthor("skills-maker")

    draw_cover(c, sections, total_pages, meta)
    c.showPage()

    draw_overview(c, sections, 2, total_pages)
    c.showPage()

    draw_playbook_flow(c, sections, 3, total_pages)
    c.showPage()

    for i, page_data in enumerate(cat_pages):
        draw_category_page(c, page_data, 4 + i, total_pages)
        c.showPage()

    draw_back(c, total_pages, total_pages)
    c.save()

    skill_count = sum(len(s["rows"]) + sum(len(sub["rows"]) for sub in s["subsections"]) for s in sections)
    print(f"PDF: {OUT_PDF}")
    print(f"Pages: {total_pages}, Skills: {skill_count}, Category pages: {len(cat_pages)}")


if __name__ == "__main__":
    main()
