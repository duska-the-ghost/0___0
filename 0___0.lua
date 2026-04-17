-- 0___0
-- 
--   tape looper
--
--      x2 wtape
--
--
--
-----------------
--
--
--
-- play/rev/rec/echo
-- loop start/ loop end
-- loop active
-- loop playhead indicator
-- erase_strength selector
-- rec/monitor_level selector
--
-- TODO 
-- Setup Frequency and Speed relationship and how to get scales from musicutil
--
----------------

local musicutil = include 'lib/0___0_musicutil'

With = 1      -- can be 1 or 2 determines which W/ gets commands

wWith = {1,0} -- to check if key is selected
bCast = 0     -- 0 or 1 determines if calls are sent to both w/s
w1 = 0        -- to check state of W/1 select key, 1 = pressed
w2 = 0        -- to check state of W/2 select key, 1 = pressed
Shift = 0    -- to check if shift key is selected, 1 = pressed

-- to keep track of W/s states 1 or 0
wPlay = {0,0}
wRev = {0,0}
wRec = {0,0}
wEcho = {0,0}
wStart = {0,0}
wEnd = {0,0}
wLoop = {0,0}


-- to keep track of W/s data floats and int
wErase = {11,11} -- holds x position of grid, converted to useful float in erase()
wMonLevel = {16,16} -- holds x position of grid, converted to useful float in monLevel()
wRecLevel = {16,16} -- holds x position of grid, converted to useful float in recLevel() 
wSpeed = {0,0} -- holds speed
wFreq = {0,0} -- holds frequency
lStime = {0,0}  -- to hold timestamp
lEtime = {0,0}  -- to hold timestamp
lPos = {1,1}    -- to hold loop position on grid
dir = {1,1}     -- 1 = forward, -1 = reverse

g = grid.connect() -- connect to your grid


function init()
  -- initialize startup state for W/s
  -- TODO 
  -- define with params. saved states and resetable
  for i = 1, 2 do
    crow.ii.wtape[i].loop_active(0)
    crow.ii.wtape[i].speed(1)
    crow.ii.wtape[i].freq(0)
    crow.ii.wtape[i].play(0) -- TODO: why is W1 init set to (1)?
    crow.ii.wtape[i].record(0)
    crow.ii.wtape[i].echo_mode(0)
    crow.ii.wtape[i].erase_strength(0.5)
    crow.ii.wtape[i].monitor_level(1)
    crow.ii.wtape[i].rec_level(1)   
  end
  
  -- initiate grid rows for loop indicators
  for j = 1, 2 do
    for k = 1, 16 do
      g:led(k,j,1) 
    end
  end
  
  Lights()
end


----------------
-- grid

g.key = function(x,y,z)
  
 if y == 8 then
  if z == 1 then
    if x == 1 then
      w1 = 1

      if bCast == 1 then
        -- from bCast, tap W1 -> W1
        bCast = 0
        With = 1
        wWith = {1,0}
      else
        -- normal selection
        With = 1
        wWith = {1,0}

        -- if both are now down together, latch broadcast
        if w2 == 1 then
          bCast = 1
          wWith = {1,1}
        end
      end

      Lights()
      return

    elseif x == 2 then
      w2 = 1

      if bCast == 1 then
        -- from bCast, tap W2 -> W2
        bCast = 0
        With = 2
        wWith = {0,1}
      else
        -- normal selection
        With = 2
        wWith = {0,1}

        -- if both are now down together, latch broadcast
        if w1 == 1 then
          bCast = 1
          wWith = {1,1}
        end
      end

      Lights()
      return

    elseif x == 16 then
      -- Shift function toggle
      Shift = 1 - Shift
      Lights()
      return
    end

  elseif z == 0 then
    if x == 1 then
      w1 = 0
    elseif x == 2 then
      w2 = 0
    end

    -- release does not change latched mode
    Lights()
    return
  end
