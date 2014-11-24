--[[
@see https://github.com/luochong/SWFUIExport
@author LeoLuo(luochong1987@gmail.com)
Creation: 2014-11-24
]]
local LayoutUtil = require("LayoutUtil")

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

function MainScene:ctor()
   self.layout = LayoutUtil.new("game")
   self.prognum = 0
end


function MainScene:onEnter()
   self.gameView = self.layout:buildLayout("gameView")
   self.gameView:pos(display.cx, display.cy)
   self:addChild(self.gameView)

   self.star1 = self:g(self.gameView,"star1")
   self.star2 = self:g(self.gameView,"star2")

   self.actionView = self:g(self.gameView,"actionView")
   self.button = self:g(self.actionView, "btnS_fblogin")
   self.progbar = self:g(self.actionView, "prog_mainloading")
   self.progtxt = self:g(self.actionView, "jdtxt")


   self.star2:gotoAndStop(5)
   self.progbar:setPercentage(0)

   self.button:addEventListener("click", function() 
   		self.prognum = self.prognum + 10
   		if self.prognum > 100 then
            self.star1:stop()
   			self.prognum = 0
   		end
   		self.progtxt:setString(self.prognum .. "%")
   		self.progbar:setPercentage(self.prognum)
   end)
end


function MainScene:g(parent,name)
   return self.layout:getChildByName(parent, name)
end

return MainScene
