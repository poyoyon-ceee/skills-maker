const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, PageOrientation, BorderStyle,
  WidthType, ShadingType, VerticalAlign, TableLayoutType, TabStopType,
} = require("docx");
const fs = require("fs");
const path = require("path");

const OUT = path.join(__dirname, "..", "skills一覧手動_独自開発-デザイン-Git.docx");

const C = {
  dark: "1E1E1E",
  blue: "0066FF",
  cyan: "0066FF",
  headerText: "FFFFFF",
  cmd: "0052CC",
  ink: "1E1E1E",
  mute: "4A4A4A",
  line: "D0D7DE",
  alt: "F4F7FC",
  white: "FFFFFF",
  section: "0B3D91",
  noteBg: "EEF3FA",
};

const FONT = "Yu Gothic";
const MONO = "Consolas";
const PAGE_W = 15718; // A4 landscape long edge minus 0.39" sides (16838 - 560*2)

const bThin = { style: BorderStyle.SINGLE, size: 4, color: C.line };
const bNone = { style: BorderStyle.NONE, size: 0, color: "FFFFFF" };
const borders = { top: bThin, bottom: bThin, left: bThin, right: bThin };
const bordersOpen = { top: bThin, bottom: bThin, left: bNone, right: bNone };

function p(runs, opts = {}) {
  return new Paragraph({
    spacing: { before: 0, after: 0, line: 240 },
    ...opts,
    children: runs,
  });
}

function run(text, extra = {}) {
  return new TextRun({
    text,
    font: FONT,
    size: 18,
    color: C.ink,
    ...extra,
  });
}

function cell(children, width, extra = {}) {
  return new TableCell({
    borders,
    width: { size: width, type: WidthType.DXA },
    shading: { fill: extra.fill || C.white, type: ShadingType.CLEAR },
        margins: { top: 20, bottom: 20, left: 60, right: 60 },
    verticalAlign: extra.valign || VerticalAlign.CENTER,
    columnSpan: extra.span,
    children,
  });
}

function headerCell(text, width, extra = {}) {
  return cell(
    [p([run(text, { bold: true, color: C.headerText, size: extra.size || 16 })])],
    width,
    { fill: extra.fill || C.dark }
  );
}

function cmdCell(cmd, width, fill) {
  return cell(
    [p([run(cmd, { font: MONO, bold: true, color: C.cmd, size: 18 })])],
    width,
    { fill }
  );
}

function textCell(text, width, fill) {
  return cell([p([run(text, { size: 16, color: C.ink })])], width, { fill });
}

function sectionRow(label, widths) {
  const total = widths.reduce((a, b) => a + b, 0);
  return new TableRow({
    cantSplit: true,
    children: [
      cell(
        [p([run(label, { bold: true, color: C.headerText, size: 18 })])],
        total,
        { fill: C.section, span: widths.length }
      ),
    ],
  });
}

function dataRow(cmd, what, when, widths, alt) {
  const fill = alt ? C.alt : C.white;
  return new TableRow({
    cantSplit: true,
    children: [
      cmdCell(cmd, widths[0], fill),
      textCell(what, widths[1], fill),
      textCell(when, widths[2], fill),
    ],
  });
}

const W = [2600, 7200, 5918]; // 15718
if (W[0] + W[1] + W[2] !== PAGE_W) {
  throw new Error("main widths " + (W[0] + W[1] + W[2]));
}

const mainRows = [
  new TableRow({
    tableHeader: true,
    cantSplit: true,
    children: [
      headerCell("コマンド", W[0]),
      headerCell("何をする", W[1]),
      headerCell("いつ使う", W[2]),
    ],
  }),
  sectionRow("3. 独自の開発系スキル（7件）", W),
  dataRow(
    "/00",
    "そのターンだけ Superpowers を切る。次のメッセージには引き継がない。",
    "今の依頼だけ素早く処理したいとき。文章中・コード内では発動しない。",
    W, false
  ),
  dataRow(
    "/chat-handoff",
    "別PC用メモを 質疑応答M-D.MD に書く。結論・決定・未解決TODOを残す。",
    "「別PC用に残して」と明示されたとき。通常の備忘は /session-recap。",
    W, true
  ),
  dataRow(
    "/new-project",
    "空フォルダの土台。README必須。既存ファイルは上書きしない。",
    "新規と判定されたとき。既存リポジトリでは使わない。",
    W, false
  ),
  dataRow(
    "/session-recap",
    "会話を 備忘録.md の日付エントリにする。変更履歴.md には書かない。",
    "「まとめて」「備忘録に残して」と明示されたときだけ。",
    W, true
  ),
  dataRow(
    "/to-issues",
    "プラン・仕様・PRDを、独立して着手できる Issue に分解する。",
    "設計書を実装可能な単位に分割したいとき。",
    W, false
  ),
  dataRow(
    "/to-knowledge",
    "決定・失敗・設定だけを Obsidian の 04_知見 へ提案。書く前に承認を取る。",
    "「知見に落として」と明示されたとき。時系列の備忘は /session-recap。",
    W, true
  ),
  dataRow(
    "/to-prd",
    "会話をヒアリングなしで PRD にして、Issue トラッカーへ公開する。",
    "要件がすでに固まっており、そのまま PRD 化したいとき。",
    W, false
  ),
  sectionRow("4. デザイン・コンテンツ制作（2件）", W),
  dataRow(
    "/debug-allrun",
    "データ破損・非同期レース・分岐ミスの3種を探索・自動修正・報告する。",
    "明示したとき。「クラッシュしないから安全」を信用しない。",
    W, true
  ),
  dataRow(
    "/edit-article",
    "見出しで章分けし、明確さ・一貫性・流れで書き直す。1段落は最大240字。",
    "記事の下書きを編集・改善・推敲したいとき。",
    W, false
  ),
  sectionRow("5. GitHub / Git 運用（2件）", W),
  dataRow(
    "/git-in-clone",
    "指定した GitHub リポジトリを、今いる空フォルダへ git clone . で取り込む。",
    "「このフォルダにクローンして」と言われたとき。",
    W, true
  ),
  dataRow(
    "/github-make-sync",
    "非公開 GitHub リポジトリを作り、gh CLI で origin を付ける。",
    "新規プロジェクトを GitHub に接続したいとき。",
    W, false
  ),
];

