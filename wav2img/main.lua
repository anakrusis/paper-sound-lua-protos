require "camera"

function love.load()
	filename = "oldy.wav"

	file = io.open(filename,"rb")
	song = file:read("*all")
end

function love.update(dt)
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
	
	if love.keyboard.isDown("lshift") then
		speedmodifier = 10
	else
		speedmodifier = 1
	end
end

function love.keypressed(key)
	if key == "r" then
		--file = io.open(filename,"wb")
		--file:write(song)
		--file:close()
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
		
		render = love.image.newImageData(render_w,render_h)
		for i=0,columns-1 do
			for j=0,render_h-1 do
				for k=0,strip_width-1 do
					val = string.byte(string.sub(song,(i*render_h)+j+1,(i*render_h)+j+1))
					render:setPixel(i*(column_width)+k,j,val/255,val/255,val/255)
				end
			end
		end
		render_image = love.graphics.newImage(render)
	elseif key == "u" then
		render:encode("png","test.png")
		-- todo render:getString, write to png in native directory
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
	love.graphics.print(filename)
	love.graphics.print(string.len(song),0,20)
	love.graphics.print("Press R to render, and U to write")
	--love.graphics.print(string.sub(song,1,4)) -- should say "RIFF", works!
	if render_image ~= nil then
		love.graphics.draw(render_image,tra_x(0),tra_y(0),0,cam_zoom,cam_zoom)
	end
	--for i=1,#song do
		--val = string.byte(string.sub(song,i,i))
		--love.graphics.setColor(val/255,val/255,val/255)
		--love.graphics.rectangle("fill",tra_x(0),tra_y(i),100*cam_zoom,1*cam_zoom)
	--end
end