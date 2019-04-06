--[[
    GameCofig
    Author:夏阳
    Des:用于游戏配置的静态信息
]]
local GameCofig = class("GameCofig")

function GameCofig:ctor()
    self._bgColor = cc.c3b(249, 247, 234)
    self._gameBg = {
        color = cc.c3b(173, 157, 143),
        contentSize = cc.size(710, 710),
        radius = 20
    }
    self._darkFontColor = cc.c3b(100, 91, 82)
    self._lightFontColor = cc.c3b(255, 255, 255)
    self._cell = {
        bgColor = cc.c3b(193, 178, 164),
        contentSize = cc.size(152.5, 152.5),
        radius = 10,
        interval = 20, --间距
        valueColor = {
            [2] = cc.c3b(234, 221, 209),
            [4] = cc.c3b(231, 216, 188),
            [8] = cc.c3b(236, 161, 102),
            [16] = cc.c3b(228, 161, 66),
            [32] = cc.c3b(240, 101, 77),
            [64] = cc.c3b(225, 66, 42),
            [128] = cc.c3b(239, 210, 89),
            [256] = cc.c3b(237, 200, 59),
            [512] = cc.c3b(221, 181, 33),
            [1024] = cc.c3b(218, 174, 18),
            [2048] = cc.c3b(231, 186, 9),
            [4096] = cc.c3b(82, 214, 129)
            -- [8192]
        },
        fontColor = {
            [2] = self._darkFontColor,
            [4] = self._darkFontColor,
            [8] = self._lightFontColor,
            [16] = self._lightFontColor,
            [32] = self._lightFontColor,
            [64] = self._lightFontColor,
            [128] = self._lightFontColor,
            [256] = self._lightFontColor,
            [512] = self._lightFontColor,
            [1024] = self._lightFontColor,
            [2048] = self._lightFontColor,
            [4096] = self._lightFontColor
        }
    }
    self._actionTime = 0.1
    self._cellScaleRange = 1.2
    self._touchMoveDis = 100
    self._moveSpeed = 2500 --每秒
end

return GameCofig
