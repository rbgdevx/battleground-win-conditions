local _, NS = ...

local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local GetTime = GetTime
local print = print
local format = format
local type = type
local next = next
local select = select
local setmetatable = setmetatable
local getmetatable = getmetatable
local GetInstanceInfo = GetInstanceInfo
local GetNumGroupMembers = GetNumGroupMembers
local GetRealmName = GetRealmName
local UnitName = UnitName

local sformat = string.format
local mfloor = math.floor
local mceil = math.ceil
local mmin = math.min
local mmax = math.max
local tinsert = table.insert
local tsort = table.sort
local twipe = table.wipe

local IsSoloRBG = C_PvP.IsSoloRBG

NS.secondsToMinutes = function(seconds)
  return seconds / SECONDS_PER_MIN
end

NS.minutesToSeconds = function(minutes)
  return minutes * SECONDS_PER_MIN
end

function ConvertSecondsToUnits(timestamp)
  timestamp = mmax(timestamp, 0)
  local days = mfloor(timestamp / SECONDS_PER_DAY)
  timestamp = timestamp - (days * SECONDS_PER_DAY)
  local hours = mfloor(timestamp / SECONDS_PER_HOUR)
  timestamp = timestamp - (hours * SECONDS_PER_HOUR)
  local minutes = mfloor(timestamp / SECONDS_PER_MIN)
  timestamp = timestamp - (minutes * SECONDS_PER_MIN)
  local seconds = mfloor(timestamp)
  local milliseconds = timestamp - seconds
  return {
    days = days,
    hours = hours,
    minutes = minutes,
    seconds = seconds,
    milliseconds = milliseconds,
  }
end

NS.secondsToClock = function(seconds, displayZeroHours)
  local units = ConvertSecondsToUnits(seconds)
  if units.hours > 0 or displayZeroHours then
    return format(HOURS_MINUTES_SECONDS, units.hours, units.minutes, units.seconds)
  else
    return format(MINUTES_SECONDS, units.minutes, units.seconds)
  end
end

NS.getSeconds = function(time)
  return time % SECONDS_PER_MIN
end

NS.getMinutes = function(time)
  return mfloor(time / SECONDS_PER_MIN)
end

NS.formatTime = function(time)
  return NS.secondsToClock(time, false)
  -- return sformat("%02d:%02d", NS.getMinutes(time), NS.getSeconds(time))
end

NS.isArathi = function(zoneID)
  if zoneID == 1366 or zoneID == 1383 or zoneID == 837 then
    return true
  else
    return false
  end
end

NS.isDeepwind = function(zoneID)
  if zoneID == 1576 then
    return true
  else
    return false
  end
end

NS.isEOTS = function(zoneID)
  if zoneID == 112 or zoneID == 397 then
    return true
  else
    return false
  end
end

NS.isBlitz = function()
  local maxPlayers = select(5, GetInstanceInfo())
  local groupSize = GetNumGroupMembers()
  local isSolo = IsSoloRBG()

  local correctMaxPlayers = maxPlayers >= NS.DEFAULT_GROUP_SIZE
  local correctGroupSize = groupSize > NS.MIN_GROUP_SIZE
  local correctGameMode = not isSolo

  return not (correctMaxPlayers or correctGroupSize or correctGameMode)

  -- if maxPlayers >= NS.DEFAULT_GROUP_SIZE or groupSize > NS.MIN_GROUP_SIZE or not isSolo then
  -- 	return false
  -- else
  -- 	return true
  -- end
end

local formatToAlliance = function(string)
  return sformat("\124cff00AAFF%s\124r", string)
end

local formatToHorde = function(string)
  return sformat("\124cffFF0000%s\124r", string)
end

NS.formatTextByFaction = function(faction, string)
  if faction == NS.ALLIANCE_NAME then
    return formatToAlliance(string)
  else
    return formatToHorde(string)
  end
end

NS.formatScore = function(team, score)
  if team == NS.ALLIANCE_NAME then
    return formatToAlliance(tostring(mfloor(score)))
  elseif team == NS.HORDE_NAME then
    return formatToHorde(tostring(mfloor(score)))
  else
    return mfloor(score)
  end
end

NS.GetUnitNameAndRealm = function(unit)
  local name, realm = UnitName(unit)
  local nameAndRealm = realm and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())
  return nameAndRealm
end

NS.getCorrectName = function(team, faction)
  if team == faction then
    return NS.WIN_NOUN
  else
    return NS.LOSE_NOUN
  end
end

NS.formatTeamName = function(team, faction)
  if team == NS.ALLIANCE_NAME then
    return formatToAlliance(NS.getCorrectName(team, faction))
  elseif team == NS.HORDE_NAME then
    return formatToHorde(NS.getCorrectName(team, faction))
  end
