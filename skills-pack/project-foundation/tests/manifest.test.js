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
});
