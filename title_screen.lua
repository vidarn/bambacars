function load_title()
end

function update_title(dt)
end

function draw_title()
	love.graphics.translate(1920/2,1080/2-100)
	love.graphics.setFont(title_font)
	local w = 1024
	love.graphics.printf("Bambacars!",-w/2,0,w, "center")
end

function keypressed_title(key)
	game_state = "character_select"
end
