 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#181214',
    base01 = '#251e21',
    base02 = '#2f282b',
    base03 = '#9e8c93',
    base04 = '#d6c1c9',
    base05 = '#eddfe3',
    base06 = '#eddfe3',
    base07 = '#eddfe3',
    base08 = '#ffb4ab',
    base09 = '#ffb59e',
    base0A = '#e7bacf',
    base0B = '#ffaed8',
    base0C = '#ffb59e',
    base0D = '#ffaed8',
    base0E = '#e7bacf',
    base0F = '#ffd8e9',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  -- telescope.nvim
  hi('TelescopeNormal',         { fg = '#eddfe3',          bg = '#181214' })
  hi('TelescopeBorder',         { fg = '#9e8c93',             bg = '#181214' })
  hi('TelescopePromptNormal',   { fg = '#eddfe3',          bg = '#181214' })
  hi('TelescopePromptBorder',   { fg = '#9e8c93',             bg = '#181214' })
  hi('TelescopePromptPrefix',   { fg = '#ffaed8',             bg = '#181214' })
  hi('TelescopePromptCounter',  { fg = '#d6c1c9',  bg = '#181214' })
  hi('TelescopePromptTitle',    { fg = '#181214',             bg = '#ffaed8' })
  hi('TelescopePreviewTitle',   { fg = '#181214',             bg = '#e7bacf' })
  hi('TelescopeResultsTitle',   { fg = '#181214',             bg = '#ffb59e' })
  hi('TelescopeSelection',      { fg = '#eddfe3',          bg = '#2f282b' })
  hi('TelescopeSelectionCaret', { fg = '#ffaed8',             bg = '#2f282b' })
  hi('TelescopeMatching',       { fg = '#ffaed8',             bold = true })

  -- mini.pick
  hi('MiniPickNormal',         { fg = '#eddfe3',          bg = '#181214' })
  hi('MiniPickBorder',         { fg = '#9e8c93',             bg = '#181214' })
  hi('MiniPickPrompt',   { fg = '#eddfe3',          bg = '#181214' })
  hi('MiniPickPromptPrefix',   { fg = '#ffaed8',             bg = '#181214' })
  hi('MiniPickBorderText',    { fg = '#181214',             bg = '#ffaed8' })
  hi('MiniPickMatchCurrent',      { fg = '#eddfe3',          bg = '#2f282b' })
  hi('MiniPickPromptCaret', { fg = '#ffaed8',             bg = '#2f282b' })
  hi('MiniPickMatchRanges',       { fg = '#ffaed8',             bold = true })
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
