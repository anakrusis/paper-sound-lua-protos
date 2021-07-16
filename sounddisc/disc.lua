function loadRecord()
	filename = wav_import.text
	file = io.open(filename,"rb")
	
	if file == nil or (string.sub(filename, -3) ~= "wav") then 
		print("File not found!"); return;
	end
	
	song = file:read("*all")
	
	setImageConstants(2048, 2048)
	renderdata = love.image.newImageData(RENDER_W, RENDER_H)
	
	-- draws a black border around it first for easy printing
	
	bordercanvas = love.graphics.newCanvas( renderdata:getWidth(), renderdata:getHeight() );
	love.graphics.setCanvas(bordercanvas)
	
	love.graphics.setColor(0,0,0)
	love.graphics.setLineWidth( 10 )
	love.graphics.rectangle("line",0,0,bordercanvas:getWidth(), bordercanvas:getHeight());
	love.graphics.setColor(1,1,1)
	
	love.graphics.setCanvas()
	
	bordercanvas_data = bordercanvas:newImageData()
	renderdata:paste(bordercanvas_data, 0, 0)
	
	cam_x = CENTER_X
	cam_y = CENTER_Y

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
				
				if (playheadX >= 0 and playheadY >= 0 and playheadX < RENDER_W and playheadY < RENDER_H ) then
			
					r,g,b,a = renderdata:getPixel(playheadX, playheadY)
					playingVal = (r+g+b)/3
					
					if love.math.random() < 0.0001 then
						playingVal = playingVal + (love.math.random() / 2.5)
					end
					
					playingVal = (playingVal * 2) - 1
					
					soundData:setSample(i - 1, playingVal)
					
				else
				
					soundData:setSample(i - 1, 127)
				
				end
			
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