end
  
  if Shift == 1 then
    -- handle shifted behavior only
    return
  end

  if z == 1 then
    
    if y == 7 then
    -- record current W/  
      if x == 1 then
        wRec[With] = 1 - wRec[With]
        rec(With, wRec[With])
        print("W/" .. With .. " recording " .. wRec[With] )
      elseif x == 2 then
    -- switch for echo mode
        wEcho[With] = 1 - wEcho[With]
        echo(With,wEcho[With])
        print("W/" .. With .. " echo " .. wEcho[With] )
      end
      
      if x > 5 then
        wErase[With] = x
        erase(With,x)
        print(wErase[With])
      end
        
    elseif y == 6 then 
    -- play current W/
      if x == 1 then
        wPlay[With] = 1 - wPlay[With]
        play(With, wPlay[With])
        print("W/" .. With .. " playing " .. wPlay[With] )
    -- reverse current W/
      elseif x == 2 then
        rev(With)
      end
    -- speed selector current W/
      if x > 5 then
        wSpeed[With] = x
        speed(With,x)
        print(wSpeed[With])
      end
    
    elseif y == 5 then
    -- set loop in/out
      if x == 1 then
        wStart[With] = 1
        lStart(With, 1)
        print("W/ " .. With )
      elseif x == 2 then
        wEnd[With] = 1
        lEnd(With, 1)
        wLoop[With] = 1
      elseif x == 3 then
        wStart[With] = 1 - wStart[With]
        wEnd[With] = 1 - wEnd[With]
        wLoop[With] = 1 - wLoop[With]
        lActive(With,wLoop[With])
      end
 
    elseif y == 4 then
    -- record level selector current W/
      if x > 5 then
        wRecLevel[With] = x
        recLevel(With,x)
        print(wRecLevel[With])
      end
 
    elseif y == 3 then
    -- monitor level selector current W/
      if x > 5 then
        wMonLevel[With] = x
        monLevel(With,x)
        print(wMonLevel[With])
      end
    end   
   
    -- call to update grid lights
    Lights()
    
    print(x,y)
  end

end

function Lights()
-- illuminate the grid based on current status of W/
-- which W/
  if bCast == 1 then
    g:led(1,8,12+3)  
    g:led(2,8,12+3)  
  else
    g:led(1,8,wWith[1]*12+3)  
    g:led(2,8,wWith[2]*12+3)  
  end
  
-- is grid shifted???
  g:led(16,8,(Shift or 0)*12+3)
    
  
-- who is playing???
  g:led(1,6,(wPlay[With] or 1)*12+3)
  
-- is it reversed??? 
  if bCast == 1 then
    if dir[1] == -1 or dir[2] == -1 then
      g:led(2,6,15)
    else
      g:led(2,6,3)
    end
  else
    g:led(2,6,(wRev[With] or 0) * 12 + 3)
  end
  
-- who is recording???
  g:led(1,7,(wRec[With] or 1) *12+3)
  
-- is it in echo mode???
  g:led(2,7, (wEcho[With] or 1) *12+3)
  
-- erase strength?
-- iterate through erase strength indicator and zero it out
  for i = 1, 11 do 
    g:led(5+i,7,3)
  end

-- iterate through speed indicator and zero it out
  for i = 1, 11 do 
    g:led(5+i,6,3)
  end
  
-- iterate through recLevel strength indicator and zero it out
  for i = 1, 11 do 
    g:led(5+i,4,3)
  end
  
 -- iterate through monLevel strength indicator and zero it out
  for i = 1, 11 do 
    g:led(5+i,3,3)
  end
   
  
  
