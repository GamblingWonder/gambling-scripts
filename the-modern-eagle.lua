------------------------------------------------------------------------------------
-- THE MODERN EAGLE v1.4
------------------------------------------------------------------------------------
-- by winmachine (pd/stake/wolf/duckdice: WinMachine)
------------------------------------------------------------------------------------
-- contributions:
-- pflip
------------------------------------------------------------------------------------
-- based on "The Eagle" Script from PMG
------------------------------------------------------------------------------------
-- 1) Pre roll strategy that analyzes as much luck as you want and in both directions.
-- 2) Locate the rare series (example: 4 rolls above 90 in a row) you can set
--    what type of series (the probability of series) you are looking for with the variable NBM 
--    (example NBM = 1000 is looking for series with at least 1 chance out of 1000 to arrive)
-- 3) Following the series in the same direction and with the corresponding luck (e.g.: - 2).
--    ple after 4 rolls higher than 90 it follows in chance 90 and under)
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
--  FAQ:
--  agressivite:
--     increases/decreases martingales' best minimum increase 
--     for instance with multiplier=2 and aggressivite = 50 after every loses, wager are increase by 150%) 
--   NBM : 
--     probability of the series
--     (for instance with NBM=100 we are looking for series that have 1 chance in 100 ) 
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- changelog
------------------------------------------------------------------------------------
-- webdicebot detection
-- compatibility with wdb
-- virtual balance/vault for casinos without vault feature
-- switch settings system
-- multiple settings feature
-- vault feature
-- settings values optimizations for more safest possible
------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
local version           = 1.4

local edge              = 0
local allow_vault       = false
local debugg            = false
local display_frequency = 10 -- displays info every x bets
------------------------------------------------------------------------------------
enablezz   = false
enablesrc  = true
------------------------------------------------------------------------------------

local basebet_min              = 0.00000001
local initial_mode             = 0
local vault_enabled            = true
local default_vault_percentage = 10 -- percentage of the balance
local balance_safe_parts = 2 -- 1 = 100% of the balance or virtual balance, number of parts of the balance used for martingale optimization

local stop_on_target_reached = false
local stop_on_losse_target_reached = false -- if enabled, will use limite as max losse target

------------------------------------------------------------------------------------
-- multiple bot
------------------------------------------------------------------------------------
-- for run on WebDiceBot isWDB must be true, otherwise it should be false

local isWDB             = false
if isWDB then 
  edge  = 1    -- House edge
  allow_vault = false
else
  edge = site.Edge
  allow_vault = site.CanVault 
end

------------------------------------------------------------------------------------

