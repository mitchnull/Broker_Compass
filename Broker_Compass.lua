local AppName = "Broker_Compass"
local DisplayName = "Broker: Compass"
local LDB = LibStub:GetLibrary("LibDataBroker-1.1")
local L = LibStub("AceLocale-3.0"):GetLocale(AppName)
local Icon = [[Interface\AddOns\]] .. AppName .. [[\arrow.tga]]
local Pi = math.pi
local floor = math.floor
local sin = math.sin
local cos = math.cos
local rawset = rawset

local Defaults = {
  ["updateDelay"] = 0.1,
  ["iconIdx"] = 1,
  ["textIdx"] = 1,
}


local GetPlayerFacing = GetPlayerFacing

local function round(v)
  return floor(v + 0.5)
end

Broker_CompassDB = Broker_CompassDB or {}
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

local MilDirections = {}
for i = 0, 8 do
  MilDirections[i] = ("[.%s.|.%s.|.%s.]"):format(
    Directions[(i + 7) % 8],
    Directions[i],
    Directions[(i + 1) % 8]
  )
end

local Texts = {
  Directions,
  LongDirections,
  MilDirections,
}
local texts = Texts[1]

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
        db.iconIdx = db.iconIdx + 1
        if db.iconIdx > #Icons then
          db.iconIdx = 1
        end
        bc.icon = Icons[db.iconIdx]
        update(true)
      else
        db.textIdx = db.textIdx + 1
        if db.textIdx > #Texts then
          db.textIdx = 1
        end
        texts = Texts[db.textIdx]
        update(true)
      end
    end
  end,
}
LDB:NewDataObject(AppName, bc)

update = function(forced)
  local pf = GetPlayerFacing() or 0
  local deg = 360 - round((pf * 180) / Pi)
  if deg == 360 then
    deg = 0
  end
  if deg == bc.value and not forced then
    return
  end
  local idx = round(deg / 45)
  bc.value = deg
  bc.text = texts[idx]
  bc.iconCoords = texcoords[deg]
end

local bcTimerFrame = CreateFrame("Frame")
bcTimerFrame:SetScript("OnEvent", function(frame, event, arg)
  if event == 'ADDON_LOADED' and arg == AppName then
    db = setmetatable(Broker_CompassDB, { __index = Defaults })
    if db.iconIdx < 1 or db.iconIdx > #Icons then
      db.iconIdx = 1
    end
    bc.icon = Icons[db.iconIdx]
    if db.textIdx < 1 or db.textIdx > #Texts then
      db.textIdx = 1
    end
    texts = Texts[db.textIdx]
    update(true)
    local bcTimerAnim = frame:CreateAnimationGroup()
    local anim = bcTimerAnim:CreateAnimation()
    anim:SetDuration(db.updateDelay > 0 and db.updateDelay or Defaults.updateDelay)
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
