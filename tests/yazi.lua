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

-- line-count: spotter renders wc line/word/byte counts -------------------

local function chainable(o)
	return setmetatable(o, { __index = function(self)
		return function()
			return self
		end
	end })
end

ui = {
	Row = function(t)
		return chainable(t)
	end,
	Style = function()
		return chainable({})
	end,
	Pos = function(t)
		return t
	end,
	Constraint = { Length = function()
		return {}
	end, Fill = function()
		return {}
	end },
	Table = function(rows)
		return chainable({ rows = rows })
	end,
}
th = { spot = { tbl_col = {}, tbl_cell = {} } }
rt = { plugin = {} }
for _, kind in ipairs({ "spotters", "previewers", "fetchers", "preloaders" }) do
	rt.plugin[kind] = { match = function()
		return {}
	end }
end

local WC_ARGV, WC_STDOUT, WC_FAIL = nil, nil, nil
local SPOTTED = nil
ya.spot_table = function(job, tbl)
	SPOTTED = { job = job, rows = tbl.rows }
end

Command = setmetatable({}, {
	__call = function(_, cmd)
		local b = { argv = { cmd } }
		local function add(_, t)
			if type(t) == "table" then
				for _, v in ipairs(t) do
					b.argv[#b.argv + 1] = v
				end
			else
				b.argv[#b.argv + 1] = t
			end
			return b
		end
		b.arg = add
		b.output = function()
			if WC_FAIL then
				return nil, "no such file or directory"
			end
			WC_ARGV = b.argv
			return { status = { success = true }, stdout = WC_STDOUT }
		end
		return b
	end,
})

local lc = dofile("home/.config/yazi/plugins/line-count.yazi/main.lua")

local function spot_value(label)
	for _, row in ipairs(SPOTTED.rows) do
		if row[1] == label then
			return row[2]
		end
	end
	return nil
end

local function has_row(first)
	for _, row in ipairs(SPOTTED.rows) do
		if row[1] == first then
			return true
		end
	end
	return false
end

WC_STDOUT = "      42     210     900 /tmp/notes.txt\n"
lc:spot({
	file = { path = "/tmp/notes.txt", cha = { btime = 1000000000, mtime = 1600000000 } },
	mime = "text/plain",
})
assert(
	vim.deep_equal(WC_ARGV, { "wc", "-lwc", "--", "/tmp/notes.txt" }),
	"wc invoked with -lwc and the hovered path"
)
assert(has_row("Base") and has_row("Counts") and has_row("Plugins"), "renders base, counts and plugins sections")
assert(spot_value("  Lines:") == "42", "renders line count")
assert(spot_value("  Words:") == "210", "renders word count")
assert(spot_value("  Bytes:") == "900", "renders byte count")
assert(spot_value("  Created:") == os.date("%Y-%m-%d %H:%M:%S", 1000000000), "keeps base created row")
assert(spot_value("  Modified:") == os.date("%Y-%m-%d %H:%M:%S", 1600000000), "keeps base modified row")
assert(spot_value("  Mimetype:") == "text/plain", "keeps base mimetype row")
assert(spot_value("  Spotter:") == "-", "keeps plugins section with no rules matched")
assert(SPOTTED.job.mime == "text/plain", "spot receives the job")

-- wc failure renders an error row instead of crashing, base info stays intact
WC_FAIL = true
lc:spot({ file = { path = "/tmp/gone.txt", cha = {} }, mime = "text/plain" })
assert(spot_value("  Error:") ~= nil, "wc failure renders error row")
assert(spot_value("  Mimetype:") == "text/plain", "base section survives wc failure")
