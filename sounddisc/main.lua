urutora = require 'urutora'
u = urutora:new()
require "camera"

function love.load()
	love.window.setTitle( "sound-disc" )
	success = love.window.setMode( 800, 600, {resizable=true} )
	
	recordLoaded = false
	
	playing = false
	playingSample = 0
	playingRadius = 0
	playingAngle  = 0
	
	wav_label = urutora.label({ text = "(.wav path below)", x = 150, y = 20, w = 150, h = 50})
	u:add(wav_label)
	
	wav_import = urutora.text({ text = "", x = 20, y = 75, w = 300, h = 30 })
	u:add(wav_import)
	
	import_button = urutora.button({ text = "Import .wav", x = 10, y = 20, w = 125, h = 50 })
	import_button:action(function(e)
	
		loadRecord()
		
	end)
	u:add(import_button)
	
	play_button = urutora.button({ text = "Play", x = love.graphics.getWidth() / 2, y = 20, w = 50, h = 50 })
	play_button:action(function(e)
	
		playRecord()
		
	end)
	u:add(play_button)
	
end

function love.mousepressed(x, y, button) u:pressed(x, y) end

function love.mousereleased(x, y, button) u:released(x, y) end

function love.textinput(text) u:textinput(text) end

function love.keypressed(key, scancode, isrepeat)

	u:keypressed(key, scancode, isrepeat)

	if key == "u" then
		if renderdata ~= nil then
			renderdata:encode("png","test.png")
		end
	end	
	
	if key == "r" then



	end
	
	if key == "space" and recordLoaded then

	end
end

function love.update(dt)

	play_button.x = -(play_button.w/2) + love.graphics.getWidth() / 2
	
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
	
	u:draw()
end

function drawLine(x, y, angle, breadth, val)
	for i = 0-(breadth / 2), breadth/2 do
		
		renderX =  x + (math.cos(angle) * i)
		renderY =  y + (math.sin(angle) * i)
		
		renderdata:setPixel(renderX,renderY, val, val, val)
	end
	
end

function loadRecord()
	filename = wav_import.text
	file = io.open(filename,"rb")
	
	if file ~= nil then
		song = file:read("*all")

		STRIP_BREADTH = 3
	
		RENDER_H = 2048
		RENDER_W = 2048
		
		CENTER_X = RENDER_W/2
		CENTER_Y = RENDER_H/2
		renderdata = love.image.newImageData(RENDER_W, RENDER_H)
		
		-- in pixels
		RADIUS_START = 1000
		RADIUS_END   = 300
	
		SAMPLE_RATE = string.byte(string.sub(song,0x19,0x19)) + (0x100 * string.byte(string.sub(song,0x1a,0x1a)))
		print("Original Sample Rate: " .. SAMPLE_RATE)
		BITS_PER_SAMPLE = string.byte(string.sub(song,0x23,0x23))
		print(BITS_PER_SAMPLE .. "-bit")
		
		SAMPLE_DIVISOR = 1 -- for reducing sample rate
		SAMPLE_RATE = SAMPLE_RATE / SAMPLE_DIVISOR
		print("Sample Rate / " .. SAMPLE_DIVISOR .. " = " .. SAMPLE_RATE)
		
		LENGTH_IN_SECONDS = 60
		SAMPLES_COUNT = ( SAMPLE_RATE ) * LENGTH_IN_SECONDS 
		
		SAMPLES_PER_REVOLUTION = RADIUS_START * 4.5 * math.pi
		
		REVOLUTIONS_PER_SAMPLE = 1/SAMPLES_PER_REVOLUTION
		REVOLUTIONS_PER_MINUTE = REVOLUTIONS_PER_SAMPLE * SAMPLE_RATE * 60
		print(REVOLUTIONS_PER_MINUTE .. "RPM")
			
		SAMPLES_PER_TICK = math.floor(SAMPLE_RATE / 60)
		
		currentRadius = RADIUS_START
		currentAngle  = 0
		-- 0x2C (+1 because lua) is the beginning of audio data in a typical WAV
		for i = 0x2d, SAMPLES_COUNT * SAMPLE_DIVISOR, SAMPLE_DIVISOR do
			val = string.byte(string.sub(song,i,i))
			--print(val)
			
			currentX = CENTER_X + (currentRadius * math.cos(currentAngle))
			currentY = CENTER_Y + (currentRadius * math.sin(currentAngle))
			
			currentAngle = currentAngle + (( 2 * math.pi ) / SAMPLES_PER_REVOLUTION)
			currentRadius = currentRadius - (( RADIUS_START - RADIUS_END ) / SAMPLES_COUNT )
			
			--print(currentX .. " " .. currentY)
			if val ~= nil then
				drawLine(currentX, currentY, currentAngle, STRIP_BREADTH, val/255)
			end
		end
		
		renderimg = love.graphics.newImage(renderdata)
		recordLoaded = true
	
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