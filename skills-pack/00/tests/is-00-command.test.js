import { test } from 'node:test';
import assert from 'node:assert/strict';
import { isExplicit00Command, requestBodyAfter00 } from '../scripts/is-00-command.js';

test('leading /00 with a request is an explicit command', () => {
    assert.equal(isExplicit00Command('/00 このファイルの内容だけ簡単に説明して'), true);
    assert.equal(requestBodyAfter00('/00 このファイルの内容だけ簡単に説明して'), 'このファイルの内容だけ簡単に説明して');
});

test('leading $00 is an explicit Codex-style mention', () => {
    assert.equal(isExplicit00Command('$00 summarize this file'), true);
    assert.equal(requestBodyAfter00('$00 summarize this file'), 'summarize this file');
});

test('leading whitespace before /00 still counts as message start', () => {
    assert.equal(isExplicit00Command('  /00 ping'), true);
    assert.equal(requestBodyAfter00('  /00 ping'), 'ping');
});

test('/00 alone has no request body', () => {
    assert.equal(isExplicit00Command('/00'), true);
    assert.equal(requestBodyAfter00('/00').trim(), '');
    assert.equal(isExplicit00Command('/00   '), true);
    assert.equal(requestBodyAfter00('/00   ').trim(), '');
});

test('/00 in quotes, code, or running text does not trigger', () => {
    assert.equal(isExplicit00Command('Use `/00` to skip Superpowers'), false);
    assert.equal(isExplicit00Command('例えば /00 と書く'), false);
    assert.equal(isExplicit00Command('```\n/00 skip\n```'), false);
    assert.equal(isExplicit00Command('Please ignore "/00" in this sentence'), false);
});

test('/000 and /00foo are not the command', () => {
    assert.equal(isExplicit00Command('/000 skip'), false);
    assert.equal(isExplicit00Command('/00foo'), false);
    assert.equal(isExplicit00Command('/00/'), false);
});
