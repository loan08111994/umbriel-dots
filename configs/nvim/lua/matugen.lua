 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#13140d',
    base01 = '#202019',
    base02 = '#2a2a23',
    base03 = '#919280',
    base04 = '#c8c8b4',
    base05 = '#e5e3d7',
    base06 = '#e5e3d7',
    base07 = '#e5e3d7',
    base08 = '#ffb4ab',
    base09 = '#97e2a5',
    base0A = '#c5ca9c',
    base0B = '#ccd975',
    base0C = '#8cd79b',
    base0D = '#c1ce6c',
    base0E = '#c5ca9c',
    base0F = '#e1e6b6',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#e5e3d7',          bg = '#13140d' })
  hi('TelescopeBorder',         { fg = '#919280',             bg = '#13140d' })
  hi('TelescopePromptNormal',   { fg = '#e5e3d7',          bg = '#13140d' })
  hi('TelescopePromptBorder',   { fg = '#919280',             bg = '#13140d' })
  hi('TelescopePromptPrefix',   { fg = '#ccd975',             bg = '#13140d' })
  hi('TelescopePromptCounter',  { fg = '#c8c8b4',  bg = '#13140d' })
  hi('TelescopePromptTitle',    { fg = '#13140d',             bg = '#ccd975' })
  hi('TelescopePreviewTitle',   { fg = '#13140d',             bg = '#c5ca9c' })
  hi('TelescopeResultsTitle',   { fg = '#13140d',             bg = '#97e2a5' })
  hi('TelescopeSelection',      { fg = '#e5e3d7',          bg = '#2a2a23' })
  hi('TelescopeSelectionCaret', { fg = '#ccd975',             bg = '#2a2a23' })
  hi('TelescopeMatching',       { fg = '#ccd975',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#e5e3d7',          bg = '#13140d' })
  hi('MiniPickBorder',         { fg = '#919280',             bg = '#13140d' })
  hi('MiniPickPrompt',   { fg = '#e5e3d7',          bg = '#13140d' })
  hi('MiniPickPromptPrefix',   { fg = '#ccd975',             bg = '#13140d' })
  hi('MiniPickBorderText',    { fg = '#13140d',             bg = '#ccd975' })
  hi('MiniPickMatchCurrent',      { fg = '#e5e3d7',          bg = '#2a2a23' })
  hi('MiniPickPromptCaret', { fg = '#ccd975',             bg = '#2a2a23' })
  hi('MiniPickMatchRanges',       { fg = '#ccd975',             bold = true })
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
