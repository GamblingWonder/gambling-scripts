--------------------------------------------------------------
label       = "DICEBOT TEMPLATE TO PLAY KENO ON STAKE"
version     = "v1.3"
author      = "WinMachine"
--------------------------------------------------------------------------

-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
-- THIS IS JUST A SCRIPT TO DEMONSTRATE THE IMPLEMENTATION OF KENO GAME
-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

--------------------------------------------------------------------------
-- developed by winmachine (primedice/stake/wolf/duckdice: WinMachine)
-- stake.com/?c=WinMachine
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- All donations are welcome and appreciated! 
--------------------------------------------------------------
-- TRON : TUo92MJpmrrNYDCNgGGoMLNEnTkpTPcA6S
--------------------------------------------------------------
-- DOGE : DNwsyyhUw5Busx3t9uk6ZFcgYNzczHfM61
--------------------------------------------------------------
-- LTC  : LXrxHi8pUb6ieGkVDMMJbuBnodjPpitMJT
--------------------------------------------------------------
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-------------------------------------------------------------

-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
-- THIS IS JUST A SCRIPT TO DEMONSTRATE THE IMPLEMENTATION OF KENO GAME
-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

--------------------------------------------------------------------------
-------------------------------------------
--| risk : classic | low | medium | high
-------------------------------------------
--|  1 |  2 |  3 |  4 |  5 | 6  |  7 |  8 |
--|  9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
--| 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 |
--| 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 |
--| 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 |
-------------------------------------------

game     = "keno"
risk     = "high"   -- classic | low | medium | high
currency = "bch"       -- set currency
bb1      = 0.0000001           -- 0.000001
inc1     = 1.05
chance   = 0

local numbersList = 
{
  [0]={1,2,3,4,5,6,7,8,9,10},
  [1]={10,11,26,27,14,23,30,39},
  [2]={1,10,19,28,37},
  [3]={8,15,22,29,36,27,18,9,2,11},
  [4]={1,2,3,4,5},
  [5]={6,7,8,9,10}
}

--local currentNumberSet = 0
local currentNumberSet = math.random(0,#numbersList)

nextbet = bb1

--selected = {1,2,3,4,5,6,7,8,9,10}
--selected = numbersList[1]
selected = numbersList[currentNumberSet]

function dobet()

  -- KENO VARIABLES
  print("-----------------------------------------------------------")
  print(lastBet.Amount)
  print(lastBet.Multiplier) --| decimal
  print(lastBet.Currency) --| decimal
  print(lastBet.nonce)
  print(lastBet.RiskRules) --| string

  print(lastBet.SubmitRaw)-- | string "1,2,3,4,5,6,7,8,9" last submited numbers
  print(lastBet.ResultRaw) --| string "1,6,3,4,7,9,10,15,29" last result numbers
  print(lastBet.Profit) --| decimal
  print(tostring(lastBet.IsWin)) --| bool
  print(lastBet.Hits) --| int | total of hits
  print("-----------------------------------------------------------")

  if win then

    if partialprofit > 0.00000001 then
      nextbet = bb1
      resetpartialprofit()
    end

    if lastBet.Multiplier > 5 then
      risk = "classic"
    else
      risk = "high"
    end
    
    if lastBet.Hits > 5 then
      risk = "classic"
    else
      risk = "medium"
    end
    
    --selected = numbersList[currentNumberSet]
    selected = numbersList[math.random(0,#numbersList)]    

  else

    nextbet  = previousbet * inc1   
    
    --selected = numbersList[currentNumberSet]
    selected = numbersList[math.random(0,#numbersList)]
    
    if currentstreak > -5 and risk ~= "high"   then
      risk = "high"
    end

  end

end