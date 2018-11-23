function load_title()
end

function update_title(dt)
end

function draw_title()
	love.graphics.setColor(0,0,0,1)
	love.graphics.rectangle('fill',0,0,1920,1080)
	love.graphics.setColor(1,1,1,1)
	love.graphics.translate(1920/2,1080/2-100)
	love.graphics.setFont(title_font)
	local w = 1024
	love.graphics.printf("Bambacars!",-w/2,0,w, "center")
end

function keypressed_title(key)
	switch_to_state("character_select")
end
