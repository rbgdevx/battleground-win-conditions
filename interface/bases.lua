local AddonName, NS = ...

local CreateFrame = CreateFrame
local LibStub = LibStub
local GetTime = GetTime

local mmin = math.min
local mmax = math.max
local sformat = string.format

local Info = NS.Info
local Banner = NS.Banner

local LSM = LibStub("LibSharedMedia-3.0")

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
    LSM:Fetch("font", NS.db.global.general.infogroup.infofont),
    NS.db.global.general.infogroup.infofontsize,
    "THINOUTLINE"
  )
  NS.UpdateSize(BasesFrame, frame)
end

function Bases:ToggleAlpha()
  local curAlpha = self.frame:GetAlpha()
  local newAlpha = curAlpha == 0 and 1 or 0
  self.frame:SetAlpha(newAlpha)
end

local function stopAnimation(frame, animationGroup)
  animationGroup:Stop()
  frame.frame:SetAlpha(0)
  frame.text:SetFormattedText("")
end

function Bases:Stop(frame, animationGroup)
  stopAnimation(frame, animationGroup)
end

local function winMessage(text, winCondition)
  local winTime = winCondition.winTime - GetTime()
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
      message = message .. sformat("Hold %d for %s to win\n", winMinBases, NS.formatTime(winTime))
    else
      message = message
        .. sformat("Hold %d for %s to win with %d\n", winMinBases, NS.formatTime(ownTime), maxWinMinBases)
    end
  end

  Bases:SetText(text, "%s", message)
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

  Bases:SetText(text, "%s", message)
end

local function animationUpdate(frame, winTable, animationGroup)
  local t = GetTime()
  local winCondition

  local firstKey = next(winTable)
  if firstKey and winTable[firstKey] then
    winCondition = winTable[firstKey]
  end

  if t >= frame.exp then
    animationGroup:Stop()
    -- frame.text:Hide()
  else
    local time = frame.exp - t
    frame.remaining = time
    if firstKey and winCondition then
      local ownTime = winCondition.ownTime - t

      -- 2
      if ownTime > 0 then
        if winCondition.winName == NS.PLAYER_FACTION then
          winMessage(frame.text, winCondition)
        else
          loseMessage(frame.text, winCondition)
        end
      elseif winCondition.bases == winCondition.maxBases then
        if winCondition.winName == NS.PLAYER_FACTION then
          winMessage(frame.text, winCondition)
        else
          loseMessage(frame.text, winCondition)
        end
      else
        local secondKey = winCondition.bases + 1
        if secondKey and winTable[secondKey] then
          winCondition = winTable[secondKey]
          ownTime = winCondition.ownTime - t

          -- 3
          if ownTime > 0 then
            if winCondition.winName == NS.PLAYER_FACTION then
              winMessage(frame.text, winCondition)
            else
              loseMessage(frame.text, winCondition)
            end
          elseif winCondition.bases == winCondition.maxBases then
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

              -- 4
              if ownTime > 0 then
                if winCondition.winName == NS.PLAYER_FACTION then
                  winMessage(frame.text, winCondition)
                else
                  loseMessage(frame.text, winCondition)
                end
              elseif winCondition.bases == winCondition.maxBases then
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

                  -- 5
                  if ownTime > 0 then
                    if winCondition.winName == NS.PLAYER_FACTION then
                      winMessage(frame.text, winCondition)
                    else
                      loseMessage(frame.text, winCondition)
                    end
                  elseif winCondition.bases == winCondition.maxBases then
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

                      -- 6
                      if ownTime > 0 then
                        if winCondition.winName == NS.PLAYER_FACTION then
                          winMessage(frame.text, winCondition)
                        else
                          loseMessage(frame.text, winCondition)
                        end
                      elseif winCondition.bases == winCondition.maxBases then
                        if winCondition.winName == NS.PLAYER_FACTION then
                          winMessage(frame.text, winCondition)
                        else
                          loseMessage(frame.text, winCondition)
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
    -- frame.text:Show()
  end
end

function Bases:Start(duration, winTable)
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
        NS.UpdateContainerSize(Info.frame, Banner)
      end
    else
      self.frame:SetAlpha(0)
    end

    self.timerAnimationGroup:SetScript("OnLoop", function(updatedGroup)
      if updatedGroup then
        animationUpdate(Bases, winTable, updatedGroup)
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
