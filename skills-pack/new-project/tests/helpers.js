import fs from 'fs';
import os from 'os';
import path from 'path';

export function makeTempDir(prefix = 'np-test-') {
    return fs.mkdtempSync(path.join(os.tmpdir(), prefix));
}

export function rmTempDir(dir) {
    fs.rmSync(dir, { recursive: true, force: true });
}
