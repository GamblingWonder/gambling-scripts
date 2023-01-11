------------------------------------------------------------------------------------
-- THE MODERN EAGLE v1.1
------------------------------------------------------------------------------------
-- by winmachine, based on "The Eagle" Script from FuckingGambling.com
------------------------------------------------------------------------------------
-- adapted to WebDicebot by pflip
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

--[[
-- Introducing "The Eagle" Script for DiceBot from FuckingGambling.com 
1) Pre roll strategy that analyzes as much luck as you want and in both directions.
 
2) Locate the rare series (example: 4 rolls above 90 in a row) you can set
what type of series (the probability of series) you are looking for with the variable NBM (example
NBM = 1000 is looking for series with at least 1 chance out of 1000 to arrive)
 
3) Following the series in the same direction and with the corresponding luck (e.g.: - 2).
ple after 4 rolls higher than 90 it follows in chance 90 and under)
 
 FAQ:
 
 agressivite:
    increases/decreases martingales' best minimum increase 
    for instance with multiplier=2 and aggressivite = 50 after every loses, wager are increase by 150%) 

  NBM : 
    probability of the series
    (for instance with NBM=100 we are looking for series that have 1 chance in 100 ) 

]]--

------------------------------------------------------------------------------------
version = 1.1
------------------------------------------------------------------------------------
enablezz   = false
enablesrc  = true
------------------------------------------------------------------------------------
debugg = false
display_frequency = 10 -- displays info every x bets
------------------------------------------------------------------------------------
basebet_min = 0.000000001
initial_mode = 0
default_vault_percentage = 10 -- percentage of the balance
he = 1    -- House edge
------------------------------------------------------------------------------------
local settings = {
  [0]={
    name               = "SAFE",
    div                = 50000, -- base unit
    agressivite        = -1 ,
    casino             = he,  -- site.Edge, --% edge house
    chancePreroll      = 92, --chance to pre roll
    maxchance          = 85,-- max chance authorized
    minchance          = 10,--42--36 --minimum chance authorized
    NBRchance          = 80, --number of chance analyzed
    target             = 5, -- percentage
    limite             = 0, --STOP_IF_BALANCE_UNDER
    bb                 = 0,--balance / settings[1].div, -------------------base bet
    bbPreroll          = 0,--bb/2, --pre roll base bet
    NBM                = 95,
    reset_seed_on_goal = true,
    next_play_mode     = -1 -- -1 to random
  },
  [1]={
    name               = "WAGER",
    div                = 5000, -- base unit
    agressivite        = -10 ,
    casino             = he, --site.Edge, --% edge house
    chancePreroll      = 92, --chance to pre roll
    maxchance          = 65,-- max chance authorized
    minchance          = 33,--42--36 --minimum chance authorized
    NBRchance          = 80, --number of chance analyzed
    target             = 1, -- percentage
    limite             = 0, --STOP_IF_BALANCE_UNDER
    bb                 = 0,--balance / settings[2].div, -------------------base bet
    bbPreroll          = 0,--bb/2, --pre roll base bet
    NBM                = 95,
    reset_seed_on_goal = false,
    next_play_mode     = -1 -- -1 to random
  },
  [2]={
    name               = "CRAZY",
    div                = 10000, -- base unit
    agressivite        = 10 ,
    casino             = he,  -- site.Edge, --% edge house
    chancePreroll      = 92, --chance to pre roll
    maxchance          = 65,-- max chance authorized
    minchance          = 45,--42--36 --minimum chance authorized
    NBRchance          = 80, --number of chance analyzed
    target             = 5, -- percentage
    limite             = 0, --STOP_IF_BALANCE_UNDER
    bb                 = 0,--balance / settings[3].div, -------------------base bet
    bbPreroll          = 0,--bb/2, --pre roll base bet
    NBM                = 95,
    reset_seed_on_goal = true,
    next_play_mode     = -1 -- -1 to random, 0 - to nothing
  }
}
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- INTERNAL VARIABLES
------------------------------------------------------------------------------------
-- this values will be overrided with the values from settings
------------------------------------------------------------------------------------
local div = 0
local agressivite = 0
local casino     = 0
local chancePreroll = 0
local maxchance  = 0
local minchance  = 0
local NBRchance  = 0
local target     = 0
local limite     = 0
local bb         = 0
local bbPreroll  = 0
local reset_seed_on_goal = false
local NBM        = 0
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
local startbank   = balance
local bestTOUMX   = 0 -- Memorizes the probability of the best chance
local N           = 0
local n           = 1
local bestchain   = 0 -- memorizes the value of the most rare series
local indice      = 1 -- index of the rarest series at the last control
local pr          = 0 -- memorizes profit/progression
local prinitiale  = pr

