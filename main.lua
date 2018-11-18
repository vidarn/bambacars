debug = true

require("title_screen")
require("game")
require("character_select")
require("win_screen")

joysticks = {}
num_players = 2
players = {}
input_keys = {
	{
		up = "up",
		down = "down",
		left = "left",
		right = "right",
		accept = "return"
	},
	{
		up = "w",
		left = "a",
		down = "s",
		right = "d",
		accept = "space"
	}
}
player_colors = {
	{1,0.5,0,1},
	{0,0.5,1,1},
	{0.5,1,0,1},
	{0.5,0,0.5,1},
	{1,1,1,1},
}
characters = {
	{name="Greedo"},
	{name="Takeshi", sprite = love.graphics.newImage("Assets/Characters/Takeshi_Portrait.png")},
	{name="Robot"},
}
num_characters = 3

if true then
	game_state = "title"
	game_countdown = 3
else
	game_state = "game"
	game_countdown = 0
end


function spring(x,target_x,v,k,d,dt)
	local delta = target_x - x
	local F = delta*k
	local new_v = d*v + F*dt
	local new_x = x + new_v*dt
	return new_x, new_v
end


function love.load(arg)
	print("Load!")
	num_keyboard_players = num_players
	title_font = love.graphics.newFont("Assets/Fonts/Asap-SemiBold.ttf",120)
	main_font = love.graphics.newFont("Assets/Fonts/Asap-SemiBold.ttf",30)
	large_font = love.graphics.newFont("Assets/Fonts/Asap-SemiBold.ttf",80)
	love.graphics.setFont(main_font)
	joysticks = love.joystick.getJoysticks()
	print("Joysticks:")
	for _,joystick in pairs(joysticks) do 
		print(joystick:getName():sub(1,1))
		if joystick:getName():sub(1,1) == "X" then
			num_players = num_players +1
		end
	end
	for i_player =1,num_players do
		local player = {active=false}
		if i_player <= num_keyboard_players then
			player.input_keys = input_keys[i_player]
		else
			player.input_joystick = joysticks[i_player - num_keyboard_players]
		end
		player.character_index = i_player
		player.color = player_colors[i_player]
		players[i_player] = player
	end
	load_title()
	load_win()
	load_game()
	load_character_select()
end

function love.update(dt)
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
end

function love.draw()
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
