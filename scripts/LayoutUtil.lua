--[[
@see https://github.com/luochong/SWFUIExport
@author LeoLuo(luochong1987@gmail.com)
Creation: 2014-11-24
]]
local  LayoutUtil = class("LayoutUtil")

-- 常量 
	-- 容器
LayoutUtil.SPRITE = "sprite"    -- 插小红旗
	-- 图片
LayoutUtil.IMAGE = "image"   -- 没有小红旗又没有前缀的
	-- 布局按钮
LayoutUtil.NORMALBTN = "btn" -- 前缀 btn
	-- 2帧按钮
LayoutUtil.SBTN = "btnS"  -- 前缀 btnS
	-- 文本框
LayoutUtil.TEXT = "text"    -- 自动识别
	-- 动画
LayoutUtil.MOVIE = "movie"       -- 前缀 mov
	-- 九宫格
LayoutUtil.S9IMAGE = "s9image"    -- 前缀 s9

-- 进度条 
LayoutUtil.progressTimer = "prog"  -- 前缀 prog
--创建一个空的node
LayoutUtil.POS = "pos" -- 前缀 pos
-- 缩放按钮
LayoutUtil.BTNSC = "btnSc" -- 前缀 btnSc
-- jpg背景图
LayoutUtil.PUB = "pub" -- 前缀 pub

function LayoutUtil:ctor(layoutName)
    local contents = CCFileUtils:sharedFileUtils():getFileData(layoutName ..".info")
    layoutData = json.decode(contents) 
    self.imagePlist_ = "1x/" .. layoutName .. ".plist"
    self.imageFile_ = "1x/" .. layoutName .. ".png"
	self.layoutsData_ = layoutData.layout
	self.createDisplayObject_ = {
		[LayoutUtil.SPRITE] = self.createSprite_,
		[LayoutUtil.IMAGE] = self.createImage_,
		[LayoutUtil.NORMALBTN] = self.createButton_,
		[LayoutUtil.TEXT] = self.createTextField_,
		[LayoutUtil.MOVIE] = self.createMovieClip_,
		[LayoutUtil.SBTN] = self.createSButton_,
		[LayoutUtil.S9IMAGE] = self.createS9Image_,
		[LayoutUtil.progressTimer] = self.createProgressTimer_,
		[LayoutUtil.POS] = self.createPosNode_,
		[LayoutUtil.BTNSC] = self.createScaleBtn_,
		[LayoutUtil.PUB] = self.createImage_,
	}

	self.buttonListener_ = {}
	self.animation_ = {}
	self.nameToNode = {}
	self.isLoadSpriteFrame_ = false
end

function LayoutUtil:buildLayout(name)
	if not self.isLoadSpriteFrame_ then 
		display.addSpriteFramesWithFile(self.imagePlist_, self.imageFile_)
		self.isLoadSpriteFrame_ = true
	end

	local sprite = self:createSprite_({cname = name})
	local children = sprite:getChildren()
	local width,height = 0,0
    if children ~= nil then
        local i = 0
	    local len = children:count()
	    for i = 0, len-1, 1 do
	        local  child = tolua.cast(children:objectAtIndex(i), "CCNode")
	        local size = child:getContentSize()
	        if size.width > width then
	        	width = size.width
	        end
	        if size.height > height then
	        	height = size.height
	        end
	    end
    end
    sprite:setContentSize(CCSize(ccp(width, height)))
	return sprite
end

function LayoutUtil:setName_(target,name,layer)	
	self.nameToNode[layer] = self.nameToNode[layer] or {}
	self.nameToNode[layer][name] = target
end

function LayoutUtil:getChildByName(parent,name)
	if isset(self.nameToNode, parent) then
		return self.nameToNode[parent][name]
	else
		echoError("name :" .. name .. " not exits")
	end
end

function LayoutUtil:buildDisplayObject(data)
	if isset(self.createDisplayObject_, data.type) then		
		return self.createDisplayObject_[data.type](self,data)	
	else
		echoError("no has -- %s", data.type)
	end
	return nil
end

function LayoutUtil:createSprite_(spritedata)	
	local returnSprite = display.newNode()	
	self:createChild_(returnSprite, spritedata.cname)
	returnSprite:setCascadeOpacityEnabled(true)
	return returnSprite
end

function LayoutUtil:createChild_(layer,cname)
	local layout = self.layoutsData_[cname]
	if layout == nil then
		echoError("layoutsData 不存在 name %s" , cname)
		return 
	end
	for  i,data in ipairs(layout) do
		if not isset(data,"name") then
			 data.name = data.cname
		end
		local node = self:buildDisplayObject(data)
		if node ~= nil then
			 node:setPosition(data.x, data.y)
			 if data.type ~= LayoutUtil.S9IMAGE then
			 	node:setScaleX(data.sx)
			 	node:setScaleY(data.sy)
			 end
			 node:setSkewX(data.skx)
			 node:setSkewY(data.sky)
			 self:setName_(node,data.name,layer)		
			 node:setContentSize(cc.size(data.w/data.sx,data.h/data.sy))
			 layer:addChild(node)
		end
	end
