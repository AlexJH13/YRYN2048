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

GameScene.DirectionString = {
    [0] = "UP",
    [1] = "DOWN",
    [2] = "LEFT",
    [3] = "RIGHT"
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
    self._touchStartPos = nil
    self._touchActive = true
    self._scoreLabel = nil
    self._score = 0
    self._gameOverNodeActive = false
    self._restartItem = nil
    self._gameOverBgNode = nil

    self:addBg()
    self:addGameBg()
    self:addCellBg()
    self:addScoreLabel()
    self:startGestureListen()
    self:gameStart()
end

function GameScene:addScoreLabel()
    self._scoreLabel = cc.Label:createWithSystemFont("0", "Arial", 90)
    self._scoreLabel:setTextColor(cc.c4b(0, 0, 0, 255))
    self._scoreLabel:setPosition(self._vSize.width / 2, self._vSize.height -200)
    self:addChild(self._scoreLabel)
end

function GameScene:addScore(score)
    self._score = self._score + score
    self._scoreLabel:setString(self._score)
end

function GameScene:gameStart()
    self:initCells()
    for i = 1, 2 do
        self:addNewCell()
    end
end

function GameScene:startGestureListen()
    local function onTouchBegan(touch, event)
        if not self._gameOverNodeActive then
            self._touchStartPos = touch:getLocation()
            self._touchActive = true
        end
        return true
    end

    local function onTouchMoved(touch, event)
        if not self._gameOverNodeActive then
            if self._touchActive then
                local movePos = touch:getLocation()
                if movePos.y - self._touchStartPos.y > self._config._touchMoveDis then
                    --up
                    self:moveAndCheckAddNewCell(GameScene.Direction.UP)
                    self._touchActive = false
                elseif self._touchStartPos.y - movePos.y > self._config._touchMoveDis then
                    --down
                    self:moveAndCheckAddNewCell(GameScene.Direction.DOWN)
                    self._touchActive = false
                elseif movePos.x - self._touchStartPos.x > self._config._touchMoveDis then
                    --right
                    self:moveAndCheckAddNewCell(GameScene.Direction.RIGHT)
                    self._touchActive = false
                elseif self._touchStartPos.x - movePos.x > self._config._touchMoveDis then
                    --left
                    self:moveAndCheckAddNewCell(GameScene.Direction.LEFT)
                    self._touchActive = false
                end
            end
        end
    end

    local function onTouchEnded(touch, event)
        if self._gameOverNodeActive then
            local pos = touch:getLocation()
            if cc.rectContainsPoint(self._restartItem:getBoundingBox(), pos) then
                self:restartClick()
            end
        end
    end
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)
end

function GameScene:moveAndCheckAddNewCell(direction)
    if self:move(direction) then
        self:addNewCell()
    else
        self:checkGameOver()
    end
end

function GameScene:checkGameOver()
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
    if cleanCellsCount == 0 then
        if self:checkHasMergeCell(GameScene.Direction.UP) then
            return
        end

        if self:checkHasMergeCell(GameScene.Direction.DOWN) then
            return
        end

        if self:checkHasMergeCell(GameScene.Direction.LEFT) then
            return
        end

        if self:checkHasMergeCell(GameScene.Direction.RIGHT) then
            return
        end
        self:gameOver()
    end
end

function GameScene:checkHasMergeCell(direction)
    if direction == GameScene.Direction.LEFT then
        for row = 1, 4 do
            for column = 1, 4 do
                if column ~= 4 then
                    if self._cellValueMatrix[row][column] ~= 0 and self._cellValueMatrix[row][column] == self._cellValueMatrix[row][column + 1] then
                        return true
                    end
                end
            end
        end
    elseif direction == GameScene.Direction.RIGHT then
        for row = 1, 4 do
            for column = 4, 1, -1 do
                if column ~= 1 then
                    if self._cellValueMatrix[row][column] ~= 0 and self._cellValueMatrix[row][column] == self._cellValueMatrix[row][column - 1] then
                        return true
                    end
                end
            end
        end
    elseif direction == GameScene.Direction.UP then
        for column = 1, 4 do
            for row = 1, 4 do
                if row ~= 4 then
                    if self._cellValueMatrix[row][column] ~= 0 and self._cellValueMatrix[row][column] == self._cellValueMatrix[row + 1][column] then
                       return true
                    end
                end
            end
        end
    elseif direction == GameScene.Direction.DOWN then
        for column = 1, 4 do
            for row = 4, 1, -1 do
                if row ~= 1 then
                    if self._cellValueMatrix[row][column] ~= 0 and self._cellValueMatrix[row][column] == self._cellValueMatrix[row - 1][column] then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function GameScene:move(direction)
    --将两个矩阵的值更新，并将动画参数储存
    self:initMoveData(direction)
    --判断是否有合并的情况
    self:initMergeData(direction)
    local changeFlag1 = self:checkAndRunMove()
    --合并后还要检查一次是否还能移动
    self:initMoveData(direction)
    self._mergeList = {}
    local changeFlag2 = self:checkAndRunMove()
    if not changeFlag1 and not changeFlag2 then
        return false
    end
    return true
