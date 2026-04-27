.pragma library

// Selection-aware markdown transforms. Each function takes (text, selStart, selEnd, ...args)
// and returns { newText, selStart, selEnd } describing the desired editor state, or null for no-op.

function _lineStart(text, pos) {
    let i = pos;
    while (i > 0 && text[i - 1] !== '\n')
        i--;
    return i;
}

function _lineEnd(text, pos) {
    let i = pos;
    while (i < text.length && text[i] !== '\n')
        i++;
    return i;
}

function _selectedBlockRange(text, selStart, selEnd) {
    const start = _lineStart(text, selStart);
    let end = selEnd;
    if (selStart !== selEnd && end > start && text[end - 1] === '\n')
        end--;
    end = _lineEnd(text, end);
    return { start, end };
}

function _applyToLines(text, selStart, selEnd, mapFn) {
    const range = _selectedBlockRange(text, selStart, selEnd);
    const block = text.slice(range.start, range.end);
    const lines = block.split('\n');
    const newLines = lines.map(mapFn);
    const newBlock = newLines.join('\n');
    const newText = text.slice(0, range.start) + newBlock + text.slice(range.end);
    const firstLineDelta = newLines[0].length - lines[0].length;
    const totalDelta = newBlock.length - block.length;
    return {
        newText: newText,
        selStart: Math.max(range.start, selStart + firstLineDelta),
        selEnd: selEnd + totalDelta
    };
}

function _escape(s) {
    return s.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&');
}

function toggleWrap(text, selStart, selEnd, marker) {
    const len = marker.length;
    if (selStart === selEnd) {
        const newText = text.slice(0, selStart) + marker + marker + text.slice(selEnd);
        return { newText: newText, selStart: selStart + len, selEnd: selStart + len };
    }
    if (selEnd - selStart >= 2 * len &&
        text.substr(selStart, len) === marker &&
        text.substr(selEnd - len, len) === marker) {
        const newText = text.slice(0, selStart) + text.slice(selStart + len, selEnd - len) + text.slice(selEnd);
        return { newText: newText, selStart: selStart, selEnd: selEnd - 2 * len };
    }
    if (selStart >= len && selEnd + len <= text.length &&
        text.substr(selStart - len, len) === marker &&
        text.substr(selEnd, len) === marker) {
        const newText = text.slice(0, selStart - len) + text.slice(selStart, selEnd) + text.slice(selEnd + len);
        return { newText: newText, selStart: selStart - len, selEnd: selEnd - len };
    }
    const newText = text.slice(0, selStart) + marker + text.slice(selStart, selEnd) + marker + text.slice(selEnd);
    return { newText: newText, selStart: selStart + len, selEnd: selEnd + len };
}

function togglePrefix(text, selStart, selEnd, prefix, removeRegex) {
    const re = removeRegex || new RegExp("^" + _escape(prefix));
    const range = _selectedBlockRange(text, selStart, selEnd);
    const block = text.slice(range.start, range.end);
    const lines = block.split('\n');
    const allHave = lines.length > 0 && lines.every(l => l.length === 0 || re.test(l));
    return _applyToLines(text, selStart, selEnd, line => {
        if (line.length === 0)
            return line;
        if (allHave)
            return line.replace(re, "");
        return prefix + line;
    });
}

function toggleHeading(text, selStart, selEnd, level) {
    const wantedPrefix = '#'.repeat(level) + ' ';
    const headingRe = /^(#{1,6})\s/;
    const range = _selectedBlockRange(text, selStart, selEnd);
    const block = text.slice(range.start, range.end);
    const lines = block.split('\n');
    const allAtLevel = lines.length > 0 && lines.every(l => l.length === 0 || l.startsWith(wantedPrefix));
    return _applyToLines(text, selStart, selEnd, line => {
        if (line.length === 0)
            return line;
        const stripped = line.replace(headingRe, "");
        if (allAtLevel)
            return stripped;
        return wantedPrefix + stripped;
    });
}

function toggleCheckbox(text, selStart, selEnd) {
    const checkboxRe = /^- \[[ xX]\] /;
    return togglePrefix(text, selStart, selEnd, "- [ ] ", checkboxRe);
}

function toggleCheckedState(text, selStart, selEnd) {
    const lineStart = _lineStart(text, selStart);
    const lineEnd = _lineEnd(text, selStart);
    const line = text.slice(lineStart, lineEnd);
    let newLine = null;
    const uncheckedMatch = line.match(/^(\s*)- \[ \] /);
    const checkedMatch = line.match(/^(\s*)- \[[xX]\] /);
    if (uncheckedMatch)
        newLine = uncheckedMatch[1] + "- [x] " + line.slice(uncheckedMatch[0].length);
    else if (checkedMatch)
        newLine = checkedMatch[1] + "- [ ] " + line.slice(checkedMatch[0].length);
    else
        return null;
    return {
        newText: text.slice(0, lineStart) + newLine + text.slice(lineEnd),
        selStart: selStart,
        selEnd: selEnd
    };
}

function indent(text, selStart, selEnd) {
    return _applyToLines(text, selStart, selEnd, l => "  " + l);
}

function outdent(text, selStart, selEnd) {
    return _applyToLines(text, selStart, selEnd, l => {
        if (l.startsWith("  "))
            return l.slice(2);
        if (l.startsWith(" "))
            return l.slice(1);
        return l;
    });
}

function insertLink(text, selStart, selEnd) {
    const sel = text.slice(selStart, selEnd);
    const replacement = "[" + sel + "](url)";
    const newText = text.slice(0, selStart) + replacement + text.slice(selEnd);
    const urlStart = selStart + 1 + sel.length + 2;
    return { newText: newText, selStart: urlStart, selEnd: urlStart + 3 };
}
