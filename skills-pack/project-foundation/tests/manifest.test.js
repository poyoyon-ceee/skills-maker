import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const manifestPath = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', '..', 'MANIFEST.json');

test('MANIFEST.json has unique skill names and includes project-foundation', () => {
    const raw = fs.readFileSync(manifestPath, 'utf-8').replace(/^\uFEFF/, '');
    const entries = JSON.parse(raw);
    const names = entries.map((e) => e.name);
    assert.equal(names.length, new Set(names).size);
    assert.ok(names.includes('project-foundation'));
    assert.ok(names.includes('new-project'));
    assert.ok(names.includes('doc-maint'));
    assert.ok(names.includes('00'));
    const zero = entries.find((e) => e.name === '00');
    assert.equal(zero.path, '00/SKILL.md');
    assert.equal(zero.installTarget, '~/.agents/skills/00/');
    assert.deepEqual(zero.installTargets, ['agents', 'claude']);
    assert.ok(!zero.name.includes('"'));

    const skillCreator = entries.find((e) => e.name === 'skill-creator');
    assert.deepEqual(skillCreator.installTargets, ['cursor']);

    const chatHandoff = entries.find((e) => e.name === 'chat-handoff');
    assert.deepEqual(chatHandoff.installTargets, ['cursor', 'claude']);

    for (const entry of entries) {
        const targets = entry.installTargets ?? [];
        assert.ok(!(targets.includes('agents') && targets.includes('cursor')));
    }
});
