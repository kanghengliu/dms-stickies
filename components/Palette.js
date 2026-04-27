.pragma library

// Stickies-style accent palette.
const PALETTES = {
    yellow: { headerBg: "#FBE07F", bodyBg: "#FFF6BC", text: "#3E2A11", accent: "#F0B41A" },
    pink:   { headerBg: "#F8B5C8", bodyBg: "#FBDDE5", text: "#46161E", accent: "#D74079" },
    mint:   { headerBg: "#A1D6B5", bodyBg: "#D5EAD8", text: "#0E3F1F", accent: "#3CA66D" },
    blue:   { headerBg: "#9EC5F0", bodyBg: "#CDE0F8", text: "#0A2A55", accent: "#4078C5" },
    purple: { headerBg: "#C4A4D9", bodyBg: "#DEC9EA", text: "#2D1238", accent: "#7E47A8" },
    orange: { headerBg: "#F8C285", bodyBg: "#FBDFB7", text: "#42180A", accent: "#E07614" },
    gray:   { headerBg: "#B7C0C6", bodyBg: "#D8DDE0", text: "#1A2228", accent: "#67737B" },
    paper:  { headerBg: "#E8E8EA", bodyBg: "#F8F8F8", text: "#222222", accent: "#777777" }
};

const ORDER = ["yellow", "pink", "mint", "blue", "purple", "orange", "gray", "paper"];

function get(name) {
    return PALETTES[name] || PALETTES.yellow;
}

function names() {
    return ORDER.slice();
}