local perteP = 0
local p = false
local maxUse = 0
local bestID, badID, pirePERTE, bestPROFIT = 0,0,0,0

local g = 0
local x = 0
local bbDB = 0
local inc = 0

local A = 0
local B = 0
local Tch = {} --chance
local TOver = {} --chaine lose over
local TUnder = {} --chaine lose under
local TOUMX = {}  --plus grande chaine entre over/under
local Tsens = {} --mémorise sens de chaque chaine
local Tn = {} --chaine lose min

local NeedMartingaleOptimization = false

local current_mode = initial_mode

local total_vaulted = 0

------------------------------------------------------------------------------------
--FUNCTIONS
------------------------------------------------------------------------------------

function fCurrency(value)
  return string.format("%9.8f %s", value, currency)
end

function fPercentage(value)
  return string.format("%.8f", value)
end

function math.percentage(percentage)
  if tonumber(percentage) and tonumber(value) then
    return (value*percentage)/100
  end
  return 0
end

function math.includePercentage(value, percentage)
  if tonumber(percentage) and tonumber(value) then
    return value + ( value* (percentage/100))
  end
  return 0
end

------------------------------------------------------------------------------------

local function setMode(playMode)

  div             = settings[playMode].div
  agressivite     = settings[playMode].agressivite
  casino          = settings[playMode].casino
  chancePreroll   = settings[playMode].chancePreroll
  maxchance       = settings[playMode].maxchance
  minchance       = settings[playMode].minchance
  NBRchance       = settings[playMode].NBRchance
  target          = math.includePercentage(balance, settings[playMode].target)
  limite          = settings[playMode].limite
  bb              = balance / div
  bbPreroll       = bb/2
  reset_seed_on_goal= settings[playMode].reset_seed_on_goal
  NBM             = settings[playMode].NBM
  next_play_mode  = settings[playMode].next_play_mode

  current_mode = playMode

end

