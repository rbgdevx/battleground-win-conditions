local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub
local GetTime = GetTime
local UnitIsDeadOrGhost = UnitIsDeadOrGhost

local SharedMedia = LibStub("LibSharedMedia-3.0")

local Banner = NS.Banner
local Score = NS.Score
local Info = NS.Info
local Bases = NS.Bases
local Flags = NS.Flags
local Orbs = NS.Orbs

local Stacks = {}
NS.Stacks = Stacks

local StacksFrame = CreateFrame("Frame", AddonName .. "StacksFrame", Info.frame)
Stacks.frame = StacksFrame

local killStacks = 6
local localStacks = 0
local healingDecrease = 5
local damageIncrease = 10
local showDebuffs = false

Stacks.frame.showDebuffs = showDebuffs

function Stacks:SetAnchor(anchor, x, y, pA, pB)
  local pointA = pA or "TOPLEFT"
  local pointB = pB or "BOTTOMLEFT"
  self.frame:SetPoint(pointA, anchor, pointB, x, y)
end

function Stacks:SetText(frame, format, ...)
  frame:SetFormattedText(format, ...)
  NS.UpdateSize(StacksFrame, frame)
end

function Stacks:SetTextColor(frame, color)
  frame:SetTextColor(color.r, color.g, color.b, color.a)
end

function Stacks:SetFont(frame)
  frame:SetFont(
    SharedMedia:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "OUTLINE"
  )
  NS.UpdateSize(StacksFrame, frame)
end

function Stacks:ToggleAlpha()
  local curAlpha = self.frame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  self.frame:SetAlpha(newAlpha)
end

local function stopAnimation(frame, animationGroup)
  if animationGroup then
    animationGroup:Stop()
  end

  frame.frame:SetAlpha(0)

  if frame.text then
    frame.text:SetFormattedText("")
  end

  if NS.IN_GAME then
    Info.frame:SetSize(1, 1)
  end
end

function Stacks:Stop(frame, animationGroup)
  stopAnimation(frame, animationGroup)
end

local buffformat1 = "First stack in %s\n%d stacks - %d stacks in %s"
local alternateformat1 = ""
local buffformat2 = "Next stack in %s\n%d stack - %d stacks in %s"
local alternateformat2 = "Next stack in %s\nHealing received -%d%%\nDamage taken +%d%%\n%d stack - %d stacks in %s"
local buffformat3 = "Next stack in %s\n%d stacks - %d stacks in %s"
local alternateformat3 = "Next stack in %s\nHealing received -%d%%\nDamage taken +%d%%\n%d stacks - %d stacks in %s"
local buffformat4 = "Next stack in %s\n%d stacks"
local alternateformat4 = "Next stack in %s\nHealing received -%d%%\nDamage taken +%d%%\n%d stacks"

local function textUpdate(frame, stacks, killtime, time)
  if stacks >= 1 then
    if NS.IN_GAME then
      if NS.IS_TP and NS.db.global.maps.twinpeaks.showdebuffinfo then
        showDebuffs = NS.db.global.maps.twinpeaks.showdebuffinfo
      end
      if NS.IS_WG and NS.db.global.maps.warsonggulch.showdebuffinfo then
        showDebuffs = NS.db.global.maps.warsonggulch.showdebuffinfo
      end
    else
      if NS.db.global.maps.twinpeaks.showdebuffinfo or NS.db.global.maps.warsonggulch.showdebuffinfo then
        showDebuffs = true
      end
    end
  else
    showDebuffs = false
  end

  if stacks == 0 then
    Stacks:SetText(frame.text, buffformat1, NS.formatTime(time), stacks, killStacks, NS.formatTime(killtime))
  elseif stacks == 1 then
    -- if
    -- 	(NS.db.global.maps.twinpeaks.showdebuffinfo and (NS.IS_TP or NS.IN_GAME == false))
    -- 	or (NS.db.global.maps.warsonggulch.showdebuffinfo and (NS.IS_WG or NS.IN_GAME == false))
    -- then
    if showDebuffs then
      Stacks:SetText(
        frame.text,
        alternateformat2,
        NS.formatTime(time),
        stacks * healingDecrease,
        stacks * damageIncrease,
        stacks,
        killStacks,
        NS.formatTime(killtime)
      )
    else
      Stacks:SetText(frame.text, buffformat2, NS.formatTime(time), stacks, killStacks, NS.formatTime(killtime))
    end
  elseif stacks > 1 and stacks < killStacks then
    -- if
    -- 	(NS.db.global.maps.twinpeaks.showdebuffinfo and (NS.IS_TP or NS.IN_GAME == false))
    -- 	or (NS.db.global.maps.warsonggulch.showdebuffinfo and (NS.IS_WG or NS.IN_GAME == false))
    -- then
    if showDebuffs then
      Stacks:SetText(
        frame.text,
        alternateformat3,
        NS.formatTime(time),
        stacks * healingDecrease,
        stacks * damageIncrease,
        stacks,
        killStacks,
        NS.formatTime(killtime)
      )
    else
      Stacks:SetText(frame.text, buffformat3, NS.formatTime(time), stacks, killStacks, NS.formatTime(killtime))
    end
  else
    -- if
    -- 	(NS.db.global.maps.twinpeaks.showdebuffinfo and (NS.IS_TP or NS.IN_GAME == false))
    -- 	or (NS.db.global.maps.warsonggulch.showdebuffinfo and (NS.IS_WG or NS.IN_GAME == false))
    -- then
    if showDebuffs then
      Stacks:SetText(
        frame.text,
        alternateformat4,
        NS.formatTime(time),
        stacks * healingDecrease,
        stacks * damageIncrease,
        stacks
      )
    else
      Stacks:SetText(frame.text, buffformat4, NS.formatTime(time), stacks)
    end
  end

  if showDebuffs ~= Stacks.frame.showDebuffs then
    if NS.IN_GAME then
      NS.UpdateInfoSize(NS.Info.frame, NS.Banner, { Stacks }, "textUpdate")
    else
      NS.UpdateInfoSize(NS.Info.frame, NS.Banner, { NS.Score, NS.Bases, NS.Flags, NS.Orbs, Stacks }, "textUpdate")
    end
    Stacks.frame.showDebuffs = showDebuffs
  end
