const pptxgen = require("pptxgenjs");
const path = require("path");

const C = {
  blue: "0066FF",
  cyan: "00FFFF",
  dark: "1E1E1E",
  card: "2A2A2A",
  lift: "323232",
  white: "FFFFFF",
  mute: "B0B0B0",
  dim: "7E7E7E",
};

const FONT = "Yu Gothic";
const MONO = "Consolas";
const OUT = path.join(__dirname, "..", "skills一覧手動_独自開発-デザイン-Git.pptx");

function shadow() {
  return { type: "outer", color: "000000", blur: 12, offset: 3, angle: 135, opacity: 0.4 };
}

const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE";
pres.author = "Tom";
pres.title = "手動スキル 独自開発・デザイン・Git";
pres.subject = "skills一覧手動.md セクション3–5 + 補足";

function addRail(slide) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x: 0, y: 0, w: 0.12, h: 7.5,
    fill: { color: C.blue },
  });
}

function addFooter(slide, page) {
  slide.addText("skills一覧手動.md   §3–5 + 補足", {
    x: 0.5, y: 6.82, w: 8.5, h: 0.24,
    fontFace: FONT, fontSize: 11, color: C.mute, margin: 0,
  });
  slide.addText(String(page) + " / 6", {
    x: 11.5, y: 6.82, w: 1.3, h: 0.24,
    fontFace: FONT, fontSize: 11, color: C.mute, align: "right", margin: 0,
  });
}

function addKicker(slide, text) {
  slide.addText(text, {
    x: 0.5, y: 0.4, w: 12.3, h: 0.26,
    fontFace: FONT, fontSize: 12, color: C.cyan, bold: true,
    charSpacing: 1.5, margin: 0,
  });
}

function addTitle(slide, text) {
  slide.addText(text, {
    x: 0.5, y: 0.66, w: 12.3, h: 0.46,
    fontFace: FONT, fontSize: 26, color: C.white, bold: true, margin: 0,
  });
}

function addCard(slide, x, y, w, h) {
  slide.addShape(pres.shapes.RECTANGLE, {
    x, y, w, h,
    fill: { color: C.card },
    shadow: shadow(),
  });
  slide.addShape(pres.shapes.RECTANGLE, {
    x, y, w: 0.08, h,
    fill: { color: C.blue },
  });
}

// ---------------------------------------------------------------------------
// 1. Title
// ---------------------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.dark };
  addRail(s);

  s.addText("MANUAL SKILLS", {
    x: 0.55, y: 1.05, w: 7.5, h: 0.32,
    fontFace: FONT, fontSize: 13, color: C.cyan, bold: true,
    charSpacing: 3, margin: 0,
  });

  s.addText("独自の開発系スキル", {
    x: 0.55, y: 1.45, w: 8.2, h: 0.72,
    fontFace: FONT, fontSize: 40, color: C.white, bold: true, margin: 0,
  });

  s.addText("デザイン・コンテンツ制作   /   GitHub・Git 運用", {
    x: 0.55, y: 2.22, w: 8.2, h: 0.4,
    fontFace: FONT, fontSize: 18, color: C.mute, margin: 0,
  });

  const chips = [
    { n: "7", l: "開発系" },
    { n: "2", l: "デザイン" },
    { n: "2", l: "Git" },
  ];
  chips.forEach((c, i) => {
    const x = 0.55 + i * 2.94;
    const bar = i === 0 ? C.cyan : i === 1 ? C.blue : "7EB6FF";
    s.addShape(pres.shapes.RECTANGLE, {
      x, y: 3.2, w: 2.74, h: 1.4,
      fill: { color: C.card },
      shadow: shadow(),
    });
    s.addShape(pres.shapes.RECTANGLE, {
      x, y: 3.2, w: 0.08, h: 1.4,
      fill: { color: bar },
    });
    s.addText(c.n, {
      x: x + 0.24, y: 3.34, w: 2.3, h: 0.72,
      fontFace: FONT, fontSize: 36, color: C.white, bold: true, margin: 0,
    });
    s.addText(c.l + "コマンド", {
      x: x + 0.24, y: 4.1, w: 2.3, h: 0.32,
      fontFace: FONT, fontSize: 14, color: C.white, margin: 0,
    });
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.55, y: 4.82, w: 8.62, h: 1.55,
    fill: { color: C.card },
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.55, y: 4.82, w: 0.08, h: 1.55,
    fill: { color: C.blue },
  });
  s.addText("抜粋の範囲", {
    x: 0.85, y: 4.96, w: 8.1, h: 0.28,
    fontFace: FONT, fontSize: 12, color: C.cyan, bold: true, margin: 0,
  });
  s.addText("日常パック（MANIFEST 59件）のうち、手動で呼び出すこの範囲だけ。モデルは自分で選ばない。 /  で明示して使う。", {
    x: 0.85, y: 5.28, w: 8.1, h: 0.9,
    fontFace: FONT, fontSize: 15, color: C.white, margin: 0,
  });

  // Right visual block
  s.addShape(pres.shapes.RECTANGLE, {
    x: 9.35, y: 0, w: 3.95, h: 7.5,
    fill: { color: "141414" },
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 9.35, y: 0, w: 0.1, h: 7.5,
    fill: { color: C.cyan },
  });
  s.addText("11", {
    x: 9.55, y: 2.15, w: 3.55, h: 1.5,
    fontFace: FONT, fontSize: 96, color: C.cyan, bold: true, align: "center", margin: 0,
  });
  s.addText("コマンド", {
    x: 9.55, y: 3.65, w: 3.55, h: 0.45,
    fontFace: FONT, fontSize: 20, color: C.white, align: "center", margin: 0,
  });
  s.addText("＋ 補足 1枚", {
    x: 9.55, y: 4.15, w: 3.55, h: 0.32,
    fontFace: FONT, fontSize: 14, color: C.mute, align: "center", margin: 0,
  });

  addFooter(s, 1);
}

