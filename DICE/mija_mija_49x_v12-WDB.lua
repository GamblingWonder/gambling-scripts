--------------------------------------------------------------
-- Mija Mija 49x v.1.2
--------------------------------------------------------------
-- developed by winmachine (pd/stake/wolf/duckdice: WinMachine)
-- ported to WDB by Pflip
--------------------------------------------------------------
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
------------------------------------------------------------------------------------
-- NOTE:THIS IS NOT A STRATEGY, ITS JUST A START TEMPLATE TO START BUILDING SCRIPTS
------------------------------------------------------------------------------------
-- #################################################################################


bethigh   = true



--basebet   = balance/divider

--winchance             = 1
--inc                   = 0.5
--minbet                = 0.00000100
--losestreak_checkpoint = 200

divider               = 500000
basebet               = balance/divider --0.00010000
winchance             = 2
inc                   = 1.25
minbet                = 0.000010
losestreak_checkpoint = 60

global_goal = 0.05
global_vault = 0.01
ath 				= balance
sbal 				= balance
goal				= balance  * 1.5   	-- target for this run
sl      			= balance * 0.7		-- Stop loss




houseEdge = 1
canVault = site.CanVault

--------------------------------------------------------------
local losestreak = 0-- dont change
local winstreak  = 0-- dont change
local total_vaulted=0
local balance_initial  = balance
--------------------------------------------------------------

function multiplierToWinChance(multiplier)
  return (100-houseEdge)/multiplier
end
function PercentageIncreaseValue(value, percentage)
  return value + (value* (percentage/100)) ;
end
function fCurrency(value)
  return string.format("%9.15f %s", value, currency)
end
function fPercentage(value)
  return string.format("%.8f", value)
end

function CeckMinMaxBetAmount()
  if(nextbet < minbet) then
    nextbet = minbet
  end
end

function printb(message)
  print("---------------------------------------------------------------")
  print(message)
  print("---------------------------------------------------------------")
end
function notifyStatus()

  real_profit = profit

  local real_balance = balance_initial + profit

  print("\n\n\n\n")
  print("-------------------------------------------------------------------------------")
  print("///////////////////////////////////////////////////////////////////////////////")
  print("###############################################################################")
  print("#")
  print("#\tBalance.......... " .. fCurrency(real_balance))
  print("#\tProfit........... " .. fCurrency(real_profit))
  print("#\tGain............. " .. fPercentage(real_profit * 100 / balance_initial) .. " %")
  print("#")
  print("#\tVaulted.......... " .. fCurrency(total_vaulted))
  print("#")
  print("###############################################################################")
  print("///////////////////////////////////////////////////////////////////////////////")
  print("-------------------------------------------------------------------------------")
  print("\n\n\n\n")

end

chance  = winchance
nextbet = basebet

CeckMinMaxBetAmount()

function dobet()

  if(bets % 10 == 0) then
    notifyStatus()
  end

  if(win) then
--[[
    -----------------------------------------------  
    if(partialprofit > global_goal) then
      if(canVault) then
        vault(global_vault)  
        print ("vaulted!" .. fCurrency(global_vault) )
        total_vaulted = total_vaulted+global_vault
        print ("total vaulted......: " .. fCurrency(total_vaulted))
      end
      resetpartialprofit()
    end
--]]
    -----------------------------------------------  
    winstreak = winstreak + 1
    -----------------------------------------------  
    local currentbetAmount = previousbet
    local currWinChance    = chance

-- #################################################################################
-- YOUR CODE ON WIN - START ///////////////////
-- #################################################################################

    if balance > ath then
	  ath = balance
      currentbetAmount = basebet
      currWinChance    =  winchance
      --resetpartialprofit()
    else
      if (currWinChance == winchance) then 
        currentbetAmount = currentbetAmount/2
      end
      currWinChance    =  winchance
    end

-- #################################################################################
-- YOUR CODE ON WIN - END /////////////////////
-- #################################################################################

    chance  = currWinChance
    nextbet = currentbetAmount  
    -----------------------------------------------
    losestreak = 0
    -----------------------------------------------
  else
    -----------------------------------------------
    losestreak = losestreak +1
    -----------------------------------------------   
    local currentbetAmount = previousbet
    local currWinChance = chance

-- #################################################################################
-- YOUR CODE ON LOSE - START //////////////////
-- #################################################################################

    currentbetAmount = PercentageIncreaseValue(currentbetAmount,inc) 

    if(losestreak > losestreak_checkpoint) then
      currWinChance = winchance*3
    end

-- #################################################################################
-- YOUR CODE ON LOSE - END ////////////////////
-- #################################################################################

    chance  = currWinChance
    nextbet = currentbetAmount
    -----------------------------------------------
    winstreak = 0
    -----------------------------------------------
  end

  CeckMinMaxBetAmount()

 
	if balance > goal then 
		log("\n \t Finale Gain\t »»» " ..string.format("%.8f", balance - sbal) .." [" ..string.format("%.2f", (balance - sbal)/(sbal/100)) .." %]" )
		stop()
	end	
	if bets % 50 == 0 then  
		log("\n \t Current Gain\t »»» " ..string.format("%.8f", balance - sbal) .." [" ..string.format("%.2f", (balance - sbal)/(sbal/100)) .." %]" )
	end
	if balance - nextbet < sl then
		log(" Stop Loss")
		stop()
	end
end