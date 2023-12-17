local _, NS = ...

local WinInfo = {}
NS.WinInfo = WinInfo
NS.infoCache = NS.infoCache or {}

local barPrototype_meta = NS.barPrototype_mt
local infoCache = NS.infoCache

local next = next
local GetTime = GetTime
local CreateFrame = CreateFrame
local setmetatable = setmetatable

local mmin = math.min
local mmax = math.max
local sformat = string.format

function WinInfo:SetDuration(bar, duration)
  bar.remaining = mmin(mmax(0, duration), 1500)
end

function WinInfo:Create(label, anchor)
  local bar = next(infoCache)
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
    infoCache[bar] = nil
  end

  bar:SetFrameStrata("MEDIUM")
  bar:SetFrameLevel(100) -- Lots of room to create above or below this level
  bar:ClearAllPoints()
  bar:SetMovable(false)
  bar:SetScale(1)
  bar:SetAlpha(1)
  bar:SetClampedToScreen(false)
  bar:EnableMouse(false)

  return bar
end

local function stopInfo(bar)
  bar.updater:Stop()
  bar.data = nil
  bar.funcs = nil
  bar.running = nil
  bar.paused = nil
  bar:Hide()
  bar:SetParent(UIParent)
  infoCache[bar] = true
end

function WinInfo:Stop(bar)
  stopInfo(bar)
  infoCache[bar] = true
end

local function winMessage(text, winCondition)
  local ownTime = winCondition.ownTime - GetTime()
  local winName = winCondition.winName
  local winMinBases = winCondition.minBases
  local maxWinMinBases = winMinBases - 1 <= 0 and 1 or winMinBases - 1
  local message = ""

  if ownTime <= 0 then
    message = sformat("%s win\n", NS.formatTeamName(winName, NS.PLAYER_FACTION))
  else
    message = sformat("%s win with %d right now\n", NS.formatTeamName(winName, NS.PLAYER_FACTION), winMinBases)

    if winMinBases == 1 then
      message = message .. sformat("Hold %d for %s to win\n", winMinBases, NS.formatTime(ownTime))
    else
      message = message
        .. sformat("Hold %d for %s to win with %d\n", winMinBases, NS.formatTime(ownTime), maxWinMinBases)
    end
  end

  text:SetFormattedText(message)
end

local function loseMessage(text, winCondition)
  local capTime = winCondition.capTime - GetTime()
  local capBases = winCondition.bases
  local capScore = winCondition.capScore
  local winName = winCondition.winName
  local loseName = winCondition.loseName
  local message = ""

  message = message
    .. sformat(
      "%s need %d by %s\n",
      NS.formatTeamName(loseName, NS.PLAYER_FACTION),
      capBases,
      NS.formatScore(winName, capScore)
    )

  if capTime <= 0 then
    message = message .. sformat("Not enough cap time\n")
  else
    message = message .. sformat("Cap within %s\n", NS.formatTime(capTime))
  end

  text:SetFormattedText(message)
end

