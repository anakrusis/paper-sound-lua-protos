-- All read algorithms will multiply the pixel value, a float between 0 and 1,
-- into an integer between 0 and 255, and then convert the integer to a binary string.

function float2int(float) -- ...And this is how to do it (the first part)!!!
	return math.ceil(float*255)
end

function simple_avg_read(x,y) -- Simply averages the R, G and B values, and returns them.

	if x < renderdata:getWidth() and x >= 0 and y < renderdata:getHeight() and y >= 0 then
		r,g,b = renderdata:getPixel(x,y)
		avg = (r+g+b)/3
		
		avg = float2int(avg)
	else
		avg = 255
	end
	
	return (avg)
end

function horiz_avg_read(x,y,dist)
	-- Averages RGB like before, but also averages horizontally
	-- up to a certain distance left and right.
	vals = {}
	
	for k = 0-dist,dist,1 do
		sum = 0
		if x+k < renderdata:getWidth() and x+k >= 0 and y < renderdata:getHeight() and y >= 0 then
			r,g,b = renderdata:getPixel(x+k,y)
			rgb_avg = (r+g+b)/3 -- average of RGB
			rgb_avg = float2int(rgb_avg)
		else
			rgb_avg = 255
		end
		
		vals[k+dist] = rgb_avg -- add it to the list
		
		--sum = sum + vals[k+dist] -- and add the list value to this big SUM!!!!
	end
	--big_avg = math.floor((sum/#vals)*2*dist) -- then divide it by the list length!!!! AND FLOOR IT TO MAKE IT INTY!!!!
	big_avg = math.floor(stats.mean(vals))

	return (big_avg)
end