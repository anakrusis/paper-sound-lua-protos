-- This is a generic camera library which can be used for any game;
-- I just started doing this now (it tooked me long enough)

love.graphics.setDefaultFilter("nearest","nearest",0)
width,height = love.graphics.getDimensions() -- screen

cam_x = 0 -- wheres ya camera at
cam_y = 0
cam_zoom = 1
cam_speed = 2
cam_zoomspeed = 0.1

originx = width/2 -- middle of tha screen
originy = height/2

function tra_x(x) -- translate x based on camera values
	return ((x-cam_x)*cam_zoom)+originx
end
function tra_y(y) -- translate y based on camera values
	return ((y-cam_y)*cam_zoom)+originy
end

function untra_x(x) -- these two convert screen pos back to ingame pos (for cursor clicking and stuff)
	return ((x-originx)/cam_zoom)+cam_x
end
function untra_y(y)
	return ((y-originy)/cam_zoom)+cam_y
end

function tra_points(points,x,y) -- translates a set of points based on camera values
	local outputpoints = {}
	if x ~= nil and y ~= nil then -- and optionally the position of an object
		for j=1,#points,2 do
			outputpoints[#outputpoints+1] = tra_x(points[j]+x)
			outputpoints[#outputpoints+1] = tra_y(points[j+1]+y)
		end
	else
		for j=1,#points,2 do
			outputpoints[#outputpoints+1] = tra_x(points[j])
			outputpoints[#outputpoints+1] = tra_y(points[j+1])
		end
	end
	return outputpoints	
end

function rot_points(angle,points) -- rotates a set of points by an angle(rendering units)
	local outputpoints = {}
	for j=1,#points,2 do
		outputpoints[#outputpoints+1] = points[j]*math.cos(angle) - points[j+1]*math.sin(angle) -- appends an X val
		outputpoints[#outputpoints+1] = points[j]*math.sin(angle) + points[j+1]*math.cos(angle) -- and a Y val
	end
	return outputpoints
end