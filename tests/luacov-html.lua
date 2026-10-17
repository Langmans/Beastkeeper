-- luacov settings for the browsable report: those of .luacov, written as HTML to
-- coverage/index.html instead of the lcov file. tests/check.lua runs it after the lcov report.
local settings = dofile(".luacov")
settings.reportfile = "coverage/index.html"
return settings
