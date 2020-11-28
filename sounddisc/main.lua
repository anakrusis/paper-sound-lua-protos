urutora = require 'urutora'
u = urutora:new()
require "camera"
require "gui"

-- CONSTANTS

STRIP_BREADTH = 3

RENDER_H = 2048
RENDER_W = 2048

CENTER_X = RENDER_W/2
CENTER_Y = RENDER_H/2
-- in pixels
RADIUS_START = 1000
RADIUS_END   = 300
REVOLUTIONS_PER_MINUTE = 190


-- NOT SO CONSTANTS (they get overwritten but these are default values)

SAMPLE_RATE = 48000
SAMPLES_COUNT = SAMPLE_RATE * 60
SAMPLES_PER_TICK = math.floor(SAMPLE_RATE / 60)
BITS_PER_SAMPLE = 8
REVOLUTIONS_PER_SAMPLE = REVOLUTIONS_PER_MINUTE / 60 / SAMPLE_RATE
SAMPLES_PER_REVOLUTION = 1 / REVOLUTIONS_PER_SAMPLE

function love.load()
	love.window.setTitle( "sound-disc 0.1" )
	success = love.window.setMode( 800, 600, {resizable=true} )
	love.keyboard.setKeyRepeat(true)
	
	font = love.graphics.setNewFont("FiraMono-Bold.ttf", 20)
	
	recordLoaded = false
	
	playing = false
	playingSample = 0
	playingRadius = 0
	playingAngle  = 0
	
	initGui()
	
	--newpart = 65534
	--print(((-1 - newpart) % 2^16)+1)
end

function love.mousepressed(x, y, button) u:pressed(x, y) end

function love.mousereleased(x, y, button) u:released(x, y) end

function love.textinput(text) u:textinput(text) end

function love.keypressed(key, scancode, isrepeat)

	u:keypressed(key, scancode, isrepeat)

	if key == "u" then

	end	
	
	if key == "r" then



	end
	
	if key == "space" and recordLoaded then

	end
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
			--playingRadius = playingRadius - (( RADIUS_START - RADIUS_END ) / ( REVOLUTIONS / REVOLUTIONS_PER_SAMPLE ))
			
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
				newpart = 0
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
				newpart = 0
			end
			sample = sample + newpart
		end
	end
	sample = sample / CHANNELS
	
	return sample
end

function loadRecord()
	filename = wav_import.text
	file = io.open(filename,"rb")
	
	if file ~= nil then
		song = file:read("*all")

		renderdata = love.image.newImageData(RENDER_W, RENDER_H)
	
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
		
		--SAMPLES_PER_REVOLUTION = RADIUS_START * 4.5 * math.pi
		
		--REVOLUTIONS_PER_SAMPLE = 1/SAMPLES_PER_REVOLUTION
		--REVOLUTIONS_PER_MINUTE = REVOLUTIONS_PER_SAMPLE * SAMPLE_RATE * 60

		print(REVOLUTIONS_PER_MINUTE .. "RPM")
		REVOLUTIONS_PER_SAMPLE = REVOLUTIONS_PER_MINUTE / 60 / SAMPLE_RATE
		SAMPLES_PER_REVOLUTION = 1 / REVOLUTIONS_PER_SAMPLE
			
		SAMPLES_PER_TICK = math.floor(SAMPLE_RATE / 60)
		
		currentRadius = RADIUS_START
		currentAngle  = 0
		
		-- Determining how many bytes to step the step-amount for each sample!
		
		StepAmt = SAMPLE_DIVISOR * CHANNELS -- the base amount being just the simple divider
		if BITS_PER_SAMPLE == 16 then
			StepAmt = StepAmt * 2
		end
		
		-- 0x2C (+1 because lua) is the beginning of audio data in a typical WAV
		for i = 0x2d, SAMPLES_COUNT * StepAmt, StepAmt do
		
			-- TODO handle more than just 8-bit wav (byte = sample)
			-- 32 bit float would be good, maybe also 16 bit
			
			-- this can all be done here below
			val = getSample(i)
			
			currentX = CENTER_X + (currentRadius * math.cos(currentAngle))
			currentY = CENTER_Y + (currentRadius * math.sin(currentAngle))
			
			currentAngle = currentAngle + (( 2 * math.pi ) / SAMPLES_PER_REVOLUTION)
			currentRadius = currentRadius - (( RADIUS_START - RADIUS_END ) / ( SAMPLES_COUNT ))
			
			--print(currentX .. " " .. currentY)
			if val ~= nil then
				drawLine(currentX, currentY, currentAngle, STRIP_BREADTH, val/255)
			end
		end
		
		-- The sound data is finished drawing! now it is time to put the center stamp on it
		
		centerpiece = love.image.newImageData( "centerpiece.png" )
		centerpiece_img = love.graphics.newImage(centerpiece)
		
		canvas = love.graphics.newCanvas( centerpiece:getWidth(), centerpiece:getHeight() )
		
		love.graphics.setCanvas(canvas)
		love.graphics.draw(centerpiece_img)
		
		-- going above and below the centerpoint respectively
		string1 = filename .. "\n" .. os.date("%b %d %Y") 
		string2 = SAMPLE_RATE .. "hz" .. "\n" .. REVOLUTIONS_PER_MINUTE .. "RPM"
		string1Width = font:getWidth(string1)
		string2Width = font:getWidth(string2)
		
		love.graphics.setFont(font)		
		love.graphics.print(string1, centerpiece:getWidth()/2 - string1Width/2, 96)
		love.graphics.print(string2, centerpiece:getWidth()/2 - string2Width/2, 240)
		
		love.graphics.setCanvas()
		
		canvas_data = canvas:newImageData()
		renderdata:paste(canvas_data, CENTER_X - (canvas_data:getWidth()/2), CENTER_Y - (canvas_data:getHeight()/2))
		
		renderimg = love.graphics.newImage(renderdata)
		recordLoaded = true
		file:close()
	else
		
		print("File not found!")
		
	end
end

function playRecord()

	if recordLoaded then
	
		playing = not playing
		if playing then
		
			play_button.text = "Stop"
		
			print("Now playing...")
			playingSample = 0
			playingRadius = RADIUS_START
			playingAngle  = 0 
			
			soundData = love.sound.newSoundData( SAMPLES_COUNT, SAMPLE_RATE, BITS_PER_SAMPLE, 1 )
		
			for i = 1, SAMPLES_COUNT do 
			
				playheadX = CENTER_X + (playingRadius * math.cos(playingAngle))
				playheadY = CENTER_Y + (playingRadius * math.sin(playingAngle))
			
				r,g,b,a = renderdata:getPixel(playheadX, playheadY)
				playingVal = (r+g+b)/3
				
				if love.math.random() < 0.0001 then
					playingVal = playingVal + (love.math.random() / 2.5)
				end
				
				playingVal = (playingVal * 2) - 1
				
				soundData:setSample(i - 1, playingVal)
			
				playingAngle = playingAngle + (( 2 * math.pi ) / SAMPLES_PER_REVOLUTION)
				playingRadius = playingRadius - (( RADIUS_START - RADIUS_END ) / SAMPLES_COUNT )
				
				playingSample = playingSample + 1
			end
			
			source = love.audio.newSource(soundData, "static")
			love.audio.play( source )
			
			-- these values are reset so the visualiser can hijack them hehe
			playingRadius = RADIUS_START			
			playingAngle  = 0
			playingSample = 0
			
		else
			print("Playback stopped")
			love.audio.stop( source )
			play_button.text = "Play"
		end
	end
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
		
		--renderdata:encode("png",  )
	end
end