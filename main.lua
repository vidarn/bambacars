debug = true

map = {}
players = {}
game = {}

tile_house = 1
tile_road = 2

num_players = 2
player_radius = 1

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
}

function spring(x,target_x,v,k,d,dt)
	local delta = target_x - x
	local F = delta*k
	local new_v = d*v + F*dt
	local new_x = x + new_v*dt
	return new_x, new_v
end

function love.load(arg)
	print("Load!")
	for i_player =1,num_players do
		local player = {}
		player.x = 10 - 3*i_player
		player.y = 5
		player.vx = 0
		player.vy = 0
		player.angle = math.pi
		player.speed = 0
		player.accel = 0
		player.inputs = input_keys[i_player]
		player.color = player_colors[i_player]
		players[i_player] = player
	end

	local map_image = love.image.newImageData("data/map.png")
	map.w = map_image:getWidth()
	map.h = map_image:getHeight()
	map.tiles = {}
	for y = 1,map.h do
		for x = 1,map.w do 
			local r, g, b, a = map_image:getPixel(x-1,y-1)
			if r == 0 then
				map.tiles[x+y*map.w] = tile_house
			else
				map.tiles[x+y*map.w] = tile_road
			end
		end
	end
end


function love.keypressed( key )
end

function love.update(dt)
	local pre_collision_players_pos = {}

	for i,player in pairs(players) do
		local last_player
		local target_speed = 0
		local delta_angle = 0
		if love.keyboard.isDown(player.inputs.up) then
			target_speed = 16
		end
		if love.keyboard.isDown(player.inputs.left) then
			delta_angle = -4*dt
		end
		if love.keyboard.isDown(player.inputs.right) then
			delta_angle =  4*dt
		end
		player.speed, player.accel =spring(player.speed, target_speed, player.accel, 80.0, 0.73, dt)
		player.angle = player.angle + delta_angle
		local cos_angle = math.cos(player.angle)
		local sin_angle = math.sin(player.angle)

		player.vx = player.vx * math.pow(0.001,dt)
		player.vy = player.vy * math.pow(0.001,dt)
		local vm = math.sqrt(player.vx*player.vx + player.vy*player.vy)
		local speed = player.speed
		if vm > 1.0 then
			speed = 0
		else
			--player.vx = 0
			--player.vy = 0
		end
		local dx = cos_angle * speed * dt + player.vx *dt
		local dy = sin_angle * speed * dt + player.vy *dt
		pre_collision_players_pos[i] = {
			x = player.x + dx,
			y = player.y + dy
		}
	end

	local post_collision_players_pos = {}

	--print("--")
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
				local r = 2*player_radius
				local ox = player.x - other_player.x
				local oy = player.y - other_player.y
				local ex = pre_pos_player.x - pre_pos_other_player.x
				local ey = pre_pos_player.y - pre_pos_other_player.y
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
						--print("Hit t1 " .. i .. " " .. t1 .. " " .. t2)
						local nx = ox + t1*dx
						local ny = oy + t1*dy
						local m = math.sqrt(nx*nx + ny*ny)
						nx = nx/m
						ny = ny/m
						local dx2 = pre_pos_player.x - player.x
						local dy2 = pre_pos_player.y - player.y
						local d = math.sqrt(dx2*dx2 + dy2*dy2)
						local remaining_dist = (1-t1)*m*0.5
						t1 = t1 - 0.1
						post_collision_players_pos[i].x = player.x + t1*dx2
						post_collision_players_pos[i].y = player.y + t1*dy2
						player.vx = player.vx + nx*1.7
						player.vy = player.vy + ny*1.7
						--print(nx .. " " .. ny .. "(" .. i .. ")")
						--post_collision_players_pos[i].x = (1-t1)*player.x + t1*pre_pos_player.x
						--post_collision_players_pos[i].y = (1-t1)*player.y + t1*pre_pos_player.y
						hit = true
					end
					if t2 >= 0 and t2 <= 1 then
						--print("Hit t2")
					end
					if not hit then
						--print("Miss1 " .. i .. " " .. t1 .. " " .. t2)
					end
					--print(string.format("o %f %f d %f %f", ox, oy, dx, dy))
				else
					--print("Miss2 " .. i)
				end
			end
		end
	end
	for i,player in pairs(players) do
		player.x = post_collision_players_pos[i].x
		player.y = post_collision_players_pos[i].y
	end
end

function love.draw(dt)
	love.graphics.push()
	love.graphics.translate(10,10)
	love.graphics.scale(10,10)
	for y=1,map.w do
		for x=1,map.w do
			if map.tiles[x+y*map.w] == tile_house then
				love.graphics.setColor(0.2,0.2,0.2,1.0)
				love.graphics.rectangle("fill",x-0.25,y-0.25,0.5,0.5)
			end
		end
	end

	for i_player = 1,num_players do
		local player = players[i_player]
		love.graphics.setColor(player.color)
		love.graphics.rectangle("fill",player.x-0.5,player.y-0.5,1,1)
		love.graphics.circle("fill",player.x, player.y, player_radius)
	end

	love.graphics.pop()
end
