export function isExplicit00Command(text) {
    if (typeof text !== 'string') return false;
    return /^\s*(?:\/|\$)00(?:\s|$)/.test(text.replace(/^\uFEFF/, ''));
}

export function requestBodyAfter00(text) {
    if (!isExplicit00Command(text)) return text;
    return text.replace(/^\uFEFF/, '').replace(/^\s*(?:\/|\$)00(?:\s+|$)/, '');
}
