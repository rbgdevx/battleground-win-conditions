local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub
local GetTime = GetTime
local next = next

local mmin = math.min
local mmax = math.max
-- local mceil = math.ceil
local sformat = string.format

local Info = NS.Info
local Banner = NS.Banner

local SharedMedia = LibStub("LibSharedMedia-3.0")

local Bases = {}
NS.Bases = Bases

local BasesFrame = CreateFrame("Frame", AddonName .. "BasesFrame", Info.frame)
Bases.frame = BasesFrame

function Bases:SetAnchor(anchor, x, y)
  self.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
end

function Bases:SetText(frame, format, ...)
  frame:SetFormattedText(format, ...)
  NS.UpdateSize(BasesFrame, frame)
end

function Bases:SetTextColor(frame, color)
  frame:SetTextColor(color.r, color.g, color.b, color.a)
end

function Bases:SetFont(frame)
  frame:SetFont(
    SharedMedia:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "OUTLINE"
  )
  NS.UpdateSize(BasesFrame, frame)
end

function Bases:ToggleAlpha()
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
end

function Bases:Stop(frame, animationGroup)
  stopAnimation(frame, animationGroup)
end

local function winMessage(text, winCondition)
  local winTime = winCondition.winTime - GetTime()
  -- local winTicks = mceil(winTime / winCondition.tickRate)
  local ownTime = winCondition.ownTime - GetTime()
  -- local ownTicks = mceil(ownTime / winCondition.tickRate)
  local winName = winCondition.winName
  local loseName = winCondition.loseName
  local winMinBases = winCondition.minBases
  local maxBases = winCondition.maxBases
  local maxWinMinBases = winMinBases - 1 <= 0 and 1 or winMinBases - 1
  local capBases = winCondition.bases
  local loseBases = winCondition.loseBases
  local message = ""

  if winMinBases == 1 and ownTime <= 0 then
    message = sformat("%s win\n", NS.formatTeamName(winName, NS.PLAYER_FACTION))
  else
    if NS.WIN_INC_BASE_COUNT > 0 and NS.ACTIVE_BASE_COUNT == maxBases and capBases == winMinBases + 1 then
      message = sformat("%s win with %d after cap\n", NS.formatTeamName(winName, NS.PLAYER_FACTION), winMinBases)
    else
      message = sformat("%s win with %d right now\n", NS.formatTeamName(winName, NS.PLAYER_FACTION), winMinBases)
    end

    if
      winMinBases == 1 and capBases == winMinBases + 1 and loseBases == 0
      or (NS.WIN_INC_BASE_COUNT > 0 and capBases == winMinBases + 1)
      or (NS.ACTIVE_BASE_COUNT < maxBases and winMinBases == 1 and capBases < maxBases)
      or (NS.INCOMING_BASE_COUNT > 0 and NS.ACTIVE_BASE_COUNT == maxBases and loseBases == 0)
    then
      message = message
        .. sformat("%s can still win with %d\n", NS.formatTeamName(loseName, NS.PLAYER_FACTION), capBases)
    end

    if winMinBases == 1 then
      message = message .. sformat("Hold %d for %s to win\n", winMinBases, NS.formatTime(winTime))
    else
      message = message
        .. sformat("Hold %d for %s to win with %d\n", winMinBases, NS.formatTime(ownTime), maxWinMinBases)
    end
  end

  Bases:SetText(text, "%s", message)
end

local function loseMessage(text, winCondition)
  local ownTime = winCondition.ownTime - GetTime()
  local capTime = winCondition.capTime - GetTime()
  -- local capTicks = mceil(capTime / winCondition.tickRate)
  local capBases = winCondition.bases
  local maxBases = winCondition.maxBases
  local capScore = winCondition.capScore
  local winName = winCondition.winName
  local loseName = winCondition.loseName
  local message = ""

  if capBases == maxBases and ownTime <= 0 then
    message = sformat("%s lose\n", NS.formatTeamName(loseName, NS.PLAYER_FACTION))
  else
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
  end

  Bases:SetText(text, "%s", message)
end

