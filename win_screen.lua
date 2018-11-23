local win_cooldown = 0.5

function load_win()
end

function update_win(dt)
    win_cooldown = win_cooldown - dt
end

function draw_win()
    local  character = characters[winning_player.character_index]
	love.graphics.translate(1920/2,1080/2-100)
	love.graphics.setFont(title_font)
	local w = 1024
    love.graphics.printf("Winner!",-w/2,0,w, "center")
    if character and character.sprite then
        love.graphics.draw(character.sprite)
    else
        love.graphics.rectangle("fill",0, 0, 512, 512)
    end
end

function keypressed_win(key)
    if win_cooldown < 0 then
        game_state = "game"
        win_cooldown = 0.5
    end
end

function gamepadpressed_win(gamepad,button)
    if win_cooldown < 0 then
        game_state = "game"
        win_cooldown = 0.5
    end
end
