import fs from 'fs';

/**
 * Markdownファイルからテンプレート情報を抽出するクラス
 */
export class SourceParser {
    constructor(filePath) {
        this.content = fs.readFileSync(filePath, 'utf-8');
    }

    /**
     * 指定された名前のテンプレートまたはモジュールを取得する
     * @param {string} searchName - 'PROJECT.md' や 'EventBus' など
     * @returns {{ path: string, content: string } | null}
     */
    getSection(searchName) {
        // 正規表現用のエスケープ処理
        const escapedName = searchName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        // [TEMPLATE: path] または [MODULE: name] を探す正規表現
        const sectionHeaderRegex = new RegExp(`###\\s*\\[(?:TEMPLATE|MODULE):\\s*${escapedName}\\](?:\\s*\\(Path:\\s*(.*?)\\))?`, 'i');
        const match = this.content.match(sectionHeaderRegex);

        if (!match) return null;

        const path = match[1] || searchName; // MODULEの場合は(Path: ...)から取得、TEMPLATEはそのまま
        const startIndex = match.index + match[0].length;
        
        // 次の '### [' またはファイルの最後までを切り出す
        const nextSectionIndex = this.content.indexOf('### [', startIndex);
        const sectionText = nextSectionIndex === -1 
            ? this.content.slice(startIndex) 
            : this.content.slice(startIndex, nextSectionIndex);

        // コードブロック (```language ... ```) の中身を抽出
        const codeBlockRegex = /```(?:\w+)?\n([\s\S]*?)\n```/;
        const codeMatch = sectionText.match(codeBlockRegex);

        return {
            path: path.trim(),
            content: codeMatch ? codeMatch[1] : sectionText.trim()
        };
    }

    /**
     * 全てのセクション名を取得する（デバッグ・リスト表示用）
     */
    getAllSectionNames() {
        const regex = /###\s*\[(?:TEMPLATE|MODULE):\s*(.*?)\]/gi;
        const names = [];
        let match;
        while ((match = regex.exec(this.content)) !== null) {
            names.push(match[1].trim());
        }
        return names;
    }
}
