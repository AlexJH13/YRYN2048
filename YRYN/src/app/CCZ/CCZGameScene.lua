local CCZTextureManager = require("app.CCZ.CCZTextureManager")

local CCZGameScene = class("CCZGameScene", cc.load("mvc").ViewBase)

function CCZGameScene:onCreate()
	local tex, rects = CCZTextureManager.getTexture2DAndRect("skill", "da_bu_ji")
	local sp = cc.Sprite:createWithTexture(tex, rects[1])
	sp:setPosition(300, 500)
	self:addChild(sp)
	local ani = cc.Animation:create()
	for k,v in pairs(rects) do
		ani:addSpriteFrameWithTexture(tex, v)
	end
	ani:setDelayPerUnit(0.05)
	ani:setLoops(1)
	local animate = cc.Animate:create(ani)
	sp:runAction(animate)
	print("this is CCZ")
end

return CCZGameScene