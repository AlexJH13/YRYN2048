--[[
    GameScene
    Author:夏阳
    Des:游戏主场景
]]
local GameScene = class("GameScene", cc.load("mvc").ViewBase)

GameScene.Direction = {
    UP = 0,
    DOWN = 1,
    LEFT = 2,
    RIGHT = 3
}

function GameScene:onCreate()
    self._config = require("app.GameConfig"):create()
    self._vSize = cc.Director:getInstance():getVisibleSize()
    self._gameBg = nil 
    -- 一个 4 x 4的矩阵，标示着cell上面的值
    self._cellValueMatrix = {}
    -- 一个有值的cell矩阵
    self._cellMatrix = {}
    self._moveList = {}
    self._mergeList = {}

    self:addBg()
    self:addGameBg()
    self:addCellBg()
    self:gameStart()
end

function GameScene:gameStart()
    self:initCells()
    for i = 1, 2 do
        self:addNewCell()
    end
   
    self:startGestureListen()
end

function GameScene:startGestureListen()
    self:testMoveUI()
end

function GameScene:testMoveUI()
    local menu = cc.Menu:create()
    local menuItemLeft = cc.MenuItemFont:create("Left")
    local function left(sender)
        -- self:moveToLeft()
        self:move(GameScene.Direction.LEFT)
        self:addNewCell()
    end
    menuItemLeft:registerScriptTapHandler(left)
    menuItemLeft:setPosition(100, 100)
    menu:addChild(menuItemLeft)

    local menuItemRight = cc.MenuItemFont:create("Right")
    local function right(sender)
        -- self:moveToRight()
        self:move(GameScene.Direction.RIGHT)
        self:addNewCell()
    end
    menuItemRight:registerScriptTapHandler(right)
    menuItemRight:setPosition(200, 100)
    menu:addChild(menuItemRight)

    local menuItemUp = cc.MenuItemFont:create("Up")
    local function up(sender)
        self:moveToUp()
    end
    menuItemUp:registerScriptTapHandler(up)
    menuItemUp:setPosition(150, 150)
    menu:addChild(menuItemUp)

    local menuItemDown = cc.MenuItemFont:create("Down")
    local function down(sender)
        self:moveToDown()
    end
    menuItemDown:registerScriptTapHandler(down)
    menuItemDown:setPosition(150, 50)
    menu:addChild(menuItemDown)

    menu:setColor(cc.c4f(1, 1, 1, 1))

    self._gameBg:addChild(menu)
end

function GameScene:move(direction)
    --将两个矩阵的值更新，并将动画参数储存
    self:initMoveData(direction)
    --判断是否有合并的情况
    self:initMergeData(direction)
    self:checkAndRunMove()
    --合并后还要检查一次是否还能移动
    self:initMoveData(direction)
    self._mergeList = {}
    self:checkAndRunMove()

end

function GameScene:initMoveData(direction)
    self._moveList = {}
    local rowStart = 0
    local rowEnd = 0
    local rowAdd = 0

    local columnStart = 0
    local columnEnd = 0
    local columnAdd = 0

    if direction == GameScene.Direction.LEFT then
        rowStart = 1
        rowEnd = 4
        rowAdd = 1
        columnStart = 1
        columnEnd = 4
        columnAdd = 1
    elseif direction == GameScene.Direction.RIGHT then
        rowStart = 1
        rowEnd = 4
        rowAdd = 1
        columnStart = 4
        columnEnd = 1
        columnAdd = -1
    elseif direction == GameScene.Direction.UP then
        -- rowStart = 1
        -- rowEnd = 4
        -- rowAdd = 1
        -- columnStart = 1
        -- columnEnd = 4
        -- columnAdd = 1
    elseif direction == GameScene.Direction.DOWN then
        -- rowStart = 1
        -- rowEnd = 4
        -- rowAdd = 1
        -- columnStart = 1
        -- columnEnd = 4
        -- columnAdd = 1
    end

    

    for row = rowStart, rowEnd, rowAdd do
        for column = columnStart, columnEnd, columnAdd do
            if self._cellValueMatrix[row][column] ~= 0 then
                self:checkMoveDataLogic(row, column, direction)
            end
        end
    end
end

function GameScene:checkMoveDataLogic(row, column, direction)
    local moveToColumn = column
    local columnStart = 0

    local ciStart = 0
    local ciEnd = 0
    local ciAdd = 0

    if direction == GameScene.Direction.LEFT then
        columnStart = 1
        ciStart = column - 1
        ciEnd = 1
        ciAdd = -1
    elseif direction == GameScene.Direction.RIGHT then
        columnStart = 4
        ciStart = column + 1
        ciEnd = 4
        ciAdd = 1
    end

    if column ~= columnStart then
        for ci = ciStart, ciEnd, ciAdd do
            if self._cellValueMatrix[row][ci] == 0 then
                moveToColumn = ci
            end
        end
    end

    if moveToColumn ~= column then
        local move = {}
        move.cell = self._cellMatrix[row][column]
        move.targetIdx = {
            row = row,
            column = moveToColumn
        }
        move.merge = false
        table.insert( self._moveList, move)
        self._cellValueMatrix[row][moveToColumn] = self._cellValueMatrix[row][column]
        self._cellMatrix[row][moveToColumn] = self._cellMatrix[row][column]
        self._cellValueMatrix[row][column] = 0
        self._cellMatrix[row][column] = nil 
    end
