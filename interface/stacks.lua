local AddonName, NS = ...

local CreateFrame = CreateFrame
local GetTime = GetTime

local LSM = LibStub("LibSharedMedia-3.0")

local Stacks = {}
NS.Stacks = Stacks

local StacksFrame = CreateFrame("Frame", AddonName .. "StacksFrame", UIParent)

local killStacks = 6
local maxStacks = 15
local localStacks = 0
local healingDecrease = 5
local damageIncrease = 10

function Stacks:SetAnchor(anchor, x, y)
  self.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
end

function Stacks:SetText(frame, format, ...)
  frame:SetFormattedText(format, ...)
  NS.UpdateSize(StacksFrame, frame)
end

function Stacks:SetFont(frame)
  frame:SetFont(
    LSM:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "THINOUTLINE"
  )
  NS.UpdateSize(StacksFrame, frame)
end

function Stacks:ToggleAlpha()
  local curAlpha = self.frame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  self.frame:SetAlpha(newAlpha)
end

local function stopAnimation(frame, animationGroup)
  animationGroup:Stop()
  frame:Hide()
  frame:SetFormattedText("")
end

function Stacks:Stop(frame, animationGroup)
  stopAnimation(frame, animationGroup)
end

local buffformat1 = "First stack in %s\n%d stacks in %s"
local buffformat2 = "Next stack in %s\n%d stack - %d stacks in %s"
local alternateformat2 = "Next stack in %s\nHealing received -%d%%\nDamage taken +%d%%\n%d stack - %d stacks in %s"
local buffformat3 = "Next stack in %s\n%d stacks - %d stacks in %s"
local alternateformat3 = "Next stack in %s\nHealing received -%d%%\nDamage taken +%d%%\n%d stacks - %d stacks in %s"
local buffformat4 = "Next stack in %s\n%d stacks"
local alternateformat4 = "Next stack in %s\nHealing received -%d%%\nDamage taken +%d%%\n%d stacks"
local buffformat5 = "Reached maximum stacks\n%d stacks"
local alternateformat5 = "Reached maximum stacks\nHealing received -%d%%\nDamage taken +%d%%\n%d stacks"

local function textUpdate(frame, stacks, killtime, time)
  if stacks == 0 then
    Stacks:SetText(frame.text, buffformat1, NS.formatTime(time), killStacks, NS.formatTime(killtime))
  elseif stacks == 1 then
    if
      (NS.db.global.maps.twinpeaks.showdebuffinfo and (NS.IS_TP or NS.IN_GAME == false))
      or (NS.db.global.maps.warsonggulch.showdebuffinfo and (NS.IS_WG or NS.IN_GAME == false))
    then
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
    if
      (NS.db.global.maps.twinpeaks.showdebuffinfo and (NS.IS_TP or NS.IN_GAME == false))
      or (NS.db.global.maps.warsonggulch.showdebuffinfo and (NS.IS_WG or NS.IN_GAME == false))
    then
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
  elseif stacks == maxStacks then
    if
      (NS.db.global.maps.twinpeaks.showdebuffinfo and (NS.IS_TP or NS.IN_GAME == false))
      or (NS.db.global.maps.warsonggulch.showdebuffinfo and (NS.IS_WG or NS.IN_GAME == false))
    then
      Stacks:SetText(frame.text, alternateformat5, stacks * healingDecrease, stacks * damageIncrease, stacks)
    else
      Stacks:SetText(frame.text, buffformat5, stacks)
    end
  else
    if
      (NS.db.global.maps.twinpeaks.showdebuffinfo and (NS.IS_TP or NS.IN_GAME == false))
      or (NS.db.global.maps.warsonggulch.showdebuffinfo and (NS.IS_WG or NS.IN_GAME == false))
    then
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
end

local function animationUpdate(frame, stacks, animationGroup)
  local t = GetTime()

  if t >= frame.exp then
    localStacks = localStacks + 1

    if localStacks == maxStacks then
      animationGroup:Stop()
      if
        (NS.db.global.maps.twinpeaks.showdebuffinfo and (NS.IS_TP or NS.IN_GAME == false))
        or (NS.db.global.maps.warsonggulch.showdebuffinfo and (NS.IS_WG or NS.IN_GAME == false))
      then
        Stacks:SetText(
          frame.text,
          alternateformat5,
          localStacks * healingDecrease,
          localStacks * damageIncrease,
          localStacks
        )
      else
        Stacks:SetText(frame.text, buffformat5, localStacks)
      end
    else
      Stacks:Start(NS.STACK_TIME, localStacks)
    end
  else
    local time = frame.exp - t
    frame.remaining = time

    local killtime = 0

    if stacks < killStacks then
      killtime = frame.killexp - t
      frame.killremaining = killtime
    end

    if stacks == maxStacks then
      animationGroup:Stop()
      if
        (NS.db.global.maps.twinpeaks.showdebuffinfo and (NS.IS_TP or NS.IN_GAME == false))
        or (NS.db.global.maps.warsonggulch.showdebuffinfo and (NS.IS_WG or NS.IN_GAME == false))
      then
        Stacks:SetText(frame.text, alternateformat5, stacks * healingDecrease, stacks * damageIncrease, stacks)
      else
        Stacks:SetText(frame.text, buffformat5, stacks)
      end
    else
      textUpdate(frame, stacks, killtime, time)
    end
  end
end

function Stacks:Start(duration, stacks)
  self:Stop(self.text, self.timerAnimationGroup)

  localStacks = stacks

  self.remaining = duration
  local time = self.remaining
  self.start = GetTime()
  self.exp = self.start + time

  local killtime = 0
  if stacks < killStacks then
    self.killremaining = NS.STACK_TIME * (killStacks - localStacks)
    killtime = self.killremaining
    self.killstart = GetTime()
    self.killexp = self.killstart + killtime
  end

  textUpdate(self, localStacks, killtime, time)

  self:SetFont(self.text)
  self.frame:SetAlpha(1)
  self.text:Show()

  self.timerAnimationGroup:SetScript("OnLoop", function(updatedGroup)
    if updatedGroup then
      animationUpdate(Stacks, stacks, updatedGroup)
    end
  end)

  self.timerAnimationGroup:Play()
end

function Stacks:Create(anchor)
  if not Stacks.frame then
    local Text = StacksFrame:CreateFontString(nil, "ARTWORK")
    self:SetFont(Text)
    Text:SetAllPoints()
    Text:SetTextColor(1, 1, 1, 1)
    Text:SetShadowOffset(0, 0)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("LEFT")
    Text:SetJustifyV("TOP")

    StacksFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)

    Stacks.frame = StacksFrame
    Stacks.text = Text
    Stacks.timerAnimationGroup = NS.CreateTimerAnimation(StacksFrame)
  end
end
