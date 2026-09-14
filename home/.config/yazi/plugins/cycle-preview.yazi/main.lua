--- @since 26.8.15
--- @sync entry

local function entry(st)
	local ratio = rt.mgr.ratio

	if st.mode == "two-pane" then
		st.base[2], st.base[3] = ratio[2], ratio[3]
		st.mode = "fullscreen"
		rt.mgr.ratio = { 0, 0, 9999 }
	elseif st.mode == "fullscreen" then
		st.mode = nil
		rt.mgr.ratio = { st.base[1], st.base[2], st.base[3] }
	else
		st.base = { ratio[1], ratio[2], ratio[3] }
		st.mode = "two-pane"
		rt.mgr.ratio = { 0, ratio[2], ratio[3] }
	end

	ya.emit("app:resize", {})
end

return { entry = entry }
