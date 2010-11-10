local AppName = "Broker_Compass"
local DisplayName = "Broker: Compass"
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local L = LibStub("AceLocale-3.0"):GetLocale(AppName)
local Icon = [[Interface\AddOns\]] .. AppName .. [[\arrow.tga]]
local UpdateDelay = 0.1
local Pi = math.pi
local floor = math.floor
local sin = math.sin
local cos = math.cos
local rawset = rawset

local GetPlayerFacing = GetPlayerFacing

local function round(v)
    return floor(v + 0.5)
end

Broker_CompassDB = Broker_CompassDB or {
}
local db

local Directions = {
    L["NorthEast"],
    L["East"],
    L["SouthEast"],
    L["South"],
    L["SouthWest"],
    L["West"],
    L["NorthWest"],
    L["North"],
}
Directions[0] = Directions[8]

local LongDirections = {
    L["NorthEast-long"],
    L["East-long"],
    L["SouthEast-long"],
    L["South-long"],
    L["SouthWest-long"],
    L["West-long"],
    L["NorthWest-long"],
    L["North-long"],
}
LongDirections[0] = LongDirections[8]

local Icons = {
    Icon,
    [[Interface\AddOns\]] .. AppName .. [[\arrow2.tga]],
    [[Interface\AddOns\]] .. AppName .. [[\arrow3.tga]],
}

local texcoords = setmetatable({}, {
    __index = function(t, deg)
        local rad = (360 - deg) * Pi / 180
        local sv, cv = 0.5 * sin(rad), 0.5 * cos(rad)
        local res = {
            0.5 - cv + sv, 0.5 - cv - sv,
            0.5 - cv - sv, 0.5 + cv - sv,
            0.5 + cv + sv, 0.5 - cv + sv,
            0.5 + cv - sv, 0.5 + cv + sv
        }
        rawset(t, deg, res)
        return res
    end
})

local update, bc -- forward decl
bc = {
        type = "data source",
        label = L["Direction"],
        icon = Icon,
        staticIcon = Icon,
        iconCoords = texcoords[0],
        text = "",
        value = "",
        suffix = "°",
        OnTooltipShow = function(tt)
            tt:AddLine(DisplayName)
            tt:AddLine(L["|cffeda55fLeft Click|r to change text format"])
            tt:AddLine(L["|cffeda55fAlt + Left Click|r to change icon"])
        end,
        OnClick = function(frame, button)
            if button == "LeftButton" then
                if IsAltKeyDown() then
                    if not db.iconIdx or db.iconIdx < 1 or db.iconIdx > #Icons then
                        db.iconIdx = 2
                    else
                        db.iconIdx = db.iconIdx + 1
                    end
                    if db.iconIdx > #Icons then
                        db.iconIdx = nil
                        bc.icon = Icon
                    else
                        bc.icon = Icons[db.iconIdx]
                    end
                    update(true)
                else
                    db.longFormat = not db.longFormat or nil
                    update(true)
                end
            end
        end,
}
LDB:NewDataObject(AppName, bc)

update = function(forced)
    local deg = 360 - round((GetPlayerFacing() * 180) / Pi)
    if deg == 360 then
        deg = 0
    end
    if deg == bc.value and not forced then
        return
    end
    local idx = round(deg / 45)
    bc.value = deg
    bc.text = db.longFormat and LongDirections[idx] or Directions[idx]
    bc.iconCoords = texcoords[deg]
end

local bcTimerFrame = CreateFrame("Frame")
bcTimerFrame:SetScript("OnEvent", function(frame, event, arg)
    if event == 'ADDON_LOADED' and arg == AppName then
        db = Broker_CompassDB
        if db.iconIdx and 1 <= db.iconIdx and db.iconIdx <= #Icons then
            bc.icon = Icons[db.iconIdx]
        end
        update(true)
        local bcTimerAnim = frame:CreateAnimationGroup()
        local anim = bcTimerAnim:CreateAnimation()
        anim:SetDuration(db.updateDelay and db.updateDelay > 0 and db.updateDelay or UpdateDelay)
        bcTimerAnim:SetScript("OnFinished", function(self)
            update()
            self:Play()
        end)
        bcTimerAnim:Play()

        frame:UnregisterEvent('ADDON_LOADED')
        frame:SetScript("OnEvent", nil)
    end
end)
bcTimerFrame:RegisterEvent('ADDON_LOADED')
