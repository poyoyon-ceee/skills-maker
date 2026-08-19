import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const skillDir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const skillPath = path.join(skillDir, 'SKILL.md');
const openaiPath = path.join(skillDir, 'agents', 'openai.yaml');
const MACHINE_PATH_RE = /(?:[A-Za-z]:\\|\\\\)(?:Users\\|home\\|Dev-App\\)/;

function readSkill() {
    return fs.readFileSync(skillPath, 'utf8');
}

test('00 SKILL.md exists with quoted name 00 and explicit-only frontmatter', () => {
    const text = readSkill();
    assert.equal(text.startsWith('---'), true);
    assert.match(text, /^name:\s*"00"\s*$/m);
    assert.match(text, /^disable-model-invocation:\s*true\s*$/m);
    assert.doesNotMatch(text, /^name:\s*00\s*$/m);
});

test('00 skill is a one-turn Superpowers bypass and does not persist', () => {
    const text = readSkill();
    assert.match(text, /THIS TURN|this turn|1ターン/);
    assert.match(text, /using-superpowers/);
    assert.match(text, /brainstorming/);
    assert.match(text, /test-driven-development|TDD/);
    assert.match(text, /next (user )?message|次の(?:ユーザー)?メッセージ/i);
    assert.match(text, /do not persist|引き継がない|保存しない|not persist/i);
    assert.match(text, /system|安全|safety/i);
});

test('00 skill documents start-of-message trigger and empty-command halt', () => {
    const text = readSkill();
    assert.match(text, /\/00/);
    assert.match(text, /quotes|引用|code|コード/);
    assert.match(text, /no request|依頼本文がない|作業を開始しない/i);
});

test('00 skill files do not contain machine-specific absolute paths', () => {
    const files = [
        skillPath,
        openaiPath,
        path.join(skillDir, 'scripts', 'is-00-command.js'),
    ];
    for (const file of files) {
        const text = fs.readFileSync(file, 'utf8');
        assert.equal(MACHINE_PATH_RE.test(text), false, file);
        assert.equal(/C:\\Users\\/i.test(text), false, file);
        assert.equal(/D:\\Dev-App\\/i.test(text), false, file);
    }
});

test('Codex sidecar disables implicit invocation', () => {
    const text = fs.readFileSync(openaiPath, 'utf8');
    assert.match(text, /allow_implicit_invocation:\s*false/);
});
