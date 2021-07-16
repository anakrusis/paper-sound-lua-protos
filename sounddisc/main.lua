urutora = require 'urutora'
u = urutora:new()
require "camera"
require "gui"
require "disc"
require "reads"
require "stats"

-- CONSTANTS

REVOLUTIONS_PER_MINUTE = 190


-- NOT SO CONSTANTS (they get overwritten but these are default values)

SAMPLE_RATE = 48000
SAMPLES_COUNT = SAMPLE_RATE * 60
SAMPLES_PER_TICK = math.floor(SAMPLE_RATE / 60)
BITS_PER_SAMPLE = 8
REVOLUTIONS_PER_SAMPLE = REVOLUTIONS_PER_MINUTE / 60 / SAMPLE_RATE
SAMPLES_PER_REVOLUTION = 1 / REVOLUTIONS_PER_SAMPLE

DISCMODE = false; -- whether to use the disc format (better for sending online) or the sound-strip format (better for printing)

origin_x = 0; origin_y = 0; columns = 50; column_width = 100; column_height = 10000; avgdist = 4;

function love.load()
	love.window.setTitle( "sound-disc 0.2" )
	success = love.window.setMode( 800, 600, {resizable=true} )
	love.keyboard.setKeyRepeat(true)
	
	font = love.graphics.setNewFont("FiraMono-Bold.ttf", 20)
	
	recordLoaded = false
	
	playing = false
	playingSample = 0
	playingRadius = 0
	playingAngle  = 0
	
	setImageConstants(2048, 2048)
	initGui()
end

function love.mousepressed(x, y, button) u:pressed(x, y) end

function love.mousereleased(x, y, button) u:released(x, y) end

function love.textinput(text) u:textinput(text) end

function love.keypressed(key, scancode, isrepeat)

	u:keypressed(key, scancode, isrepeat)

end

function love.update(dt)

	-- Buttons whose positions change when the screen resizes
	play_button.x = -(play_button.w/2) + love.graphics.getWidth() / 2
	samplerate_button.x = love.graphics.getWidth() - 170
	samplerate_label.x  = love.graphics.getWidth() - 170
	
	-- Buttons whose text dynamically updates
	samplerate_button.text = "Sample rate: " .. (SAMPLE_RATE/1000) .. "khz"
	
	u:update(dt)

	if playing then
		
		for i = 1, SAMPLES_PER_TICK do 
			playheadX = CENTER_X + (playingRadius * math.cos(playingAngle))
			playheadY = CENTER_Y + (playingRadius * math.sin(playingAngle))
			
			playingAngle = playingAngle + (( 2 * math.pi ) / SAMPLES_PER_REVOLUTION)
			playingRadius = playingRadius - (( RADIUS_START - RADIUS_END ) / SAMPLES_COUNT )
			
			playingSample = playingSample + 1
			
			if playingSample > SAMPLES_COUNT then
				playing = false
				print("Playback stopped")
				play_button.text = "Play"
				break
			end
		end
		
	end
end

function love.draw()

	if renderimg ~= nil then
	
		love.graphics.draw( renderimg, tra_x(0), tra_y(0), 0, cam_zoom, cam_zoom );
		
	end
	
	if playing then

		love.graphics.circle("fill", tra_x(playheadX), tra_y(playheadY), cam_zoom * 10)
	end
	
	if not DISCMODE then
	
		love.graphics.setColor(1,0,1,0.5)
		for i=0,columns-1 do
			cur_colm_x = (i*column_width)+origin_x

			love.graphics.rectangle("fill",tra_x(cur_colm_x-avgdist),tra_y(origin_y),2*avgdist*cam_zoom,column_height*cam_zoom)
		end
		
		love.graphics.setColor(1,0,1,1)
		love.graphics.setLineWidth(5)
		for i=0,columns-1 do
			cur_colm_x = (i*column_width)+origin_x -- at the top 

			love.graphics.line(tra_x(cur_colm_x),tra_y(origin_y),tra_x(cur_colm_x),tra_y(origin_y+column_height))
		end
	
	end
	
	u:draw()
end

