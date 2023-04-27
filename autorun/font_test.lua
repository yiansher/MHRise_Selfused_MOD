local FONT_NAME = "msyh.ttf"
local FONT_SIZE = 18

local CHINESE_GLYPH_RANGES = {
    0x0020, 0x00FF, -- Basic Latin + Latin Supplement
    0x2000, 0x206F, -- General Punctuation
    0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
    0x31F0, 0x31FF, -- Katakana Phonetic Extensions
    0xFF00, 0xFFEF, -- Half-width characters
    0x4e00, 0x9FAF, -- CJK Ideograms
    0,
}

local font = imgui.load_font(FONT_NAME, FONT_SIZE, CHINESE_GLYPH_RANGES)
local needs_initial_push = true

re.on_frame(function()
    if needs_initial_push then
        imgui.push_font(font)
        needs_initial_push = false
    end

    imgui.pop_font()
    imgui.push_font(font)
end)

re.on_draw_ui(function()
    imgui.text("中文字库显示已正确安装")
end)