// ---------------------------------------------------------------------------
// 2. Dev skills 7
// ---------------------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.dark };
  addRail(s);
  addKicker(s, "SECTION  3");
  addTitle(s, "独自の開発系スキル（7件）");

  const items = [
    {
      cmd: "/00",
      what: "そのターンだけ Superpowers を切る。依頼本文はいつもどおり。次のメッセージには引き継がない。",
      when: "今の依頼だけ素早く処理したいとき。文章中・コード内では発動しない。",
    },
    {
      cmd: "/chat-handoff",
      what: "別PC用の引き継ぎメモを、リポジトリ直下の 質疑応答M-D.MD に書く。結論・決定・未解決TODOを残す。",
      when: "「別PC用に残して」と明示されたとき。",
    },
    {
      cmd: "/new-project",
      what: "空フォルダ向けの土台作り。必須は README。Hidem プロファイルは選択式。既存ファイルは上書きしない。",
      when: "新規と判定されたとき。既存リポジトリでは使わない。",
    },
    {
      cmd: "/session-recap",
      what: "今の会話を 備忘録.md の日付エントリにする。変更履歴.md には書かない。",
      when: "「まとめて」「備忘録に残して」と明示されたときだけ。",
    },
    {
      cmd: "/to-issues",
      what: "プラン・仕様・PRDを、独立して着手できる Issue に分解する。",
      when: "設計書を実装可能な単位に分割したいとき。",
    },
    {
      cmd: "/to-knowledge",
      what: "残す価値のある決定・失敗・設定だけを、Obsidian の 04_知見 へ提案。書く前に承認を取る。",
      when: "「知見に落として」と明示されたとき。作業ログは書かない。",
    },
    {
      cmd: "/to-prd",
      what: "会話をヒアリングなしで PRD にして、Issue トラッカーへ公開する。",
      when: "要件がすでに固まっており、そのまま PRD 化したいとき。",
    },
  ];

  const row1 = items.slice(0, 4);
  const row2 = items.slice(4);
  const gap = 0.28;
  const y1 = 1.28;
  const h = 2.46;
  const w1 = (13.3 - 1.0 - gap * 3) / 4;

  function paintCard(item, x, y, w) {
    addCard(s, x, y, w, h);
    s.addText(item.cmd, {
      x: x + 0.22, y: y + 0.12, w: w - 0.34, h: 0.34,
      fontFace: MONO, fontSize: 14, color: C.cyan, bold: true, margin: 0,
    });
    s.addText(item.what, {
      x: x + 0.22, y: y + 0.48, w: w - 0.38, h: 1.02,
      fontFace: FONT, fontSize: 12, color: C.white, margin: 0, valign: "top",
    });
    s.addText("いつ", {
      x: x + 0.22, y: y + 1.58, w: w - 0.38, h: 0.2,
      fontFace: FONT, fontSize: 10, color: C.cyan, bold: true, margin: 0,
    });
    s.addText(item.when, {
      x: x + 0.22, y: y + 1.78, w: w - 0.38, h: 0.56,
      fontFace: FONT, fontSize: 11, color: C.mute, margin: 0, valign: "top",
    });
  }

  row1.forEach((item, i) => paintCard(item, 0.5 + i * (w1 + gap), y1, w1));

  const y2 = y1 + h + gap;
  const w2 = (13.3 - 1.0 - gap * 2) / 3;
  row2.forEach((item, i) => paintCard(item, 0.5 + i * (w2 + gap), y2, w2));

  addFooter(s, 2);
}