-- then write the current value

  if wErase[1] == wErase[2] then --check if value is equal/stacked and display full brightness
    g:led(wErase[2],7, 1*12+3)
  else
    g:led(wErase[2],7, wWith[2]*12+3) -- display brightness based on With when not stacked
    g:led(wErase[1],7, wWith[1]*12+3)
  end

  if wSpeed[1] == wSpeed[2] then --check if value is equal/stacked and display full brightness
    g:led(wSpeed[2],6, 1*12+3)
  else
    g:led(wSpeed[2],6, wWith[2]*12+3) -- display brightness based on With when not stacked
    g:led(wSpeed[1],6, wWith[1]*12+3)
  end
  
  if wRecLevel[1] == wRecLevel[2] then --check if value is equal/stacked and display full brightness
    g:led(wRecLevel[2],4, 1*12+3)
  else
    g:led(wRecLevel[2],4, wWith[2]*12+3) -- display brightness based on With when not stacked
    g:led(wRecLevel[1],4, wWith[1]*12+3)
  end
 
 
  if wMonLevel[1] == wMonLevel[2] then --check if value is equal/stacked and display full brightness
    g:led(wMonLevel[2],3, 1*12+3)
  else
    g:led(wMonLevel[2],3, wWith[2]*12+3) -- display brightness based on With when not stacked
    g:led(wMonLevel[1],3, wWith[1]*12+3)
  end


-- is loop set????
  g:led(1,5, (wStart[With] or 0)*12+3)
  g:led(2,5, (wEnd[With] or 0)*12+3)
-- illuminate key for loop activation
  g:led(3,5, 3)

  
-- will start creating indicators for both W/s current state. active W/ will be displayed brighter than inactive W/   
-- see handling of erase strength above for how this can work
-- to refresh the lights
  g:refresh()
end

----------------
-- w/ functions
-- crow.ii.wtape.help() 
-- call this to see list of actual functions

function play(w,p)
  if bCast == 1 then
    for i = 1, 2 do
      wPlay[i] = p
      crow.ii.wtape[i].play(p)
    end
  else
    crow.ii.wtape[w].play(p)
  end
  
 --[[ if wStart[1] == 1 then
    l1:start()
  end
  if wStart[2] == 1 then
    l2:start()
  end ]]--
end

function rec(w,p)
  if bCast == 1 then
    for i = 1, 2 do
      wRec[i] = p
      crow.ii.wtape[i].record(p)
    end
  else
    crow.ii.wtape[w].record(p)
  end
end

function erase(w,p)
  if bCast == 1 then
    wErase[1] = p
    wErase[2] = p
    p = (10 -(p-16) -10)/ 10
    for i = 1, 2 do
      crow.ii.wtape[i].erase_strength(p)
    end
  else
    p = (10 -(p-16) -10)/ 10
    crow.ii.wtape[w].erase_strength(p)
  end
end

function speed(w,p)
  if bCast == 1 then
    wSpeed[1] = p
    wSpeed[2] = p
    p = (10 -(p-16) -10)/ 10
    for i = 1, 2 do
      crow.ii.wtape[i].speed(p)
    end
  else
    p = (10 -(p-16) -10)/ 10
    crow.ii.wtape[w].speed(p)
  end
end

function recLevel(w,p)
  if bCast == 1 then
    wRecLevel[1] = p
    wRecLevel[2] = p
    p = (10 -(p-16) -10)/ 10
    for i = 1, 2 do
      crow.ii.wtape[i].rec_level(p)
    end
  else
    p = (10 -(p-16) -10)/ 10
    crow.ii.wtape[w].rec_level(p)
  end
end

function monLevel(w,p)
  if bCast == 1 then
    wMonLevel[1] = p
    wMonLevel[2] = p
    p = (10 -(p-16) -10)/ 10
    for i = 1, 2 do
      crow.ii.wtape[i].monitor_level(p)
    end
  else
    p = (10 -(p-16) -10)/ 10
    crow.ii.wtape[w].monitor_level(p)
  end
end

function echo(w,p)
  if bCast == 1 then
    for i = 1, 2 do
      wEcho[i] = p
      crow.ii.wtape[i].echo_mode(p)
    end
  else
    crow.ii.wtape[w].echo_mode(p)
  end
