selections = {}

function load_character_select()
    for i,player in pairs(players) do
        selections[i] = player
    end
end

function update_character_select(dt)
end

function love.keypressed(key)
    if key == "escape" then
        game_state = "game"
        print("blajj")
    end
end

function draw_character_select(dt)
    local rect_w = 256
    local rect_h = 256
    local rect_spacing_x = 24
    local rect_spacing_y = 16
    local rows = 2
    local cols = 4
    local total_w = cols*rect_w + (cols-1)*rect_spacing_x
    local total_h = rows*rect_h + (rows-1)*rect_spacing_y
    local offset_y = 128
    love.graphics.translate((1920-total_w)/2,(1080-total_h)/2-offset_y)
    local i = 1
    for r=1,rows do
        for c=1,cols do
            local player = selections[i]
            if player then
                love.graphics.setColor(player.color)
            else
                love.graphics.setColor(1,1,1,1)
            end
            love.graphics.rectangle("fill",(c-1)*(rect_w+rect_spacing_x), (r-1)*(rect_h+rect_spacing_y), rect_w, rect_h)
            i = i + 1
        end
    end
end