// ---------------------------------------------------------------------------
// 3. Three destinations
// ---------------------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.dark };
  addRail(s);
  addKicker(s, "使い分け");
  addTitle(s, "記録の置き場は3つ。混ぜない。");

  const cols = [
    {
      cmd: "/chat-handoff",
      tag: "別PCへ引き継ぐ",
      dest: "質疑応答M-D.MD",
      where: "リポジトリ直下",
      keep: "結論・決定・未解決TODO",
      note: "Cursor のチャット履歴は、その端末に残る前提。",
      avoid: "同じPCの備忘には使わない",
    },
    {
      cmd: "/session-recap",
      tag: "同じPCの備忘",
      dest: "備忘録.md",
      where: "日付エントリ",
      keep: "決定・調査・次のTODO",
      note: "コード変更の履歴は 変更履歴.md には書かない。",
      avoid: "別PC引き継ぎには使わない",
    },
    {
      cmd: "/to-knowledge",
      tag: "残す価値だけ",
      dest: "04_知見",
      where: "Obsidian  04_知見",
      keep: "決定・失敗・再現コストの高い設定",
      note: "書く前に承認を取る。作業ログは書かない。",
      avoid: "時系列の備忘には使わない",
    },
  ];

  const gap = 0.3;
  const w = (13.3 - 1.0 - gap * 2) / 3;
  const y = 1.28;
  const h = 5.2;

  cols.forEach((c, i) => {
    const x = 0.5 + i * (w + gap);
    s.addShape(pres.shapes.RECTANGLE, {
      x, y, w, h,
      fill: { color: C.card },
      shadow: shadow(),
    });
    s.addShape(pres.shapes.RECTANGLE, {
      x, y, w, h: 0.12,
      fill: { color: i === 1 ? C.cyan : C.blue },
    });

    s.addText(c.tag, {
      x: x + 0.28, y: y + 0.32, w: w - 0.5, h: 0.3,
      fontFace: FONT, fontSize: 13, color: C.cyan, bold: true, margin: 0,
    });
    s.addText(c.cmd, {
      x: x + 0.28, y: y + 0.64, w: w - 0.5, h: 0.42,
      fontFace: MONO, fontSize: 18, color: C.white, bold: true, margin: 0,
    });

    const rows = [
      { k: "行き先", v: c.dest },
      { k: "場所", v: c.where },
      { k: "残すもの", v: c.keep },
    ];
    rows.forEach((r, ri) => {
      const ry = y + 1.28 + ri * 0.95;
      s.addText(r.k, {
        x: x + 0.28, y: ry, w: w - 0.5, h: 0.24,
        fontFace: FONT, fontSize: 11, color: C.mute, margin: 0,
      });
      s.addText(r.v, {
        x: x + 0.28, y: ry + 0.26, w: w - 0.5, h: 0.58,
        fontFace: FONT, fontSize: 16, color: C.white, bold: true, margin: 0, valign: "top",
      });
    });

    s.addText(c.note, {
      x: x + 0.28, y: y + 4.0, w: w - 0.5, h: 0.52,
      fontFace: FONT, fontSize: 13, color: C.mute, margin: 0, valign: "top",
    });
    s.addText(c.avoid, {
      x: x + 0.28, y: y + 4.58, w: w - 0.5, h: 0.42,
      fontFace: FONT, fontSize: 13, color: C.cyan, margin: 0, valign: "top",
    });
  });

  addFooter(s, 3);
}

