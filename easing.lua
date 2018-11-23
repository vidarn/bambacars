
function BounceEaseIn(p)
	return 1 - BounceEaseOut(1 - p)
end

function BounceEaseOut(p)
	if p < 4/11.0 then
		return (121 * p * p)/16.0
	elseif p < 8/11.0 then
		return (363/40.0 * p * p) - (99/10.0 * p) + 17/5.0
	elseif p < 9/10.0 then
		return (4356/361.0 * p * p) - (35442/1805.0 * p) + 16061/1805.0
	else
		return (54/5.0 * p * p) - (513/25.0 * p) + 268/25.0
    end
end

function BounceEaseInOut(p)
	if(p < 0.5) then
		return 0.5 * BounceEaseIn(p*2)
	else
		return 0.5 * BounceEaseOut(p * 2 - 1) + 0.5
    end
end


function ElasticEaseIn(p)
	return math.sin(13 * math.pi*0.5 * p) * math.pow(2, 10 * (p - 1))
end

function ElasticEaseOut(p)
	return math.sin(-13 * math.pi*0.5 * (p + 1)) * math.pow(2, -10 * p) + 1
end

function ElasticEaseInOut(p)
	if p < 0.5 then
		return 0.5 * math.sin(13 * math.pi*0.5 * (2 * p)) * math.pow(2, 10 * ((2 * p) - 1))
	else
		return 0.5 * (math.sin(-13 * math.pi*0.5 * ((2 * p - 1) + 1)) * math.pow(2, -10 * (2 * p - 1)) + 2)
    end
end

