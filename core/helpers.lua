local _, NS = ...

local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local GetTime = GetTime
local print = print
local format = format
local type = type
local next = next

local sformat = string.format
local mfloor = math.floor
local mceil = math.ceil
local mmin = math.min
local mmax = math.max
local tinsert = table.insert
local tsort = table.sort
local wipe = table.wipe

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

NS.isRandomEOTS = function(zoneID)
  if zoneID == 112 then
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

NS.calculateFlagsToCatchUp = function(maxScore, winScore, loseScore, winBases, loseBases, curMapInfo)
  local flagValue = curMapInfo.flagResources[loseBases]
  local flagsNeeded

  if winScore < loseScore then
    for flags = 1, 20 do
      local potentialLoseTeamScore = loseScore + (flagValue * flags)
      local potentialWinTeamScore = winScore

      local l = NS.getWinTime(maxScore, potentialLoseTeamScore, curMapInfo.baseResources[loseBases])
      local w = NS.getWinTime(maxScore, potentialWinTeamScore, curMapInfo.baseResources[winBases])

      if l < w then
        flagsNeeded = flags
        break
      end
    end
  else
    local scoreDifference = winScore - loseScore
    flagsNeeded = mceil(scoreDifference / flagValue)
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

NS.getWinTime = function(maxScore, score, points)
  local remaining = maxScore - score
  local ticksToWin = mceil(points == 0 and 10000 or remaining / points)
  return mmin(ticksToWin, 10000)
end

NS.checkWinCondition = function(
  bases,
  maxBases,
  currentWinningTeamBaseCount,
  currentLosingTeamBaseCount,
  currentFutureWinTime,
  currentWinTeamScore,
  currentLoseTeamScore,
  resources,
  maxScore,
  winTimeIncrease,
  currentWinTime,
  winName,
  loseName
)
  local table = {}

  local potentialLoseTeamBaseCount = bases
  local potentialWinTeamBaseCount = ((bases + currentWinningTeamBaseCount) > maxBases) and maxBases - bases
    or currentWinningTeamBaseCount

  local loseTeamGapScore = NS.CONTESTED_TIME * resources[currentLosingTeamBaseCount]
  local winTeamGapScore = NS.CONTESTED_TIME * resources[potentialWinTeamBaseCount]
  local assaultScore = NS.ASSAULT_TIME * resources[currentWinningTeamBaseCount]

  local timeMax = currentFutureWinTime

  for time = 0, timeMax do
    local loseTeamScoreIncrease = time * resources[currentLosingTeamBaseCount]
    local winTeamScoreIncrease = time * resources[currentWinningTeamBaseCount]

    local loseTeamScoreNow = currentLoseTeamScore + loseTeamScoreIncrease
    local winTeamScoreNow = currentWinTeamScore + winTeamScoreIncrease

    local loseGapScore = (currentWinTime < NS.CONTESTED_TIME) and loseTeamScoreNow
      or loseTeamScoreNow + loseTeamGapScore
    local winGapScore = (currentWinTime < NS.CONTESTED_TIME) and winTeamScoreNow or winTeamScoreNow + winTeamGapScore

    local l = NS.getWinTime(maxScore, loseGapScore, resources[potentialLoseTeamBaseCount])
    local w = NS.getWinTime(maxScore, winGapScore, resources[potentialWinTeamBaseCount])

    local scoreCheck = winTeamScoreNow

    if l < w and scoreCheck < maxScore then
      local ownTime = time + winTimeIncrease
      local capTime = ownTime - NS.ASSAULT_TIME
      local ownScore = scoreCheck
      local capScore = ownScore - assaultScore
      local minBases = NS.getWinMinBases(currentWinningTeamBaseCount, maxBases, potentialLoseTeamBaseCount)

      table[potentialLoseTeamBaseCount] = {
        bases = potentialLoseTeamBaseCount,
        ownScore = ownScore,
        ownTime = ownTime + GetTime(),
        capTime = capTime + GetTime(),
        capScore = capScore,
        minBases = minBases,
        maxBases = maxBases,
        winName = winName,
        loseName = loseName,
      }
    end
  end

  return table
end

NS.getIncomingBaseInfo = function(timers, ownedBases, incomingBases, resources, winTime)
  local baseIncrease = 0
  local timeIncrease = 0
  local scoreIncrease = 0
  local previousTime = 0
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
        if timeLeft and timeLeft > 0 and timeLeft < winTime then
          local newBases = ownedBases + index - 1
          local newTime = timeLeft - previousTime
          local newPoints = newTime * resources[newBases]
          baseIncrease = index
          timeIncrease = timeIncrease + newTime
          scoreIncrease = scoreIncrease + newPoints
          previousTime = timeLeft
        end
      end
    end
  end
  return baseIncrease, timeIncrease, scoreIncrease
end

NS.write = function(...)
  print(NS.userClassHexColor .. "BattlegroundWinConditions|r: ", ...)
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

-- Cleanup savedvariables by removing table values in src that no longer
-- exists in table dst (default settings)
NS.CleanupDB = function(src, dst)
  for key, value in pairs(src) do
    if dst[key] == nil then
      -- HACK: offsetsXY are not set in DEFAULT_SETTINGS but sat on demand instead to save memory,
      -- which causes nil comparison to always be true here, so always ignore these for now
      if key ~= "offsetsX" and key ~= "offsetsY" and key ~= "version" then
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
      pool[wipe(tbl)] = true -- add to pool, wipe returns pointer to tbl here
    end
  end

  NS.ReleaseTables = function()
    if next(pool) then
      pool = {}
    end
  end
end
