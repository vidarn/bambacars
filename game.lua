
local player_radius = 16
local food_spawn_cooldown = 0

local pickups = { } 
local hungry_people = { }
local hungry_people_spawn_queue = { }
local hungry_people_locations = { }

local food_spawn_points = { }
local num_active_food = 0
local splash_numbers = {
}

local tank_controls = true

local car_names = {
	"Bus",
	"Bigfoot",
	"Pickup",
	"Supra",
}

function load_car_sprite(name)
	sprites = {}
	for i=0,31 do
		sprites[i+1] = love.graphics.newImage(string.format("Assets/Cars/%s/%s_%04d.png",name,name,i))
	end
	return sprites
end

local obstacle_types = {
	{name="Cone", weight = 0.02},
	{name="Gnome", weight = 0.7},
	{name="Box", weight = 1.6},
}
local obstacles = {}

function load_obstacle_sprites()
	local direction_steps = 8
	local angle_steps = 8
	for _,ot in pairs(obstacle_types) do 
		ot.sprites = {}
		for i = 1,direction_steps*angle_steps do
			ot.sprites[i] = love.graphics.newImage(string.format("Assets/Obstacles/%s/%s_%04d.png",ot.name,ot.name,i-1))
		end
		ot.sprite_w, ot.sprite_h = ot.sprites[1]:getDimensions()
	end
end

