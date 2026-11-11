require("gigi.core")
require("gigi.lazy")
require("matugen").setup()

local ok, matugen = pcall(require, 'matugen')
if ok then matugen.setup() end