end


function GameScene:initMergeData(direction)
    -- body
end

function GameScene:moveToLeft()
    --往左移的将两个矩阵的值更新，并将动画参数储存
    self:initMoveLeftData()
    --判断是否有合并的情况
    self:initMergeData()
    self:checkAndRunMove()
    --合并后还要检查一次是否还能移动
    self:initMoveLeftData()
    self._mergeList = {}
    self:checkAndRunMove()
end

function GameScene:moveToRight()
end

function GameScene:moveToUp()
end

function GameScene:moveToDown()
end

function GameScene:initMoveLeftData()
    self._moveList = {}
    for row = 1, 4 do
        for column = 1,4 do
            if self._cellValueMatrix[row][column] ~= 0 then
                local moveToColumn = column
                if column ~= 1 then
                    for ci = column - 1, 1, -1 do
                        if self._cellValueMatrix[row][ci] == 0 then
                            moveToColumn = ci
                        end
                    end
                end
                if moveToColumn ~= column then 
                    local move = {}
                    move.cell = self._cellMatrix[row][column]
                    move.targetIdx = {
                        row = row,
                        column = moveToColumn
                    }
                    move.merge = false
                    table.insert( self._moveList, move)
                    self._cellValueMatrix[row][moveToColumn] = self._cellValueMatrix[row][column]
                    self._cellMatrix[row][moveToColumn] = self._cellMatrix[row][column]
                    self._cellValueMatrix[row][column] = 0
                    self._cellMatrix[row][column] = nil 
                end
            end
        end
    end
end

function GameScene:initMergeData()
    self._mergeList = {}
    for row = 1, 4 do
        for column = 1, 4 do
            if column ~= 4 then
                if self._cellValueMatrix[row][column] ~= 0 and self._cellValueMatrix[row][column] == self._cellValueMatrix[row][column + 1] then
                    self._cellValueMatrix[row][column] = self._cellValueMatrix[row][column] * 2
                    self._cellValueMatrix[row][column + 1] = 0
                    local doubleCell = {
                        row = row,
                        column = column
                    }
                    local findMoveCell = false
                    for k,v in pairs(self._moveList) do
                        if v.targetIdx.row == row and v.targetIdx.column == column + 1 then
                            v.merge = true
                            findMoveCell = true
                            break
                        end
                    end
                    if not findMoveCell then
                        self._cellMatrix[row][column + 1]:removeFromParent()
                    end
                    table.insert(self._mergeList, doubleCell)
                    self._cellMatrix[row][column + 1] = nil
                end
            end
        end
    end
end

function GameScene:checkAndRunMove()
    for k,v in pairs(self._moveList) do
        local targetPos = self:getCellPosition(v.targetIdx.row, v.targetIdx.column)
        local targetCellSp = v.cell
        local moveTo = cc.MoveTo:create(self._config._actionTime, targetPos)
        if v.merge then
            local removeSelf = cc.RemoveSelf:create()
            local seq = cc.Sequence:create(moveTo, removeSelf)
            targetCellSp:runAction(seq)
        else 
            targetCellSp:runAction(moveTo)
        end
    end

    for k,v in pairs(self._mergeList) do
        local mergeCell = self._cellMatrix[v.row][v.column]
        mergeCell:removeFromParent()
        local newCell = self:createValueCell(self._cellValueMatrix[v.row][v.column])
        newCell:setPosition(self:getCellPosition(v.row, v.column))
        self._cellMatrix[v.row][v.column] = newCell
        self._gameBg:addChild(newCell)

        local scaleToBig = cc.ScaleTo:create(self._config._actionTime / 2, self._config._cellScaleRange)
        local scaleToNormal = cc.ScaleTo:create(self._config._actionTime / 2, 1)
        local seq = cc.Sequence:create(scaleToBig, scaleToNormal)
        newCell:runAction(seq)
    end
    
end

function GameScene:initCells()
    self._cellValueMatrix = {}
    self._cellMatrix = {}
    self._moveList = {}
    self._mergeList = {}
    for row = 1, 4 do
        local columnValue = {}
        local columnCell = {}
        for column = 1, 4 do
            columnValue[column] = 0
            columnCell[column] = nil
        end
        self._cellValueMatrix[row] = columnValue
        self._cellMatrix[row] = columnCell
    end
end

