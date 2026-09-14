local function assert_ratio(expected, label)
	assert(
		vim.deep_equal(rt.mgr.ratio, expected),
		string.format("%s: expected %s, got %s", label, vim.inspect(expected), vim.inspect(rt.mgr.ratio))
	)
end

rt = { mgr = { ratio = { 1, 2, 4 } } }
ya = {
	dbg = function() end,
	emit = function(action)
		assert(action == "app:resize")
	end,
}

local original_require = require
require = function(name)
	if name == "toggle-pane" then
		error("sync plugins cannot yield to require another plugin")
	end
	return original_require(name)
end

local cycle = dofile("home/.config/yazi/plugins/cycle-preview.yazi/main.lua")
local resize = dofile("home/.config/yazi/plugins/resize-preview.yazi/main.lua")
local state = {}

cycle.entry(state)
assert_ratio({ 0, 2, 4 }, "first T")

resize.entry(nil, { args = { "1" } })
assert_ratio({ 0, 2, 5 }, "resize in two-pane mode")

cycle.entry(state)
assert_ratio({ 0, 0, 9999 }, "second T")

resize.entry(nil, { args = { "-1" } })
assert_ratio({ 0, 0, 9999 }, "resize in fullscreen mode")

cycle.entry(state)
assert_ratio({ 1, 2, 5 }, "third T")

cycle.entry(state)
cycle.entry(state)
cycle.entry(state)
assert_ratio({ 1, 2, 5 }, "second layout cycle")

rt.mgr.ratio = { 1, 2, 1 }
resize.entry(nil, { args = { "-1" } })
assert_ratio({ 1, 2, 1 }, "minimum preview ratio")

rt.mgr.ratio = { 1, 2, 9998 }
resize.entry(nil, { args = { "1" } })
assert_ratio({ 1, 2, 9998 }, "maximum preview ratio")
