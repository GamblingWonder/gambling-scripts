
--------------------------------------------------------------
sc = "BalanceUp v.1"
------------------------------------------------------------------------------------
-- developed by winmachine (primedice/stake/wolf/duckdice: WinMachine)
------------------------------------------------------------------------------------
-- All donations are welcome and appreciated! 
------------------------------------------------------------------------------------
-- TRON : TUo92MJpmrrNYDCNgGGoMLNEnTkpTPcA6S
------------------------------------------------------------------------------------
-- DOGE : DNwsyyhUw5Busx3t9uk6ZFcgYNzczHfM61
------------------------------------------------------------------------------------
-- LTC  : LXrxHi8pUb6ieGkVDMMJbuBnodjPpitMJT
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
-- THERE ARE NO PERFECT STRATS OR SCRIPTS WHEN GAMBLING, BE SAFE!-------------------
-- #################################################################################
-- ALWAYS CHECK SETTINGS AND TEST WITH LOW VALUE COINS BEFORE RUN WITH VALUABLE COINS
-- #################################################################################
--------------------------------------------------------------
--
--  (     (     )   (   (   (   (  (       )   ) ) 
--  )\    )\ ( ((.  )\: )\: )\  (\ )\   ( ((. (\(  
-- ((_)  ((())\))\ ((_)((_)(_() (\((_)  )\))\  )(| 
-- \ \    / /_)(_))|  \/  |(_)()( ) |_ (_)(_)) ()\ 
--  \ \/\/ /| | ' \) |\/| | _` | _|   \| | ' \) -_)
--   \_/\_/ |_|_||_|_|  |_|__/_|__|_||_|_|_||_|___|
--
-- #################################################################################
-- ALWAYS CHECK SETTINGS AND TEST WITH LOW VALUE COINS BEFORE RUN WITH VALUABLE COINS
-- #################################################################################

curency = 'usdt'
------------------------------------------------------------------------------------
bethigh = true

------------------------------------------------------------------------------------
divider1 = 1000 -- <-- increase this value if big balance and low value coins
divider2 = 50 -- <-- increase this value if big balance and low value coins
------------------------------------------------------------------------------------
basebet1   = balance / divider1
basebet2 = balance / divider2
basebet2_reset= true -- if false the next bet on win will be half of the last
------------------------------------------------------------------------------------
winchance1 = 98  -- percentage
winchance2 = 49.5  -- percentage
------------------------------------------------------------------------------------
inc1       = 0 -- percentage
inc2       = 100 -- percentage
------------------------------------------------------------------------------------
minbet = 0.0000001-- <-- adjust the value based on casino min bet amount
------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

local stage=0-- dont change
local losestreak              = 0 -- dont change
local winstreak               = 0 -- dont change

------------------------------------------------------------------------------------

function multiplierToWinChance(multiplier)  return (100 - houseEdge) / multiplier end
function PercentageIncreaseValue(value, percentage) 
  if(percentage==null) then percentage=0 end
  return value + (value * (percentage / 100)) 
end
function PercentageOf(value,percentage)
  if tonumber(percentage) and tonumber(value) then return (value*percentage)/100 end
  return 0
end
function PercentageReduced(value,percentage)
  if tonumber(percentage) and tonumber(value) then return value-(value*percentage)/100 end
  return 0
end
function fCurrency(value)  return string.format("%9.15f %s", value, currency) end
function fPercentage(value)  return string.format("%.8f", value) end
function iff(cond, a, b) if cond then return a else return b end end

function CeckMinMaxBetAmount() 
  if (nextbet < minbet) then 
    nextbet = minbet 
  end 
end

function printb(message)
  print("---------------------------------------------------------------")
  print(message)
  print("---------------------------------------------------------------")
end

function notifyStatus()

  print("\n\n\n\n")
  print("-------------------------------------------------------------------------------")
  print("///////////////////////////////////////////////////////////////////////////////")
  print("###############################################################################")
  print("#\t" .. sc)
  print("#\t2023 by WinMachine (pd/stake/wolf/duckdice: WinMachine)")
  print("-------------------------------------------------------------------------------")
  print("#")
  print("#\tStage................ " .. stage)
  print("#")
  print("###############################################################################")
  print("///////////////////////////////////////////////////////////////////////////////")
  print("-------------------------------------------------------------------------------")
  print("\n\n\n\n")

end

local function onStart()
  if win then winstreak = winstreak + 1 else losestreak = losestreak + 1 end  
end

local function onEnd()
  if win then losestreak = 0 else winstreak = 0 end  
  CeckMinMaxBetAmount()
end

chance  = winchance1
nextbet = basebet1

CeckMinMaxBetAmount()

function dobet()

  onStart()

  if(bets % 10 == 0) then
    notifyStatus()
  end

  if(stage==0) then

    if(not win) then
      printb("We have problems, lets recover!! Changing stage...")

      stage = 1
      chance  = winchance2
      nextbet = basebet2
    end

  elseif(stage==1) then

    if(win) then

      if(partialprofit>0) then   
        stage = 0
        basebet1   = balance / divider1
        basebet2 = balance / divider2
        chance  = winchance1
        nextbet = basebet1
        resetpartialprofit()
        printb("Recover completed!! Changing stage...")
      else
        if(basebet2_reset) then
          nextbet = previousbet/2
        else
          nextbet = basebet2
        end
      end

    else
      nextbet = PercentageIncreaseValue(previousbet,inc2) 
    end
  else
    printb("Something is wrong!")
    stop()
  end
  onEnd()
end
