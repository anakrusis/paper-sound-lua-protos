require "camera"
require "stringshit"
require "reads"
require "stats"

function love.load()
	filename = "high res picture.png"
	output_filename = "high res picture.wav"
	
	font = love.graphics.newFont(30)
	love.window.setMode(1024,768)
	
	file = io.open(filename,"rb")
	rawdata = file:read("*all")
	filedata = love.filesystem.newFileData(rawdata,"yeah")
	
	render_data = love.image.newImageData(filedata)
	render_image = love.graphics.newImage(render_data)
	
	-- These are simply default values which can be calibrated in the interface
	-- before rendering to audio.
	
	origin_x = 20 -- what point does song data begin?
	origin_y = 0
	bottom_x = 20 -- and where does it end (x only, y can be inferred from the column height still.)
	-- these new variables are conducive to shearing and perspective crap)
	
	columns = 10 -- how many columns
	column_width = 60 -- how far between columns? (at the top)
	column_w_bottom = 60 -- (at the bottom)
	column_height = render_data:getHeight() -- how tall each column?
	avgdist = 15 -- how far out in each direction (left, right) to average values?
	
	songlength = 4.8 -- in seconds
end

function love.update(dt)
	-- moving the camera
	if love.keyboard.isDown("w") then
		cam_y = cam_y - cam_speed*speedmodifier
	elseif love.keyboard.isDown("s") then
		cam_y = cam_y + cam_speed*speedmodifier
	end
	if love.keyboard.isDown("a") then
		cam_x = cam_x - cam_speed*speedmodifier
	elseif love.keyboard.isDown("d") then
		cam_x = cam_x + cam_speed*speedmodifier
	end
	-- origin adjusment
	if love.keyboard.isDown("up") then
		origin_y = origin_y - 1
	elseif love.keyboard.isDown("down") then
		origin_y = origin_y + 1
	end
	if love.keyboard.isDown("left") then
		origin_x = origin_x - 1
	elseif love.keyboard.isDown("right") then
		origin_x = origin_x + 1
	end
	-- bottom adjustment
	if love.keyboard.isDown("z") then
		bottom_x = bottom_x - 1
	elseif love.keyboard.isDown("c") then
		bottom_x = bottom_x + 1
	end
	
	-- column size adjusment
	if love.keyboard.isDown("kp8") then
		column_height = column_height - 1
	elseif love.keyboard.isDown("kp2") then
		column_height = column_height + 1
	end
	if love.keyboard.isDown("kp4") then
		column_width = column_width - 0.25
	elseif love.keyboard.isDown("kp6") then
		column_width = column_width + 0.25
	end
	if love.keyboard.isDown("kp1") then
		column_w_bottom = column_w_bottom - 0.25
	elseif love.keyboard.isDown("kp3") then
		column_w_bottom = column_w_bottom + 0.25
	end
	
	if love.keyboard.isDown("lshift") then
		speedmodifier = 10
	else
		speedmodifier = 1
	end
end

function love.keypressed(key)
	if key == "q" then
		columns = columns - 1
	elseif key == "e" then
		columns = columns + 1
	end
	
	if key == "u" then -- write to wav
	
		wChannels = 1 -- mono
		dwSamplesPerSec = math.floor((columns*column_height)/songlength) -- samplerate in Hz
		dwBitsPerSample = 8
		wBlockAlign = wChannels * (dwBitsPerSample / 8)
		dwAvgBytesPerSec = dwBitsPerSample * wBlockAlign	
		
		output = "RIFF"
		local filelengthplace = output:len()
		output = output .. string.char(0):rep(4) .. "WAVE" -- header (blank is dwFileLength)
		
		output = output .. "fmt " 
		local chunklengthplace = output:len()
		output = output .. tostr_W(16,4) .. tostr_W(1,2) -- format (blank is dwChunkSize)
		
		output = output .. tostr_W(wChannels,2) .. tostr_W(dwSamplesPerSec,4)
		output = output .. tostr_W(dwAvgBytesPerSec,4) .. tostr_W(wBlockAlign,2)
		output = output .. tostr_W(dwBitsPerSample,2)
		
		rest = output
		
		--local thischunk = output:sub(chunklengthplace-4) -- backs up four to include the chunk title, "fmt "
		--local chunklength = thischunk:len()
		--output = output:sub(1,chunklengthplace) .. tostr_W(chunklength,4) .. string.sub(rest,chunklengthplace+4)
		
		output = output .. "data" .. tostr_W(columns*column_height,4) -- data
		
		width_ratio = (columns*column_width)/(columns*column_w_bottom)
		-- top/bottom ratio
		
		for i=0,columns-1 do
			cur_colm_x = math.floor(i*column_width)+origin_x -- at the top 
			cur_colm_x2 = math.floor(i*column_w_bottom)+bottom_x -- at the bottom

			for j=0,column_height-1 do
				local last = column_height-1
				local pos_ratio = (j/last)
				
				currentx = math.floor(pos_ratio*(cur_colm_x2-cur_colm_x)+cur_colm_x)
				output = output .. horiz_avg_read(currentx,origin_y+j,avgdist)
			end
		end
		
		local filelen = string.len(output)-8
		rest = output
		output = "RIFF" .. tostr_W(filelen,4) .. string.sub(rest,9)
		
		file = io.open(output_filename,"wb")
		file:write(output)
		file:close()
		
	end
end

function love.wheelmoved(x, y)
	if y > 0 then
		cam_zoom = cam_zoom + cam_zoomspeed
	elseif y < 0 then
		cam_zoom = cam_zoom - cam_zoomspeed
	end
end

function love.draw()
	love.graphics.setColor(1,1,1)
	love.graphics.setFont(font)

	love.graphics.draw(render_image,tra_x(0),tra_y(0),0,cam_zoom,cam_zoom)
	
	love.graphics.setColor(1,0,1,0.5)
	for i=0,columns-1 do
		cur_colm_x = (i*column_width)+origin_x
		cur_colm_x2 = (i*column_w_bottom)+bottom_x -- at the bottom
		temp = 1
		--love.graphics.rectangle("fill",tra_x(cur_colm_x-avgdist),tra_y(origin_y),2*avgdist*cam_zoom,column_height*cam_zoom)
		love.graphics.polygon("fill",
		tra_x(cur_colm_x-avgdist),tra_y(origin_y),
		tra_x(cur_colm_x+avgdist),tra_y(origin_y),
		tra_x(cur_colm_x2+avgdist),tra_y(origin_y+column_height),
		tra_x(cur_colm_x2-avgdist),tra_y(origin_y+column_height))
	end
	
	love.graphics.setColor(1,0,1,1)
	love.graphics.setLineWidth(5)
	for i=0,columns-1 do
		cur_colm_x = (i*column_width)+origin_x -- at the top 
		cur_colm_x2 = (i*column_w_bottom)+bottom_x -- at the bottom
		love.graphics.line(tra_x(cur_colm_x),tra_y(origin_y),tra_x(cur_colm_x2),tra_y(origin_y+column_height))
	end
	
	love.graphics.setColor(0,0,1)
	love.graphics.print("Origin: " .. origin_x .. ", " .. origin_y,0,0)
	love.graphics.print("Columns: " .. columns,0,40)
	love.graphics.print("Col width: " .. column_width,0,80)
	love.graphics.print("Col height: " .. column_height,0,120)
	
	love.graphics.print(math.floor(songlength/60) .. ":" .. math.floor(songlength)%60)
	
end