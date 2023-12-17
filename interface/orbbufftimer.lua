local _, NS = ...

local OrbBuffTimer = {}
NS.OrbBuffTimer = OrbBuffTimer
NS.buffCache = NS.buffCache or {}

local barPrototype_meta = NS.barPrototype_mt
local buffCache = NS.buffCache

local next = next
local GetTime = GetTime
local CreateFrame = CreateFrame
local setmetatable = setmetatable

local mmin = math.min
local mmax = math.max

function OrbBuffTimer:SetDuration(bar, duration)
  bar.remaining = mmin(mmax(0, duration), 1500)
end

function OrbBuffTimer:Create(label, anchor)
  local bar = next(buffCache)
  if not bar then
    local frame = CreateFrame("Frame", nil, UIParent)
    bar = setmetatable(frame, barPrototype_meta)

    bar.label = label

    local text = bar:CreateFontString(nil, "ARTWORK")
    text:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, 0)
    bar.text = text

    local updater = bar:CreateAnimationGroup()
    updater:SetLooping("REPEAT")
    updater.parent = bar

    local anim = updater:CreateAnimation()
    anim:SetDuration(0.04)

    bar.updater = updater
    bar.repeater = anim
  else
    buffCache[bar] = nil
  end

  bar:SetFrameStrata("MEDIUM")
  bar:SetFrameLevel(100)
  bar:ClearAllPoints()
  bar:SetMovable(false)
  bar:SetScale(1)
  bar:SetAlpha(1)
  bar:SetClampedToScreen(false)
  bar:EnableMouse(false)

  return bar
end

local function stopBuff(bar)
  bar.updater:Stop()
  bar.data = nil
  bar.funcs = nil
  bar.running = nil
  bar.paused = nil
  bar:Hide()
  bar:SetParent(UIParent)
  buffCache[bar] = true
end

function OrbBuffTimer:Stop(bar)
  stopBuff(bar)
  buffCache[bar] = true
end

local buffformat1 = "%s get 4x points in %s"
local buffformat2 = "%s are earning 4x points"

local function buffUpdate(updater)
  local bar = updater.parent
  local t = GetTime()
  if t >= bar.exp then
    bar.updater:Stop()
    bar.running = nil
    bar.paused = nil
    bar.text:SetFormattedText(buffformat2, bar.winTeam)
    -- bar:Hide()
    -- bar:SetParent(UIParent)
  else
    local time = bar.exp - t
    bar.remaining = time
    bar.text:SetFormattedText(buffformat1, bar.winTeam, NS.formatTime(time))
  end
end

function OrbBuffTimer:Start(bar, winTeam)
  bar.running = true
  local time = bar.remaining
  bar.gap = 0
  bar.start = GetTime()
  bar.exp = bar.start + time
  bar.winTeam = winTeam

  bar.text:SetFormattedText(buffformat1, bar.winTeam, NS.formatTime(time))

  bar.updater:SetScript("OnLoop", buffUpdate)
  bar.updater:Play()

  bar:Show()
end

function OrbBuffTimer:HideBuff(bar)
  bar:SetAlpha(0)
end

function OrbBuffTimer:ShowBuff(bar)
  bar:SetAlpha(1)
end

function OrbBuffTimer:UpdateBuff(bar, remaining, winTeam)
  self:Stop(bar)
  self:SetDuration(bar, remaining)
  self:Start(bar, winTeam)
end

function OrbBuffTimer:StopBuff(bar)
  self:Stop(bar)
end
