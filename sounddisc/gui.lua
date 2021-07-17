-- All the GUI elements are added here! (they were taking up an awful lot of space in main.lua before)

function initGui()

	discmode_toggle = urutora.toggle({ text = "Disc/Strip", DISCMODE, 0, 0, 200, 30 })
	discmode_toggle:action(function(e)
		DISCMODE = not DISCMODE
	end)
	u:add(discmode_toggle)
	
	
	samplerate_label = urutora.label({ text = "(If it sounds broken or skippy\nthen try other sample rate)", x = 175, y = 50, w = 100, h = 50})
	u:add(samplerate_label)
	
	wav_label = urutora.label({ text = "(.wav in directory with\nprogram, path below)", x = 175, y = 10, w = 100, h = 50})
	u:add(wav_label)
	
	png_label = urutora.label({ text = "(image in directory with\nprogram, path below)", x = 175, y = 170, w = 100, h = 50})
	u:add(png_label)
	
	wav_import = urutora.text({ text = "", x = 20, y = 75, w = 300, h = 30 })
	u:add(wav_import)
	
	import_button = urutora.button({ text = "Import .wav", x = 10, y = 20, w = 125, h = 50 })
	import_button:action(function(e)
		
		if DISCMODE then
			loadRecord();
		else
			loadStrips()
		end
		
	end)
	u:add(import_button)
	
	import_button = urutora.button({ text = "Export .png", x = 10, y = 110, w = 125, h = 50 })
	import_button:action(function(e)
		
		saveImage()
		
	end)
	u:add(import_button)
	
	play_button = urutora.button({ text = "Play", x = love.graphics.getWidth() / 2, y = 20, w = 50, h = 50 })
	play_button:action(function(e)
		
		if DISCMODE then
			playRecord()
		else
			playStrips()
		end
		
	end)
	u:add(play_button)
	
	importimg_button = urutora.button({ text = "Import image", x = 10, y = 175, w = 125, h = 50 })
	importimg_button:action(function(e)
	
		loadImage()
		
	end)
	u:add(importimg_button)
	
	img_import = urutora.text({ text = "", x = 20, y = 225, w = 300, h = 30 })
	u:add(img_import)
	
	samplerate_button = urutora.button({ text = "Sample rate: 48khz", x = 500, y = 20, w = 160, h = 35 })
	samplerate_button:action(function(e)
	
		if not playing then -- changing sample rate mid play wont work anyways. dont try it
			if SAMPLE_RATE == 48000 then
				SAMPLE_RATE = 44100
			else
				SAMPLE_RATE = 48000
			end
			
			SAMPLES_COUNT = SAMPLE_RATE * 60
			SAMPLES_PER_TICK = math.floor(SAMPLE_RATE / 60)
			REVOLUTIONS_PER_SAMPLE = REVOLUTIONS_PER_MINUTE / 60 / SAMPLE_RATE
			SAMPLES_PER_REVOLUTION = 1 / REVOLUTIONS_PER_SAMPLE
		end
		
	end)
	u:add(samplerate_button)

end