--- @since 26.9.1
--- @sync entry

local function entry(st)
	if st.on then
		st.on = false
		ya.emit("sort", { st.by, reverse = st.reverse and "yes" or "no" })
		ya.emit("linemode", { st.linemode })
		st.by, st.reverse, st.linemode = nil, nil, nil
	else
		st.on = true
		local p = cx.active.pref
		st.by, st.reverse, st.linemode = p.sort_by, p.sort_reverse, p.linemode
		ya.emit("sort", { "mtime", reverse = "yes" })
		ya.emit("linemode", { "mtime" })
	end
end

return { entry = entry }
