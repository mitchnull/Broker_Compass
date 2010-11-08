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

local directions = {
    L["NorthEast"],
    L["East"],
    L["SouthEast"],
    L["South"],
    L["SouthWest"],
    L["West"],
    L["NorthWest"],
    L["North"],
}
directions[0] = directions[8]

local longDirections = {
    L["NorthEast-long"],
    L["East-long"],
    L["SouthEast-long"],
    L["South-long"],
    L["SouthWest-long"],
    L["West-long"],
    L["NorthWest-long"],
    L["North-long"],
}
longDirections[0] = longDirections[8]

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

local update -- forward decl
local bc = {
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
        end,
        OnClick = function(frame, button)
            if button == "LeftButton" then
                db.longFormat = not db.longFormat
                update(true)
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
    bc.text = db.longFormat and longDirections[idx] or directions[idx]
    bc.iconCoords = texcoords[deg]
end

local bcTimerFrame = CreateFrame("Frame")
bcTimerFrame:SetScript("OnEvent", function(frame, event, arg)
    if event == 'ADDON_LOADED' and arg == AppName then
        db = Broker_CompassDB
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