end

function rev(w)
  if bCast == 1 then
    for i = 1, 2 do
      wRev[i] = 1 - (wRev[i] or 0)
      dir[i] = (dir[i] or 1) * -1
      crow.ii.wtape[i].reverse()
    end
  else
    wRev[w] = 1 - (wRev[w] or 0)
    dir[w] = (dir[w] or 1) * -1
    crow.ii.wtape[w].reverse()
  end
end

function lStart(w,p)
  if bCast == 1 then
    for i = 1, 2 do
      wStart[i] = p
      crow.ii.wtape[i].loop_start(p)
      crow.ii.wtape[i].get('loop_start')
    end
  else
    crow.ii.wtape[w].loop_start(p)
    crow.ii.wtape[w].get('loop_start')
  end
end

function lEnd(w,p)
  if bCast == 1 then
    for i = 1, 2 do
      wEnd[i] = p
      crow.ii.wtape[i].loop_end(p)
      crow.ii.wtape[i].get('loop_end')
      --l1:start() ?????
      --l2:start() ?????
    end
  else
    crow.ii.wtape[w].loop_end(p)
    crow.ii.wtape[w].get('loop_end')
    
  end
end

function lActive(w,p)
  if bCast == 1 then
    for i = 1, 2 do
      wLoop[i] = p

      crow.ii.wtape[i].loop_active(p)
      if p == 0 then
        l1:stop()
        l2:stop()
      elseif p == 1 then
        crow.ii.wtape[i].timestamp(lStime[i])
        crow.ii.wtape[i].loop_active(p)
        l1:start()
        l2:start()
      end
      lPos[i] = 1
    end
  else
   
    crow.ii.wtape[w].loop_active(p)
    lPos[w] = 1
    if w == 1 then
      if p == 0 then
        l1:stop()
      elseif p == 1 then
        crow.ii.wtape[w].timestamp(lStime[w])
        crow.ii.wtape[w].loop_active(p)
        l1:start()
      end
    elseif w == 2 then
      if p == 0 then
        l2:stop()
      elseif p == 1 then
        crow.ii.wtape[w].timestamp(lStime[w])
        crow.ii.wtape[w].loop_active(p)
        l2:start()
      end
    end
  end
end



-- to determine getter calls!!!!!


crow.ii.wtape.event = function( e, value )
	if e.name == 'loop_start' then
	 -- lS[e.device] = value
	  lStime[e.device] = value
    print('loop_start ' .. value)
    print(e.device)-- will print the time stamp of loop start
	elseif e.name == 'loop_end' then
    lEtime[e.device] = value
    if e.device == 1 then
      l1.time = math.abs((lEtime[1]-lStime[1])/16)
      print('time ' .. l1.time)
      l1:start()
    elseif e.device == 2 then
      l2.time = math.abs((lEtime[2]-lStime[2])/16)
      l2:start()
    end
    print('loop_end ' .. value) -- will print value of loop end
  elseif e.name == 'timestamp' then
    print('timestamp ' .. value) -- will print current playhead timestamp
     -- we can do more than just print the value here
     -- we can also save it in a previously defined variable
      -- wTime = value  -- now wTime will be filled with the current timestamp
	end
end

l1 = metro.init()
l1.time = 1
l1.event = function()
  lPos[1] = (lPos[1] + dir[1]) % 16
  g:led(lPos[1]-dir[1],1,3)
  g:led(lPos[1],1,15)
  Lights()
  if wPlay[1] == 0 then
    l1:stop()
  end
end

l2 = metro.init()
l2.time = 1
l2.event = function()
  lPos[2] = (lPos[2] + dir[2]) % 16
  g:led(lPos[2]-dir[2],2,3)
  g:led(lPos[2],2,15)
  Lights()
  if wPlay[2] == 0 then
    l2:stop()
  end
