--[[
startup:
shell.run("/rom/programs/turtle/dig", "restore")
shell.run("/dig", "restore")
]]

local stateFileName = "/dig.state"
local maxDepth = 1000  -- for debug, default=1000

local restore = false
local size = 0
local shitSize = 0
local xPos,zPos = 0,-1
local xDir,zDir = 0,1
local depth = 0

local function usage()
    print( "Usage: dig <diameter> <shit_count> [max_depth]" )
    print( "Pattern: ")
    print( "###" )
    print( "###" )
    print( "###" )
    print( "^    <-turtle" )
    print( "@    <-chest" )
end

local function restoreState()
    if not fs.exists(stateFileName) then
        print("Can't find state file")
        return false
    end

    local f = fs.open(stateFileName, "r")
    local state = f.readAll()
    f.close()

    local result = textutils.unserialize( state )
    if type(result) == "table" and #result == 7 then
        size = result[1]
        shitSize = result[2]
        xPos, zPos = result[3], result[4]
        xDir, zDir = result[5], result[6]
        maxDepth = result[7]
        return true
    else
        print("Incorrect format")
        return false
    end
end

local function saveState()
    local f = fs.open(stateFileName, "w")
    local state = textutils.serialize({size, shitSize, xPos, zPos, xDir, zDir, maxDepth})
    f.write(state)
    f.close()
end

local function deleteState()
    fs.delete(stateFileName)
end

local function refuel(needed)
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" then
        return true
    end

    if fuelLevel < needed then
        for n=1,16 do
            if turtle.getItemCount(n) > 0 then
                turtle.select( n )
                if turtle.refuel(1) then
                    while turtle.getItemCount(n) > 0 and turtle.getFuelLevel() < needed do
                        turtle.refuel(1)
                    end
                end
                if turtle.getFuelLevel() >= needed then
                    turtle.select(1)
                    return true
                end
            end
        end
        turtle.select(1)
        return false
    end

    return true
end

local function hasSlots()
    if turtle.getItemCount(16)==0 then
        return true
    else
        return false
    end
end

local function cleanSlots()
    for i=1,shitSize do
        local n = turtle.getItemCount(i)
        if n>1 then
            turtle.select(i)
            turtle.drop(n-1)
        end
    end
end

local function forceDig()
    turtle.select(1)
    if turtle.dig() then
        cleanSlots()
        return true
    else
        return false
    end
end

local function tryDig()
    if not hasSlots() then
        return false
    end
    turtle.select(1)
    if turtle.dig() then
        cleanSlots()
        return true
    else
        return false
    end
end

local function tryDigDown()
    if not hasSlots() then
        return false
    end
    turtle.select(1)
    if turtle.digDown() then
        cleanSlots()
        return true
    else
        return false
    end
end

local function tryDown()
    if depth>=maxDepth then
        return false
    end
    if not turtle.down() then
        if not tryDigDown() then
            return false
        end
        if not turtle.down() then
            return false
        end
    end
    depth = depth + 1
    return true
end

local function tryUp()
    if not turtle.up() then
        if not turtle.digUp() then
            return false
        end
        if not turtle.up() then
            return false
        end
    end
    depth = depth - 1
    return true
end

local function makeMine()
    if refuel(512)==false then
        return false
    end

    while tryDown() do
    end
    while depth>0 do
        tryUp()
    end
    if hasSlots() then
        return true
    else
        return false
    end
end

local function dropResources()
    local k = shitSize+1
    for i=k,16 do
        if turtle.getItemCount(i)>0 then
            turtle.select(i)
            turtle.drop()
            sleep(0.5)
        end
    end
end

local function turnLeft()
    turtle.turnLeft()
    xDir, zDir = -zDir, xDir
end

local function turnRight()
    turtle.turnRight()
    xDir, zDir = zDir, -xDir
end

local function tryForward()
    refuel(10)
    if not turtle.forward() then
        if not tryDig() then
            return false
        end
        if not turtle.forward() then
            return false
        end
    end
    xPos = xPos + xDir
    zPos = zPos + zDir
    return true
end

local function forceForward()
    refuel(10)
    while not turtle.forward() do
        forceDig()
        sleep(0.8)
    end
    xPos = xPos + xDir
    zPos = zPos + zDir
    return true
end

local function gotoDir(xd, zd)
    while (xDir ~= xd) or (zDir ~= zd) do
        turnLeft()
    end
end

local function goto(x, z, xd0, zd0)
    local xd = 0
    if (xPos-x) < 0 then
        xd = 1
    else
        xd = -1
    end

    local zd = 0
    if (zPos-z) < 0 then
        zd = 1
    else
        zd = -1
    end

    gotoDir(xd, 0)
    while xPos ~= x do
        forceForward()
    end

    gotoDir(0, zd)
    while zPos ~= z do
        forceForward()
    end

    gotoDir(xd0, zd0)
end

local function goNext()
    local z = zPos + zDir
    if (z>=0) and (z<size) then
        return tryForward()
    end
    if (xPos+1) >= size then
        return false
    end
    local zd = zDir
    if zd==1 then
        turnRight()
    else
        turnLeft()
    end
    if not tryForward() then
        return false
    end
    if zd==1 then
        turnRight()
    else
        turnLeft()
    end
    return true
end






local tArgs = { ... }

if tArgs[1]=="restore" then
    restore = true
    print("restoring state...")
    restoreState()
elseif tArgs[1]=="autorun" then
    local s = "while turtle.up() do\nend\nturtle.down()\n"
    local f = fs.open("/startup", "w")
    f.write(s)
    f.close()
    return
else
    if #tArgs < 2 then
        usage()
        return
    end
    size = tonumber( tArgs[1] )
    shitSize = tonumber( tArgs[2] )
    if #tArgs > 2 then
        maxDepth = tonumber( tArgs[3] )
    end
end

if size < 1 then
    print( "Excavate diameter must be positive" )
    return
end

if (shitSize<1) or (shitSize>8) then
    print( "Shit size must be in interval [1;8]" )
    return
end

for i=1,shitSize do
    if turtle.getItemCount(i)==0 then
        print("Fill shit slots!")
        return
    end
end


if restore then
    local x,z,xd,zd = xPos,zPos,xDir,zDir
    xPos,zPos,xDir,zDir = 0,-1,0,1
    depth = 0
    goto(x,z,xd,zd)
else
    goto(0, 0, 0, 1)
end

while true do
    saveState()
    while not makeMine() do
        local x,z,xd,zd = xPos,zPos,xDir,zDir
        goto(0, -1, 0, -1)
        dropResources()
        if refuel(512)==false then
            print("No enough fuel")
            goto(0, -1, 0, 1)
            break
        end
        goto(x,z,xd,zd)
        saveState()
    end
    if not goNext() then
        break
    end
end

goto(0, -1, 0, -1)
dropResources()
turnLeft()
turnLeft()

deleteState()


