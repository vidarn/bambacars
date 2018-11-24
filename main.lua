debug = true

require("title_screen")
require("game")
require("character_select")
require("win_screen")
require("easing")

local transition_pixelcode = [[
uniform float transition_t;
vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
{
	const vec4 one = vec4(1.f,1.f,1.f,1.f);
	float f = texture_coords.x+texture_coords.y;
	float a = step(transition_t,f);
	float a2 = step(transition_t+0.3,f);
	vec4 c = Texel(texture, texture_coords);
	c = mix(one,c,a2);
	vec4 texcolor = a*c;
	return texcolor;
}
]]

local transition_vertexcode = [[
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
	vec4 p = transform_projection * vertex_position;
	return p;
}
]] 

joysticks = {}
num_players = 2
players = {}
active_players = {}
input_keys = {
	{
		up = "up",
		down = "down",
		left = "left",
		right = "right",
		accept = "space",
		drift = "space"
	},
	{
		up = "w",
		left = "a",
		down = "s",
		right = "d",
		accept = "return",
		drift = "lctrl"
	}
}
characters = {
	--{name="Greedo", sprite = love.graphics.newImage("Assets/Characters/Takeshi_Portrait.png")},
	--{name="Takeshi", sprite = love.graphics.newImage("Assets/Characters/Takeshi_Portrait.png")},
	--{name="Robot", sprite = love.graphics.newImage("Assets/Characters/Takeshi_Portrait.png")},
	{name="P1", color= {1,0.5,0,1}, },
	{name="P2", color= {0,0.5,1,1}, },
	{name="P3", color= {0.5,1,0,1}, },
	{name="P4", color= {0.5,0,0.5,1}, },
	{name="P5", color= {0.5,0.5,0.5,1}, },
	{name="P6", color= {1,1,1,1}, },
}
num_characters = 3

if true then
	game_state = "title"
	game_countdown_start = 3
else
	game_state = "character_select"
	game_countdown_start = 0
end

local transition_t = 4

function switch_to_state(state_name)
	prev_state_canvas:renderTo(main_draw)
	game_state = state_name
	transition_t = 0
end


function spring(x,target_x,v,k,d,dt)
	local delta = target_x - x
	local F = delta*k
	local new_v = d*v + F*dt
	local new_x = x + new_v*dt
	return new_x, new_v
end


function love.load(arg)
	prev_state_canvas = love.graphics.newCanvas()
	transition_shader = love.graphics.newShader(transition_pixelcode,transition_vertexcode)
	num_keyboard_players = num_players
	title_font = love.graphics.newFont("Assets/Fonts/Asap-SemiBold.ttf",120)
	main_font = love.graphics.newFont("Assets/Fonts/Asap-SemiBold.ttf",30)
	large_font = love.graphics.newFont("Assets/Fonts/Asap-SemiBold.ttf",80)
	love.graphics.setFont(main_font)
	joysticks = love.joystick.getJoysticks()
	for _,joystick in pairs(joysticks) do 
		--print(joystick:getName():sub(1,1))
		--if joystick:getName():sub(1,1) == "X" then
			num_players = num_players +1
		--end
	end
	for i_player =1,num_players do
		local player = {active=false}
		if i_player <= num_keyboard_players then
			player.input_keys = input_keys[i_player]
		else
			player.input_joystick = joysticks[i_player - num_keyboard_players]
		end
		player.character_index = i_player
		players[i_player] = player
	end
	load_title()
	load_win()
	load_game()
	load_character_select()
end

function love.update(dt)
	if transition_t > 2 then 
		if game_state == "title" then
			update_title(dt)
		end
		if game_state == "game" then
			update_game(dt)
		end
		if game_state == "character_select" then
			update_character_select(dt)
		end
		if game_state == "win" then
			update_win(dt)
		end
	else
		transition_t = transition_t + dt*6
	end
end

function love.draw()
	--love.graphics.setBlendMode("alpha")
	main_draw()
	--love.graphics.setBlendMode("replace")
	if transition_t < 2 then
	love.graphics.setShader(transition_shader)
	transition_shader:send("transition_t",transition_t)
	love.graphics.draw(prev_state_canvas,0,0)
	love.graphics.setShader()
	end
end

function main_draw()
	love.graphics.push()
    local width, height = love.graphics.getDimensions()
    local xscale = width/1920
    local yscale = height/1080
    if yscale < xscale then
        love.graphics.translate((1920*xscale-1920*yscale)/2,0)
        love.graphics.scale(yscale,yscale)
    else
        love.graphics.translate(0,(1080*yscale-1080*xscale)/2)
        love.graphics.scale(xscale,xscale)
    end
	if game_state == "title" then
		draw_title(dt)
	end
	if game_state == "game" then
		draw_game()
	end
	if game_state == "character_select" then
		draw_character_select()
	end
	if game_state == "win" then
		draw_win(dt)
	end
	love.graphics.pop()
end

function love.keypressed(key)
	if game_state == "character_select" then
		keypressed_character_select(key)
	end
	if game_state == "title" then
		keypressed_title(key)
	end
	if game_state == "win" then
		keypressed_win(key)
	end
end

function love.gamepadpressed( gamepad, button )
	if game_state == "character_select" then
		gamepadpressed_character_select(gamepad,button)
	end
	if game_state == "title" then
		gamepadpressed_title(gamepad,button)
	end
	if game_state == "win" then
		gamepadpressed_win(gamepad,button)
	end
end
