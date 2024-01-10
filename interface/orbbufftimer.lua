local _, NS = ...

local OrbBuffTimer = {}
NS.OrbBuffTimer = OrbBuffTimer
NS.buffCache = NS.buffCache or {}

local buffCache = NS.buffCache

local next = next
local GetTime = GetTime
local CreateFrame = CreateFrame

local mmin = math.min
local mmax = math.max

function OrbBuffTimer:SetDuration(bar, duration)
  bar.remaining = mmin(mmax(0, duration), 1500)
end

function OrbBuffTimer:Create(label, anchor)
  local bar = next(buffCache)

  if not bar then
    local frame = CreateFrame("Frame", "BGWCOrbBuffTimerFrame", UIParent)
    bar = {}

    bar.label = label

    local text = frame:CreateFontString(nil, "ARTWORK")
    text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    bar.text = text

    local updater = frame:CreateAnimationGroup()
    updater:SetLooping("REPEAT")
    -- updater.parent = bar

    local anim = updater:CreateAnimation()
    anim:SetDuration(0.05)

    bar.updater = updater
    bar.frame = frame
  else
    buffCache[bar] = nil
  end

  bar.frame:SetFrameStrata("MEDIUM")
  bar.frame:SetFrameLevel(100)
  bar.frame:ClearAllPoints()
  bar.frame:SetMovable(false)
  bar.frame:SetScale(1)
  bar.frame:SetAlpha(1)
  bar.frame:SetClampedToScreen(false)
  bar.frame:EnableMouse(false)

  return bar
end

local function stopBuff(bar)
  bar.updater:Stop()
  bar.frame:Hide()
  bar.frame:SetParent(UIParent)
  buffCache[bar] = true
end

function OrbBuffTimer:Stop(bar)
  stopBuff(bar)
  buffCache[bar] = true
end

local buffformat1 = "%s get 4x points in %s"
local buffformat2 = "%s are earning 4x points"

local function buffUpdate(bar, winTeam, updater)
  local t = GetTime()
  if t >= bar.exp then
    bar.updater:Stop()
    bar.text:SetFormattedText(buffformat2, winTeam)
    -- bar.frame:Hide()
    -- bar.frame:SetParent(UIParent)
  else
    local time = bar.exp - t
    bar.remaining = time
    bar.text:SetFormattedText(buffformat1, winTeam, NS.formatTime(time))
  end
end

function OrbBuffTimer:Start(bar, winTeam)
  local time = bar.remaining
  bar.start = GetTime()
  bar.exp = bar.start + time

  bar.text:SetFormattedText(buffformat1, winTeam, NS.formatTime(time))

  bar.frame:Show()

  bar.updater:SetScript("OnLoop", function(updater)
    buffUpdate(bar, winTeam, updater)
  end)

  bar.updater:Play()
end

function OrbBuffTimer:HideBuff(bar)
  if bar.frame then
    bar.frame:SetAlpha(0)
  end
end

function OrbBuffTimer:ShowBuff(bar)
  if bar.frame then
    bar.frame:SetAlpha(1)
  end
end

function OrbBuffTimer:UpdateBuff(bar, remaining, winTeam)
  self:Stop(bar)
  self:SetDuration(bar, remaining)
  self:Start(bar, winTeam)
end

function OrbBuffTimer:StopBuff(bar)
  self:Stop(bar)
end
