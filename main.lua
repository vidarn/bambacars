debug = true

require("game")
require("character_select")

scale = 0.5
joysticks = {}
num_players = 2
players = {}
input_keys = {
	{
		up = "up",
		down = "down",
		left = "left",
		right = "right",
	},
	{
		up = "w",
		left = "a",
		down = "s",
		right = "d",
	}
}
player_colors = {
	{1,0,0,1},
	{0,0.5,1,1},
	{0.5,1,0,1},
}

game_state = "character_select"

function spring(x,target_x,v,k,d,dt)
	local delta = target_x - x
	local F = delta*k
	local new_v = d*v + F*dt
	local new_x = x + new_v*dt
	return new_x, new_v
end


function love.load(arg)
	print("Load!")
	love.window.setMode(scale*1920,scale*1080,{resizable = false,vsync = true})
	num_keyboard_players = num_players
	joysticks = love.joystick.getJoysticks()
	print("Joysticks:")
	for _,joystick in pairs(joysticks) do 
		print(joystick:getName())
		num_players = num_players +1
	end
	for i_player =1,num_players do
		local player = {}
		if i_player <= num_keyboard_players then
			player.input_keys = input_keys[i_player]
		else
			player.input_joystick = joysticks[i_player - num_keyboard_players]
		end
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

function love.draw(dt)
	love.graphics.push()
	love.graphics.scale(scale,scale)
    if game_state == "game" then
        draw_game(dt)
    end
    if game_state == "character_select" then
        draw_character_select(dt)
    end
	love.graphics.pop()
end