const mainTable = new Table({
  width: { size: PAGE_W, type: WidthType.DXA },
  columnWidths: W,
  layout: TableLayoutType.FIXED,
  rows: mainRows,
});

const U = [5239, 5239, 5240];
function useCell(title, cmd, dest, whenNot, width) {
  return cell(
    [
      p([
        run(title + "  ", { bold: true, size: 16, color: C.section }),
        run(cmd, { font: MONO, bold: true, size: 16, color: C.cmd }),
      ]),
      p([run(dest + "  /  " + whenNot, { size: 15, color: C.mute })]),
    ],
    width,
    { fill: C.noteBg, valign: VerticalAlign.CENTER }
  );
}

const useTable = new Table({
  width: { size: PAGE_W, type: WidthType.DXA },
  columnWidths: U,
  layout: TableLayoutType.FIXED,
  rows: [
    new TableRow({
      cantSplit: true,
      children: [
        cell(
          [p([run("記録の置き場は3つ。混ぜない。", { bold: true, color: C.headerText, size: 18 })])],
          PAGE_W,
          { fill: C.dark, span: 3 }
        ),
      ],
    }),
    new TableRow({
      cantSplit: true,
      children: [
        useCell("別PCへ引き継ぐ", "/chat-handoff", "質疑応答M-D.MD（リポジトリ直下）", "同じPCの備忘には使わない", U[0]),
        useCell("同じPCの備忘", "/session-recap", "備忘録.md（日付エントリ）", "別PC引き継ぎには使わない", U[1]),
        useCell("残す価値だけ", "/to-knowledge", "Obsidian  04_知見", "時系列の備忘には使わない", U[2]),
      ],
    }),
  ],
});

const N = [3929, 3929, 3930, 3930];
function noteCell(title, body, w) {
  return cell(
    [
      p([run(title, { bold: true, size: 15, color: C.section })]),
      p([run(body, { size: 15 })]),
    ],
    w,
    { fill: C.white, valign: VerticalAlign.TOP }
  );
}

const noteTable = new Table({
  width: { size: PAGE_W, type: WidthType.DXA },
  columnWidths: N,
  layout: TableLayoutType.FIXED,
  rows: [
    new TableRow({
      cantSplit: true,
      children: [
        cell(
          [p([run("補足", { bold: true, color: C.headerText, size: 16 })])],
          PAGE_W,
          { fill: C.dark, span: 4 }
        ),
      ],
    }),
    new TableRow({
      cantSplit: true,
      children: [
        noteCell("計19件", "playbooks 7 + その他12。日常パック59件のうち手動はこれだけ。", N[0]),
        noteCell("自動は別", "/project-foundation は自動。土台作りは /new-project。", N[1]),
        noteCell("明示が必要", "モデルは自分で選ばない。 /  で呼び出す。", N[2]),
        noteCell("正本", "skills一覧.md。マーケは marketing-skills一覧.md。", N[3]),
      ],
    }),
  ],
});

const doc = new Document({
  styles: {
    default: {
      document: { run: { font: FONT, size: 18 } },
    },
  },
  sections: [
    {
      properties: {
        page: {
          size: {
            width: 11906,
            height: 16838,
            orientation: PageOrientation.LANDSCAPE,
          },
          margin: { top: 360, right: 480, bottom: 280, left: 480 },
        },
      },
      headers: {
        default: new Header({
          children: [new Paragraph({ spacing: { before: 0, after: 0 }, children: [] })],
        }),
      },
      footers: {
        default: new Footer({
          children: [
            new Paragraph({
              spacing: { before: 60, after: 0 },
              children: [
                run("出典  skills一覧手動.md    パワポ版は同名の .pptx（6枚）", {
                  size: 15,
                  color: C.mute,
                }),
              ],
            }),
          ],
        }),
      },
      children: [
        new Paragraph({
          spacing: { before: 0, after: 60 },
          tabStops: [{ type: TabStopType.RIGHT, position: PAGE_W }],
          children: [
            run("手動スキル  §3–5 + 補足", { bold: true, size: 26, color: C.dark }),
            run("\t"),
            run("11コマンド  /  印刷用1枚", { size: 18, color: C.mute }),
          ],
        }),
        mainTable,
        new Paragraph({ spacing: { before: 80, after: 0 }, children: [] }),
        useTable,
        new Paragraph({ spacing: { before: 80, after: 0 }, children: [] }),
        noteTable,
      ],
    },
  ],
});

Packer.toBuffer(doc).then((buffer) => {
  fs.writeFileSync(OUT, buffer);
  console.log("Wrote", OUT);
});