end

NS.getFinalScore = function(maxScore, score, fallbackScore, bases, incBases, win, winTicks, tickRate, points)
  local increase = tickRate * points
  local initialScore = win and maxScore or score + (winTicks * increase)
  local finalScore = (bases == 0 and incBases == 0) and fallbackScore or initialScore
  return mmin(finalScore, maxScore)
end

NS.getWinTicks = function(maxScore, score, tickRate, points)
  local increase = tickRate * points -- points per tick
  local remaining = maxScore - score -- points needed to max score
  local ticksToWin = increase == 0 and 10000 or mceil(remaining / increase)
  return mmin(ticksToWin, 10000)
end

NS.getWinTime = function(ticksToWin, tickRate)
  local timeToWin = ticksToWin == 10000 and ticksToWin or tickRate * ticksToWin -- convert ticks to seconds
  return mmin(timeToWin, 10000)
end

NS.getWinTimeIncrease = function() end

NS.calculateFlagsToCatchUp = function(maxScore, winScore, loseScore, winBases, loseBases, curMap)
  local flagValue = curMap.flagResources[loseBases]
  local flagsNeeded = 0

  for flags = 1, 20 do
    local potentialLoseTeamScore = loseScore + (flagValue * flags)
    local potentialWinTeamScore = winScore

    local loseTicksToWin =
      NS.getWinTicks(maxScore, potentialLoseTeamScore, curMap.tickRate, curMap.baseResources[loseBases])
    local winTicksToWin =
      NS.getWinTicks(maxScore, potentialWinTeamScore, curMap.tickRate, curMap.baseResources[winBases])

    if loseTicksToWin < winTicksToWin then
      flagsNeeded = flags
      break
    end
  end

  return mmin(mmax(1, flagsNeeded), 20)
end

NS.getWinMinBases = function(winBases, maxBases, needBases)
  local minBases = maxBases - needBases + 1
  if minBases > winBases then
    return winBases
  else
    return minBases
  end
end

NS.checkWinCondition = function(
  needBases,
  winBases,
  loseBases,
  winScore,
  loseScore,
  winName,
  loseName,
  winTime,
  winTicks,
  winTimeIncrease,
  maxBases,
  maxScore,
  oldWinTime,
  oldWinTicks,
  tickRate,
  resources,
  assaultTime,
  contestedTime
)
  local table = {}

  --[[
  -- we're assuming here the incoming bases have capped over and now looking forward
  -- to win conditions, not win conditions of active incoming and owned
  --
  -- we're also assuming the maximum amount of bases each team
  -- could have at any given time for each potential winning base amount
  -- to be sure they could win with X amount of bases
  --]]
  local potentialLoseTeamBaseCount = needBases
  local potentialWinTeamBaseCount = ((needBases + winBases) > maxBases) and maxBases - needBases or winBases

  local loseTeamGapScore = mceil(contestedTime / tickRate) * (tickRate * resources[loseBases])
  local winTeamGapScore = mceil(contestedTime / tickRate) * (tickRate * resources[potentialWinTeamBaseCount])
  local assaultScore = mceil(assaultTime / tickRate) * (tickRate * resources[winBases])

  --[[
  -- we need to look ahead in time to compare
  -- scores and win times at each point in time
  -- with any new potential bases from the lose team
  --]]
  for ticks = 0, winTicks, tickRate do
    local loseTeamScoreIncrease = ticks * (tickRate * resources[loseBases])
    local winTeamScoreIncrease = ticks * (tickRate * resources[winBases])

    --[[
    -- we need to add the current score
    -- with the score for this point in time
    -- plus whatever the gap score would be
    -- during a base change
    --]]
    local loseTeamScoreNow = loseScore + loseTeamScoreIncrease
    local winTeamScoreNow = winScore + winTeamScoreIncrease

    local loseGapScore = (oldWinTicks < mceil(contestedTime / tickRate)) and loseTeamScoreNow
      or loseTeamScoreNow + loseTeamGapScore
    local winGapScore = (oldWinTicks < mceil(contestedTime / tickRate)) and winTeamScoreNow
      or winTeamScoreNow + winTeamGapScore

    local loseTicksToWin = NS.getWinTicks(maxScore, loseGapScore, tickRate, resources[potentialLoseTeamBaseCount])
    local winTicksToWin = NS.getWinTicks(maxScore, winGapScore, tickRate, resources[potentialWinTeamBaseCount])

    if loseTicksToWin < winTicksToWin and winTeamScoreNow < maxScore then
      local time = ticks * tickRate
      --[[
      -- we need add the pending time of the current incoming
      -- bases since they actually haven't capped over yet
      --]]
      local ownTime = time + winTimeIncrease
      local ownTicks = mceil(ownTime / tickRate)
      --[[
      -- we need to accomodate for the assault time
      --]]
      local capTime = ownTime - assaultTime
      local capTicks = mceil(capTime / tickRate)
      --[[
      -- we need to subtract the gap score from the score
      -- you need to get the base by because we were just looking
      -- ahead to see had you got that base would you win
      -- so this is that score you need prior to having a gap to be had
      --]]
      local ownScore = winTeamScoreNow
      --[[
      -- we need to subtract the score they'll be earning during cap time
      -- as well, so thats 5 more seconds of score
      --]]
      local capScore = ownScore - assaultScore
      --[[
      -- We need to calculate the minimum bases the winning team
      -- wins with and store it for later
      --]]
      local minBases = NS.getWinMinBases(winBases, maxBases, potentialLoseTeamBaseCount)

      table[potentialLoseTeamBaseCount] = {
        --[[
        -- the amount of bases you need to get to win
        --]]
        bases = potentialLoseTeamBaseCount,
        minBases = minBases,
        maxBases = maxBases,
        --[[
        -- we add the gap score from the score to know when
        -- you need to get the base by
        --]]
        ownScore = ownScore,
        --[[
        -- we need to subtract the gap score from the score
        -- you need to get the base by because we were just looking
        -- ahead to see had you got that base would you win
        -- so this is that score you need prior to having a gap to be had
        --]]
        capScore = capScore,
        --[[
        -- we need add the pending time of the current incoming
        -- bases since they actually haven't capped over yet
        --]]
        ownTime = ownTime + GetTime(),
        ownTicks = ownTicks,
        --[[
        -- we need to accommodate for the assault time to get by this time
        -- as well as the cap time
        --]]
        capTime = capTime + GetTime(),
        capTicks = capTicks,
        --[[
        -- we need to accommodate for the assault time to get by this time
        -- as well as the cap time
        --]]
        winTime = winTime + GetTime(), -- mmin(mmax(0, winTime), 1500) + GetTime(),
        winTicks = winTicks, -- mmin(mmax(0, winTicks), mceil(1500 / tickRate)),
        --[[
        -- who wins and loses
        --]]
        winName = winName,
        loseName = loseName,
        loseBases = loseBases,
        tickRate = tickRate,
      }
    end
  end

  return table