end

function LayoutUtil:createImage_(data)
	-- print("createImage -- ", data.name)
	if data.type == "pub" then
		if device.platform == "ios" or device.platform == "mac" then
			CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGB565)
		end
		return display.newSprite(string.format("public/%s.jpg" , data.cname))
	else
		return display.newSprite(string.format("#%s.png" , data.cname))
	end
end

function LayoutUtil:createProgressTimer_(data)
	local progress = display.newProgressTimer(string.format("#%s.png" , data.cname), kCCProgressTimerTypeBar)

	
	progress:setType(kCCProgressTimerTypeBar)
    progress:setMidpoint(CCPoint(0, 1))
    progress:setBarChangeRate(CCPoint(1,0))
    progress:setPercentage(100)
    
    return progress
end

function LayoutUtil:createS9Image_(data)
    local sprite = display.newScale9Sprite(string.format("#%s.png" , data.cname))
    -- 默认 CCRectMake(w/3, h/3, w/3, h/3);
    sprite:setContentSize(cc.size(data.w, data.h))
	-- body
	return sprite
end

function LayoutUtil:createTextField_(data)
	local label = CCLabelTTF:create(string.trim(data.text), data.font, data.size)
	label:setColor(ccc3(data.color / 256 / 256 % 256, data.color / 256 % 256, data.color % 256))
	if data.align == "center" then  label:setHorizontalAlignment(kCCTextAlignmentCenter) end
	if data.align == "left" then  label:setHorizontalAlignment(kCCTextAlignmentLeft) end
	if data.align == "right" then  label:setHorizontalAlignment(kCCTextAlignmentRight) end
	label:setVerticalAlignment(kCCVerticalTextAlignmentCenter)
	label:setDimensions(CCSize(data.w ,data.h))
	label:setAnchorPoint(ccp(0.5, 0.4))
	return label
end


function LayoutUtil:createMovieClip_(data)
    if not table.find(self.animation_, data.cname) then
    	local frames = display.newFrames(data.cname .. "%d.png", 1, data.len)
    	local animation = display.newAnimation(frames, 1 / 30)
    	table.insert(self.animation_, data.cname)
   		display.setAnimationCache(data.cname, animation)
    end

    local sprite = display.newSprite("#" .. data.cname .. "1.png")
    sprite:playAnimationForever(display.getAnimationCache(data.cname))
	return self:extendMovieClip_(sprite,data.cname)
end

function LayoutUtil:extendMovieClip_(object,name)
	object.animationName = name
	function object:gotoAndStop(index)
		object:stopAllActions()
		object:setDisplayFrameWithAnimationName(object.animationName, index)
	end

	function object:play()
		object:playAnimationForever(display.getAnimationCache(object.animationName))
	end

	function object:playOnce(removeWhenFinished, onComplete, delay)
		object:playAnimationOnce(display.getAnimationCache(object.animationName), removeWhenFinished, onComplete, delay)
	end

	return object
end

function LayoutUtil:createButton_(data)
	local layer = LayoutUtil.newSpriteButton(function (tag,moved) 
    	if isset(self.buttonListener_, data.name) then
    		self.buttonListener_[data.name](tag,moved)
    	end
    end)
	self:createChild_(layer,data.cname)
	return layer
end

function LayoutUtil:createSButton_(data)
	local button = nil
	local function listener(tag,moved)
		if button.clickSound ~= nil then
    		audio.playEffect(button.clickSound)
    	end
    	if isset(self.buttonListener_, data.name) then
    		self.buttonListener_[data.name](tag,moved)
    	end
    end
	button = LayoutUtil.newButton(data.cname,listener)
	function button:setClickSound(sound)
		button.clickSound = sound
	end
	return button
end

function LayoutUtil:createScaleBtn_(data)
	local button = nil
    button = LayoutUtil.newScaleButton(data.cname, function(tag, moved)
		if button.clickSound ~= nil then
			audio.playEffect(button.clickSound)
		end
		
		if isset(self.buttonListener_, data.name) then
    		self.buttonListener_[data.name](tag,moved)
    	end
	end)
	function button:setClickSound(sound)
		button.clickSound = sound
	end
	return button
end

function LayoutUtil.newScaleButton(imageName, listener)
	local sprite = display.newSprite(string.format("#%s.png", imageName))
	sprite:setTouchEnabled(true)
	require("framework.api.EventProtocol").extend(sprite)
	local isHeightLight = false
    local isMoveed = false
    local scale = 0.95
    sprite:addNodeEventListener(cc.NODE_TOUCH_EVENT,function(event)
        if event.name == "began" then
            if not isHeightLight then
            	sprite:setScale(scale)
            	isHeightLight = true
        	end
            return true
        end
        local rect = sprite:getCascadeBoundingBox();
        local touchInSprite = sprite:getCascadeBoundingBox():containsPoint(CCPoint(event.x, event.y))
        if event.name == "moved" then
            if touchInSprite then
            	if not isHeightLight then
               		sprite:scale(scale)
               		isHeightLight = true
        		end
        		isMoveed = true;
            else
            	if isHeightLight then
              		sprite:scale(1)
              		isHeightLight = false
              	end
            end
        elseif event.name == "ended" then
            if isHeightLight then
            	sprite:scale(1)
            	isHeightLight = false
            end
            if touchInSprite then 
            	sprite:dispatchEvent({name = "click"})
            	listener(sprite:getTag(),isMoveed) 
           	end
            isMoveed = false
        else
        	if isHeightLight then
            	sprite:scale(1)
            	isHeightLight = false
            end
        end
    end)
	return sprite