function GameScene:addNewCell()
    --判断当前是否还有空间显示增加新的cell
    local cleanCells = {}
    for row = 1, 4 do
        for column = 1,4 do
            if self._cellValueMatrix[row][column] == 0 then
                local cell = {}
                cell.row = row
                cell.column = column
                table.insert(cleanCells, cell)
            end
        end
    end
    local cleanCellsCount = table.maxn(cleanCells)
    if cleanCellsCount ~= 0 then
        --随机一个位置用于显示
        local idx = math.random(cleanCellsCount)
        --随机一个2或者4 作为cell的值
        local valueRandom = math.random(2)
        local value = valueRandom * 2
        --创建cell
        local cellSp = self:createValueCell(value)
        cellSp:setPosition(self:getCellPosition(cleanCells[idx].row, cleanCells[idx].column))
        self._gameBg:addChild(cellSp)
        self._cellValueMatrix[cleanCells[idx].row][cleanCells[idx].column] = value
        self._cellMatrix[cleanCells[idx].row][cleanCells[idx].column] = cellSp
    else
        self:gameOver()
    end
end

function GameScene:createValueCell(value)
    local cell = self:createColorRoundRectSprite(self._config._cell.contentSize,
                                                 self._config._cell.valueColor[value],
                                                 self._config._cell.radius)
    local cellLabel = cc.Label:createWithSystemFont(value, "Arial", 90)
    cellLabel:setPosition(self._config._cell.contentSize.width / 2, self._config._cell.contentSize.height / 2)
    local color4b = cc.c4b(self._config._cell.fontColor[value].r, self._config._cell.fontColor[value].g, self._config._cell.fontColor[value].b, 255)
    cellLabel:setTextColor(color4b)
    cellLabel:enableOutline(color4b, 5)
    cell:addChild(cellLabel)
    return cell
end

function GameScene:gameOver()
end

function GameScene:addCellBg()
    -- 4行4列的cell
    for row = 1, 4 do
        for column = 1, 4 do
            local cellBg = self:createColorRoundRectSprite(self._config._cell.contentSize,
                                                           self._config._cell.bgColor,
                                                           self._config._cell.radius)
            cellBg:setPosition(self:getCellPosition(row, column))
            self._gameBg:addChild(cellBg)
        end
    end
end

function GameScene:addGameBg()
    self._gameBg = self:createColorRoundRectSprite(self._config._gameBg.contentSize, 
                                                   self._config._gameBg.color, 
                                                   self._config._gameBg.radius)
    self._gameBg:setPosition(self._vSize.width / 2, self._vSize.height / 2)
    self:addChild(self._gameBg)
end

function GameScene:addBg()
    local bgSprite = self:createColorRectSprite(self._vSize, self._config._bgColor)
    bgSprite:setPosition(self._vSize.width / 2, self._vSize.height / 2)
    self:addChild(bgSprite)
end

function GameScene:getCellPosition(row, column)
    local x = self._config._cell.interval + self._config._cell.contentSize.width / 2 
            + (column - 1) * (self._config._cell.contentSize.width + self._config._cell.interval)
    local y = self._config._gameBg.contentSize.height 
            - (self._config._cell.interval + self._config._cell.contentSize.height / 2 
            + (row - 1) * (self._config._cell.contentSize.height + self._config._cell.interval))
    return cc.p(x, y)
end

function GameScene:createColorRectSprite(contentSize, color)
    local drawNode = cc.DrawNode:create()
    drawNode:setContentSize(contentSize)
    drawNode:setAnchorPoint(0.5, 0.5)
    local verts = {}
    verts[1] = cc.p(0, 0)
    verts[2] = cc.p(contentSize.width, 0)
    verts[3] = cc.p(contentSize.width, contentSize.height)
    verts[4] = cc.p(0, contentSize.height)
    local color4f = cc.c4f(color.r / 255, color.g / 255, color.b / 255, 1)
    drawNode:drawPolygon(verts, 4, color4f, 0, color4f)
    return drawNode
end

function GameScene:createColorRoundRectSprite(contentSize, color, radius)
    local drawNode = cc.DrawNode:create()
    drawNode:setContentSize(contentSize)
    drawNode:setAnchorPoint(0.5, 0.5)
    local color4f = cc.c4f(color.r / 255, color.g / 255, color.b / 255, 1)
    --水平矩形
    local vertsHor = {}
    vertsHor[1] = cc.p(0, radius)
    vertsHor[2] = cc.p(contentSize.width, radius)
    vertsHor[3] = cc.p(contentSize.width, contentSize.height - radius)
    vertsHor[4] = cc.p(0, contentSize.height - radius)
    drawNode:drawPolygon(vertsHor, 4, color4f, 0, color4f)
    --竖直矩形
    local vertsVer = {}
    vertsVer[1] = cc.p(radius, 0)
    vertsVer[2] = cc.p(contentSize.width - radius, 0)
    vertsVer[3] = cc.p(contentSize.width - radius, contentSize.height)
    vertsVer[4] = cc.p(radius, contentSize.height)
    drawNode:drawPolygon(vertsVer, 4, color4f, 0, color4f)
    --角落里的四个圆
    drawNode:drawDot(cc.p(radius, radius), radius, color4f)
    drawNode:drawDot(cc.p(contentSize.width - radius, radius), radius, color4f)
    drawNode:drawDot(cc.p(contentSize.width - radius, contentSize.height - radius), radius, color4f)
    drawNode:drawDot(cc.p(radius, contentSize.height - radius), radius, color4f)

    return drawNode
end

return GameScene
