import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const skillDir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const skill = fs.readFileSync(path.join(skillDir, 'SKILL.md'), 'utf-8');

test('human card body sections are required', () => {
    assert.ok(skill.includes('## できること'), 'missing できること template');
    assert.ok(skill.includes('## 直近の変化'), 'missing 直近の変化 template');
    assert.ok(skill.includes('## 骨格'), 'missing 骨格 template');
});

test('does not forbid restating overview in the body', () => {
    assert.equal(skill.includes('台帳の正本は frontmatter のみ'), false);
    assert.equal(skill.includes('概要の再掲'), false);
    assert.equal(skill.includes('主な機能の箇条書き再掲'), false);
});

test('tech stack must stay out of the body except 骨格', () => {
    assert.ok(skill.includes('## 骨格'));
    assert.ok(skill.includes('技術スタックの表'), 'must forbid stack tables in the body');
});

test('digest window is git tags then 90 days', () => {
    assert.ok(/git\s*タグ/.test(skill) || skill.includes('git タグ'));
    assert.ok(skill.includes('90日') || skill.includes('90 日'));
    assert.ok(skill.includes('major.minor') || skill.includes('マイナー'));
});

test('digest body has a 7-line cap regardless of window', () => {
    assert.ok(/7\s*行/.test(skill));
    assert.ok(skill.includes('付いた') && skill.includes('直した'));
});

test('未反映 is user-facing feat only and uncertain cases stay unmarked', () => {
    assert.ok(skill.includes('未反映'));
    assert.ok(skill.includes('迷ったら未反映にしない') || skill.includes('迷ったら') && skill.includes('未反映'));
    assert.ok(skill.includes('feat'));
});

test('doc-maint runs after all notes are saved, never first, never without GO', () => {
    assert.ok(skill.includes('doc-maint'));
    assert.ok(skill.includes('全件') || skill.includes('バッチ'));
    assert.ok(!/先に\s*`?doc-maint/.test(skill) || skill.includes('先に `doc-maint` しない') || skill.includes('先にdoc-maintしない') || skill.includes('先に `doc-maint` をかけない') || skill.includes('先に doc-maint しない'));
    assert.ok(skill.includes('GO'));
    assert.ok(skill.includes('README'));
});

test('③ remains out of scope; digest (lightweight ②) is in scope', () => {
    assert.ok(skill.includes('③') && (skill.includes('範囲外') || skill.includes('別工程')));
    assert.equal(/commit履歴分析（②）やリリースノート突き合わせ（③）は別工程であり、このスキルの範囲外/.test(skill), false);
});