local function infoUpdate(updater)
  local bar = updater.parent
  local t = GetTime()
  local winCondition

  local firstKey, _ = next(bar.winTable)
  if firstKey and bar.winTable[firstKey] then
    winCondition = bar.winTable[firstKey]
  end

  if t >= bar.exp then
    bar.updater:Stop()
    bar.running = nil
    bar.paused = nil
    -- bar:Hide()
    -- bar:SetParent(UIParent)
  else
    local time = bar.exp - t
    bar.remaining = time

    if firstKey and winCondition then
      local ownTime = winCondition.ownTime - t

      -- 2
      if ownTime > 0 then
        if winCondition.winName == NS.PLAYER_FACTION then
          winMessage(bar.text, winCondition)
        else
          loseMessage(bar.text, winCondition)
        end
      elseif winCondition.bases == winCondition.maxBases then
        if winCondition.winName == NS.PLAYER_FACTION then
          winMessage(bar.text, winCondition)
        else
          loseMessage(bar.text, winCondition)
        end
      else
        local secondKey = winCondition.bases + 1
        if secondKey and bar.winTable[secondKey] then
          winCondition = bar.winTable[secondKey]
          ownTime = winCondition.ownTime - t

          -- 3
          if ownTime > 0 then
            if winCondition.winName == NS.PLAYER_FACTION then
              winMessage(bar.text, winCondition)
            else
              loseMessage(bar.text, winCondition)
            end
          elseif winCondition.bases == winCondition.maxBases then
            if winCondition.winName == NS.PLAYER_FACTION then
              winMessage(bar.text, winCondition)
            else
              loseMessage(bar.text, winCondition)
            end
          else
            local thirdKey = winCondition.bases + 1
            if thirdKey and bar.winTable[thirdKey] then
              winCondition = bar.winTable[thirdKey]
              ownTime = winCondition.ownTime - t

              -- 4
              if ownTime > 0 then
                if winCondition.winName == NS.PLAYER_FACTION then
                  winMessage(bar.text, winCondition)
                else
                  loseMessage(bar.text, winCondition)
                end
              elseif winCondition.bases == winCondition.maxBases then
                if winCondition.winName == NS.PLAYER_FACTION then
                  winMessage(bar.text, winCondition)
                else
                  loseMessage(bar.text, winCondition)
                end
              else
                local fourthKey = winCondition.bases + 1
                if fourthKey and bar.winTable[fourthKey] then
                  winCondition = bar.winTable[fourthKey]
                  ownTime = winCondition.ownTime - t

                  -- 5
                  if ownTime > 0 then
                    if winCondition.winName == NS.PLAYER_FACTION then
                      winMessage(bar.text, winCondition)
                    else
                      loseMessage(bar.text, winCondition)
                    end
                  elseif winCondition.bases == winCondition.maxBases then
                    if winCondition.winName == NS.PLAYER_FACTION then
                      winMessage(bar.text, winCondition)
                    else
                      loseMessage(bar.text, winCondition)
                    end
                  else
                    local fifthKey = winCondition.bases + 1
                    if fifthKey and bar.winTable[fifthKey] then
                      winCondition = bar.winTable[fifthKey]
                      ownTime = winCondition.ownTime - t

                      -- 6
                      if ownTime > 0 then
                        if winCondition.winName == NS.PLAYER_FACTION then
                          winMessage(bar.text, winCondition)
                        else
                          loseMessage(bar.text, winCondition)
                        end
                      elseif winCondition.bases == winCondition.maxBases then
                        if winCondition.winName == NS.PLAYER_FACTION then
                          winMessage(bar.text, winCondition)
                        else
                          loseMessage(bar.text, winCondition)
                        end
                      else
                        -- print("NO OPTIONS LEFT")
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

function WinInfo:Start(bar, winTable)
  bar.running = true
  local time = bar.remaining
  bar.gap = 0
  bar.start = GetTime()
  bar.exp = bar.start + time
  bar.winTable = winTable

  local firstKey, _ = next(winTable)
  if firstKey and winTable[firstKey] then
    local winCondition = winTable[firstKey]

    if winCondition.winName == NS.WIN_NOUN then
      winMessage(bar.text, winCondition)
    else
      loseMessage(bar.text, winCondition)
    end

    bar.updater:SetScript("OnLoop", infoUpdate)
    bar.updater:Play()

    if NS.db.banner == false then
      bar:Show()
    end
  end
end

function WinInfo:HideInfo(bar)
  bar:Hide()
end

function WinInfo:ShowInfo(bar)
  bar:Show()
end

function WinInfo:UpdateInfo(bar, remaining, winTable)
  self:Stop(bar)
  self:SetDuration(bar, remaining)
  self:Start(bar, winTable)
end

function WinInfo:StopInfo(bar)
  self:Stop(bar)
end