end

function GameScene:printValueMatrix()
    print("_cellValueMatrix = {")
    for i = 1, 4 do
        print(self._cellValueMatrix[i][1].." "..self._cellValueMatrix[i][2].." "..self._cellValueMatrix[i][3].." "..self._cellValueMatrix[i][4])
    end
    print("}")
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
        rowStart = 1
        rowEnd = 4
        rowAdd = 1
        columnStart = 1
        columnEnd = 4
        columnAdd = 1
    elseif direction == GameScene.Direction.DOWN then
        rowStart = 4
        rowEnd = 1
        rowAdd = -1
        columnStart = 1
        columnEnd = 4
        columnAdd = 1
    end

    if direction == GameScene.Direction.LEFT or direction == GameScene.Direction.RIGHT then
        for row = rowStart, rowEnd, rowAdd do
            for column = columnStart, columnEnd, columnAdd do
                if self._cellValueMatrix[row][column] ~= 0 then
                    self:checkMoveDataLogic(row, column, direction)
                end
            end
        end
    elseif direction == GameScene.Direction.UP or direction == GameScene.Direction.DOWN then
        for column = columnStart, columnEnd, columnAdd do
            for row = rowStart, rowEnd, rowAdd do
                if self._cellValueMatrix[row][column] ~= 0 then
                    self:checkMoveDataLogic(row, column, direction)
                end
            end
        end
    end
end

function GameScene:checkMoveDataLogic(row, column, direction)
    local ciStart = 0
    local ciEnd = 0
    local ciAdd = 0
    if direction == GameScene.Direction.LEFT or direction == GameScene.Direction.RIGHT then
        local moveToColumn = column
        local columnStart = 0

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
    elseif direction == GameScene.Direction.UP or direction == GameScene.Direction.DOWN then
        local moveToRow = row
        local rowStart = 0
        if direction == GameScene.Direction.UP then
            rowStart = 1
            ciStart = row - 1
            ciEnd = 1
            ciAdd = -1
        elseif direction == GameScene.Direction.DOWN then
            rowStart = 4
            ciStart = row + 1
            ciEnd = 4
            ciAdd = 1
        end

        if row ~= rowStart then
            for ci = ciStart, ciEnd, ciAdd do
                if self._cellValueMatrix[ci][column] == 0 then
                    moveToRow = ci
                end
            end
        end

        if moveToRow ~= row then
            local move = {}
            move.cell = self._cellMatrix[row][column]
            move.targetIdx = {
                row = moveToRow,
                column = column
            }
            move.merge = false
            table.insert( self._moveList, move)
            self._cellValueMatrix[moveToRow][column] = self._cellValueMatrix[row][column]
            self._cellMatrix[moveToRow][column] = self._cellMatrix[row][column]
            self._cellValueMatrix[row][column] = 0
            self._cellMatrix[row][column] = nil 
        end
    end
end


