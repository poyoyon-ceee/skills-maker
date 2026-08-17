import fs from 'fs';
import path from 'path';
import { CollisionError, PathEscapeError, resolveInsideDest, findExistingCollision } from './paths.js';

export { CollisionError, PathEscapeError };

/**
 * ファイルとディレクトリの生成を担当するクラス
 */
export class ProjectWriter {
    constructor(baseDir = process.cwd()) {
        this.baseDir = baseDir;
    }

    /**
     * 指定されたパスにファイルを書き出す。ディレクトリがない場合は作成する。
     * 既存ファイルは上書きしない。生成先外へのパスは拒否する。
     * @param {string} relativePath
     * @param {string} content
     */
    writeFile(relativePath, content) {
        const fullPath = resolveInsideDest(this.baseDir, relativePath);
        const collision = findExistingCollision(this.baseDir, relativePath);
        if (collision) {
            throw new CollisionError(relativePath);
        }

        const dir = path.dirname(fullPath);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
        }

        fs.writeFileSync(fullPath, content, 'utf-8');
        return fullPath;
    }

    /**
     * プレースホルダを一括置換するユーティリティ
     * @param {string} content
     * @param {Object} variables
     */
    static replacePlaceholders(content, variables) {
        let result = content;
        for (const [key, value] of Object.entries(variables)) {
            const regex = new RegExp(`{{${key}}}`, 'g');
            result = result.replace(regex, value);
        }
        return result;
    }
}
