local card_flip_anim = {}
local card_done_anim = {}

local card_pixelcode = [[
uniform float line_t;
vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
	float f = texture_coords.x+texture_coords.y;
	float a = (step(line_t-0.3,f) -step(line_t,f));
	vec4 c = Texel(texture, texture_coords) * color;
	vec4 texcolor = a*vec4(c.a) + (1-a)*c;
	return texcolor;
}
]]

local card_vertexcode = [[
//uniform float flip_t;
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
	vec4 p = transform_projection * vertex_position;
	return p;
}
]] 

function load_character_select()
	done_sound = love.audio.newSource("Assets/Sound/car_start.wav", "static");
	menu_sound = love.audio.newSource("Assets/Sound/menu.wav", "static");
	card_shader = love.graphics.newShader(card_pixelcode,card_vertexcode)
	for i,player in pairs(players) do
		player.done = false
	end
end

function update_character_select(dt)
	for i,_ in pairs(card_flip_anim) do
		card_flip_anim[i] = card_flip_anim[i] - dt*10
		if card_flip_anim[i] < -1 then card_flip_anim[i] = -1 end
	end
	for i,_ in pairs(card_done_anim) do
		card_done_anim[i] = card_done_anim[i] - dt
		if card_done_anim[i] < -1 then card_done_anim[i] = -1 end
	end
	local all_done = true
	local num_players = 0
	for i,player in pairs(players) do
		if player.active then
			if not player.done then
				all_done = false
			end
			num_players = num_players + 1
		end
	end
	for i,a in pairs(card_done_anim) do
		if a > 0 then 
			all_done = false
		end
	end
	if all_done and num_players >1 then
		switch_to_state("game")
		reset_game()
        for i,player in pairs(players) do
            player.done = false
        end
	end
end

function keypressed_character_select(key)
	for i,player in pairs(players) do 
		if player.input_keys then 
			for action,k in pairs(player.input_keys) do
				if k == key then 
					if player.active then 
						if not player.done then 
							if action == "left" then 
								--player.character_index = player.character_index - 1
								--card_flip_anim[player.index] = 1.0
							end
							if action == "right" then 
								--player.character_index = player.character_index + 1
								--card_flip_anim[player.index] = 1.0
							end
							if action == "accept" then 
								player.done = true
								card_done_anim[player.index] = 1.0
								love.audio.play(done_sound)
							end
							if player.character_index < 1 then player.character_index = num_characters end
							if player.character_index > num_characters then player.character_index = 1 end
						end
					else
						player.active = true
						table.insert(active_players,player)
						player.index = #active_players
						card_flip_anim[player.index] = 1.0
						love.audio.play(menu_sound)
					end
				end
			end
		end
	end
end

function gamepadpressed_character_select(gamepad, button)
	for i,player in pairs(players) do 
		if player.input_joystick and player.input_joystick == gamepad then 
			if not player.done then 
				if player.active then 
					if button == "dpleft" then 
						--player.character_index = player.character_index - 1
						--card_flip_anim[player.index] = 1.0
					end
					if button == "dpright" then 
						--player.character_index = player.character_index + 1
						--card_flip_anim[player.index] = 1.0
					end
					if button == "a" then 
						player.done = true
						card_done_anim[player.index] = 1.0
						love.audio.play(done_sound)
					end
					if player.character_index < 1 then player.character_index = num_characters end
					if player.character_index > num_characters then player.character_index = 1 end
				else
					player.active = true
					table.insert(active_players,player)
					player.index = #active_players
					card_flip_anim[player.index] = 1.0
					love.audio.play(menu_sound)
				end
			end
		end
	end
end

function draw_character_select()
	love.graphics.setColor(0,0,0,1)
	love.graphics.rectangle('fill',0,0,1920,1080)
	love.graphics.setColor(1,1,1,1)
	local rect_w = 512
	local rect_h = 512
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
			local player = active_players[i]
			local col = {0.2,0.2,0.2,1}
			local character = nil
			if player and player.active then
				character = characters[player.character_index]
			end
			local x = (c-1)*(rect_w+rect_spacing_x)
			local y = (r-1)*(rect_h+rect_spacing_y)

			love.graphics.push()
			love.graphics.translate(x+rect_w/2,y)
			local flip_t = 1
			if card_flip_anim[i] then
				flip_t = card_flip_anim[i]
			end

			love.graphics.setShader(card_shader)

			local line_t = 1
			if card_done_anim[i] then 
				line_t = 1-card_done_anim[i]
			else
			end

			love.graphics.scale(math.abs(flip_t),1)
			card_shader:send("line_t",line_t)

			love.graphics.translate(-rect_w/2,0)

			love.graphics.setColor(1,1,1,1)
			if character then
                if character.sprite then
                    card_shader:send("line_t",line_t*10)
                    love.graphics.draw(character.sprite)
                else
                    col = character.color
                    love.graphics.setColor(col)
                    love.graphics.rectangle("fill",0, 0, rect_w, rect_h)
                end
            else
                love.graphics.setColor(col)
                love.graphics.rectangle("fill",0, 0, rect_w, rect_h)
            end

			love.graphics.setFont(main_font)
			local text_col = {col[1]+0.6, col[2]+0.6, col[3]+0.6, 1}
			love.graphics.setColor(text_col)
			love.graphics.print("P"..i,0,0)

            if player then
                if player.done then
                    love.graphics.setFont(large_font)
                    love.graphics.print("Ready!",150,100)
                end
            else
                love.graphics.setFont(main_font)
                love.graphics.print("Press button",150,100)
                love.graphics.print("to join",200,130)
            end

			love.graphics.pop()
			love.graphics.setShader()

			i = i + 1
		end
	end
end