local function switchMode()

  if(next_play_mode < 0) then
    local randomModeIndex = 0
    repeat
      randomModeIndex = math.random(0, #settings)
    until (randomModeIndex ~= current_mode)
    setMode(randomModeIndex)
  elseif next_play_mode > 0 then
    setMode(next_play_mode)
  end
end


local function setup(firtRun)

  A = minchance-((maxchance-minchance)/(NBRchance-1))
  B = balance - limite ---it's the part of the scale at stake

  for x=1, NBRchance,1 do --Remplis les table selectione les chances
    A = A +(maxchance-minchance)/(NBRchance-1)
    Tch[x] = A --chance
    TOver[x] = 0 --chaine lose over
    TUnder[x] = 0 --chaine lose under
    TOUMX[x] = 0 --plus grande chaine entre over/under
    Tn[x] = 0 --chaine lose min
    Tsens[x] = 0 --mémorise sens de chaque chaine
  end

--[[ 
for x=1,NBRchance,1 do --table serie win min
    if Tch[x]==nil then break end
    Tn[x]=math.ceil(math.log(1/NBM)/math.log((Tch[x])/100))
end 
--]]

  for x=1, NBRchance, 1 do --table serie lose min
    if Tch[x] == nil then break end
    Tn[x] = math.ceil(math.log(1/NBM) / math.log((100-Tch[x])/100))
  end

  x = 0

  bbDB = bb

end

function increase_adapter()
  payout = (100 - casino)/chance
  q = ((1+(1/(payout-1)))-1)*(1+(agressivite/100))+1
  inc = (q-1)*100
end

function martingale_optimise() --optimizing the base bet to use 100% of the balance

  if (lastBet.profit >= 0) then -- if win
    B = balance-limite-0.00000001
    n = math.log((B/bb)*(-1+q)+1)/math.log(q) 
    n = math.floor(n) 
    nextbet = B/((1-q^n)/(1-q)) -- bet maximum amount to cash these "n" loses
  else
    nextbet = previousbet*q
  end
 if p == true then
  log("INCREASE= " ..inc .."%")
  log("MAX SERIES OF POSSIBLE LOSSES= " ..n-1 )
 end
end

function reset_to_preroll()

  if (lastBet.profit >= 0) then -- if win then

    if bestTOUMX < Tn[indice] then
      chance = chancePreroll
      nextbet = bbPreroll
	  CheckMinBet()
      NeedMartingaleOptimization = false
    end
  end --return to preroll after win 

end

function looking_for_series_of_win()


  for x=1, NBRchance,1 do

    if Tch[x] == nil then break end

    if lastBet.roll < Tch[x] then
      TUnder[x] = TUnder[x] + 1
    else
      TUnder[x] =0
    end

    if lastBet.roll > (100-Tch[x]-0.01) then
      TOver[x] = TOver[x] + 1
    else
      TOver[x] =0
    end

    if TUnder[x] >= TOver[x] then
      TOUMX[x]=TUnder[x]
      Tsens[x]=false
    else
      TOUMX[x]=TOver[x]
      Tsens[x]=true
    end

  end

end

function looking_for_series_of_lose()

  for x=1, NBRchance, 1 do

    if Tch[x]==nil then break end

    if lastBet.roll < Tch[x] then
      TUnder[x] =0
    else
      TUnder[x] = TUnder[x] + 1
    end

    if lastBet.roll > (100-Tch[x]-0.01) then
      TOver[x] =0
    else
      TOver[x] = TOver[x] + 1
    end

    if TUnder[x] >= TOver[x] then
      TOUMX[x]=TUnder[x]
      Tsens[x]=false
    else
      TOUMX[x]=TOver[x]
      Tsens[x]=true
    end

  end

end

function selection_of_best_win_series()
  for x=1,NBRchance,1 do
    if Tch[x] == nil then break end
    if (1/(((Tch[x])/100)^TOUMX[x])) > bestchain then
      bestchain=(1/(((Tch[x])/100)^TOUMX[x]))
      indice=x
      bestTOUMX=TOUMX[indice]
    end
  end
  if bestTOUMX >= Tn[indice] and (lastBet.profit >= 0) then
    NeedMartingaleOptimization = true
    bestchain=0 --pour garder en mémoire même si la serie est cassé
    chance=Tch[indice]
    bethigh=Tsens[indice]
  end
end

function selection_of_best_lose_series()
  for x=1,NBRchance,1 do
    if Tch[x]==nil then break end
    if (1/(((100-Tch[x])/100)^TOUMX[x])) > bestchain then
      bestchain=(1/(((100-Tch[x])/100)^TOUMX[x]))
      indice=x
      bestTOUMX=TOUMX[indice]
    end
  end
  if bestTOUMX >= Tn[indice] and ((lastBet.profit >= 0) or chance==chancePreroll) then
    NeedMartingaleOptimization=true
    chance=Tch[indice]
    bethigh=Tsens[indice]
  end
end


local function manageGoals()
  if balance > target then
  
  --[[
    if site.CanVault then

      local vault_x = math.percentage(balance,default_vault_percentage)

      print("try vault_x " .. fCurrency(vault_x))

      vault(vault_x)
      total_vaulted = total_vaulted + vault_x
      balance = balance - vault_x
      bb      = balance / div -------------------base bet
      bbPreroll     = bb/2 --pre roll base bet
      bbDB = bb    
    end
  --]]

    if reset_seed_on_goal then resetseed() end

    -- switch mode
    switchMode()

    chance = chancePreroll
    nextbet = bbPreroll

  end
end

function limiteSTOP(target,limite)
  if balance > target then
    printInfo()
    log("TARGET REACHED !!!!!!!!!!!!!!")
  elseif  balance-nextbet < limite then
    printInfo()
    log("............................. USELESS ....")
    --stop()  
  end
end

function CheckMinBet()
  if(nextbet<basebet_min) then 
    nextbet=basebet_min
  end
end

function printInfo()
  log("\n\n")
  log("#######################################################################################")
  log("# ")
  log("# THE \"MODERN\" EAGLE v."..tostring(version))
  log("# optimized by WinMachine based on pmg version")
  log("# ")
  log("# THERE ARE NO PERFECT STRATS OR SCRIPTS WHEN GAMBLING, BE SAFE")
  log("# ####################################################################################")
  log("#")
  log("# [SETTINGS/MODE....... " .. current_mode .. " (" .. settings[current_mode].name .. ")")
  log("# [START BANK.......... " .. fCurrency(startbank) .. "")
  log("# [BALANCE............. " .. fCurrency(balance) .. "")
  log("# [BASEBET............. " .. fCurrency(bbDB) .. "")
  log("# -------------------------------------------------------------------------------------")
  log("# [WINCHANCE........... " .. fPercentage(chance) .. "")
  log("# [NEXTBET............. " .. fCurrency(nextbet) .." ROLL  n° " ..bets .."")
  log("# ")
  log("# [PROFIT.............. " .. fCurrency( profit) .." (balance x" ..string.format("%2.2f",((balance)/(startbank))) ..")")
  log("# [VAULTED............. " .. fCurrency(total_vaulted))
  log("# [Max bet placed...... " .. fCurrency(maxUse) .. "")
--  log("# [WAGERED............. " .. fCurrency(wagered) .." (" ..string.format("%2.2f",wagered/(startbank)) .." x start balance)")
  log("# ")
  --log("# [Avg profit/bet...... " ..fCurrency(profit/bets/bbDB) .." x base bet")
--  log("# [Avg wag/bet......... " .. fCurrency(wagered/bets))
  log("# ")
  -- log("# [PROFIT MAX.......... " ..bestID .."")
  -- log("# [PERTE MAX........... " ..badID .."")
  log("# ")
  log("# ####################################################################################")
  log("\n\n")
end

function calculPrint()

  if p == true then
    log(chance)
    log(nextbet)
    log(coef)
  end

  perteP = perteP + currentprofit

  if perteP >= 0 then perteP = 0 end

  if -perteP + nextbet > maxUse then maxUse = -perteP + nextbet end

  if bets % display_frequency == 0 then
    printInfo()
  end

  if currentprofit >= bestPROFIT then
    bestID = lastBet.id
    bestPROFIT = currentprofit
  end

  if currentprofit <= pirePERTE then
    badID = lastBet.id
    pirePERTE = currentprofit
  end

end
--_______________________________________________________________________

setMode(initial_mode)
setup(true)

chance = chancePreroll
nextbet = bbPreroll

CheckMinBet()

function dobet()

  if debugg == true then

    if bethigh == true then sens24 = "over" else sens24 = "under" end
    if win then gain24 = " win" else gain24 = "lose" end

    log("================================")
    log("=[Amount" .."  ][  " .."sens" .."    ][  " .."Chance" .."  ][  " .."gain]=")
    log("=[" ..string.format("%9.2f",previousbet) .."  ][  " ..sens24 .."  ][  "..string.format("%1.2f",chance).."      ][  "..gain24 .." ]=")
    log("================================")

  end

  pr = pr + currentprofit

  manageGoals()

  looking_for_series_of_lose()
  --looking_for_series_of_win()

  bestchain = 0
  selection_of_best_lose_series()
  --selection_of_best_win_series()

  reset_to_preroll()

  if NeedMartingaleOptimization == true then

    increase_adapter()
    martingale_optimise()
  end

  calculPrint()

  limiteSTOP(target,limite)

  CheckMinBet()

end