end

NS.getIncomingBaseInfo = function(timers, ownedBases, incomingBases, resources, tickRate, winTicks)
  local baseIncrease = 0
  local scoreIncrease = 0
  local tickIncrease = 0
  local previousTime = 0
  local previousTicks = 0
  if timers and incomingBases > 0 then
    local timersSorted = {}
    for key, value in pairs(timers) do
      if value then
        if value - GetTime() > 0 then
          tinsert(timersSorted, key)
        end
      end
    end
    tsort(timersSorted, function(a, b)
      return timers[a] - GetTime() < timers[b] - GetTime()
    end)
    for index, key in ipairs(timersSorted) do
      if key then
        local timeLeft = timers[key] - GetTime()
        if timeLeft and timeLeft > 0 then
          local ticksLeft = mceil(timeLeft / tickRate)
          if ticksLeft < winTicks then
            --[[
            -- we need to subtract 1 from each incoming base + current bases
            -- in order to calculate what we'll gain while each incoming
            -- base is contested and not earning points
            --]]
            local newBases = ownedBases + index - 1
            --[[
            -- we need to calculate the time difference between
            -- one incoming base and the next to know
            -- how much time we have earning points with each
            -- base until the next one caps over
            --]]
            -- local newTime = timeLeft - previousTime
            local newTicks = ticksLeft - previousTicks
            --[[
            -- we need to get the point values for prior base count to
            -- each incoming base
            -- this will render 1 then 1.5 since we have 1 owned, and 2 incoming
            -- 1 point is for 1 base (2-1) and 1.5 is for 2 bases (3-1)
            --]]
            local newPoints = newTicks * (tickRate * resources[newBases])
            --[[
            -- this is a way to store up our total time
            -- spent capping over incoming bases
            --]]
            baseIncrease = index
            scoreIncrease = scoreIncrease + newPoints
            tickIncrease = tickIncrease + newTicks
            --[[
            -- setting previous values last so our initial
            -- values are 0 when used the first time
            --]]
            previousTime = timeLeft
            previousTicks = mceil(previousTime / tickRate)
          end
        end
      end
    end
  end
  return baseIncrease, scoreIncrease, tickIncrease
end

NS.write = function(...)
  print(NS.userClassHexColor .. "BattlegroundWinConditions|r: ", ...)
end

NS.Debug = function(...)
  if NS.db and NS.db.global.debug then
    print(...)
  end
end

