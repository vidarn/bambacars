local card_flip_anim = {}

local anime_line_pixelcode = [[
    uniform float t;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
    {
        float f = texture_coords.x+texture_coords.y;
        float a = (step(t-0.1,f) -step(t,f));
        vec4 c = Texel(texture, texture_coords) * color;
        vec4 texcolor = a*vec4(c.a) + (1-a)*c;
        return texcolor;
    }
]]
 
local anime_line_vertexcode = [[
    vec4 position( mat4 transform_projection, vec4 vertex_position )
    {
        return transform_projection * vertex_position;
    }
]] 

function load_character_select()
    anime_line_shader = love.graphics.newShader(anime_line_pixelcode,anime_line_vertexcode)
	for i,player in pairs(players) do
		player.character_index = i
	end
end

anime_line_t =-2
function update_character_select(dt)
	for i,_ in pairs(card_flip_anim) do
		card_flip_anim[i] = card_flip_anim[i] - dt*10
		if card_flip_anim[i] < -1 then card_flip_anim[i] = -1 end
	end
    anime_line_t = anime_line_t +dt
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
                            card_flip_anim[i] = 1.0
						end
						if action == "right" then 
							player.character_index = player.character_index + 1
                            card_flip_anim[i] = 1.0
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
                            card_flip_anim[i] = 1.0
                    card_flip_anim[i] = 1.0
				end
				if button == "dpright" then 
					player.character_index = player.character_index + 1
                    card_flip_anim[i] = 1.0
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
            love.graphics.translate(x+rect_w/2,y)
			if card_flip_anim[i] then
				love.graphics.scale(math.abs(card_flip_anim[i]),1)
			end
            love.graphics.translate(-rect_w/2,0)

            love.graphics.setShader(anime_line_shader)
            anime_line_shader:send("t",anime_line_t)

			love.graphics.setColor(col)
			love.graphics.rectangle("fill",0, 0, rect_w, rect_h)
			love.graphics.setFont(main_font)
			local text_col = {col[1]+0.4, col[2]+0.4, col[3]+0.4, 1}
			love.graphics.setColor(text_col)
			love.graphics.print("P"..i,0,0)

			if character then
				love.graphics.setColor(1,1,1,1)
				love.graphics.print(character.name,0,rect_h-100)
			end
			love.graphics.pop()
            love.graphics.setShader()

			i = i + 1
		end
	end
end

