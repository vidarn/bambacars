local map = {}
local game = {}

local player_radius = 16

local pickups = {
	{name="pizza", x=200,y=300},
	{name="hot dog", x=800,y=600}
}

function load_game()
    for i,player in pairs(players) do
		player.x = 700 - 100*i
		player.y = 500
		player.vx = 0
		player.vy = 0
		player.angle = math.pi
		player.speed = 0
		player.accel = 0
		player.sprite = {
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0000.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0001.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0002.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0003.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0004.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0005.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0006.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0007.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0008.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0009.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0010.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0011.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0012.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0013.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0014.png"),
			love.graphics.newImage("Assets/Cars/Skyline/Skyline_0015.png"),
		}
	end
	bkg_image = love.graphics.newImage("Assets/City/townmap_01.jpg")
end

function check_circles_collision(c1, c2)
	local r = c1.r + c2.r
	local ox = c1.start_x - c2.start_x
	local oy = c1.start_y - c2.start_y
	local ex = c1.end_x - c2.end_x
	local ey = c1.end_y - c2.end_y
	local dx = ex - ox
	local dy = ey - oy
	local a = dx*dx + dy*dy
	local b = 2*(ox*dx + oy*dy)
	local c = ox*ox + oy*oy - r*r
	local discr2 = b*b - 4*a*c
	if discr2 > 0.0 then
		local discr = math.sqrt(discr2)
		local t1 = (-b-discr)/(2*a)
		local t2 = ( b-discr)/(2*a)
		local hit = false
		if t1 < t2 then
			local tmp = t1
			t1 = t2
			t2 = tmp
		end
		if t1 >= 0 and t1 <= 1 then
			local nx = ox + t1*dx
			local ny = oy + t1*dy
			local m = math.sqrt(nx*nx + ny*ny)
			nx = nx/m
			ny = ny/m
			local dx2 = c1.end_x - c1.start_x
			local dy2 = c1.end_y - c1.start_y
			local d = math.sqrt(dx2*dx2 + dy2*dy2)
			local remaining_dist = (1-t1)*m*0.5
			t1 = t1 - 0.1
			local ret = {}
			ret.x = c1.start_x + t1*dx2
			ret.y = c1.start_y + t1*dy2
			ret.vx = c1.vx + nx*17
			ret.vy = c1.vy + ny*17
			return ret
		end
	end
end

function update_game(dt)
	local pre_collision_players_pos = {}
	for i,player in pairs(players) do
		local last_player
		local target_speed = 0
		local delta_angle = 0
		local max_speed = 300
		if player.input_keys then
			if love.keyboard.isDown(player.input_keys.up) then
				target_speed = max_speed
			end
			if love.keyboard.isDown(player.input_keys.down) then
				target_speed = -50
			end
			if love.keyboard.isDown(player.input_keys.left) then
				delta_angle = -4*dt
			end
			if love.keyboard.isDown(player.input_keys.right) then
				delta_angle =  4*dt
			end
		elseif player.input_joystick then
			target_speed = player.input_joystick:getGamepadAxis("triggerright")*max_speed
			delta_angle =  player.input_joystick:getGamepadAxis("leftx")*4*dt

		end
		player.speed, player.accel =spring(player.speed, target_speed, player.accel, 20.0, 0.85, dt)
		player.angle = player.angle + delta_angle * (player.speed)/max_speed
		local cos_angle = math.cos(player.angle)
		local sin_angle = math.sin(player.angle)

		player.vx = player.vx * math.pow(0.001,dt)
		player.vy = player.vy * math.pow(0.001,dt)
		local vm = math.sqrt(player.vx*player.vx + player.vy*player.vy)
		local speed = player.speed
		if vm > 10 then
			speed = 0
		end
		local dx = cos_angle * speed * dt + player.vx *dt
		local dy = sin_angle * speed * dt + player.vy *dt
		pre_collision_players_pos[i] = {
			x = player.x + dx,
			y = player.y + dy
		}
	end

	local post_collision_players_pos = {}

	for i,player in pairs(players) do
		local pre_pos_player = pre_collision_players_pos[i]
		post_collision_players_pos[i]= {
			x = pre_pos_player.x,
			y = pre_pos_player.y
		}
		-- Player <-> Player collision
		for j,other_player in pairs(players) do
			if j ~= i then
                local pre_pos_other_player = pre_collision_players_pos[j]
                local c1 = {
                    start_x = player.x, end_x = pre_pos_player.x,
                    start_y = player.y, end_y = pre_pos_player.y,
                    vx = player.vx, vy = player.vy, r = player_radius
                }
                local c2 = {
                    start_x = other_player.x, end_x = pre_pos_other_player.x,
                    start_y = other_player.y, end_y = pre_pos_other_player.y,
                    vx = other_player.vx, vy = other_player.vy, r = player_radius
                }
                local ret = check_circles_collision(c1,c2)
                if ret then 
                    if i < j then 
                        local tmp = player.inventory
                        player.inventory = other_player.inventory
                        other_player.inventory = tmp
                    end
                    post_collision_players_pos[i].x = ret.x
                    post_collision_players_pos[i].y = ret.y
                    player.vx = ret.vx
                    player.vy = ret.vy
                end
			end
		end
	end
	for i,player in pairs(players) do
		local post_pos_player = post_collision_players_pos[i]
		local to_delete = {}
		for j,pickup in pairs(pickups) do
			local c1 = {
				start_x = player.x, end_x = post_pos_player.x,
				start_y = player.y, end_y = post_pos_player.y,
				vx = player.vx, vy = player.vy, r = player_radius
			}
			local c2 = {
				start_x = pickup.x, end_x = pickup.x,
				start_y = pickup.y, end_y = pickup.y,
				vx = 0, vy = 0, r = 16
			}
			local ret = check_circles_collision(c1,c2)
			if ret then
                local tmp = player.inventory
				player.inventory = pickup.name
                pickup.name = tmp
                if tmp == nil then
                    table.insert(to_delete,j)
                end
			end

		end
		for _,j in pairs(to_delete) do 
			pickups[j] = nil
		end
	end
	for i,player in pairs(players) do
		player.x = post_collision_players_pos[i].x
		player.y = post_collision_players_pos[i].y
		while player.x < 0 do
			player.x = player.x + 1920
		end
		while player.x > 1920 do
			player.x = player.x - 1920
		end
		while player.y < 0 do
			player.y = player.y + 1080
		end
		while player.y > 1080 do
			player.y = player.y - 1080
		end
	end
end

function draw_game(dt)
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(bkg_image)

	for i_player = 1,num_players do
		local player = players[i_player]
		love.graphics.setColor(player.color)
		local sprite_index = math.mod(-player.angle*16/math.pi/2, 16)
		sprite_index = math.floor(sprite_index+8.5)
		while sprite_index < 0 do
			sprite_index = sprite_index + 16
		end
		while sprite_index > 15 do
			sprite_index = sprite_index - 16
		end
		love.graphics.draw(player.sprite[sprite_index+1],player.x-32,player.y-32)
		if player.inventory then
			love.graphics.print(player.inventory, player.x-8, player.y-16)
		end
	end
	love.graphics.setColor(1,1,1,1)

	for _,pickup in pairs(pickups) do 
		local r = 16
		love.graphics.circle("fill",pickup.x, pickup.y, r)
	end
end
