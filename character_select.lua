local card_flip_anim = {}

function load_character_select()
	for i,player in pairs(players) do
		player.character_index = i
	end
end

function update_character_select(dt)
	for i,_ in pairs(card_flip_anim) do
		card_flip_anim[i] = card_flip_anim[i] - dt*2
	end
end

function love.keypressed(key)
	if key == "escape" then
		game_state = "game"
		print("blajj")
	end
	for i,player in pairs(players) do 
		if player.input_keys then 
			for action,k in pairs(player.input_keys) do
				if k == key then 
					if player.active then 
						if action == "left" then 
							player.character_index = player.character_index - 1
						end
						if action == "right" then 
							player.character_index = player.character_index + 1
						end
						if player.character_index < 1 then player.character_index = num_characters end
						if player.character_index > num_characters then player.character_index = 1 end
					else
						card_flip_anim[i] = 1.0
						player.active = true
					end
				end
			end
		end
	end
end

function love.gamepadpressed(gamepad, button)
	for i,player in pairs(players) do 
		if player.input_joystick and player.input_joystick == gamepad then 
			if player.active then 
				if button == "dpleft" then 
					player.character_index = player.character_index - 1
				end
				if button == "dpright" then 
					player.character_index = player.character_index + 1
				end
				if player.character_index < 1 then player.character_index = num_characters end
				if player.character_index > num_characters then player.character_index = 1 end
			else
				card_flip_anim[i] = 1.0
				player.active = true
			end
		end
	end
end

function draw_character_select()
	local rect_w = 400
	local rect_h = 500
	local rect_spacing_x = 80
	local rect_spacing_y = 30
	local rows = 2
	local cols = 3
	local total_w = cols*rect_w + (cols-1)*rect_spacing_x
	local total_h = rows*rect_h + (rows-1)*rect_spacing_y
	local offset_y = 0
	love.graphics.translate((1920-total_w)/2,(1080-total_h)/2-offset_y)
	local i = 1
	for r=1,rows do
		for c=1,cols do
			local player = players[i]
			local col = {0.2,0.2,0.2,1}
			local character = nil
			if player and player.active then
				col = player.color
				character = characters[player.character_index]
			end
			local x = (c-1)*(rect_w+rect_spacing_x)
			local y = (r-1)*(rect_h+rect_spacing_y)

			love.graphics.push()
			if card_flip_anim[i] then
				love.graphics.scale(card_flip_anim[i]*2-1,1)
			end


			love.graphics.setColor(col)
			love.graphics.rectangle("fill",x, y, rect_w, rect_h)
			love.graphics.setFont(main_font)
			local text_col = {col[1]+0.4, col[2]+0.4, col[3]+0.4, 1}
			love.graphics.setColor(text_col)
			love.graphics.print("P"..i,x,y)

			if character then
				love.graphics.setColor(1,1,1,1)
				love.graphics.print(character.name,x,y+rect_h-100)
			end
			love.graphics.pop()

			i = i + 1
		end
	end
end

