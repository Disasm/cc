local tArgs = { ... }
if #tArgs < 1 then
	print( "Usage: g [direction] <distance>" )
	return
end

local function refuel(nLimit)
    if turtle.getFuelLevel() ~= "unlimited" then
        for n=1,16 do
            local nCount = turtle.getItemCount(n)
            if nCount > 0 then
                turtle.select( n )
                if nCount >= nLimit then
                    if turtle.refuel( nLimit ) then
                        break
                    end
	            else
                    if turtle.refuel( nCount ) then
                        nLimit = nLimit - nCount
                    end
                end
            end
        end
    end
end

local function checkFuel(distance)
    if turtle.getFuelLevel() ~= "unlimited" then
        if turtle.getFuelLevel() < distance then
            refuel(distance + 2)
        end
    end
end

local tHandlers = {
    ["f"] = turtle.forward,
	["fd"] = turtle.forward,
	["forward"] = turtle.forward,
	["forwards"] = turtle.forward,
	["b"] = turtle.back,
	["bk"] = turtle.back,
	["back"] = turtle.back,
	["u"] = turtle.up,
	["up"] = turtle.up,
	["d"] = turtle.down,
	["dn"] = turtle.down,
	["down"] = turtle.down,
	["l"] = turtle.turnLeft,
	["lt"] = turtle.turnLeft,
	["left"] = turtle.turnLeft,
	["r"] = turtle.turnRight,
	["rt"] = turtle.turnRight,
	["right"] = turtle.turnRight,
}

local nArg = 1
while nArg <= #tArgs do
    local sDirection = "f"
    if tonumber(tArgs[nArg])==nil then
        sDirection = tArgs[nArg]
        nArg = nArg + 1
    end
	local nDistance = 1
	if nArg <= #tArgs then
		local num = tonumber( tArgs[nArg] )
		if num then
			nDistance = num
			nArg = nArg + 1
		end
	end

	local fnHandler = tHandlers[string.lower(sDirection)]
	if fnHandler then
        checkFuel(nDistance)
		for n=1,nDistance do
			fnHandler( nArg )
		end
	else
		print( "No such direction: "..sDirection )
		print( "Try: forward, back, up, down" )
		return
	end
end