function drawLine(x, y, angle, breadth, val)
	for i = 0-(breadth / 2), breadth/2 do
		
		renderX =  x + (math.cos(angle) * i)
		renderY =  y + (math.sin(angle) * i)
		
		renderdata:setPixel(renderX,renderY, val, val, val)
	end
	
end

function getSample(i)
	sample = 0
	for q = 0, CHANNELS-1 do
		if BITS_PER_SAMPLE == 8 then
			if string.byte(string.sub(song,q+i,q+i)) ~= nil then
				newpart = string.byte(string.sub(song,q+i,q+i))
			else
				newpart = 127
			end
			sample = sample + newpart
					
		elseif BITS_PER_SAMPLE == 16 then
			if string.byte(string.sub(song,(q*2)+i,(q*2)+i)) ~= nil and string.byte(string.sub(song,(q*2)+i+1,(q*2)+i+1)) ~= nil then
			
				newpartLow  = string.byte(string.sub(song,(q*2)+i+0,(q*2)+i+0))
				newpartHigh = string.byte(string.sub(song,(q*2)+i+1,(q*2)+i+1))
				
				newpart = (newpartLow) + (256 * newpartHigh)
				--print(newpart)
				
				if newpart > 32767 then
					newpart = 0-(((-1 - newpart) % 2^16)+1)
				end
				
				newpart = (newpart / 0x100 ) + 128
			else
				newpart = 127
			end
			sample = sample + newpart
		end
	end
	sample = sample / CHANNELS
	
	return sample
end