local function animationUpdate(frame, winTable, animationGroup, callbackFn)
  local t = GetTime()

  if t >= frame.exp then
    if animationGroup then
      animationGroup:Stop()
    end
    -- frame.text:Hide()
    return
  end

  local time = frame.exp - t
  frame.remaining = time

  local winCondition
  local ownTime

  local firstKey = next(winTable)
  if firstKey and winTable[firstKey] then
    winCondition = winTable[firstKey]
    ownTime = winCondition.ownTime - t
    -- local ownTicks = mceil(ownTime / winCondition.tickRate)

    -- 5
    if ownTime > 0 or winCondition.bases == winCondition.maxBases then
      if winCondition.winName == NS.PLAYER_FACTION then
        winMessage(frame.text, winCondition)
      else
        loseMessage(frame.text, winCondition)
      end
    else
      if NS.IN_GAME and NS.BASE_TIMER_EXPIRED == false then
        NS.BASE_TIMER_EXPIRED = true

        if callbackFn then
          callbackFn:BasePredictor(true)
        end
      else
        local secondKey = winCondition.bases + 1
        if secondKey and winTable[secondKey] then
          winCondition = winTable[secondKey]
          ownTime = winCondition.ownTime - t
          -- ownTicks = mceil(ownTime / winCondition.tickRate)

          -- 4
          if ownTime > 0 or winCondition.bases == winCondition.maxBases then
            if winCondition.winName == NS.PLAYER_FACTION then
              winMessage(frame.text, winCondition)
            else
              loseMessage(frame.text, winCondition)
            end
          else
            local thirdKey = winCondition.bases + 1
            if thirdKey and winTable[thirdKey] then
              winCondition = winTable[thirdKey]
              ownTime = winCondition.ownTime - t
              -- ownTicks = mceil(ownTime / winCondition.tickRate)

              -- 3
              if ownTime > 0 or winCondition.bases == winCondition.maxBases then
                if winCondition.winName == NS.PLAYER_FACTION then
                  winMessage(frame.text, winCondition)
                else
                  loseMessage(frame.text, winCondition)
                end
              else
                local fourthKey = winCondition.bases + 1
                if fourthKey and winTable[fourthKey] then
                  winCondition = winTable[fourthKey]
                  ownTime = winCondition.ownTime - t
                  -- ownTicks = mceil(ownTime / winCondition.tickRate)

                  -- 2
                  if ownTime > 0 or winCondition.bases == winCondition.maxBases then
                    if winCondition.winName == NS.PLAYER_FACTION then
                      winMessage(frame.text, winCondition)
                    else
                      loseMessage(frame.text, winCondition)
                    end
                  else
                    local fifthKey = winCondition.bases + 1
                    if fifthKey and winTable[fifthKey] then
                      winCondition = winTable[fifthKey]
                      ownTime = winCondition.ownTime - t
                      -- ownTicks = mceil(ownTime / winCondition.tickRate)

                      -- 1
                      if ownTime > 0 or winCondition.bases == winCondition.maxBases then
                        if winCondition.winName == NS.PLAYER_FACTION then
                          winMessage(frame.text, winCondition)
                        else
                          loseMessage(frame.text, winCondition)
                        end
                      else
                        NS.Debug("NO OPTIONS LEFT")
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

  -- frame.text:Show()
end

function Bases:Start(duration, winTable, callbackFn)
  self:Stop(self, self.timerAnimationGroup)

  self.remaining = mmin(mmax(0, duration), 1500)
  local time = self.remaining
  self.start = GetTime()
  self.exp = self.start + time

  self:SetFont(self.text)

  local firstKey = next(winTable)
  if firstKey and winTable[firstKey] then
    local winCondition = winTable[firstKey]

    if winCondition.winName == NS.PLAYER_FACTION then
      winMessage(self.text, winCondition)
    else
      loseMessage(self.text, winCondition)
    end

    if NS.db.global.general.banner == false then
      self.frame:SetAlpha(1)

      if NS.db.global.general.infogroup.infobg then
        NS.UpdateInfoSize(Info.frame, Banner)
      end
    else
      self.frame:SetAlpha(0)
    end

    NS.BASE_TIMER_EXPIRED = false

    self.timerAnimationGroup:SetScript("OnLoop", function(updatedGroup)
      if updatedGroup then
        animationUpdate(self, winTable, updatedGroup, callbackFn)
      end
    end)

    self.timerAnimationGroup:Play()
  end
end

function Bases:Create(anchor)
  if not Bases.text then
    local Text = BasesFrame:CreateFontString(nil, "ARTWORK")
    Text:SetAllPoints()
    self:SetFont(Text)
    self:SetTextColor(Text, NS.db.global.general.infogroup.infotextcolor)
    Text:SetShadowOffset(0, 0)
    Text:SetShadowColor(0, 0, 0, 1)
    Text:SetJustifyH("LEFT")
    Text:SetJustifyV("TOP")

    BasesFrame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -5)
    BasesFrame:SetAlpha(0)

    Bases.text = Text
    Bases.timerAnimationGroup = NS.CreateTimerAnimation(BasesFrame)
  end
end