NS.CreateTimerAnimation = function(frame)
  local TimerAnimationGroup = frame:CreateAnimationGroup()
  TimerAnimationGroup:SetLooping("REPEAT")

  local TimerAnimation = TimerAnimationGroup:CreateAnimation()
  TimerAnimation:SetDuration(0.05)

  return TimerAnimationGroup
end

NS.UpdateSize = function(frame, text)
  frame:SetWidth(text:GetStringWidth())
  frame:SetHeight(text:GetStringHeight())
end

-- Function to update the size of the container based on visible children
NS.UpdateContainerSize = function(frame)
  if frame == nil then
    return
  end

  local maxWidth, maxHeight = 1, 1
  for i = 1, frame:GetNumChildren() do
    local child = select(i, frame:GetChildren())
    if child and child:IsShown() and child:GetAlpha() > 0 then -- Check if the child is visible and not fully transparent
      local childRight = child:GetRight() or 0
      local childBottom = child:GetBottom() or 0
      -- local childTop = child:GetTop() or 0
      -- local childLeft = child:GetLeft() or 0

      -- Adjust the container size based on child extents
      maxWidth = frame:GetLeft() and mmax(maxWidth, childRight - frame:GetLeft()) or maxWidth
      maxHeight = frame:GetTop() and mmax(maxHeight, frame:GetTop() - childBottom) or maxHeight
    end
  end

  frame:SetSize(maxWidth, maxHeight)
end

-- Function to update the size of the container based on visible children
NS.UpdateInfoSize = function(frame, banner)
  if frame == nil or banner == nil then
    return
  end

  local maxWidth, maxHeight = 1, 1
  for i = 1, frame:GetNumChildren() do
    local child = select(i, frame:GetChildren())
    if child and child:IsShown() and child:GetAlpha() > 0 then -- Check if the child is visible and not fully transparent
      local childRight = child:GetRight() or 0
      local childBottom = child:GetBottom() or 0
      -- local childTop = child:GetTop() or 0
      -- local childLeft = child:GetLeft() or 0

      -- Adjust the container size based on child extents
      maxWidth = frame:GetLeft() and mmax(maxWidth, childRight - frame:GetLeft()) or maxWidth
      maxHeight = frame:GetTop() and mmax(maxHeight, frame:GetTop() - childBottom) or maxHeight
    end
  end

  frame:SetSize(maxWidth, maxHeight)
  banner.frame:SetWidth(maxWidth)
end

-- Function to strip color codes for plain text reference
NS.stripColorCode = function(s)
  return s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

-- Copies table values from src to dst if they don't exist in dst
NS.CopyDefaults = function(src, dst)
  if type(src) ~= "table" then
    return {}
  end

  if type(dst) ~= "table" then
    dst = {}
  end

  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = NS.CopyDefaults(v, dst[k])
    elseif type(v) ~= type(dst[k]) then
      dst[k] = v
    end
  end

  return dst
end

NS.CopyTable = function(src, dest)
  -- Handle non-tables and previously-seen tables.
  if type(src) ~= "table" then
    return src
  end

  if dest and dest[src] then
    return dest[src]
  end

  -- New table; mark it as seen an copy recursively.
  local s = dest or {}
  local res = {}
  s[src] = res

  for k, v in next, src do
    res[NS.CopyTable(k, s)] = NS.CopyTable(v, s)
  end

  return setmetatable(res, getmetatable(src))
end

-- Cleanup savedvariables by removing table values in src that no longer
-- exists in table dst (default settings)
NS.CleanupDB = function(src, dst)
  for key, value in pairs(src) do
    if dst[key] == nil then
      -- HACK: offsetsXY are not set in DEFAULT_SETTINGS but sat on demand instead to save memory,
      -- which causes nil comparison to always be true here, so always ignore these for now
      if
        key ~= "lastReadVersion"
        and key ~= "onlyShowWhenNewVersion"
        and key ~= "lastFlagCapBy"
        and key ~= "version"
      then
        src[key] = nil
      end
    elseif type(value) == "table" then
      if key ~= "disabledCategories" and key ~= "categoryTextures" then -- also sat on demand
        dst[key] = NS.CleanupDB(value, dst[key])
      end
    end
  end
  return dst
end

-- Pool for reusing tables. (Garbage collector isn't ran in combat unless max garbage is reached, which causes fps drops)
do
  local pool = {}

  NS.NewTable = function()
    local t = next(pool) or {}
    pool[t] = nil -- remove from pool
    return t
  end

  NS.RemoveTable = function(tbl)
    if tbl then
      pool[twipe(tbl)] = true -- add to pool, wipe returns pointer to tbl here
    end
  end

  NS.ReleaseTables = function()
    if next(pool) then
      pool = {}
    end
  end
end