// ---------------------------------------------------------------------------
// 4. Design / content
// ---------------------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.dark };
  addRail(s);
  addKicker(s, "SECTION  4");
  addTitle(s, "デザイン・コンテンツ制作（2件）");

  addCard(s, 0.5, 1.28, 6.0, 5.2);
  s.addText("/debug-allrun", {
    x: 0.76, y: 1.46, w: 5.48, h: 0.4,
    fontFace: MONO, fontSize: 22, color: C.cyan, bold: true, margin: 0,
  });
  s.addText("デバッガ付きで起動し、隠れバグを能動的に探索・自動修正・報告する。", {
    x: 0.76, y: 1.88, w: 5.48, h: 0.5,
    fontFace: FONT, fontSize: 14, color: C.white, margin: 0,
  });

  const bugs = [
    { n: "01", t: "サイレントなデータ破損", d: "落ちないまま中身が壊れる" },
    { n: "02", t: "非同期レース", d: "タイミング次第で結果が変わる" },
    { n: "03", t: "分岐ミス", d: "通らないはずの道を通る" },
  ];
  bugs.forEach((b, i) => {
    const y = 2.5 + i * 0.78;
    s.addShape(pres.shapes.RECTANGLE, {
      x: 0.76, y, w: 5.48, h: 0.68,
      fill: { color: C.lift },
    });
    s.addText(b.n, {
      x: 0.9, y, w: 0.7, h: 0.68,
      fontFace: MONO, fontSize: 16, color: C.cyan, bold: true, valign: "middle", margin: 0,
    });
    s.addText(b.t, {
      x: 1.68, y: y + 0.06, w: 4.36, h: 0.32,
      fontFace: FONT, fontSize: 15, color: C.white, bold: true, margin: 0,
    });
    s.addText(b.d, {
      x: 1.68, y: y + 0.34, w: 4.36, h: 0.26,
      fontFace: FONT, fontSize: 12, color: C.mute, margin: 0,
    });
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.76, y: 4.92, w: 5.48, h: 1.32,
    fill: { color: C.lift },
  });
  s.addText("いつ", {
    x: 0.96, y: 5.04, w: 5.08, h: 0.24,
    fontFace: FONT, fontSize: 12, color: C.cyan, bold: true, margin: 0,
  });
  s.addText([
    { text: "/debug-allrun を明示したとき。", options: { breakLine: true } },
    { text: "「クラッシュしないから安全」を信用しない。" },
  ], {
    x: 0.96, y: 5.3, w: 5.08, h: 0.82,
    fontFace: FONT, fontSize: 14, color: C.white, margin: 0,
  });

  addCard(s, 6.8, 1.28, 6.0, 5.2);
  s.addText("/edit-article", {
    x: 7.06, y: 1.46, w: 5.48, h: 0.4,
    fontFace: MONO, fontSize: 22, color: C.cyan, bold: true, margin: 0,
  });
  s.addText("記事を見出しで章分けし、各章を書き直す。", {
    x: 7.06, y: 1.88, w: 5.48, h: 0.5,
    fontFace: FONT, fontSize: 14, color: C.white, margin: 0,
  });

  const lens = [
    { n: "01", t: "明確さ", d: "何を言っているか、すぐ分かるか" },
    { n: "02", t: "一貫性", d: "用語・主張が途中でブレていないか" },
    { n: "03", t: "流れ", d: "章から章へ、読み手が迷わないか" },
  ];
  lens.forEach((b, i) => {
    const y = 2.5 + i * 0.78;
    s.addShape(pres.shapes.RECTANGLE, {
      x: 7.06, y, w: 5.48, h: 0.68,
      fill: { color: C.lift },
    });
    s.addText(b.n, {
      x: 7.2, y, w: 0.7, h: 0.68,
      fontFace: MONO, fontSize: 16, color: C.cyan, bold: true, valign: "middle", margin: 0,
    });
    s.addText(b.t, {
      x: 7.98, y: y + 0.06, w: 4.36, h: 0.32,
      fontFace: FONT, fontSize: 15, color: C.white, bold: true, margin: 0,
    });
    s.addText(b.d, {
      x: 7.98, y: y + 0.34, w: 4.36, h: 0.26,
      fontFace: FONT, fontSize: 12, color: C.mute, margin: 0,
    });
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 7.06, y: 4.92, w: 5.48, h: 1.32,
    fill: { color: C.lift },
  });
  s.addText("制約  /  いつ", {
    x: 7.26, y: 5.04, w: 5.08, h: 0.24,
    fontFace: FONT, fontSize: 12, color: C.cyan, bold: true, margin: 0,
  });
  s.addText([
    { text: "1段落は最大240字。", options: { breakLine: true } },
    { text: "記事の下書きを編集・改善・推敲したいとき。" },
  ], {
    x: 7.26, y: 5.3, w: 5.08, h: 0.82,
    fontFace: FONT, fontSize: 14, color: C.white, margin: 0,
  });

  addFooter(s, 4);
}

