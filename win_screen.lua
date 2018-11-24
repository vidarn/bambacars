local win_cooldown = 0.5

function load_win()
end

function update_win(dt)
    win_cooldown = win_cooldown - dt
end

function draw_win()
    local  character = characters[winning_player.character_index]
    love.graphics.setColor(character.color)
    love.graphics.rectangle('fill',0,0,1920,1080)
    love.graphics.setColor(1,1,1,1)
	love.graphics.translate(1920/2,1080/2-100)
	love.graphics.setFont(title_font)
	local w = 1024
    love.graphics.printf(string.format("Player %d won!",winning_player.index),-w/2,0,w, "center")
    if character and character.sprite then
        love.graphics.draw(character.sprite)
    end
end

function keypressed_win(key)
    if win_cooldown < 0 then
        switch_to_state("game")
        win_cooldown = 0.5
    end
end

function gamepadpressed_win(gamepad,button)
    if win_cooldown < 0 then
        switch_to_state("game")
        win_cooldown = 0.5
    end
end
