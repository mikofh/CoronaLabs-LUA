local storyboard = require( "storyboard" )
local widget = require( "widget" )
system.activate( "multitouch" )

local scene = storyboard.newScene()
local maxpos, maypos, maxminuspos, mayminuspos = 1000, 1000, -1000, -1000
local background
local previousTouches, numTotalTouches

function calculateDelta( previousTouches, event )
	local id,touch = next( previousTouches )
	if event.id == id then
		id,touch = next( previousTouches, id )
		assert( id ~= event.id )
	end
 
	local dx = touch.x - event.x
	local dy = touch.y - event.y
	return dx, dy
end

function backgroundTouch( event )
	local result = true
 
	local phase = event.phase
 
	previousTouches = background.previousTouches
 
	numTotalTouches = 1
	if ( previousTouches ) then
		-- add in total from previousTouches, subtract one if event is already in the array
		numTotalTouches = numTotalTouches + background.numPreviousTouches
		if previousTouches[event.id] then
			numTotalTouches = numTotalTouches - 1
		end
	end
 
	if "began" == phase then
		-- Very first "began" event
		if ( not background.isFocus ) then
			-- Subsequent touch events will target button even if they are outside the contentBounds of button
			--display.getCurrentStage():setFocus( self )
			background.isFocus = true
			--miko collect values for panning
			background.myX = event.x-background.x
			background.myY = event.y-background.y
			-- Store initial position
			--self.isDragging = true
			--miko end collection
 
			previousTouches = {}
			background.previousTouches = previousTouches
			background.numPreviousTouches = 0
		elseif ( not background.distance ) then
			local dx,dy
 
			if previousTouches and ( numTotalTouches ) >= 2 then
				dx,dy = calculateDelta( previousTouches, event )
			end
 
			-- initialize to distance between two touches
			if ( dx and dy ) then
				local d = math.sqrt( dx*dx + dy*dy )
				if ( d > 0 ) then
					background.distance = d
					background.xScaleOriginal = background.xScale
					background.yScaleOriginal = background.yScale
					print( "distance = " .. background.distance )
				end
			end
		end
 
		if not previousTouches[event.id] then
			background.numPreviousTouches = background.numPreviousTouches + 1
		end
		previousTouches[event.id] = event
 
	elseif background.isFocus then
		if "moved" == phase then
			if ( background.distance ) then
				local dx,dy
				if previousTouches and ( numTotalTouches ) >= 2 then
					dx,dy = calculateDelta( previousTouches, event )
				end
	
				if ( dx and dy ) then
					local newDistance = math.sqrt( dx*dx + dy*dy )
					local scale = newDistance / background.distance
					print( "newDistance(" ..newDistance .. ") / distance(" .. background.distance .. ") = scale("..  scale ..")" )
					if ( scale > 0 ) then
						background.xScale = background.xScaleOriginal * scale
						background.yScale = background.yScaleOriginal * scale
					end
					--miko test ind her om xScale < 1 og så juster ved at gange op.
				end
			else
				background.x = event.x - background.myX
				background.y = event.y - background.myY
				if (background.x > maxpos) then
					background.x = maxpos
				elseif (background.x < maxminuspos) then
					background.x = maxminuspos
				end
				if (background.y > maypos) then
					background.y = maypos
				elseif (background.y < mayminuspos) then
					background.y = mayminuspos
				end
			end
 
			if not previousTouches[event.id] then
				background.numPreviousTouches = background.numPreviousTouches + 1
			end
			previousTouches[event.id] = event
 
		elseif "ended" == phase or "cancelled" == phase then
			
			if previousTouches[event.id] then
				background.numPreviousTouches = background.numPreviousTouches - 1
				previousTouches[event.id] = nil
			end
 
			if ( #previousTouches > 0 ) then
				-- must be at least 2 touches remaining to pinch/zoom
				background.distance = nil
			else
				-- previousTouches is empty so no more fingers are touching the screen
				-- Allow touch events to be sent normally to the objects they "hit"
				display.getCurrentStage():setFocus( nil )
 
				background.isFocus = false
				background.distance = nil
				background.xScaleOriginal = nil
				background.yScaleOriginal = nil
 
				-- reset array
				background.previousTouches = nil
				background.numPreviousTouches = nil
			end
		end
	end
 
	return result
end




-- Called when the scene's view does not exist:
function scene:createScene( event )
    local group = self.view

    background = display.newImage( "img/" .. storyboard.state.map, 0, 0 )
    background.width = display.contentWidth
    background.height = display.contentHeight
	background:setReferencePoint( display.CenterReferencePoint )
	background.x=display.contentWidth/2
	background.y=display.contentHeight/2
	--background.xScale = 1.02 * 0.12
	--background.yScale = 1.02 * 0.12
    group:insert(background)

    local function handleButtonEvent( event )


    	if ( "ended" == event.phase ) then

		storyboard.gotoScene( "picker", "fade", 400 )
    	end
	end

    local myButton = widget.newButton
	{
	    left = 0,
	    top = 0,
	    id = "button1",
		defaultFile = "img/backbtn1.png",
				overFile = "img/backbtn2.png",
	    label = "",
	    onEvent = handleButtonEvent
	}
	group:insert(myButton)
 
end
-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )

	storyboard.purgeScene( "picker" )
	print ( "purged picker" )
	storyboard.state.lastPage = "kort1"

    local group = self.view --self peger på storyboard så koden for self skal laves om til at pege direkte

    

    
    background:addEventListener( "touch", backgroundTouch )



end


-- Called when scene is about to move offscreen:
function scene:exitScene( event )
    local group = self.view

    background:removeEventListener( "touch", backgroundTouch )

    

end


-- Called prior to the removal of scene's "view" (display group)
function scene:destroyScene( event )
    local group = self.view

    

end

---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )


return scene 