end

-----------------------------------------------------
-----------------------------------------------------
-----------------------------------------------------
-- below is 1a test for storing metros in a list and calling them programatically.
-- to start the below metro
-- loop[1]:start()
-- 
-- this would allow iterative ability to start and stop any number of clocks from a single function.
-- could also be applied to normal functions I think. so, all the above functions for play/record/etc.
-- could be consolidated into a single function just called with a different index, or some such...
-- I'm still trying to work out the details... but this could simplify many repetitive functions.
tester = 0
loop = {}
loop[1] = metro.init()
loop[1].time = 1
loop[1].event = function()
  tester = tester + 1
  print(tester)
end

-----------------------------------------------------
-----------------------------------------------------
-----------------------------------------------------
-----------------------------------------------------
-----------------------------------------------------
-----------------------------------------------------
-- an algorithm to randomly jumble a loop
-- taken from wip script REVAEW
-- built for softcut initally, 
-- but could possibly work for w/tape?????
-- and it seems to.
-- run the newRhythm() function to jumble your loop
-- currently no way out of it. But still fun
-----------------------------------------------------
-----------------------------------------------------
sampleBufLeng = 0 --200

bufLengMin = 6
bufLengMax = 40
newBufLeng = 0

playBack = {}
playRate = {}
playPan = {}
playTime = {}
playCount = 1

encOrigin = 0

diceRoll = 0

rateRat = { 1/1, 16/15, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3, 16/9, 15/8}
rateOct = {0.25, 0.5, 1, 2, 4}
rateDir = {-1,1}

-- textural variables
dTime = 0.3


playClock = metro.init()
playClock.time = 1
playClock.event = function()
  --softcut.rate(2,playRate[playCount])
  if playRate[playCount] ~= nil then
    crow.ii.wtape[1].speed(playRate[playCount])
  end
  --softcut.loop_start(2,playBack[playCount]/100)
  if playBack[playCount] ~= nil then
    crow.ii.wtape[1].timestamp(playBack[playCount])
  end
  
  --softcut.loop_end(2,(playBack[playCount]/100)+1)
  --softcut.pan(2,(playPan[playCount]))
  playClock.time = playTime[playCount]
  --softcut.play(2,1)
  playCount = playCount + 1
  --print(playCount)
  if playCount > newBufLeng then
    playCount = 1
    print("wrap")
  end
end


function newRhythm()
  playClock:stop()
  --clear tables
  playBack = {}
  playRate = {}
  playPan = {}
  playTime = {}
  playCount = 1
  -- generate a random number for newBufLeng, witihin a range of values
  newBufLeng = math.random(bufLengMin,bufLengMax)
  
  -- use newBufLeng and generate a new series of start positions within the range of the samplBufLeng
  for i = 1, newBufLeng do
    
    -- play back order
    table.insert(playBack,(math.random() * (lEtime[1] - lStime[1]) + lStime[1]))
    --table.insert(playBack,math.random(0,sampleBufLeng)) 
    table.insert(playTime, math.random(11,50)/100)
    --table.insert(playPan,(math.random(1,150)/100)-0.75)
    
    -- play back speeds
    diceRoll = math.random(1,20)
    if diceRoll > 14 then
      table.insert(playRate, rateRat[math.random(1,8)] * rateOct[math.random(1,4)] * rateDir[math.random(1,2)])
    else
      table.insert(playRate,1)
    end
    
    -- other play back parameters
    
  end
  wLoop[With] = 0
  lActive(With,wLoop[With])
  Lights()
  playClock.time = 0.1
  playClock:start()
end

function stopRhythm()
  playClock:stop()
  wLoop[With] = 1
  lActive(With,wLoop[With])
  crow.ii.wtape[1].speed(1)
  Lights()
end

-------------------------------------
-------------------------------------
-------------------------------------



function cleanup()
  print("sweep, sweep, sweep, all clean!")
end
