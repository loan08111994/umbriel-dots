 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#1a120b',
    base01 = '#2c1e13',
    base02 = '#3a2819',
    base03 = '#745d4e',
    base04 = '#b5a496',
    base05 = '#ede0d4',
    base06 = '#ede0d4',
    base07 = '#ede0d4',
    base08 = '#c97a7a',
    base09 = '#a3b19b',
    base0A = '#ddb892',
    base0B = '#e29578',
    base0C = '#b4e996',
    base0D = '#e9ac96',
    base0E = '#e9c096',
    base0F = '#f4d9be',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#ede0d4',          bg = '#1a120b' })
  hi('TelescopeBorder',         { fg = '#745d4e',             bg = '#1a120b' })
  hi('TelescopePromptNormal',   { fg = '#ede0d4',          bg = '#1a120b' })
  hi('TelescopePromptBorder',   { fg = '#745d4e',             bg = '#1a120b' })
  hi('TelescopePromptPrefix',   { fg = '#e29578',             bg = '#1a120b' })
  hi('TelescopePromptCounter',  { fg = '#b5a496',  bg = '#1a120b' })
  hi('TelescopePromptTitle',    { fg = '#1a120b',             bg = '#e29578' })
  hi('TelescopePreviewTitle',   { fg = '#1a120b',             bg = '#ddb892' })
  hi('TelescopeResultsTitle',   { fg = '#1a120b',             bg = '#a3b19b' })
  hi('TelescopeSelection',      { fg = '#ede0d4',          bg = '#3a2819' })
  hi('TelescopeSelectionCaret', { fg = '#e29578',             bg = '#3a2819' })
  hi('TelescopeMatching',       { fg = '#e29578',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#ede0d4',          bg = '#1a120b' })
  hi('MiniPickBorder',         { fg = '#745d4e',             bg = '#1a120b' })
  hi('MiniPickPrompt',   { fg = '#ede0d4',          bg = '#1a120b' })
  hi('MiniPickPromptPrefix',   { fg = '#e29578',             bg = '#1a120b' })
  hi('MiniPickBorderText',    { fg = '#1a120b',             bg = '#e29578' })
  hi('MiniPickMatchCurrent',      { fg = '#ede0d4',          bg = '#3a2819' })
  hi('MiniPickPromptCaret', { fg = '#e29578',             bg = '#3a2819' })
  hi('MiniPickMatchRanges',       { fg = '#e29578',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
