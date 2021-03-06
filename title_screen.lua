local title_image = nil
function load_title()
	title_image = love.graphics.newImage("Assets/Splash_Screen/Splash_Screen_v01.png")
end

function update_title(dt)
end

function draw_title()
	if false then
		love.graphics.setColor(1,1,1,1)
		love.graphics.draw(title_video)
		love.graphics.translate(1920/2,1080/2-100)
		love.graphics.setFont(title_font)
		local w = 1024
		love.graphics.printf("Bambacars!",-w/2,0,w, "center")
	else
		love.graphics.draw(title_image)
	end
end

function keypressed_title(key)
	switch_to_state("character_select")
end

function gamepadpressed_title(gamepad,button)
	print("gamepad pressed")
	switch_to_state("character_select")
end
