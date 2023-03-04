-- Getting Graphics from Screen
BoxRadius = 6
InputSize = (BoxRadius * 2 + 1) * (BoxRadius * 2 + 1)
Inputs = InputSize + 1

client.pause()

g_client = require("gameClient")




--Input Functions
function getPosition()
    marioScreenX = memory.readbyte(0x0086)
    screenEdgeX = memory.readbyte(0x071C)
    marioX = memory.readbyte(0x006D) * 0x100 + memory.readbyte(0x0086)
    marioY = memory.readbyte(0x03B8) + 16
end
function getSprites()
    local sprites = {}
    for slot = 0, 4 do
        local enemy = memory.readbyte(0xF + slot)
        if enemy ~= 0 then
            local ex = memory.readbyte(0x6E + slot) * 0x100 + memory.readbyte(0x87 + slot)
            local ey = memory.readbyte(0xCF + slot) + 24
            sprites[#sprites + 1] = {
                ["x"] = ex,
                ["y"] = ey
            }
        end
    end

    return sprites
end
function getTile(dx, dy)
    local x = marioX + dx + 8
    local y = marioY + dy - 16
    local page = math.floor(x / 256) % 2

    local subx = math.floor((x % 256) / 16)
    local suby = math.floor((y - 32) / 16)
    local addr = 0x500 + page * 13 * 16 + suby * 16 + subx

    if suby >= 13 or suby < 0 then
        return 0
    end

    if memory.readbyte(addr) >= 0x0010 and memory.readbyte(addr) <= 0x0021 then
        return 0.6 --Pipe Tile
    end

    if memory.readbyte(addr) >= 0x00C0 and memory.readbyte(addr) <= 0x00C1 then
        return 0.4 --Lucky Block
    end

    if memory.readbyte(addr) == 0x00C2 then
        return 0.2 --Coin
    end

    if memory.readbyte(addr) >= 0x0024 and memory.readbyte(addr) <= 0x0025 then
        return 0.8 --Flag Tile
    end

    if memory.readbyte(addr) ~= 0 then
        return 1 --Other Collision
    else
        return 0
    end
end
function getInputs()
    local inputs = {}
    
    getPosition()
    sprites = getSprites()

    for dy = -BoxRadius*16, BoxRadius*16, 16 do
        for dx = -BoxRadius*16, BoxRadius*16, 16 do
            inputs[#inputs + 1] = 0

            tile = getTile(dx, dy)

            if tile == 1 and marioY + dy < 0x1B0 then
                inputs[#inputs] = 1
            else 
                inputs[#inputs] = tile
            end
            
            for i = 1, #sprites do
                distx = math.abs(sprites[i]["x"] - (marioX + dx))
                disty = math.abs(sprites[i]["y"] - (marioY + dy))
                if distx <= 8 and disty <= 8 then
                    inputs[#inputs] = -1
                end
            end

            

        end
    end
    return inputs
end

--Connection Functions
function connect()
    -- local hostnameFile, err = io.open('hostname.txt', 'w')
	-- hostnameFile:write(forms.gettext(hostnameBox))
	-- hostnameFile:close()

	if g_client.isConnected() then
		forms.settext(connectButton, "Connect Start")
		g_client.close()
	else
		forms.settext(connectButton, "Connect Stop")
		g_client.connect(forms.gettext(hostnameBox))
		if g_client.isConnected() then
			print("Connected.")
		else
			print("Unable to connect.")
		end

	end
end

--Forms
form = forms.newform(195, 335, "Play")
hostnameBox = forms.textbox(form, "LAPTOP-F79I9PRS", 100, 20, "TEXT", 60, 70)
forms.label(form, "Hostname:", 3, 73)
connectButton = forms.button(form, "Connect Button", connect, 3, 100)



while(true) do
    console.clear()
    inputs = getInputs()
    g_client.sendList(inputs)

    emu.frameadvance()
end