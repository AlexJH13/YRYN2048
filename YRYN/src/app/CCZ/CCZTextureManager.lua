local CCZTextureManager = class("CCZTextureManager")

CCZTextureManager._localResource = {
	skill = {
		zhuo_shao  = "CCZ/meff/0.png",
		da_huo_qiu = "CCZ/meff/1.png",
		da_bu_ji   = "CCZ/meff/10.png"
	}
}

function CCZTextureManager.getTexture2DAndRect(resType, key)
	local texture2d = nil
	local rects = {}
	local res = CCZTextureManager._localResource[resType][key]
	if res then
		texture2d = cc.Director:getInstance():getTextureCache():addImage(res)
		local w = texture2d:getPixelsWide()
		local h = texture2d:getPixelsHigh()
		if h > w then
			local count = math.modf(h / w)
			local per = h / count
			for i = 1, count do
				local x = 0
				local y = per * (i - 1)
				local rect = cc.rect(x, y, w, per)
				table.insert(rects, rect)
			end
		elseif w > h then
			local count = math.modf(w / h)
			local per = w / count
			for i = 1, count do
				local x = per * (i - 1)
				local y = 0
				local rect = cc.rect(x, y, w, per)
				table.insert(rects, rect)
			end
		end
	end
	return texture2d, rects
end

return CCZTextureManager