function loadStrips()

	filename = wav_import.text
	file = io.open(filename,"rb")
	
	if file == nil or (string.sub(filename, -3) ~= "wav") then 
		print("File not found!"); return;
	end
	
	song = file:read("*all")
	
	SAMPLE_RATE = string.byte(string.sub(song,0x19,0x19)) + (0x100 * string.byte(string.sub(song,0x1a,0x1a)))
	print("Original Sample Rate: " .. SAMPLE_RATE)
	BITS_PER_SAMPLE = string.byte(string.sub(song,0x23,0x23))
	print(BITS_PER_SAMPLE .. "-bit")
	
	SAMPLE_DIVISOR = 1 -- for reducing sample rate
	SAMPLE_RATE = SAMPLE_RATE / SAMPLE_DIVISOR
	print("Sample Rate / " .. SAMPLE_DIVISOR .. " = " .. SAMPLE_RATE)
	
	LENGTH_IN_SECONDS = 60
	SAMPLES_COUNT = ( SAMPLE_RATE ) * LENGTH_IN_SECONDS
	
	CHANNELS = string.byte(string.sub(song,23,23)) + (0x100 * string.byte(string.sub(song,24,24)))
	if (CHANNELS == 1) then print("Mono") elseif (CHANNELS == 2) then print ("Stereo") end

	strip_width = 50
	margin_width = 10
	
	column_width = strip_width + margin_width
	i = 1
	while (column_width*i)/(#song/i) <= 0.77 do
		i = i+1
	end
	columns = i
	render_h = (#song/columns)
	render_w = (column_width*columns)
	
	renderdata = love.image.newImageData(render_w,render_h)
	for i=0,columns-1 do
		for j=0,render_h-1 do
			for k=0,strip_width-1 do
				--val = string.byte(string.sub(song,(i*render_h)+j+1,(i*render_h)+j+1))
				val = getSample( (i*render_h)+j+1 );
				renderdata:setPixel(i*(column_width)+k,j,val/255,val/255,val/255)
			end
		end
	end
	renderimg = love.graphics.newImage(renderdata)
	recordLoaded = true
	file:close()
end

function playStrips()

	-- wChannels = 1 -- mono
	-- dwSamplesPerSec = math.floor((columns*column_height)/songlength) -- samplerate in Hz
	-- dwBitsPerSample = 8
	-- wBlockAlign = wChannels * (dwBitsPerSample / 8)
	-- dwAvgBytesPerSec = dwBitsPerSample * wBlockAlign	
	
	-- output = "RIFF"
	-- local filelengthplace = output:len()
	-- output = output .. string.char(0):rep(4) .. "WAVE" -- header (blank is dwFileLength)
	
	-- output = output .. "fmt " 
	-- local chunklengthplace = output:len()
	-- output = output .. tostr_W(16,4) .. tostr_W(1,2) -- format (blank is dwChunkSize)
	
	-- output = output .. tostr_W(wChannels,2) .. tostr_W(dwSamplesPerSec,4)
	-- output = output .. tostr_W(dwAvgBytesPerSec,4) .. tostr_W(wBlockAlign,2)
	-- output = output .. tostr_W(dwBitsPerSample,2)
	
	-- rest = output
	
	-- --local thischunk = output:sub(chunklengthplace-4) -- backs up four to include the chunk title, "fmt "
	-- --local chunklength = thischunk:len()
	-- --output = output:sub(1,chunklengthplace) .. tostr_W(chunklength,4) .. string.sub(rest,chunklengthplace+4)
	
	-- output = output .. "data" .. tostr_W(columns*column_height,4) -- data
	
	-- width_ratio = (columns*column_width)/(columns*column_w_bottom)
	-- top/bottom ratio
	
	print("Now playing...")
	playingSample = 0
	playingRadius = RADIUS_START
	playingAngle  = 0 
	
	soundData = love.sound.newSoundData( SAMPLES_COUNT, SAMPLE_RATE, BITS_PER_SAMPLE, 1 )
	
	origin_x = 0; origin_y = 0;
	
	for i=0,columns-1 do
		cur_colm_x = math.floor(i*column_width)+origin_x -- at the top 
		
		for j=0,column_height-1 do
		
			playingVal = horiz_avg_read(cur_colm_x,origin_y+j,avgdist) / 255;
			
			playingVal = (playingVal * 2) - 1
			
			soundData:setSample(i * columns + j, playingVal)
			
			playingSample = playingSample + 1
		
		end
		
	end
	
	source = love.audio.newSource(soundData, "static")
	love.audio.play( source )
	
	-- these values are reset so the visualiser can hijack them hehe
	playingRadius = RADIUS_START			
	playingAngle  = 0
	playingSample = 0
	
		-- cur_colm_x2 = math.floor(i*column_w_bottom)+bottom_x -- at the bottom

		-- for j=0,column_height-1 do
			-- -- local last = column_height-1
			-- -- local pos_ratio = (j/last)
			
			-- -- currentx = math.floor(pos_ratio*(cur_colm_x2-cur_colm_x)+cur_colm_x)
			-- -- --output = output .. 
		-- end
	-- end
	
	-- local filelen = string.len(output)-8
	-- rest = output
	-- output = "RIFF" .. tostr_W(filelen,4) .. string.sub(rest,9)
	
	-- file = io.open(output_filename,"wb")
	-- file:write(output)
	-- file:close()

end

function loadImage()

	filename = img_import.text
	file = io.open(filename,"rb")
	--
	if file ~= nil and (string.sub(filename, -3) == "png" or string.sub(filename, -3) == "jpg" or string.sub(filename, -3) == "bmp" or string.sub(filename, -3) == "gif") then
	
		imgdata = file:read("*all")
		
		filedata = love.filesystem.newFileData( imgdata, filename )
		renderdata = love.image.newImageData( filedata )
		renderimg = love.graphics.newImage(renderdata)
		
		setImageConstants(renderdata:getWidth(), renderdata:getHeight())
		cam_x = CENTER_X
		cam_y = CENTER_Y
		
		recordLoaded = true
		file:close()
	end
	
end

function saveImage()
	if renderdata ~= nil then
		filenameout = string.sub(filename, 0, #filename-4) .. ".png"
		
		dataOut = renderdata:encode("png")
		str_out = dataOut:getString()
		
		file = io.open (filenameout, "wb")
		file:write(str_out)
		file:close()
	end
end

function setImageConstants( width, height )
	
	RENDER_H = height	
	RENDER_W = width

	CENTER_X = RENDER_W/2
	CENTER_Y = RENDER_H/2
	-- in pixels
	RADIUS_START = ( 1000 ) * ( RENDER_H / 2048 )
	RADIUS_END   = ( 300  ) * ( RENDER_H / 2048 )
	STRIP_BREADTH = ( 3 ) *   ( RENDER_H / 2048 )
	
end 