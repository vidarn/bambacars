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
		for i_player =1,num_players do
			local player = {}
			player.x = 7 - 2*i_player
			player.y = 5
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
    local last_players = {}
    for i,player in pairs(players) do
        last_player = {}
        for k,v in pairs(player) do
            last_player[k] = v
        end
        last_players[i] = last_player
    end

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

        local dx = cos_angle * player.speed * dt
        local dy = sin_angle * player.speed * dt
        player.x = player.x + dx
        player.y = player.y + dy
        -- Obstacle collision
        -- TODO(Vidar):Implement
    end
    for i,player in pairs(players) do
        local last_player = last_players[i]
        -- Player collision
        for j,other_player in pairs(last_players) do
            local last_other_player = last_players[j]
            local r = 2*player_radius
            local ox = last_player.x - last_other_player.x
            local oy = last_player.y - last_other_player.y
            local ex = player.x - other_player.x
            local ey = player.y - other_player.y
            local dx = ex - ox
            local dy = ey - oy
            local a = dx*dx + dy*dy
            local b = 2*(ox*dx + oy*dy)
            local c = ox*ox + oy*oy
            local discr2 = b*b - 4*a*c
            if discr2 > 0.0 then
                local discr = math.sqrt(discr2)
                local t1 = (-b-discr)/(2*a)
                local t2 = ( b-discr)/(2*a)
                if t1 < t2 then
                    local tmp = t1
                    t1 = t2
                    t2 = tmp
                end
                if t1 >= 0 and t1 <= 1 then
                    print("Hit t1")
                end
                if t2 >= 0 and t2 <= 1 then
                    print("Hit t2")
                end
            end
        end
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