function add_obstacle(x,y)
	local obst_type = obstacle_types[math.random(#obstacle_types)]
	local obst = {
		x = math.random()*1920, y= math.random()*980, z = 0,
		direction = math.random()*2*math.pi, angle = 0,
	}
	for k,v in pairs(obst_type) do
		obst[k] = v
	end
	obst.last_x = obst.x
	obst.last_y = obst.y
	obst.last_z = obst.z
	obst.last_angle = obst.angle
	obst.last_direction = obst.direction
	table.insert(obstacles, obst)
end

function update_obstacles(dt, post_collision_players_pos)
	for _,obst in pairs(obstacles) do
		local last_x = obst.last_x
		local last_y = obst.last_y
		local last_z = obst.last_z
		local last_angle = obst.last_angle
		local last_direction = obst.last_direction

		obst.last_x = obst.x
		obst.last_y = obst.y
		obst.last_z = obst.z
		obst.last_angle = obst.angle
		obst.last_direction = obst.direction

		local gravity = 5

		local vz = math.min((obst.z - last_z),3)
		obst.z = obst.z + (vz - gravity*dt)
		local friction = 0
		if obst.z < 0 then
			obst.z = -obst.z
			friction = 0.1
			obst.last_z = - obst.last_z*0.3
		end
		local vx = math.min((obst.x - last_x),3)
		local vy = math.min((obst.y - last_y),3)
		obst.x = obst.x + vx*(1-friction)
		obst.y = obst.y + vy*(1-friction)
		obst.angle = obst.angle + (obst.angle - last_angle)*(1-friction)

		local new_x, new_y, friction, nx, ny = collide_sdf(obst.x, obst.x, obst.y, obst.y, 10, obstacle_sdf)
		if friction > 0.7 then
			obst.x = new_x
			obst.y = new_y
		end

		if obst.z < 20 then
			for i,player in pairs(active_players) do
				local post_pos_player = post_collision_players_pos[i]
				local c1 = {
					start_x = player.x, end_x = post_pos_player.x,
					start_y = player.y, end_y = post_pos_player.y,
					vx = player.vx, vy = player.vy, r = player_radius
				}
				local c2 = {
					start_x = obst.x, end_x = obst.x,
					start_y = obst.y, end_y = obst.y,
					vx = 0, vy = 0, r = 20
				}
				local ret = check_circles_collision(c1,c2)
				if ret then
					print("Cone hit")
					local vx = ret.dx
					local vy = ret.dy
					local v = math.sqrt(vx*vx + vy*vy)
					obst.x = obst.x + ret.dx * (1-ret.t)
					obst.y = obst.y + ret.dy * (1-ret.t)
					obst.z = obst.z + 0.5*v*v*dt/obst.weight
					obst.angle = obst.angle + 0.01*v*v*dt/obst.weight
					obst.direction = math.atan2(vx,vy)
				end
			end
		end

		local has_warped = false
		while obst.x < 0 do
			obst.x = obst.x + 1920
			has_warped = true
		end
		while obst.x > 1920 do
			obst.x = obst.x - 1920
			has_warped = true
		end
		while obst.y - obst.z < 0 do
			obst.y = obst.y + 980
			has_warped = true
		end
		while obst.y - obst.z > 980 do
			obst.y = obst.y - 980
			has_warped = true
		end

	end
end

function render_obstacles()
	for _,obst in pairs(obstacles) do
		--print("---")
		local direction_steps = 8
		local angle_steps = 8
		local angle_i = math.mod(math.floor(obst.angle/math.pi*angle_steps), angle_steps*2)
		while angle_i < 0 do
			angle_i = angle_i + angle_steps*2
		end
		local direction_offset = 0
		--print(angle_i)
		if angle_i >= angle_steps then
			angle_i = 2*angle_steps - angle_i - 1
			direction_offset = direction_steps/2
		end
		local direction_i = math.mod(math.floor(obst.direction/math.pi/2*direction_steps)+direction_offset, direction_steps)
		while direction_i < 0 do
			direction_i = direction_i + direction_steps
		end
		local i = direction_i*angle_steps+angle_i + 1
		--print(angle_i)
		--print(direction_i)
		--print(i)
		love.graphics.draw(obst.sprites[i],obst.x-obst.sprite_w/2, obst.y-obst.z-obst.sprite_h/2)
	end
end

local snow_flakes = {}
local snow_flake_sprite = love.graphics.newImage("Assets/Effects/snowflake.png")

function spawn_snow()
	--table.insert(snow_flakes, {x = math.random()*1920, y=math.random()*1200, z = 300, vx = math.random()*2-1})
end

function update_snow(dt)
	local speed = 40
	for _,flake in pairs(snow_flakes) do 
		if flake.z > 0 then
			flake.z = flake.z - dt*0.3*speed
			flake.x = flake.x + flake.vx*dt*speed
			flake.vx = flake.vx*0.9 + 0.1*(math.random()*2-1)
		end
	end
end

function render_snow(fallen)
	love.graphics.setColor(1,1,1,1)
	--local points = {}
	for _,flake in pairs(snow_flakes) do 
		if (fallen and flake.z <= 0) or (not fallen and flake.z > 0) then
			love.graphics.draw(snow_flake_sprite, flake.x, flake.y-flake.z)
		end
		--table.insert(points, {flake.x, flake.y-flake.z})
	end
	--love.graphics.points(points)
end

function reset_game()
	game_countdown = game_countdown_start
	food_spawn_cooldown = 0
	pickups = {}
	hungry_people = { }
	hungry_people_spawn_queue = { }
	hungry_people_locations = {
		{x= 1000, y =418},
		{x= 1200, y =400},
		{x= 873, y =407},
		{x= 170, y =636},
		{x= 1373, y =389},
	}
	food_spawn_points = {
		{name="Hamburger",x=345,y=880},
		{name="Pizza",x=1802,y=670},
		{name="HotDog",x=484,y=427},
		{name="IceCream",x=982,y=900},
		{name="Shrimp",x=1644,y=264},
	}
	local start_positions = {
		{x=344,y=484},
		{x=1100,y=222},
		{x=1674,y=122},
		{x=344,y=752},
		{x=1100,y=626},
		{x=1706,y=708},
	}
	num_active_food =0
	for i,fsp in pairs(food_spawn_points) do 
		local sprite_file = "Assets/Food/"..fsp.name..".png"
		fsp.sprite = love.graphics.newImage(sprite_file)
		local sound_file = "Assets/Sound/"..fsp.name..".wav"
		fsp.sound = love.audio.newSource(sound_file,"static")
	end
	for i,player in pairs(active_players) do
		j = math.random(#car_names)
		player.x = start_positions[j].x + math.random()*200
		player.y = start_positions[j].y + math.random()*200
		player.vx = 0
		player.vy = 0
		player.steering_angle = 3*math.pi/2
		player.movement_angle = 3*math.pi/2
		player.speed = 0
		player.accel = 0
		player.swap_cooldown = 0
		player.boost_cooldown = 0
		player.score = {}
		player.inventory = nil
		i = math.random(#car_names)
		local_car_name = car_names[math.random(#car_names)]
		if i <= #car_names then
			car_name =car_names[i]
		end
		player.sprite = load_car_sprite(car_name)
		player.skidmarks_verts = {{}, {}, {}, {}}
		player.skidmarks_mesh_id = nil
		if not player.active then
			player.ai_state = {
				drift_cooldown = math.random()*3
			}
		end

	end
	skidmarks_meshes = {}
	snow_flakes = {}
	for i=1,200 do
		spawn_snow()
	end
	obstacles = {}
	for i=1,32 do
		add_obstacle()
	end
end

function load_game()
	load_obstacle_sprites()
	reset_game()
	pickup_sound =love.audio.newSource("Assets/Sound/pickup.wav", "static")
	eat_sound =love.audio.newSource("Assets/Sound/bite.wav", "static")
	phone_sound =love.audio.newSource("Assets/Sound/phone.wav", "static")
	bkg_image = love.graphics.newImage("Assets/City/townmap_06.png")
	--bkg_video = love.graphics.newVideo("Assets/VideoTest/test.ogg")
	speech_bubble = love.graphics.newImage("Assets/Speech_Bubble/Speech_Bubble_v01.png")
	local obst_data = love.filesystem.read("string", "Assets/City/townmap_05_sdf.sdf")
	local w, h, pos = love.data.unpack("=ii",obst_data)
	obstacle_sdf = {}
	for i=1,w*h do 
		obstacle_sdf[i],pos = love.data.unpack("f",obst_data,pos)
	end
	obstacle_sdf.w = w
	obstacle_sdf.h = h
	splash_numbers = {
		love.graphics.newImage("Assets/Splash_Screen/Go_v01.png"),
		love.graphics.newImage("Assets/Splash_Screen/One_v01.png"),
		love.graphics.newImage("Assets/Splash_Screen/Two_v01.png"),
		love.graphics.newImage("Assets/Splash_Screen/Three_v01.png"),
	}
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
			local hungry_person = {x=hungry_people_location.x, y=hungry_people_location.y, wants = food_name, sprite = pickups[i].sprite}
			pickups[i].sound:play()
			hungry_person.spawn_cooldown = 1.7
			table.insert(hungry_people_spawn_queue, hungry_person)
			pickups[i].bounce_timer = 0
			num_active_food = num_active_food+1
			break
		end
	end
end

function player_sdf_get_value(players,x,y)
	local dist = 99999
	for _,player in pairs(players) do
		local dx = x - player.x
		local dy = y - player.y
		local d = math.sqrt(dx*dx + dy*dy)
		if d < dist then
			dist = d
		end
	end
	return dist
end
function player_sdf_get_gradient(players,x,y)
	local delta = 0.5
	local dx = (player_sdf_get_value(players,x+delta,y) - player_sdf_get_value(players,x-delta,y))/delta
	local dy = (player_sdf_get_value(players,x,y+delta) - player_sdf_get_value(players,x,y-delta))/delta
	return dx,dy
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

function sdf_trace(x,y,dx,dy,r,max_d,sdf,sign)
	local num_steps = 100
	local dd = max_d/num_steps
	local d = dd
	for i=1,num_steps do
		local sdf_dist = sdf_get_value(sdf,x+dx*d,y+dy*d) -r
		if sdf_dist*sign < 0 then
			--TODO(Vidar):We can be more precise...
			return d - dd/2,true
		end
		d = d + dd
	end
	return d,false
end

function collide_sdf(x1, x2, y1, y2, r,sdf)
	r = r/1920
	x1 = x1/1920
	x2 = x2/1920
	y1 = y1/980
	y2 = y2/980
	local dx = x2 - x1
	local dy = y2 - y1
	local d = math.sqrt(dx*dx + dy*dy)
	local sdf_dist = sdf_get_value(sdf,x1,y1) - r

	if sdf_dist >= 0 then
		local nx = 0
		local ny = 0
		t,hit = sdf_trace(x1,y1,dx,dy,r,1,sdf,1)
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
		local friction = 0
		if hit then
			tx = -ny
			ty = nx
			local dot_t = dx/d*tx + dy/d*ty
			if math.abs(dot_t) > 0.2 then
				hit = false
				--x1 = x1 + nx*1/1920
				--y1 = y1 + ny*1/980
			end
			friction = 1 - math.abs(dot_t)
			dx = tx*(d*(1-t))*dot_t 
			dy = ty*(d*(1-t))*dot_t
			t,hit = sdf_trace(x1,y1,dx,dy,r,1,sdf,1)
			x1 = x1+dx*t
			y1 = y1+dy*t
		end
		return x1*1920,y1*980,friction,-nx,-ny
	else
		local gx,gy = sdf_get_gradient(sdf,x1,y1)
		local n = math.sqrt(gx*gx + gy*gy)
		if n == 0 then
			gx = 1
			gy = 0
			n = 1
		end
		gx = gx/n
		gy = gy/n
		d, hit = sdf_trace(x1,y1,gx,gy,r,30/1920,sdf,-1)
		local friction = 0
		if hit then friction = 1 end
		return (x1 + gx*d)*1920, (y1 + gy*d)*980,friction,gx,gy
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
			ret.dx = dx2
			ret.dy = dy2
			ret.t = t1
			return ret
		end
	end
end

function player_steer(player, target_angle, target_speed_fraction, drift, boost, dt)
	local boost_speed = 700
	local max_speed = 350
	local max_delta_angle = 0.15
	if drift then
		max_delta_angle = 0.2
	end
	delta_angle = target_angle - player.steering_angle
	while delta_angle > math.pi do
		delta_angle = delta_angle - math.pi*2
	end
	while delta_angle <-math.pi do
		delta_angle = delta_angle + math.pi*2
	end
	--delta_angle = delta_angle * (player.speed)/max_speed  
	delta_angle = math.max(math.min(delta_angle,max_delta_angle),-max_delta_angle)
	if drift then
		player.steering_angle = player.steering_angle + delta_angle * 50* dt
		--player.speed, player.accel =spring(player.speed, 0, player.accel, 30.0, 0.0, dt)
		-- TODO(Vidar):These are frame rate dependent...
		local t = 0.95
		player.movement_angle = t*player.movement_angle + (1-t)*player.steering_angle
	else
		target_speed = max_speed*target_speed_fraction
		if target_speed > player.speed then
			player.speed, player.accel = spring(player.speed, target_speed, player.accel, 60.0, 0.0, dt)
		else
			player.speed, player.accel = spring(player.speed, target_speed, player.accel, 40.0, 0.75, dt)
		end
		if math.abs(target_speed) > 0 then
			player.steering_angle = player.steering_angle + delta_angle * 40* dt
			local t = 0.8
			player.movement_angle = t*player.movement_angle + (1-t)*player.steering_angle
		end
	end
	if boost then
		player.speed = boost_speed
	end
	return player
end

function update_game(dt)
	if math.random() < 0.2 then spawn_snow() end
	update_snow(dt)
	if game_countdown < 0 then 
		local food_positions = {}
		for i,player in pairs(active_players) do
			if player.inventory then
				table.insert(food_positions, {x=player.x, y=player.y})
			end
		end
		for i,pickup in pairs(pickups) do
			table.insert(food_positions, {x=pickup.x, y=pickup.y})
		end
		local pre_collision_players_pos = {}
		for i,player in pairs(active_players) do
			local target_speed = 0
			local target_angle = 0
			local dx = 0
			local dy = 0
			local drift = false
			local boost = false
			if player.active and player.input_keys then
				if tank_controls then
					local angle = player.steering_angle
					if love.keyboard.isDown(player.input_keys.up) then
						target_speed = 1
					end
					if love.keyboard.isDown(player.input_keys.left) then
						angle = angle - 5*dt
					end
					if love.keyboard.isDown(player.input_keys.right) then
						angle = angle + 5*dt
					end
					dx = math.cos(angle)
					dy = math.sin(angle)
				else
					if love.keyboard.isDown(player.input_keys.up) then
						dy = -1
						target_speed = 1
					end
					if love.keyboard.isDown(player.input_keys.down) then
						dy = 1
						target_speed = 1
					end
					if love.keyboard.isDown(player.input_keys.left) then
						dx = -1
						target_speed = 1
					end
					if love.keyboard.isDown(player.input_keys.right) then
						dx = 1
						target_speed = 1
					end
				end
				if love.keyboard.isDown(player.input_keys.drift) then
					drift = true
				end
			elseif player.active and player.input_joystick then
				local gpx = player.input_joystick:getGamepadAxis("leftx")
				if math.abs(gpx) < 0.2 then
					gpx = 0
				end
				local gpy = player.input_joystick:getGamepadAxis("lefty")
				if math.abs(gpy) < 0.2 then
					gpy = 0
				end
				if tank_controls then
					local angle = player.steering_angle
					angle = angle + 6*dt*gpx
					dx = math.cos(angle)
					dy = math.sin(angle)
				else
					dx = gpx
					dy = gpy
				end
				drift = player.input_joystick:isGamepadDown("a")
				boost = player.input_joystick:isGamepadDown("b")
				target_speed = player.input_joystick:getGamepadAxis("triggerright")
				reverse_speed = player.input_joystick:getGamepadAxis("triggerleft")
				if reverse_speed > 0.3 then
					target_speed = -reverse_speed*0.3
				end
			else
				--NOTE(Vidar):"AI"
				target_speed = 1
				local prev_dx = math.cos(player.steering_angle)
				local prev_dy = math.sin(player.steering_angle)
				local random_dx = 2*math.random()-1
				local random_dy = 2*math.random()-1
				local target_dx = 0
				local target_dy = 0
				if food_positions[1] then
					target_dx = food_positions[1].x - player.x
					target_dy = food_positions[1].y - player.y
				end
				if player.inventory and hungry_people[1] then
					target_dx = hungry_people[1].x - player.x
					target_dy = hungry_people[1].y - player.y
				end
				local n = target_dx*target_dx + target_dy*target_dy
				if n > 0.1 then
					target_dx = target_dx/n
					target_dy = target_dy/n
				end
				local other_players = {}
				for j,p in pairs(active_players) do 
					if i ~= j and not p.inventory then
						table.insert(other_players, p)
					end
				end
				player_sdf_dx, player_sdf_dy = player_sdf_get_gradient(other_players,player.x,player.y)
				player_sdf = player_sdf_get_value(other_players,player.x,player.y)
				sdf_dx, sdf_dy = sdf_get_gradient(obstacle_sdf,player.x/1920,player.y/980)
				sdf = sdf_get_value(obstacle_sdf,player.x/1920,player.y/980)

				local avoidance = 50
				if player.inventory then 
					avoidance = 100
				end

				dx = prev_dx + 0.1*random_dx + 0.07*sdf_dx/sdf + 500*target_dx + avoidance*player_sdf_dx/player_sdf
				dy = prev_dy + 0.1*random_dy + 0.07*sdf_dy/sdf + 500*target_dy + avoidance*player_sdf_dy/player_sdf

				local ai_state = player.ai_state
				ai_state.drift_cooldown = ai_state.drift_cooldown - dt
				if ai_state.drift_cooldown < 0 then
					ai_state.drift_cooldown = math.random()*3
					ai_state.drifting = not ai_state.drifting
				end
				drift = ai_state.drifting and player.speed > 0.2
				if math.random() < 0.004 and not drift then 
					boost = true
				end
			end
			if math.abs(dx) > 0.1 or math.abs(dy) > 0.1 then
				target_angle = math.atan2(dy,dx)
			else
				target_angle = player.movement_angle
			end
			if boost and player.boost_cooldown > 0 then
				boost =false
			end
			if boost then
				player.boost_cooldown = 2
				if player.input_joystick then
					player.input_joystick:setVibration(1.0,0.2,0.2)
				end
			end

			local do_skidmarks = drift

			player = player_steer(player,target_angle, target_speed, drift, boost, dt)
			if drift and player.input_joystick and player.active then
				player.input_joystick:setVibration(0.0,0.8,2*dt)
			end

			local movement_angle = player.movement_angle
			local sprite_index = math.mod(-movement_angle*32/math.pi/2, 32)
			sprite_index = math.floor(sprite_index+16)
			while sprite_index < 0 do
				sprite_index = sprite_index + 32
			end
			while sprite_index > 31 do
				sprite_index = sprite_index - 32
			end
			movement_angle = -(sprite_index-15)/32*math.pi*2

			local cos_angle = math.cos(movement_angle)
			local sin_angle = math.sin(movement_angle)

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
			if do_skidmarks then 
				local wheel_positions = {{10,10},{-10,10},{10,-10},{-10,-10}}
				for i,wheel_pos in pairs(wheel_positions) do
					local w = 8
					local x = player.x - math.sin(player.steering_angle)*wheel_pos[1] + math.cos(player.steering_angle)*wheel_pos[2]
					local y = player.y + math.cos(player.steering_angle)*wheel_pos[1] + math.sin(player.steering_angle)*wheel_pos[2]
					local dx = -math.sin(movement_angle)
					local dy = math.cos(movement_angle)
					local a = math.random()*0.5 + 0.5
					if #player.skidmarks_verts[i] < 32  then
						a = a*#player.skidmarks_verts[i]/32
					end
					local vert1 = {x + dx*w*0.5, y + dy*w*0.5, 0, 0.5, a, a, a, a}
					table.insert(player.skidmarks_verts[i],vert1)
					local vert2 = {x - dx*w*0.5, y - dy*w*0.5, 1, 0.5, a, a, a, a}
					table.insert(player.skidmarks_verts[i],vert2)
					if #player.skidmarks_verts[i] > 2 then 
						if player.skidmarks_mesh_id == nil then
							player.skidmarks_mesh_id = #skidmarks_meshes
						end
						skidmarks_meshes[player.skidmarks_mesh_id + i] = love.graphics.newMesh(player.skidmarks_verts[i], "strip")
					end
				end
			else
				player.skidmarks_verts = {{},{},{},{}}
				player.skidmarks_mesh_id = nil
			end
		end

		local post_collision_players_pos = {}

		for i,player in pairs(active_players) do
			local pre_pos_player = pre_collision_players_pos[i]
			post_collision_players_pos[i]= {
				x = pre_pos_player.x,
				y = pre_pos_player.y
			}
			-- Player <-> Player collision
			for j,other_player in pairs(active_players) do
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
						if not player.inventory then
							player.vx = ret.vx
							player.vy = ret.vy
						end
						player.speed = 0
						player.accel = 0
						if player.input_joystick then
							player.input_joystick:setVibration(1.,1.,0.1)
						end
					end
				end
			end
			post_collision_players_pos[i].x, post_collision_players_pos[i].y,
			friction, nx, ny = 
			collide_sdf(player.x, post_collision_players_pos[i].x, player.y, post_collision_players_pos[i].y, player_radius,obstacle_sdf)
			player.speed = player.speed*(1-friction)
			player.accel = player.accel*(1-friction)
			if friction > 0.2 then
				player.vx = nx*100
				player.vy = ny*100
				if player.input_joystick then
					player.input_joystick:setVibration(0.7,0.7,0.1)
				end
			end
		end
		for i,player in pairs(active_players) do
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
					vx = 0, vy = 0, r = 32
				}
				local ret = check_circles_collision(c1,c2)
				if ret and player.swap_cooldown < 0 then
					local tmp = player.inventory
					player.inventory = {name= pickup.name, sprite=pickup.sprite}
					player.swap_cooldown = 0.5
					pickup_sound:play()
					if tmp == nil then
						table.insert(to_delete,j)
					else
						pickup.name = tmp.name
						pickup.sprite = tmp.sprite
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
					vx = 0, vy = 0, r = 48
				}
				local ret = check_circles_collision(c1,c2)
				if ret then
					if player.inventory and player.inventory.name == person.wants then
						eat_sound:play()
						table.insert(player.score,{name=player.inventory.name,sprite=player.inventory.sprite})
						player.inventory = nil
						num_active_food = num_active_food-1
						table.insert(to_delete,j)
					end
				end

			end
			for _,j in pairs(to_delete) do 
				table.insert(hungry_people_locations,hungry_people[j])
				hungry_people[j] = nil
			end
		end
		for j,person in pairs(hungry_people) do
			person.anim_t = person.anim_t+dt*1
		end
		update_obstacles(dt,post_collision_players_pos)
		for i,player in pairs(active_players) do
			player.x = post_collision_players_pos[i].x
			player.y = post_collision_players_pos[i].y
			local has_warped = false
			while player.x < 0 do
				player.x = player.x + 1920
				has_warped = true
			end
			while player.x > 1920 do
				player.x = player.x - 1920
				has_warped = true
			end
			while player.y < 0 do
				player.y = player.y + 980
				has_warped = true
			end
			while player.y > 980 do
				player.y = player.y - 980
				has_warped = true
			end
			if has_warped then 
				player.skidmarks_verts = {{},{},{},{}}
				player.skidmarks_mesh_id = nil
			end
			player.swap_cooldown = player.swap_cooldown - dt
			player.boost_cooldown = player.boost_cooldown - dt
			if #player.score >= 3 then
				winning_player = player
				switch_to_state("win")
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
				phone_sound:play()
				for j=1,999 do
					if hungry_people[j] == nil then
						hungry_people[j] = person
						person.intro_anim_t = 0
						person.anim_t = 0
						break
					end
				end
				table.remove(hungry_people_spawn_queue,i)
			end
		end
		if food_spawn_cooldown < 0 then
			if num_active_food < 1 then
				spawn_food()
			end
			food_spawn_cooldown = math.random()*9+1.2
		end
		food_spawn_cooldown = food_spawn_cooldown - dt
		for j,person in pairs(hungry_people) do
			person.intro_anim_t = math.min(person.intro_anim_t+dt*1.5,1.0)
		end
	end
	game_countdown = game_countdown - dt

end

function draw_game(dt)
	love.graphics.push()
	love.graphics.translate(0,100)
	love.graphics.setColor(1,1,1,1)
	if bkg_video then 
		if not bkg_video:isPlaying() then
			bkg_video:rewind()
			bkg_video:play()
		end
		love.graphics.draw(bkg_video)
	else
		love.graphics.draw(bkg_image)
	end

	render_snow(true)

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

	love.graphics.setColor(0,0,0,0.15)
	for _,mesh in pairs(skidmarks_meshes) do
		love.graphics.draw(mesh)
	end
	love.graphics.setColor(1,1,1,1)

	for i_player,player in pairs(active_players) do
		love.graphics.setColor(1,1,1,1)
		local character = characters[player.character_index]
		local sprite_index = math.mod(player.steering_angle*32/math.pi/2, 32)
		sprite_index = math.floor(sprite_index+16)
		while sprite_index < 0 do
			sprite_index = sprite_index + 32
		end
		while sprite_index > 31 do
			sprite_index = sprite_index - 32
		end
		sprite_w, sprite_h = player.sprite[sprite_index+1]:getDimensions()
		love.graphics.draw(player.sprite[sprite_index+1],player.x-sprite_w/2,player.y-sprite_h/2)
		if player.inventory then
			love.graphics.setColor(1,1,1,1)
			love.graphics.push()
			love.graphics.translate(player.x,player.y)
			love.graphics.scale(0.5,0.5)
			love.graphics.draw(player.inventory.sprite, -80, -160)
			love.graphics.pop()
		end
		if false then
			local sdf_val = sdf_get_value(obstacle_sdf,player.x/1920,player.y/1080)
			love.graphics.setFont(main_font)
			love.graphics.circle("fill",player.x,player.y,3)
			love.graphics.print(sdf_val,player.x-8,player.y-16)
			local sdf_dx, sdf_dy = sdf_get_gradient(obstacle_sdf,player.x,player.y)
			love.graphics.line(player.x,player.y,player.x+sdf_dx*100000,player.y+sdf_dy*100000)
		end
	end
	love.graphics.setColor(1,1,1,1)
	render_obstacles()

	for _,pickup in pairs(pickups) do 
		if pickup then
			local r = 32
			local bounce = math.abs(math.sin(pickup.bounce_timer*6))
			if false then
				love.graphics.setFont(main_font)
				love.graphics.print(pickup.name,pickup.x-20,pickup.y-40)
				love.graphics.circle("fill",pickup.x, pickup.y-bounce*10, r)
			else
				love.graphics.draw(pickup.sprite,pickup.x-110,pickup.y-bounce*10-100)
				--love.graphics.circle("fill",pickup.x, pickup.y, r)
			end
		end
	end
	for _,person in pairs(hungry_people) do 
		love.graphics.setFont(main_font)
		if true then
			love.graphics.push()
			love.graphics.translate(person.x,person.y)
			love.graphics.scale(ElasticEaseOut(person.intro_anim_t))
			love.graphics.scale(math.abs(math.sin(person.anim_t*2))*0.1+0.95)
			love.graphics.setColor(1,1,1,1)
			love.graphics.draw(speech_bubble,-170,-180)
			--love.graphics.print(person.wants,-100,-100)
			love.graphics.draw(person.sprite,-170,-170)
			love.graphics.pop()
		else
			love.graphics.print("I want\n"..person.wants,person.x-20,person.y-40)
			love.graphics.circle("fill",person.x,person.y,2)
		end
	end
	render_snow(false)
	love.graphics.pop()

	love.graphics.setColor(0,0,0,1)
	love.graphics.rectangle('fill',0,0, 1920,100)

	for i_player,player in pairs(active_players) do
		local character = characters[player.character_index]
		love.graphics.setColor(1,1,1,1)
		love.graphics.push()
		love.graphics.translate((i_player-1)*200,0)
		if character then
			if character.sprite then
				love.graphics.push()
				love.graphics.scale(100/512)
				love.graphics.draw(character.sprite)
				love.graphics.pop()
			else
				--love.graphics.setColor(character.color)
				--love.graphics.rectangle("fill",0,0,100,100)
				love.graphics.draw(player.sprite[1],32,32)
				love.graphics.setColor(1,1,1,1)
				love.graphics.setFont(main_font)
				love.graphics.print(character.name,0,0)
			end
		else
			love.graphics.rectangle("line",0,0,100,100)
		end
		love.graphics.translate(100,0)
		for i,score in pairs(player.score) do 
			r = 10
			--love.graphics.circle("fill",2*r,r+(i-1)*(3*r),r)
			love.graphics.push()
			love.graphics.scale(0.3,0.3)
			love.graphics.translate(2*r,r+(i-1)*(10*r))
			love.graphics.draw(score.sprite,0,-10)
			love.graphics.pop()
		end
		love.graphics.pop()
	end

	if false then 
		love.graphics.push()
		love.graphics.translate(1920/2,1080/2)
		love.graphics.setFont(title_font)
		love.graphics.pop()
		if game_countdown > 0 then
			love.graphics.printf(math.ceil(game_countdown), -200, -100, 400, "center")
		elseif game_countdown > -1 then
			love.graphics.printf("GO!", -200, -100, 400, "center")
		end
	else
		local n = math.ceil(game_countdown) + 1
		local s = splash_numbers[n]
		local f = game_countdown - n + 2
		if s then
			love.graphics.push()
			love.graphics.translate(1920/2,1080/2)
			local scale = ElasticEaseOut(1-f)
			love.graphics.scale(scale,scale)
			love.graphics.translate(-1920/2,-1080/2)
			--print(string.format("%f %f",n,f))
			love.graphics.draw(s,0,0)
			love.graphics.pop()
		end
	end

end

function keypressed_game(key)
	--Debug keys
	if key == "t" then
		if tank_controls == true then
			tank_controls =false
		else 
			tank_controls = true
		end
	end
end