local settings = {
  [0]={
    name               = "SAFE",
    div                = 50000, -- base unit
    agressivite        = -1 ,
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
    div                = 15000, -- base unit
    agressivite        = -10 ,
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
    div                = 50000, -- base unit
    agressivite        = 5 ,
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
local div                = 0
local agressivite        = 0
local casino             = 0
local chancePreroll      = 0
local maxchance          = 0
local minchance          = 0
local NBRchance          = 0
local target             = 0
local limite             = 0
local bb                 = 0
local bbPreroll          = 0
local reset_seed_on_goal = false
local NBM                = 0
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
local startbank        = balance
local vbalance_enabled = false
------------------------------------------------------------------------------------
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
local bbInitial = 0
local inc = 0

local A,B = 0,0
local Tch    = {} -- chance
local TOver  = {} -- chaine lose over
local TUnder = {} -- chaine lose under
local TOUMX  = {} -- plus grande chaine entre over/under
local Tsens  = {} -- mémorise sens de chaque chaine
local Tn     = {} -- chaine lose min

local NeedMartingaleOptimization = false

local current_mode = initial_mode

local total_vaulted = 0

------------------------------------------------------------------------------------
--FUNCTIONS
------------------------------------------------------------------------------------
function cPrint(msg)
  if isWDB then log(msg) else print(msg) end  
end 

function fCurrency(value)
  return string.format("%9.12f %s", value, currency)
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

function vBalance()
  if vbalance_enabled then return balance-total_vaulted else return balance end
end

------------------------------------------------------------------------------------
local vault_types = { DISABLED=0, REAL=1, VIRTUAL=2} -- 1 -- 0 - disabled, 1 - real, 2 - virtual
local vault_type = 0

local function setupInterop()
  if allow_vault then
    vbalance_enabled = false
    vault_type = vault_types.REAL    
  else
    vbalance_enabled = true
    vault_type = vault_types.VIRTUAL
  end
end

local function printCurrentMode()
  cPrint("div................ " .. div)
  cPrint("agressivite........ " .. agressivite)
  cPrint("casino............. " .. casino)
  cPrint("chancePreroll...... " .. chancePreroll)
  cPrint("maxchance.......... " .. maxchance)
  cPrint("minchance.......... " .. minchance)
  cPrint("NBRchance.......... " .. NBRchance)
  cPrint("target............. " .. target)
  cPrint("limite............. " .. limite)
  cPrint("bb................. " .. bb)
  cPrint("bbPreroll.......... " .. bbPreroll)
  cPrint("reset_seed_on_goal. " .. tostring(reset_seed_on_goal))
  cPrint("NBM................ " .. NBM)
  cPrint("next_play_mode..... " .. next_play_mode)
  cPrint("current_mode....... " .. current_mode)
end

local function setMode(playMode)

  div             = settings[playMode].div
  agressivite     = settings[playMode].agressivite
  casino          = edge
  chancePreroll   = settings[playMode].chancePreroll
  maxchance       = settings[playMode].maxchance
  minchance       = settings[playMode].minchance
  NBRchance       = settings[playMode].NBRchance
  target          = math.includePercentage(vBalance(), settings[playMode].target)
  limite          = settings[playMode].limite
  bb              = vBalance() / div
  bbPreroll       = bb/2
  reset_seed_on_goal= settings[playMode].reset_seed_on_goal
  NBM             = settings[playMode].NBM
  next_play_mode  = settings[playMode].next_play_mode

  current_mode = playMode

  printCurrentMode()

  setup()

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

local function setup()

  A = minchance - ((maxchance-minchance)/(NBRchance-1))
  B = vBalance() - limite --it's the part of the scale at stake

  -- Remplis les table selectione les chances
  for x = 1, NBRchance, 1 do 
    A         = A + (maxchance-minchance)/(NBRchance-1)
    Tch[x]    = A -- chance
    TOver[x]  = 0 -- chaine lose over
    TUnder[x] = 0 -- chaine lose under
    TOUMX[x]  = 0 -- plus grande chaine entre over/under
    Tn[x]     = 0 -- chaine lose min
    Tsens[x]  = 0 -- mémorise sens de chaque chaine
  end

--[[ 
for x=1,NBRchance,1 do --table serie win min
    if Tch[x]==nil then break end
    Tn[x]=math.ceil(math.log(1/NBM)/math.log((Tch[x])/100))
end 
--]]

  -- table serie lose min
  for x=1, NBRchance, 1 do 
    if Tch[x] == nil then break end
    Tn[x] = math.ceil(math.log(1/NBM) / math.log((100-Tch[x])/100))
  end

  x = 0
  bbInitial = bb

end

function increase_adapter()
  payout = (100 - casino)/chance
  q      = ((1+(1/(payout-1)))-1)*(1+(agressivite/100))+1
  inc    = (q-1)*100
end

function martingale_optimise() --optimizing the base bet to use 100% of the balance

  if (lastBet.profit >= 0) then -- if win
    B       = (vBalance()/balance_safe_parts) - limite - 0.00000001
    n       = math.log((B/bb)*(-1+q)+1)/math.log(q) 
    n       = math.floor(n) 
    nextbet = B/((1-q^n)/(1-q)) -- bet maximum amount to cash these "n" loses
  else
    nextbet = previousbet*q
  end

  cPrint("INCREASE= " .. inc .."%")
  cPrint("MAX SERIES OF POSSIBLE LOSSES= " .. n-1 )

end

function reset_to_preroll()

  if (lastBet.profit >= 0) then -- if win then
    if bestTOUMX < Tn[indice] then
      --return to preroll after win 
      chance = chancePreroll
      nextbet = bbPreroll
      NeedMartingaleOptimization = false
    end
  end 

end

------------------------------------------------------------------------------------
function looking_for_series_of_win()

  for x=1, NBRchance,1 do

    if Tch[x] == nil then break end

    if lastBet.roll < Tch[x] then
      TUnder[x] = TUnder[x] + 1
    else
      TUnder[x] = 0
    end

    if lastBet.roll > (100-Tch[x]-0.01) then
      TOver[x] = TOver[x] + 1
    else
      TOver[x] = 0
    end

    if TUnder[x] >= TOver[x] then
      TOUMX[x] = TUnder[x]
      Tsens[x] = false
    else
      TOUMX[x] = TOver[x]
      Tsens[x] = true
    end

  end

end
------------------------------------------------------------------------------------
function looking_for_series_of_lose()

  for x=1, NBRchance, 1 do

    if Tch[x] == nil then break end

    if lastBet.roll < Tch[x] then
      TUnder[x] = 0
    else
      TUnder[x] = TUnder[x] + 1
    end

    if lastBet.roll > (100-Tch[x]-0.01) then
      TOver[x] = 0
    else
      TOver[x] = TOver[x] +  1
    end

    if TUnder[x] >= TOver[x] then
      TOUMX[x] = TUnder[x]
      Tsens[x] = false
    else
      TOUMX[x] = TOver[x]
      Tsens[x] = true
    end

  end

end
------------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------
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
------------------------------------------------------------------------------------


local function manageGoals()

  if vBalance() > target then

    if vault_enabled then

      local vault_x = math.percentage( vBalance(), default_vault_percentage)

      if vault_type== vault_types.REAL then

        cPrint("----------------------------------------------------------------")
        cPrint("# try real vault.............. " .. fCurrency(vault_x))
        cPrint("----------------------------------------------------------------")

        vault(vault_x)
        total_vaulted = total_vaulted + vault_x

      elseif vault_type== vault_types.VIRTUAL then

        cPrint("----------------------------------------------------------------")
        cPrint("# try virtual vault........... " .. fCurrency(vault_x))
        cPrint("----------------------------------------------------------------")

        total_vaulted = total_vaulted + vault_x

      end

    end

    -- reset seed
    if reset_seed_on_goal then resetseed() end

    -- switch mode
    switchMode()

    chance = chancePreroll
    nextbet = bbPreroll

  end
end

function limiteSTOP(target,limite)
  if vBalance() > target then
    printnfo()
    cPrint("TARGET REACHED")
    if stop_on_target_reached then 
      cPrint("STOP REQUESTED")
      stop()
    end
  elseif  vBalance() - nextbet < limite then
    printInfo()
    cPrint("MAX LOSSES REACHED")
    if stop_on_losse_target_reached then 
      cPrint("STOP REQUESTED")
      stop()
    end
  end
end

function CheckMinBet()
  if(nextbet<basebet_min) then 
    nextbet=basebet_min
  end
end

function printInfo()
  cPrint("\n\n")
  cPrint("#######################################################################################")
  cPrint("# ")
  cPrint("# THE \"MODERN\" EAGLE v."..tostring(version))
  cPrint("# optimized by WinMachine based on pmg version")
  cPrint("# ")
  cPrint("# THERE ARE NO PERFECT STRATS OR SCRIPTS WHEN GAMBLING, BE SAFE!")
  cPrint("# ####################################################################################")
  cPrint("#")
  cPrint("# [SETTINGS/MODE....... " .. current_mode .. " (" .. settings[current_mode].name .. ")")
  cPrint("# [START BANK.......... " .. fCurrency(startbank) .. "")
  cPrint("# [BALANCE............. " .. fCurrency(balance) .. "")

  if vbalance_enabled then
    cPrint("# [VIRTUAL BALANCE..... " .. fCurrency(vBalance()) .. "")
    cPrint("# [VIRTUAL VAULTED..... " .. fCurrency(total_vaulted))
  else
    cPrint("# [VAULTED............. " .. fCurrency(total_vaulted))
  end

  cPrint("# [TARGET.............. " .. fCurrency(target) .. "")
  cPrint("# [LEFT TO TARGET...... " .. fCurrency(target-vBalance()) .. "")
  cPrint("# ")
  cPrint("# -------------------------------------------------------------------------------------")
  cPrint("# [BASEBET............. " .. fCurrency(bbInitial) .. "")
  cPrint("# [WINCHANCE........... " .. fPercentage(chance) .. "")
  cPrint("# [NEXTBET............. " .. fCurrency(nextbet) .." ROLL  n° " ..bets .."")
  cPrint("# -------------------------------------------------------------------------------------")
  cPrint("# ")
  cPrint("# [PROFIT.............. " .. fCurrency( profit) .." (balance x" ..string.format("%2.2f",((vBalance())/(startbank))) ..")")
  cPrint("# [MAX BET PLACED...... " .. fCurrency(maxUse) .. "")
  cPrint("# ")
  cPrint("# ####################################################################################")
  cPrint("\n\n")
end

function calculPrint()

  if p == true then
    cPrint(chance)
    cPrint(nextbet)
    cPrint(coef)
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

------------------------------------------------------------------------------------

setupInterop()
setMode(initial_mode)

chance = chancePreroll
nextbet = bbPreroll

CheckMinBet()

------------------------------------------------------------------------------------

function dobet()

  if debugg == true then

    if bethigh == true then sens24 = "over" else sens24 = "under" end
    if win then gain24 = " win" else gain24 = "lose" end

    cPrint("================================")
    cPrint("=[Amount" .."  ][  " .."sens" .."    ][  " .."Chance" .."  ][  " .."gain]=")
    cPrint("=[" ..string.format("%9.2f",previousbet) .."  ][  " ..sens24 .."  ][  "..string.format("%1.2f",chance).."      ][  "..gain24 .." ]=")
    cPrint("================================")

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
