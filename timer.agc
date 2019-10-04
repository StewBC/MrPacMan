/*------------------------------------------------------------------------------*\

   Mr Pac Man - Arcade game "remake"

   Created by Stefan Wessels.
   Copyright (c) 2019 Wessels Consulting Ltd. All rights reserved.

   This software is provided 'as-is', without any express or implied warranty.
   In no event will the authors be held liable for any damages arising from the use of this software.

   Permission is granted to anyone to use this software for any purpose,
   including commercial applications, and to alter it and redistribute it freely.

\*------------------------------------------------------------------------------*/

//----------------------------------------------------------------------------
// Always use timers by ID unless you use the index right after a done or
// find.  The index isn't neccesarily valid accross frames as timers come
// and go

//----------------------------------------------------------------------------
// The main way to create timers
function timerMakeTimer(time as float, timerFlag as integer, timerData ref as TypeTimerData)
	local gt as TypeTimer
	
	gt.ID = GameTimerNextID
	gt.timerFlag = timerFlag
	gt.time = time
	gt.setTime = time
	gt.timerData = timerData

	gameTimers.insert(gt)
	
	timerData.index = gameTimers.length
	
	inc gameTimerNextID
	
	// Won't happen but if wrapping, don't have an ID of 0
	// that way the game can use 0 as an unused timerID
	if not gameTimerNextID then inc gameTimerNextID

endFunction gt.ID

//----------------------------------------------------------------------------
// Shorthand countdown timer
function timerMakeWrap(time as float)
	
	local id as integer
	local timerData as TypeTimerData
	
	id = timerMakeTimer(time, TIMER_FLAG_WRAP, timerData)
	
endFunction id

//----------------------------------------------------------------------------
// Shorthand countdown timer
function timerMakeOneShot(time as float)
	
	local id as integer
	local timerData as TypeTimerData
	
	id = timerMakeTimer(time, TIMER_FLAG_DESTROY, timerData)
	
endFunction id

//----------------------------------------------------------------------------
// Set the user data in a timer with matching ID
function timerSetTimerData(id as integer, timerData ref as TypeTimerData)

	local i, done as integer
	
	done = 0
	for i = 0 to gameTimers.length
		if gameTimers[i].ID = id
			timerData.index = i
			gameTimers[i].timerData = timerData
			done = 1
			exit
		endif
	next i

endFunction done

//----------------------------------------------------------------------------
// Get the user data in a timer with matching ID
function timerGetTimerData(id as integer, timerData ref as TypeTimerData)

	local i, done as integer
	
	done = 0
	for i = 0 to gameTimers.length
		if gameTimers[i].ID = id
			timerData.index = i
			timerData = gameTimers[i].timerData
			done = 1
			exit
		endif
	next i

endFunction done

//----------------------------------------------------------------------------
// Set the user data in a timer directly at array index
function timerByIndexSettimerData(timerData ref as TypeTimerData)
	
	local i, done as integer
	
	done = 0
	if timerData.index <= gameTimers.length
		gameTimers[timerData.index].timerData = timerData
		done = 1
	endif

endFunction done

//----------------------------------------------------------------------------
// Delete a timer
function timerDeleteTimer(id as integer)
	
	local i, done as integer
	
	done = 0
	for i = 0 to gameTimers.length
		if gameTimers[i].ID = id 
			done = 1
			gameTimers.remove(i)
			exit
		endif
	next i
	
endFunction done

//----------------------------------------------------------------------------
// If the time <= 0 then fire will be 1, otherwise 0.  This returns fire
// and sets the index to a correct value and fills in timerData from the timer
function timerIsDoneAndGetTimerData(id as integer, timerData ref as TypeTimerData)
	
	local i, done as integer
	
	done = 0
	for i = 0 to gameTimers.length
		
		if gameTimers[i].ID = id
			gameTimers[i].timerData.index = i
			done = gameTimers[i].fire
			timerData = gameTimers[i].timerData
			exit
		endif
		
	next i

endFunction done

//----------------------------------------------------------------------------
// If the time <= 0 then fire will be 1, otherwise 0.  This returns fire.
function timerIsDone(id as integer)
	
	local timerData as TypeTimerData
	
	done = timerIsDoneAndGetTimerData(id, timerData)
	
endFunction done

//----------------------------------------------------------------------------
// return the index of the timer.  Index is only valid right there and then
// should not be cached and reused as it will change if timers are deleted
function findTimerIndex(id as integer)
	
	local i as integer
	
	for i = 0 to gameTimers.length
		if gameTimers[i].ID = id
			gameTimers[i].timerData.index = i
			exitFunction i
		endif
	next i
	
endFunction -1

//----------------------------------------------------------------------------
// Updates the time, sets/unsets fire on the timers and deletes timers with 
// TIMER_FLAG_DESTROY set
function updateTimers()
	
	local i as integer
	local deadTimers as integer[]

	for i = 0 to gameTimers.length
		
		dec gameTimers[i].time, dt#

		// Mark timers that had fired as dead so they can be removed
		if gameTimers[i].fire and gameTimers[i].timerFlag = TIMER_FLAG_DESTROY then deadTimers.insert(i)
		gameTimers[i].fire = 0
		
		if gameTimers[i].time <= 0.0
			
			gameTimers[i].fire = 1
			
			if gameTimers[i].timerFlag = TIMER_FLAG_WRAP
				inc gameTimers[i].time, gameTimers[i].setTime
			else
				gameTimers[i].time = gameTimers[i].setTime
			endif
		endif
		
	next i
	
	for i = deadTimers.length to 0 step -1
		gameTimers.remove(deadTimers[i])
	next i

endFunction