function GameScene:initMergeData(direction)
    self._mergeList = {}
    if direction == GameScene.Direction.LEFT then
        for row = 1, 4 do
            for column = 1, 4 do
                if column ~= 4 then
                    if self._cellValueMatrix[row][column] ~= 0 and self._cellValueMatrix[row][column] == self._cellValueMatrix[row][column + 1] then
                        self._cellValueMatrix[row][column] = self._cellValueMatrix[row][column] * 2
                        self:addScore(self._cellValueMatrix[row][column])
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
    elseif direction == GameScene.Direction.RIGHT then
        for row = 1, 4 do
            for column = 4, 1, -1 do
                if column ~= 1 then
                    if self._cellValueMatrix[row][column] ~= 0 and self._cellValueMatrix[row][column] == self._cellValueMatrix[row][column - 1] then
                        self._cellValueMatrix[row][column] = self._cellValueMatrix[row][column] * 2
                        self:addScore(self._cellValueMatrix[row][column])
                        self._cellValueMatrix[row][column - 1] = 0
                        local doubleCell = {
                            row = row,
                            column = column
                        }
                        local findMoveCell = false
                        for k,v in pairs(self._moveList) do
                            if v.targetIdx.row == row and v.targetIdx.column == column - 1 then
                                v.merge = true
                                findMoveCell = true
                                break
                            end
                        end
                        if not findMoveCell then
                            self._cellMatrix[row][column - 1]:removeFromParent()
                        end
                        table.insert(self._mergeList, doubleCell)
                        self._cellMatrix[row][column - 1] = nil
                    end
                end
            end
        end
    elseif direction == GameScene.Direction.UP then
        for column = 1, 4 do
            for row = 1, 4 do
                if row ~= 4 then
                    if self._cellValueMatrix[row][column] ~= 0 and self._cellValueMatrix[row][column] == self._cellValueMatrix[row + 1][column] then
                        self._cellValueMatrix[row][column] = self._cellValueMatrix[row][column] * 2
                        self:addScore(self._cellValueMatrix[row][column])
                        self._cellValueMatrix[row + 1][column] = 0
                        local doubleCell = {
                            row = row,
                            column = column
                        }
                        local findMoveCell = false
                        for k,v in pairs(self._moveList) do
                            if v.targetIdx.row == row + 1 and v.targetIdx.column == column then
                                v.merge = true
                                findMoveCell = true
                                break
                            end
                        end
                        if not findMoveCell then
                            self._cellMatrix[row + 1][column]:removeFromParent()
                        end
                        table.insert(self._mergeList, doubleCell)
                        self._cellMatrix[row + 1][column] = nil
                    end
                end
            end
        end
    elseif direction == GameScene.Direction.DOWN then
        for column = 1, 4 do
            for row = 4, 1, -1 do
                if row ~= 1 then
                    if self._cellValueMatrix[row][column] ~= 0 and self._cellValueMatrix[row][column] == self._cellValueMatrix[row - 1][column] then
                        self._cellValueMatrix[row][column] = self._cellValueMatrix[row][column] * 2
                        self:addScore(self._cellValueMatrix[row][column])
                        self._cellValueMatrix[row - 1][column] = 0
                        local doubleCell = {
                            row = row,
                            column = column
                        }
                        local findMoveCell = false
                        for k,v in pairs(self._moveList) do
                            if v.targetIdx.row == row - 1 and v.targetIdx.column == column then
                                v.merge = true
                                findMoveCell = true
                                break
                            end
                        end
                        if not findMoveCell then
                            self._cellMatrix[row - 1][column]:removeFromParent()
                        end
                        table.insert(self._mergeList, doubleCell)
                        self._cellMatrix[row - 1][column] = nil
                    end
                end
            end
        end
    end
end

function GameScene:checkAndRunMove()
    if table.maxn(self._moveList) == 0 and table.maxn(self._mergeList) == 0 then
        return false
    end
    for k,v in pairs(self._moveList) do
        local targetPos = self:getCellPosition(v.targetIdx.row, v.targetIdx.column)
        local targetCellSp = v.cell
        local nowPos = cc.p(0, 0)
        nowPos.x, nowPos.y = targetCellSp:getPosition()
        local dis = cc.pGetDistance(nowPos, targetPos)
        local moveTo = cc.MoveTo:create(dis / self._config._moveSpeed, targetPos)
        targetCellSp:stopAllActions()
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
    return true
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
        --显示出来的动画
        cellSp:setVisible(false)
        cellSp:setScale(0.7)
        local function callback(cell)
            cell:setVisible(true)
        end
        local callFunN = cc.CallFunc:create(callback)
        local delay = cc.DelayTime:create(self._config._actionTime)
        local scaleTo = cc.ScaleTo:create(self._config._actionTime, 1)
        local seq = cc.Sequence:create(delay, callFunN, scaleTo)
        cellSp:runAction(seq)
    else
        self:gameOver()
    end
end