end

local function animationUpdate(frame, duration, stacks, animationGroup)
  local t = GetTime()

  if t >= frame.exp then
    -- fallback to timers:
    -- if we aren't in a game
    -- enemy auras dont update while dead
    -- auras dont get tracked if nobody is carrying the flag but stacks are still counting
    if
      NS.IN_GAME == false
      or (NS.IN_GAME and UnitIsDeadOrGhost("player"))
      or (NS.IN_GAME and NS.STACKS_COUNTING and NS.HAS_FLAG_CARRIER == false)
    then
      localStacks = localStacks + 1
      NS.CURRENT_STACKS = localStacks
      Stacks:Start(duration, localStacks)
    else
      if animationGroup then
        animationGroup:Stop()
      end
      -- frame.text:Hide()
    end
  else
    local time = frame.exp - t
    frame.remaining = time

    local killtime = 0

    if stacks < killStacks then
      killtime = frame.killexp - t
      frame.killremaining = killtime
    end

    textUpdate(frame, stacks, killtime, time)
  end
end

function Stacks:Start(duration, stacks)
  self:Stop(self, self.timerAnimationGroup)

  localStacks = stacks

  self.remaining = duration
  local time = self.remaining
  self.start = GetTime()
  self.exp = self.start + time

  local killtime = 0
  if stacks < killStacks then
    self.killremaining = duration * (killStacks - localStacks)
    killtime = self.killremaining
    self.killstart = GetTime()
    self.killexp = self.killstart + killtime
  end

  if NS.db.global.general.banner == false then
    self.frame:SetAlpha(1)
  else
    self.frame:SetAlpha(0)
  end

  textUpdate(self, localStacks, killtime, time)

  self:SetFont(self.text)

  if NS.IN_GAME then
    if NS.db.global.general.banner == false and NS.db.global.general.infogroup.infobg then
      NS.UpdateInfoSize(NS.Info.frame, NS.Banner, { Stacks }, "Stacks:Start")
    end
  end

  self.timerAnimationGroup:SetScript("OnLoop", function(updatedGroup)
    if updatedGroup then
      animationUpdate(self, duration, stacks, updatedGroup)
    end
  end)

  self.timerAnimationGroup:Play()
end

function Stacks:Create(anchor)
  if not Stacks.text then
    local Text = StacksFrame:CreateFontString(nil, "ARTWORK")
    Text:SetAllPoints()
    self:SetFont(Text)
    self:SetTextColor(Text, NS.db.global.general.infogroup.infotextcolor)
    Text:SetShadowOffset(0, 0)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("LEFT")
    Text:SetJustifyV("TOP")

    StacksFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    StacksFrame:SetAlpha(0)

    -- local BG = StacksFrame:CreateTexture(nil, "BACKGROUND")
    -- BG:SetAllPoints()
    -- BG:SetColorTexture(1, 0, 1, 1)

    Stacks.text = Text
    Stacks.timerAnimationGroup = NS.CreateTimerAnimation(StacksFrame)

    Stacks.name = "Stacks"
  end
end
