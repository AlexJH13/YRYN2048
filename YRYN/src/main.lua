
cc.FileUtils:getInstance():setPopupNotify(false)

require "config"
require "cocos.init"

local function main()
	local configs = {
        viewsRoot  = "app",
        modelsRoot = "app.models",
        defaultSceneName = "MainScene",
    }
    require("app.MyApp"):create(configs):run("2048.GameScene2048")
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