// ---------------------------------------------------------------------------
// 5. Git
// ---------------------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.dark };
  addRail(s);
  addKicker(s, "SECTION  5");
  addTitle(s, "GitHub / Git 運用（2件）");

  addCard(s, 0.5, 1.28, 6.0, 5.2);
  s.addText("01", {
    x: 0.76, y: 1.5, w: 1.2, h: 0.32,
    fontFace: MONO, fontSize: 14, color: C.cyan, bold: true, margin: 0,
  });
  s.addText("/git-in-clone", {
    x: 0.76, y: 1.84, w: 5.48, h: 0.42,
    fontFace: MONO, fontSize: 22, color: C.white, bold: true, margin: 0,
  });
  s.addText("指定した GitHub リポジトリを、今いる空フォルダへ取り込む。", {
    x: 0.76, y: 2.32, w: 5.48, h: 0.62,
    fontFace: FONT, fontSize: 16, color: C.white, margin: 0,
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.76, y: 3.08, w: 5.48, h: 1.55,
    fill: { color: C.lift },
  });
  s.addText("動き", {
    x: 0.96, y: 3.2, w: 5.08, h: 0.26,
    fontFace: FONT, fontSize: 12, color: C.cyan, bold: true, margin: 0,
  });
  s.addText("git clone .  で、現在の空ディレクトリへ取得する。", {
    x: 0.96, y: 3.5, w: 5.08, h: 0.95,
    fontFace: FONT, fontSize: 16, color: C.white, margin: 0,
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.76, y: 4.86, w: 5.48, h: 1.38,
    fill: { color: C.lift },
  });
  s.addText("いつ", {
    x: 0.96, y: 4.98, w: 5.08, h: 0.24,
    fontFace: FONT, fontSize: 12, color: C.cyan, bold: true, margin: 0,
  });
  s.addText("「このフォルダにクローンして」と言われたとき。", {
    x: 0.96, y: 5.26, w: 5.08, h: 0.82,
    fontFace: FONT, fontSize: 16, color: C.white, margin: 0,
  });

  addCard(s, 6.8, 1.28, 6.0, 5.2);
  s.addText("02", {
    x: 7.06, y: 1.5, w: 1.2, h: 0.32,
    fontFace: MONO, fontSize: 14, color: C.cyan, bold: true, margin: 0,
  });
  s.addText("/github-make-sync", {
    x: 7.06, y: 1.84, w: 5.48, h: 0.42,
    fontFace: MONO, fontSize: 22, color: C.white, bold: true, margin: 0,
  });
  s.addText("指定した名前で、非公開の GitHub リポジトリを新規作成する。", {
    x: 7.06, y: 2.32, w: 5.48, h: 0.62,
    fontFace: FONT, fontSize: 16, color: C.white, margin: 0,
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 7.06, y: 3.08, w: 5.48, h: 1.55,
    fill: { color: C.lift },
  });
  s.addText("動き", {
    x: 7.26, y: 3.2, w: 5.08, h: 0.26,
    fontFace: FONT, fontSize: 12, color: C.cyan, bold: true, margin: 0,
  });
  s.addText("gh CLI で、今のプロジェクトに origin を設定する。", {
    x: 7.26, y: 3.5, w: 5.08, h: 0.95,
    fontFace: FONT, fontSize: 16, color: C.white, margin: 0,
  });

  s.addShape(pres.shapes.RECTANGLE, {
    x: 7.06, y: 4.86, w: 5.48, h: 1.38,
    fill: { color: C.lift },
  });
  s.addText("いつ", {
    x: 7.26, y: 4.98, w: 5.08, h: 0.24,
    fontFace: FONT, fontSize: 12, color: C.cyan, bold: true, margin: 0,
  });
  s.addText("新規プロジェクトを GitHub に接続したいとき。", {
    x: 7.26, y: 5.26, w: 5.08, h: 0.82,
    fontFace: FONT, fontSize: 16, color: C.white, margin: 0,
  });

  addFooter(s, 5);
}

