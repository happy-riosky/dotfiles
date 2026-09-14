--- @since 26.8.15
--- @sync entry

local function entry(_, job)
	local delta = tonumber(job.args[1]) or 0
	local ratio = rt.mgr.ratio

	-- Ignore resizing while cycle-preview is in preview-only mode.
	if delta == 0 or ratio[3] >= 9999 then
		return
	end

	local preview = math.max(1, math.min(9998, ratio[3] + delta))
	if preview == ratio[3] then
		return
	end

	rt.mgr.ratio = { ratio[1], ratio[2], preview }
	ya.emit("app:resize", {})
end

return { entry = entry }
