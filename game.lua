
local player_radius = 16
local food_spawn_cooldown = 0

local pickups = { } 
local hungry_people = { }
local hungry_people_spawn_queue = { }
local hungry_people_locations = { }

local food_spawn_points = { }
local num_active_food = 0

function reset_game()
	game_countdown = game_countdown_start
	food_spawn_cooldown = 0
	pickups = {}
	hungry_people = { }
	hungry_people_spawn_queue = { }
	hungry_people_locations = {
		{x= 600, y =200},
		{x= 1200, y =800},
		{x= 400, y =200},
		{x= 1500, y =300},
	}
	food_spawn_points = {
		{name="pizza",x=100,y=200},
		{name="hot dog",x=700,y=900},
		{name="ice cream",x=500,y=700},
	}
	for i,player in pairs(players) do
		player.x = 700 - 100*i
		player.y = 500
		player.vx = 0
		player.vy = 0
		player.angle = math.pi
		player.speed = 0
		player.accel = 0
		player.swap_cooldown = 0
		player.score = 0
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
end

function load_game()
	reset_game()
	bkg_image = love.graphics.newImage("Assets/City/townmap_04.jpg")
	local obst_data = love.filesystem.read("string", "Assets/City/townmap_04_sdf.sdf")
	local w, h, pos = love.data.unpack("=ii",obst_data)
	print(string.format("w: %f, h: %f, pos: %d",w,h,pos))
	obstacle_sdf = {}
	for i=1,w*h do 
		obstacle_sdf[i],pos = love.data.unpack("f",obst_data,pos)
	end
	obstacle_sdf.w = w
	obstacle_sdf.h = h
end