end

function LayoutUtil:addButtonListener(name, listener)
	self.buttonListener_[name] = listener
end

-- 创建图片按钮
function LayoutUtil.newButton(imageName, listener)
    local sprite = display.newSprite(string.format("#%s1.png" , imageName))
    sprite:setTouchEnabled(true)
    require("framework.api.EventProtocol").extend(sprite)
    local isHeightLight = false
    local isMoveed = false
    sprite:addNodeEventListener(cc.NODE_TOUCH_EVENT,function(event)
        if event.name == "began" then
            if not isHeightLight then

            	local frame = display.newSpriteFrame(string.format("%s2.png", imageName))
            	if frame then
            		sprite:setDisplayFrame(frame)
            	end
            	isHeightLight = true
        	end
        	sprite:dispatchEvent({name = "touchDown"})
            return true
        end
        local rect = sprite:getCascadeBoundingBox()
        local touchInSprite = sprite:getCascadeBoundingBox():containsPoint(CCPoint(event.x, event.y))
        if event.name == "moved" then
            if touchInSprite then
            	if not isHeightLight then
            		local frame = display.newSpriteFrame(string.format("%s2.png", imageName))
	            	if frame then
	            		sprite:setDisplayFrame(frame)
	            	end
               		isHeightLight = true
        		end
        		isMoveed = true;
            else
            	if isHeightLight then
              		local frame = display.newSpriteFrame(string.format("%s1.png", imageName))
	            	if frame then
	            		sprite:setDisplayFrame(frame)
	            	end
              		isHeightLight = false
              	end
            end
        elseif event.name == "ended" then
            if isHeightLight then
            	local frame = display.newSpriteFrame(string.format("%s1.png", imageName))
            	if frame then
            		sprite:setDisplayFrame(frame)
            	end
            	isHeightLight = false
            end
            if touchInSprite then 
            	sprite:dispatchEvent({name = "click"})
            	if listener ~= nil then
            		listener(sprite:getTag(),isMoveed)
            	end
           	end
           	sprite:dispatchEvent({name = "touchEnded"})
            isMoveed = false
        else
        	if isHeightLight then
        		local frame = display.newSpriteFrame(string.format("%s1.png", imageName))
            	if frame then
            		sprite:setDisplayFrame(frame)
            	end
            	isHeightLight = false
            end
        end
    end)

    return sprite
end

function LayoutUtil.newSpriteButton(listener)
    local sprite = display.newNode()
    require("framework.api.EventProtocol").extend(sprite)
     sprite:setTouchEnabled(true)
    local isHeightLight = false
    local isMoveed = false
    local scale = 0.95
    sprite:addNodeEventListener(cc.NODE_TOUCH_EVENT,function(event)
       if event.name == "began" then
            if not isHeightLight then
            	sprite:setScale(scale)
            	isHeightLight = true
        	end
            return true
        end
        local rect = sprite:getCascadeBoundingBox();
        local touchInSprite = sprite:getCascadeBoundingBox():containsPoint(CCPoint(event.x, event.y))
        if event.name == "moved" then
            if touchInSprite then
            	if not isHeightLight then
               		sprite:scale(scale)
               		isHeightLight = true
        		end
        		isMoveed = true;
            else
            	if isHeightLight then
              		sprite:scale(1)
              		isHeightLight = false
              	end
            end
        elseif event.name == "ended" then
            if isHeightLight then
            	sprite:scale(1)
            	isHeightLight = false
            end
            if touchInSprite then 
            	sprite:dispatchEvent({name = "click"})
            	listener(sprite:getTag(),isMoveed) 
           	end
            isMoveed = false
        else
        	if isHeightLight then
            	sprite:scale(1)
            	isHeightLight = false
            end
        end
    end)

    return sprite
end

function LayoutUtil:createPosNode_(data)
	return display.newNode()
end

function LayoutUtil:dispose(clearTexture)
	if clearTexture == nil then
		clearTexture = false
	end
	
	if self.isLoadSpriteFrame_  and clearTexture then 
		--display.removeUnusedSpriteFrames()
		display.removeSpriteFramesWithFile(self.imagePlist_, self.imageFile_)
	end
	table.foreach(self.animation_, function (i,name) display.removeAnimationCache(name) end)
	self.buttonListener_ = nil
	self.nameToNode = nil
end

return LayoutUtil
