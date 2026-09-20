--- @since 26.9.1

local M = {}

local function base_rows(job)
	local cha = job.file.cha or {}
	return {
		ui.Row({ "Base" }):style(ui.Style():fg("green")),
		ui.Row { "  Created:", cha.btime and os.date("%Y-%m-%d %H:%M:%S", math.floor(cha.btime)) or "-" },
		ui.Row { "  Modified:", cha.mtime and os.date("%Y-%m-%d %H:%M:%S", math.floor(cha.mtime)) or "-" },
		ui.Row { "  Mimetype:", job.mime },
	}
end

local function counts_rows(output, err)
	local lines, words, bytes
	if output and output.status.success then
		lines, words, bytes = output.stdout:match("^%s*(%d+)%s+(%d+)%s+(%d+)")
	end

	if lines then
		return {
			ui.Row({ "Counts" }):style(ui.Style():fg("green")),
			ui.Row { "  Lines:", lines },
			ui.Row { "  Words:", words },
			ui.Row { "  Bytes:", bytes },
		}
	end
	return {
		ui.Row({ "Counts" }):style(ui.Style():fg("green")),
		ui.Row { "  Error:", string.format("Failed to run `wc`: %s", err or "unexpected output") },
	}
end

local function plugin_rows(job)
	local ok, rows = pcall(function()
		local pair = { file = job.file, mime = job.mime }
		local spotter, previewer, fetchers, preloaders = nil, nil, {}, {}

		for _, v in pairs(rt.plugin.spotters:match(pair)) do
			spotter = v
			break
		end

		for _, v in pairs(rt.plugin.previewers:match(pair)) do
			previewer = v
			break
		end

		for _, v in pairs(rt.plugin.fetchers:match(pair)) do
			fetchers[#fetchers + 1] = v.name
		end
		fetchers = #fetchers ~= 0 and fetchers or { "-" }

		for _, v in pairs(rt.plugin.preloaders:match(pair)) do
			preloaders[#preloaders + 1] = v.name
		end
		preloaders = #preloaders ~= 0 and preloaders or { "-" }

		return {
			ui.Row({ "Plugins" }):style(ui.Style():fg("green")),
			ui.Row { "  Spotter:", spotter and spotter.name or "-" },
			ui.Row { "  Previewer:", previewer and previewer.name or "-" },
			ui.Row({ "  Fetchers:", fetchers }):height(#fetchers),
			ui.Row({ "  Preloaders:", preloaders }):height(#preloaders),
		}
	end)
	return ok and rows or {}
end

function M:spot(job)
	local output, err = Command("wc"):arg({ "-lwc", "--", tostring(job.file.path) }):output()

	local rows = {}
	local sections = { base_rows(job), counts_rows(output, err), plugin_rows(job) }
	for _, section in ipairs(sections) do
		for _, row in ipairs(section) do
			rows[#rows + 1] = row
		end
		rows[#rows + 1] = ui.Row {}
	end
	rows[#rows] = nil

	ya.spot_table(
		job,
		ui.Table(rows)
			:area(ui.Pos { "center", w = 60, h = 20 })
			:row(1)
			:col(1)
			:col_style(th.spot.tbl_col)
			:cell_style(th.spot.tbl_cell)
			:widths { ui.Constraint.Length(14), ui.Constraint.Fill(1) }
	)
end

return M
