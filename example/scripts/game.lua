--[[
@see https://github.com/luochong/SWFUIExport
@author LeoLuo(luochong1987@gmail.com)
Creation: 2014-11-24
]]
require("config")
require("framework.init")

game = {}
function game.startup()
    CCFileUtils:sharedFileUtils():addSearchPath("res/")
    game.enterMainScene()
end

function game.enterMainScene()
    display.replaceScene(require("scenes.MainScene").new(), "fade", 0.6, display.COLOR_WHITE)
end