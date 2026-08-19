import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const skillPath = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', 'SKILL.md');

test('using-superpowers still forces skill use when /00 is absent', () => {
    const text = fs.readFileSync(skillPath, 'utf8');
    assert.match(text, /1% chance/);
    assert.match(text, /EXTREMELY-IMPORTANT/);
    assert.match(text, /ABSOLUTELY MUST invoke the skill/);
});

test('using-superpowers has a one-turn /00 bypass before the force rule', () => {
    const text = fs.readFileSync(skillPath, 'utf8');
    const bypassIdx = text.search(/<00-BYPASS>/);
    const forceIdx = text.indexOf('<EXTREMELY-IMPORTANT>');
    assert.notEqual(bypassIdx, -1, 'missing <00-BYPASS> block');
    assert.notEqual(forceIdx, -1, 'missing <EXTREMELY-IMPORTANT> block');
    assert.equal(bypassIdx < forceIdx, true, '/00 bypass must be evaluated before the force rule');
    const bypass = text.slice(bypassIdx, text.indexOf('</00-BYPASS>'));
    assert.match(bypass, /\/00/);
    assert.match(bypass, /THIS TURN|this turn|1ターン/);
    assert.match(bypass, /next (user )?message|次の(?:ユーザー)?メッセージ/i);
    assert.match(bypass, /quotes|引用|code|コード/);
    assert.match(bypass, /do not persist|引き継がない|保存しない|not persist/i);
});