function GameScene:createValueCell(value)
    local cell = self:createColorRoundRectSprite(self._config._cell.contentSize,
                                                 self._config._cell.valueColor[value],
                                                 self._config._cell.radius)
    local fontSize = 90
    local valueNum = tonumber(value)
    local outlineSize = 5
    if valueNum / 1000 >= 1 then
        fontSize = 50
        outlineSize = 2
    elseif valueNum / 1000 < 1 and valueNum / 100 >= 1 then
        fontSize = 70
        outlineSize = 4
    end

    local cellLabel = cc.Label:createWithSystemFont(value, "Arial", fontSize)
    cellLabel:setPosition(self._config._cell.contentSize.width / 2, self._config._cell.contentSize.height / 2)
    local color4b = cc.c4b(self._config._cell.fontColor[value].r, self._config._cell.fontColor[value].g, self._config._cell.fontColor[value].b, 255)
    cellLabel:setTextColor(color4b)
    cellLabel:enableOutline(color4b, outlineSize)
    cell:addChild(cellLabel)
    return cell
end

function GameScene:gameOver()
    self:addGameOverNode()
end

function GameScene:addGameOverNode()
    self._gameOverNodeActive = true
    local nodeSize = self._vSize
    local bgColor = cc.c3b(249, 245, 235)

    self._gameOverBgNode = self:createColorRectSprite(nodeSize, bgColor)
    self._gameOverBgNode:setPosition(self._vSize.width / 2, self._vSize.height / 2)
    self:addChild(self._gameOverBgNode)

    local gameOverText= cc.Label:createWithSystemFont("Game Over!", "Arial", 110)
    gameOverText:setTextColor(cc.c4b(99, 91, 82, 255))
    gameOverText:setPosition(self._vSize.width / 2, self._vSize.height - 150)
    gameOverText:enableOutline(cc.c4b(99, 91, 82, 255), 3)
    self._gameOverBgNode:addChild(gameOverText)

    local itemBgSize = cc.size(500, 200)
    local itemBgColor = cc.c3b(172, 156, 142)
    local itemRadius = 15
    local scoreBg = self:createColorRoundRectSprite(itemBgSize, itemBgColor, itemRadius)
    scoreBg:setPosition(self._vSize.width / 2, self._vSize.height - 400)
    self._gameOverBgNode:addChild(scoreBg)

    local scoreText = cc.Label:createWithSystemFont("分数", "Arial", 55)
    scoreText:setTextColor(cc.c4b(233, 221, 203, 255))
    scoreText:setPosition(itemBgSize.width / 2, itemBgSize.height - 50)
    scoreText:enableOutline(cc.c4b(233, 221, 203, 255), 1)
    scoreBg:addChild(scoreText)

    local scoreLabel = cc.Label:createWithSystemFont(self._score, "Arial", 70)
    scoreLabel:setTextColor(cc.c4b(254, 254, 254, 255))
    scoreLabel:setPosition(itemBgSize.width / 2, 60)
    scoreLabel:enableOutline(cc.c4b(254, 254, 254, 255), 2)
    scoreBg:addChild(scoreLabel)

    self._restartItem = self:createColorRoundRectSprite(itemBgSize, itemBgColor, itemRadius)
    self._restartItem:setPosition(self._vSize.width / 2, self._vSize.height - 800)
    self._gameOverBgNode:addChild(self._restartItem)

    local restartText = cc.Label:createWithSystemFont("重新开始", "Arial", 75)
    restartText:setTextColor(cc.c4b(254, 254, 254, 255))
    restartText:setPosition(itemBgSize.width / 2, itemBgSize.height / 2)
    restartText:enableOutline(cc.c4b(254, 254, 254, 255), 1)
    self._restartItem:addChild(restartText)

    local fadeIn = cc.FadeIn:create(0.2)
    self._gameOverBgNode:runAction(fadeIn)
end

function GameScene:restartClick()
    self._gameOverBgNode:removeFromParent()
    self._gameOverBgNode = nil
    self._gameOverNodeActive = false
    self._restartItem = nil
    self._score = 0
    self._scoreLabel:setString("0")

    for row = 1, 4 do
        for column = 1, 4 do
            if self._cellMatrix[row][column] ~= nil then
                self._cellMatrix[row][column]:removeFromParent()
                self._cellMatrix[row][column] = nil
            end
            self._cellValueMatrix[row][column] = 0
        end
    end
    self:gameStart()
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