// ---------------------------------------------------------------------------
// 6. Notes
// ---------------------------------------------------------------------------
{
  const s = pres.addSlide();
  s.background = { color: C.dark };
  addRail(s);
  addKicker(s, "NOTES");
  addTitle(s, "補足。この一覧の読み方");

  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 1.28, w: 3.85, h: 5.2,
    fill: { color: C.card },
    shadow: shadow(),
  });
  s.addShape(pres.shapes.RECTANGLE, {
    x: 0.5, y: 1.28, w: 0.08, h: 5.2,
    fill: { color: C.cyan },
  });
  s.addText("計", {
    x: 0.78, y: 1.52, w: 3.3, h: 0.28,
    fontFace: FONT, fontSize: 14, color: C.mute, margin: 0,
  });
  s.addText("19件", {
    x: 0.78, y: 1.82, w: 3.3, h: 0.95,
    fontFace: FONT, fontSize: 52, color: C.cyan, bold: true, margin: 0,
  });
  s.addText("playbooks 7  +  その他 12", {
    x: 0.78, y: 2.82, w: 3.3, h: 0.36,
    fontFace: FONT, fontSize: 15, color: C.white, margin: 0,
  });
  s.addText("日常パック（MANIFEST 59件）のうち、手動はこれだけ。", {
    x: 0.78, y: 3.28, w: 3.3, h: 0.7,
    fontFace: FONT, fontSize: 14, color: C.white, margin: 0,
  });
  s.addText("このデッキは、その中の §3–5。", {
    x: 0.78, y: 4.08, w: 3.3, h: 0.5,
    fontFace: FONT, fontSize: 16, color: C.white, margin: 0,
  });
  s.addText("開発 7  /  デザイン 2  /  Git 2", {
    x: 0.78, y: 4.7, w: 3.3, h: 0.4,
    fontFace: FONT, fontSize: 14, color: C.cyan, margin: 0,
  });
  s.addText("＋ 補足。 /  で明示して使う。", {
    x: 0.78, y: 5.18, w: 3.3, h: 0.8,
    fontFace: FONT, fontSize: 14, color: C.mute, margin: 0,
  });

  const notes = [
    {
      n: "01",
      t: "/project-foundation は自動発火",
      d: "本一覧に含めない。新規判定後の土台作りは /new-project。",
    },
    {
      n: "02",
      t: "手動スキルは勝手に選ばれない",
      d: "モデルは自分で選ばない。 /  で明示呼び出しが必要。",
    },
    {
      n: "03",
      t: "マーケは別一覧",
      d: "全件手動・未インストール。正は marketing-skills一覧.md。",
    },
    {
      n: "04",
      t: "定義の正本",
      d: "運用と定義の正は skills一覧.md。このデッキは抜粋。",
    },
  ];

  notes.forEach((n, i) => {
    const y = 1.28 + i * 1.32;
    s.addShape(pres.shapes.RECTANGLE, {
      x: 4.65, y, w: 8.15, h: 1.12,
      fill: { color: C.card },
      shadow: shadow(),
    });
    s.addShape(pres.shapes.RECTANGLE, {
      x: 4.65, y, w: 0.08, h: 1.12,
      fill: { color: C.blue },
    });
    s.addText(n.n, {
      x: 4.9, y: y + 0.12, w: 0.7, h: 0.88,
      fontFace: MONO, fontSize: 16, color: C.cyan, bold: true, valign: "middle", margin: 0,
    });
    s.addText(n.t, {
      x: 5.7, y: y + 0.14, w: 6.85, h: 0.4,
      fontFace: FONT, fontSize: 18, color: C.white, bold: true, margin: 0,
    });
    s.addText(n.d, {
      x: 5.7, y: y + 0.56, w: 6.85, h: 0.4,
      fontFace: FONT, fontSize: 14, color: C.mute, margin: 0,
    });
  });

  addFooter(s, 6);
}

pres.writeFile({ fileName: OUT }).then(() => {
  console.log("Wrote", OUT);
});
