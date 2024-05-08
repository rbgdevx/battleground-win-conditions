local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub
local GetTime = GetTime

local LSM = LibStub("LibSharedMedia-3.0")

local Info = NS.Info
local Banner = NS.Banner

local Orbs = {}
NS.Orbs = Orbs

local OrbsFrame = CreateFrame("Frame", AddonName .. "OrbsFrame", Info.frame)
Orbs.frame = OrbsFrame

function Orbs:SetAnchor(anchor, x, y, pA, pB)
  local pointA = pA or "TOPLEFT"
  local pointB = pB or "BOTTOMLEFT"
  self.frame:SetPoint(pointA, anchor, pointB, x, y)
end

function Orbs:SetText(frame, format, ...)
  frame:SetFormattedText(format, ...)
  NS.UpdateSize(OrbsFrame, frame)
end

function Orbs:SetTextColor(frame, color)
  frame:SetTextColor(color.r, color.g, color.b, color.a)
end

function Orbs:SetFont(frame)
  frame:SetFont(
    LSM:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "THINOUTLINE"
  )
  NS.UpdateSize(OrbsFrame, frame)
end

function Orbs:ToggleAlpha()
  local curAlpha = self.frame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  self.frame:SetAlpha(newAlpha)
end

local function stopAnimation(frame, animationGroup)
  animationGroup:Stop()
  frame.frame:SetAlpha(0)
  frame.text:SetFormattedText("")

  if NS.IN_GAME then
    Info.frame:SetSize(1, 1)
  end
end

function Orbs:Stop(frame, animationGroup)
  stopAnimation(frame, animationGroup)
end

local orbsformat1 = "%s get 4x points in %s"
local orbsformat2 = "%s are earning 4x points"

local function animationUpdate(frame, text, animationGroup)
  local t = GetTime()
  if t >= frame.exp then
    animationGroup:Stop()
    Orbs:SetText(frame.text, orbsformat2, text)
    -- frame.text:Hide()
  else
    local time = frame.exp - t
    frame.remaining = time
    Orbs:SetText(frame.text, orbsformat1, text, NS.formatTime(time))
    -- frame.text:Show()
  end
end

function Orbs:Start(duration, text)
  self:Stop(self, self.timerAnimationGroup)

  self.remaining = duration
  local time = self.remaining
  self.start = GetTime()
  self.exp = self.start + time

  self:SetText(self.text, orbsformat1, text, NS.formatTime(time))
  self:SetFont(self.text)

  if NS.db.global.maps.templeofkotmogu.showbuffinfo == false then
    self.frame:SetAlpha(0)
  else
    self.frame:SetAlpha(1)

    if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
      NS.UpdateContainerSize(Info.frame, Banner)
    end
  end

  self.timerAnimationGroup:SetScript("OnLoop", function(updatedGroup)
    if updatedGroup then
      animationUpdate(Orbs, text, updatedGroup)
    end
  end)

  self.timerAnimationGroup:Play()
end

function Orbs:Create(anchor)
  if not Orbs.text then
    local Text = OrbsFrame:CreateFontString(nil, "ARTWORK")
    Text:SetAllPoints()
    self:SetFont(Text)
    self:SetTextColor(Text, NS.db.global.general.infogroup.infotextcolor)
    Text:SetShadowOffset(0, 0)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("LEFT")
    Text:SetJustifyV("TOP")

    OrbsFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    OrbsFrame:SetAlpha(0)

    Orbs.text = Text
    Orbs.timerAnimationGroup = NS.CreateTimerAnimation(OrbsFrame)
  end
end
