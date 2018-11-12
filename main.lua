debug = true

map = {}
players = {}
game = {}

tile_house = 1
tile_road = 2

num_players = 2

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
    for _,player in pairs(players) do
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
         -- TODO(Vidar):Spring eq for speed??
        --player.speed = target_speed
	player.speed, player.accel =spring(player.speed, target_speed, player.accel, 80.0, 0.83, dt)
        player.angle = player.angle + delta_angle
        local cos_angle = math.cos(player.angle)
        local sin_angle = math.sin(player.angle)

	print(player.speed .. " " .. target_speed)

        local dx = cos_angle * player.speed * dt
        local dy = sin_angle * player.speed * dt
        player.x = player.x + dx
        player.y = player.y + dy
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
				love.graphics.setColor(1.0,1.0,1.0,1.0)
				love.graphics.rectangle("fill",player.x-0.5,player.y-0.5,1,1)
		end

		love.graphics.pop()
end