function spawn_food()
	local available_food = {}
	for _,fs in pairs(food_spawn_points) do 
		local n = fs.name
		local ok = true
		for _,p in pairs(pickups) do 
			if p.name == n then
				ok = false
			end
		end
		if ok then
			table.insert(available_food,fs)
		end
	end
	local num_food_spawn_points = #available_food
	if num_food_spawn_points == 0 then
		return
	end
	local r = math.random(num_food_spawn_points)
	for i = 1,9999 do
		if pickups[i] == nil then
			pickups[i] = {}
			for k,v in pairs(available_food[r]) do
				pickups[i][k] = v
			end
			local food_name= pickups[i].name
			local r2 = math.random(#hungry_people_locations)
			local hungry_people_location = hungry_people_locations[r2]
			table.remove(hungry_people_locations,r2)
			local hungry_person = {x=hungry_people_location.x, y=hungry_people_location.y, wants = food_name}
			hungry_person.spawn_cooldown = 0.7
			table.insert(hungry_people_spawn_queue, hungry_person)
			pickups[i].bounce_timer = 0
			num_active_food = num_active_food+1
			break
		end
	end
end

function sdf_get_value(sdf,x,y)
	local w = sdf.w
	local h = sdf.h
	local ix = math.floor(w*x)
	local iy = math.floor(h*y)
	local tx = w*x-ix
	local ty = h*y-iy
	if ix >= w then 
		ix = w-1
		tx = 1
	end
	if ix < 1 then 
		ix = 1
		tx = 0
	end
	if iy >= h then 
		iy = h-1
		ty = 1
	end
	if iy < 1 then 
		iy = 1
		ty = 0
	end
	local v00 = sdf[(ix+0)+(iy-1)*w]
	local v01 = sdf[(ix+0)+(iy+0)*w]
	local v10 = sdf[(ix+1)+(iy-1)*w]
	local v11 = sdf[(ix+1)+(iy+0)*w]
	local x0 = v00*(1-tx) + v10*tx
	local x1 = v01*(1-tx) + v11*tx
	return -(x0*(1-ty) + x1*ty)
end

function sdf_get_gradient(sdf,x,y)
    local delta = 0.001
    local dx = (sdf_get_value(sdf,x+delta,y) - sdf_get_value(sdf,x-delta,y))/delta
    local dy = (sdf_get_value(sdf,x,y+delta) - sdf_get_value(sdf,x,y-delta))/delta
    return dx,dy
end

function sdf_trace(x,y,dx,dy,max_d,sdf,sign)
    local num_steps = 100
    local dd = max_d/num_steps
    local d = dd
    for i=1,num_steps do
        local sdf_dist = sdf_get_value(sdf,x+dx*d,y+dy*d)
        if sdf_dist*sign < 0 then
            --TODO(Vidar):We can be more precise...
            return d - dd/2,true
        end
        d = d + dd
    end
    return d,false
end

function collide_sdf(x1, x2, y1, y2,sdf)
    x1 = x1/1920
    x2 = x2/1920
    y1 = y1/980
    y2 = y2/980
    local dx = x2 - x1
    local dy = y2 - y1
    local d = math.sqrt(dx*dx + dy*dy)
    local sdf_dist = sdf_get_value(sdf,x1,y1)

    if sdf_dist >= 0 then
        local nx = 0
        local ny = 0
        t,hit = sdf_trace(x1,y1,dx,dy,1,sdf,1)
        x1 = x1+dx*t
        y1 = y1+dy*t
        nx,ny = sdf_get_gradient(sdf,x1,y1)
        local n = math.sqrt(nx*nx + ny*ny)
        if n == 0 then
            nx = 1
            ny = 0
            n = 1
        end
        nx = nx/n
        ny = ny/n
        if hit then
            tx = -ny
            ty = nx
            local dot_t = dx/d*tx + dy/d*ty
            if math.abs(dot_t) > 0.2 then
                print("glance")
                hit = false
                x1 = x1 + nx*1/1920
                y1 = y1 + ny*1/980
            end
            x1 = x1 + tx*(d*(1-t))*dot_t 
            y1 = y1 + ty*(d*(1-t))*dot_t
        end
        return x1*1920,y1*980,hit,-nx,-ny
    else
        print("inside")
        local gx,gy = sdf_get_gradient(sdf,x1,y1)
        local n = math.sqrt(gx*gx + gy*gy)
        if n == 0 then
            gx = 1
            gy = 0
            n = 1
        end
        gx = gx/n
        gy = gy/n
        d, hit = sdf_trace(x1,y1,gx,gy,30/1920,sdf,-1)
        return (x1 + gx*d)*1920, (y1 + gy*d)*980,hit,gx,gy
    end
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

function player_steer(player, target_angle, target_speed_fraction,dt)
        local max_speed = 400
        local max_delta_angle = 0.2
        target_speed = max_speed*target_speed_fraction
        if target_speed > player.speed then
            player.speed, player.accel =spring(player.speed, target_speed, player.accel, 60.0, 0.0, dt)
        else
            player.speed, player.accel =spring(player.speed, target_speed, player.accel, 100.0, 0.75, dt)
        end
        if target_speed > 0 then
            delta_angle = target_angle - player.angle
            while delta_angle > math.pi do
                delta_angle = delta_angle - math.pi*2
            end
            while delta_angle <-math.pi do
                delta_angle = delta_angle + math.pi*2
            end
            delta_angle = delta_angle * (player.speed)/max_speed  
            delta_angle = math.max(math.min(delta_angle,max_delta_angle),-max_delta_angle)
            player.angle = player.angle + delta_angle * 40* dt
        end
        return player
end

function update_game(dt)
	if game_countdown < 0 then 
		local pre_collision_players_pos = {}
		for i,player in pairs(players) do
			local target_speed = 0
			local target_angle = 0
            local dx = 0
            local dy = 0
			if player.input_keys then
                local target_angles = {}
				if love.keyboard.isDown(player.input_keys.up) then
                    dy = -1
				end
				if love.keyboard.isDown(player.input_keys.down) then
                    dy = 1
				end
				if love.keyboard.isDown(player.input_keys.left) then
                    dx = -1
				end
				if love.keyboard.isDown(player.input_keys.right) then
                    dx = 1
				end
			elseif player.input_joystick then
                dx = player.input_joystick:getGamepadAxis("leftx")
                dy = player.input_joystick:getGamepadAxis("lefty")
			end
            if dx ~= 0 or dy ~= 0 then
                target_angle = math.atan2(dy,dx)
                target_speed = 1
            end

            player = player_steer(player,target_angle, target_speed,dt)

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
							if player.swap_cooldown < 0 and other_player.swap_cooldown < 0 then
								local tmp = player.inventory
								player.inventory = other_player.inventory
								other_player.inventory = tmp
								player.swap_cooldown = 0.5
								other_player.swap_cooldown = 0.5
							end
						end
						post_collision_players_pos[i].x = ret.x
						post_collision_players_pos[i].y = ret.y
						player.vx = ret.vx
						player.vy = ret.vy
						player.speed = 0
						player.accel = 0
					end
				end
			end
            post_collision_players_pos[i].x, post_collision_players_pos[i].y,
                hit, nx, ny = 
                collide_sdf(player.x, post_collision_players_pos[i].x, player.y, post_collision_players_pos[i].y,obstacle_sdf)
            if hit then
                print("HIT!")
                player.vx = nx*100
                player.vy = ny*100
                player.speed = 0
                player.accel = 0
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
				if ret and player.swap_cooldown < 0 then
					local tmp = player.inventory
					player.inventory = pickup.name
					player.swap_cooldown = 0.5
					if tmp == nil then
						table.insert(to_delete,j)
					else
						pickup.name = tmp
					end
				end

			end
			for _,j in pairs(to_delete) do 
				pickups[j] = nil
			end
			to_delete = {}
			for j,person in pairs(hungry_people) do
				local c1 = {
					start_x = player.x, end_x = post_pos_player.x,
					start_y = player.y, end_y = post_pos_player.y,
					vx = player.vx, vy = player.vy, r = player_radius
				}
				local c2 = {
					start_x = person.x, end_x = person.x,
					start_y = person.y, end_y = person.y,
					vx = 0, vy = 0, r = 16
				}
				local ret = check_circles_collision(c1,c2)
				if ret and player.inventory == person.wants then
					player.score = player.score + 1
					player.inventory = nil
					num_active_food = num_active_food-1
					table.insert(to_delete,j)
				end

			end
			for _,j in pairs(to_delete) do 
				table.insert(hungry_people_locations,hungry_people[j])
				hungry_people[j] = nil
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
			player.swap_cooldown = player.swap_cooldown - dt
			if player.score >= 3 then
				winning_player = player
				print("Player "..i.." wins!")
				game_state = "win"
				reset_game()
			end
		end
		for i,pickup in pairs(pickups) do 
			pickup.bounce_timer = pickup.bounce_timer + dt
		end
		for i = #hungry_people_spawn_queue,1,-1 do
			local person = hungry_people_spawn_queue[i]
			person.spawn_cooldown = person.spawn_cooldown - dt
			if person.spawn_cooldown < 0 then
				for j=1,999 do
					if hungry_people[j] == nil then
						hungry_people[j] = person
						break
					end
				end
				table.remove(hungry_people_spawn_queue,i)
			end
		end
		if food_spawn_cooldown < 0 then
			if num_active_food < 3 then
				spawn_food()
			end
			food_spawn_cooldown = math.random()*4+0.3
		end
		food_spawn_cooldown = food_spawn_cooldown - dt
	end
	game_countdown = game_countdown - dt
end

function draw_game(dt)
    love.graphics.push()
	love.graphics.translate(0,100)
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(bkg_image)


	if false then
		local rect_w = 1920/obstacle_sdf.w
		local rect_h = 980/obstacle_sdf.h
		for y=1,obstacle_sdf.h do
			for x=1,obstacle_sdf.w do
				local v = obstacle_sdf[x+(y-1)*obstacle_sdf.w]
				--v = (v)/2
                if v < 0 then
                    love.graphics.setColor(v,v,v,1)
                    love.graphics.rectangle("fill",(x-1)*rect_w,(y-1)*rect_h,rect_w,rect_h)
                end
			end
		end
	end

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
			love.graphics.setFont(main_font)
			love.graphics.print(player.inventory, player.x-8, player.y-16)
		end
        if false then
            local sdf_val = sdf_get_value(obstacle_sdf,player.x/1920,player.y/1080)
            love.graphics.setFont(main_font)
            love.graphics.circle("fill",player.x,player.y,3)
            love.graphics.print(sdf_val,player.x-8,player.y-16)
            local sdf_dx, sdf_dy = sdf_get_gradient(obstacle_sdf,player.x,player.y)
            print(string.format("dx: %f, dy:%f", sdf_dx, sdf_dy))
            love.graphics.line(player.x,player.y,player.x+sdf_dx*100000,player.y+sdf_dy*100000)
        end
	end
	love.graphics.setColor(1,1,1,1)

	for _,pickup in pairs(pickups) do 
		if pickup then
			local r = 16
			local bounce = math.abs(math.sin(pickup.bounce_timer*6))
			love.graphics.setFont(main_font)
			love.graphics.print(pickup.name,pickup.x-20,pickup.y-40)
			love.graphics.circle("fill",pickup.x, pickup.y-bounce*10, r)
		end
	end
	for _,person in pairs(hungry_people) do 
		love.graphics.setFont(main_font)
		love.graphics.print("I want\n"..person.wants,person.x-20,person.y-40)
		love.graphics.circle("fill",person.x,person.y,2)
	end
    love.graphics.pop()

    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle('fill',0,0, 1920,100)

	for i_player = 1,num_players do
		local player = players[i_player]
		local character = characters[player.character_index]
		love.graphics.setColor(1,1,1,1)
		love.graphics.push()
		love.graphics.translate((i_player-1)*200,0)
		if character and character.sprite then
			love.graphics.push()
			love.graphics.scale(100/512)
			love.graphics.draw(character.sprite)
			love.graphics.pop()
		else
			love.graphics.rectangle("line",0,0,512*0.2,512*0.2)
		end
		love.graphics.translate(512*0.2,0)
		for i = 1,player.score do 
			r = 10
			love.graphics.circle("fill",2*r,r+(i-1)*(3*r),r)
		end
		love.graphics.pop()
	end

	love.graphics.push()
	love.graphics.translate(1920/2,1080/2)
	love.graphics.setFont(title_font)
	if game_countdown > 0 then
		love.graphics.printf(math.ceil(game_countdown), -200, -100, 400, "center")
	elseif game_countdown > -1 then
		love.graphics.printf("GO!", -200, -100, 400, "center")
	end
	love.graphics.pop()

end
