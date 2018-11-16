debug = true

require("game")
require("character_select")

scale = 1.0
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
}
characters = {
	{name="Greedo"},
	{name="Takeshi", sprite = love.graphics.newImage("Assets/Characters/Takeshi_Portrait.png")},
	{name="Robot"},
}
num_characters = 3

if true then
	game_state = "character_select"
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
	main_font = love.graphics.newFont("Assets/Fonts/Asap-SemiBold.ttf",30)
	large_font = love.graphics.newFont("Assets/Fonts/Asap-SemiBold.ttf",80)
	love.graphics.setFont(main_font)
	joysticks = love.joystick.getJoysticks()
	print("Joysticks:")
	for _,joystick in pairs(joysticks) do 
		print(joystick:getName())
		num_players = num_players +1
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
	load_game()
	load_character_select()
end

function love.update(dt)
	if game_state == "game" then
		update_game(dt)
	end
	if game_state == "character_select" then
		update_character_select(dt)
	end
end

function love.draw()
	love.graphics.push()
	love.graphics.scale(scale,scale)
	if game_state == "game" then
		draw_game()
	end
	if game_state == "character_select" then
		draw_character_select()
	end
	love.graphics.pop()
end

function love.keypressed(key)
	if game_state == "character_select" then
		keypressed_character_select(key)
	end
end
