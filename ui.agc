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
// Main UI entry point - called from main
function uiMain()

	select uiState
		
		case UI_STATE_INIT
			stateUIInit()
		endcase

		case UI_STATE_LIGHTS_ON
			stateUILightsOn()
		endcase
		
		case UI_STATE_NEXT_GUY
			stateUINextGuy()
		endcase
		
		case UI_STATE_MOVE_TO_TURN
			stateUIMoveToTurn()
		endcase
		
		case UI_STATE_MOVE_FROM_TURN
			stateUIMoveFromTurn()
		endcase
		
		case UI_STATE_MOVE_PACMAN
			stateUIMovePacman()
		endcase
		
		case UI_STATE_WAIT
			stateUIWait()
		endcase
		
		case UI_STATE_CLEANUP
			stateUICleanup()
		endcase
		
	endselect
	
	// As long as UI is initialised, light up the next lights
	// in the Marquee, and turn off the currently lit light
	if uiState <> UI_STATE_INIT then uiAnimateLights()

endfunction

//----------------------------------------------------------------------------
// Load the UI screen and do some init
function stateUIInit()

	local i as integer
	
	// Create the UI (marquee) - This would be much better done in code but
	// I wanted to see how I could do it using the level editor
	FrontEnd_setup()
	
	// Hide the marquee sprites
	for i = 0 to FrontEnd_lights.length
		SetSpriteVisible(FrontEnd_lights[i], 0)
	next i
	
	// Get the lights into a usable sorted order a->b->c->d->a
	uiSortLights()

	// Get the lights on and wait a while
	UiState = UI_STATE_LIGHTS_ON
	
	// This indicates which charater is moving
	activeCharacter	= -1

	// This is which light (in a segment) in the marquee is currently ON
	lightsIndex = 0
	
	for i = 0 to characters.length
		// run (re-)setup on the characters to get them into a known good state
		characterSetup(characters[i], characters[i].characterType)
		// Move all of the characters off-screen to the initial position for the UI
		SetSpritePositionByOffset(characters[i].sprite, UI_MONSTER_INITIAL_X, UI_MONSTER_INITIAL_Y)
	next i

	// Set the timer to wait before starting
	oneShotTimer = timerMakeOneShot(TIME_WAIT_FOR_LIGHTS)
	
	// Show the text needed
	SetTextVisible(textHandles[TEXT_GAME_TITLE], 1)
	SetTextVisible(textHandles[TEXT_CREDITS], 1)
	SetTextVisible(textHandles[TEXT_NUMCREDITS], 1)
	
	// Advance to next state
	uiState = UI_STATE_LIGHTS_ON
	
endFunction

//----------------------------------------------------------------------------
// Show the WITH when introducing the cast of monsters
function stateUILightsOn()

	if timerIsDone(oneShotTimer)
		SetTextVisible(textHandles[TEXT_WITH], 1)
		UiState = UI_STATE_NEXT_GUY
	endif

endfunction

//----------------------------------------------------------------------------
// Prep each character for its introduction.  Also handl ethe text display
function stateUINextGuy()

	// After Blinky, turn of the prev character's name (and the word "with")
	if activeCharacter >= 0 
		SetTextVisible(textHandles[TEXT_WITH], 0)
		SetTextVisible(textHandles[TEXT_BLINKY+activeCharacter], 0)
	endif
	
	// Next Character, and show their name
	inc activeCharacter
	SetTextVisible(textHandles[TEXT_BLINKY+activeCharacter], 1)
	
	// 1st all the monsters, then switch to Mr PacMan
	if activeCharacter > NUM_MONSTERS
		// Show the PacMan and STARRING
		SetSpriteVisible(characters[CHARACTER_PACMAN].sprite, 1)
		SetTextVisible(textHandles[TEXT_STARRING], 1)
		// Get him walking left
		characterSetDirection(characters[CHARACTER_PACMAN], DIRECTION_LEFT)
		// Tell him where to stop
		characters[CHARACTER_PACMAN].moveDest = UI_PACMAN_STOP_X
		UiState = UI_STATE_MOVE_PACMAN
	else
		// Show the monster and get it walking left to the turn point
		SetSpriteVisible(characters[CHARACTER_BLINKY+activeCharacter].sprite, 1)
		characterSetDirection(characters[CHARACTER_BLINKY+activeCharacter], DIRECTION_LEFT)
		characters[CHARACTER_BLINKY+activeCharacter].moveDest = UI_MONSTER_TURN_X
		UiState = UI_STATE_MOVE_TO_TURN
	endif

endfunction

//----------------------------------------------------------------------------
// Wait for the character to get past the marquee so it can turn up
function stateUIMoveToTurn()

	local x, arrived as integer
	local moveResult as TypeMoveResult
	
	arrived = characterMove(characters[CHARACTER_BLINKY+activeCharacter], moveResult)

	// Onced the monster is at the turn point, get it walking up
	if arrived
		characterSetDirection(characters[CHARACTER_BLINKY+activeCharacter], DIRECTION_UP)
		characters[CHARACTER_BLINKY+activeCharacter].moveDest = UI_MONSTER_INITIAL_Y - (CHARACTER_SPRITE_HEIGHT / 4.0) - (NUM_MONSTERS + 1 - activeCharacter) * CHARACTER_SPRITE_HEIGHT
		UiState = UI_STATE_MOVE_FROM_TURN
	endif

endfunction

//----------------------------------------------------------------------------
// Wait for the character to move to its spot next to the marquee
function stateUIMoveFromTurn()

	local y, arrived as integer
	local moveResult as TypeMoveResult

	arrived = characterMove(characters[CHARACTER_BLINKY+activeCharacter], moveResult)

	// If the monster has reached its dest in Y (UP) then do the next character
	if arrived
		characterSetDirection(characters[CHARACTER_BLINKY+activeCharacter], DIRECTION_NONE)
		UiState = UI_STATE_NEXT_GUY
	endif

endfunction

//----------------------------------------------------------------------------
// Move Pac Man to the middle of the screen
function stateUIMovePacman()

	local x, arrived as integer
	local moveResult as TypeMoveResult

	arrived = characterMove(characters[CHARACTER_PACMAN], moveResult)

	// Pacman walks to the middle only so once there, go to wait
	if arrived
		characterSetDirection(characters[CHARACTER_PACMAN], DIRECTION_NONE)
		oneShotTimer = timerMakeOneShot(TIME_WAIT_FOR_DEMO)
		UiState = UI_STATE_WAIT
	endif

endfunction

//----------------------------------------------------------------------------
// Hold the screen for a while before starting the gameplay demo
function stateUIWait()
	
	if timerIsDone(oneShotTimer)
		stateUICleanup()
		// Override main to go to demo instead
		mainState = MAIN_STATE_DEMO
	endif
endFunction

//----------------------------------------------------------------------------
// Unload the UI screen and prep the UI to be run again later
function stateUICleanup()
	
	local i as integer
	
	FrontEnd_cleanup()
	Frontend_lights.length = -1

	levelHideDynamicElements()
	
	for i = 0 to characters.length
		SetSpriteVisible(characters[i].sprite, 0)
	next i

	// Reset UI
	uiState = UI_STATE_INIT
	
	// set main to go to game
	mainState = MAIN_STATE_PLAY
	
endFunction

//----------------------------------------------------------------------------
// Animate the marquee in a framerate independent way (meant to be at 60 FPS)
function uiAnimateLights()
	
	local i, j, strip, index, lsi as integer
	
	// Cut into UI_NUM_LIGHTS_ON number of strips
	strip = (Frontend_lights.length + 1) / UI_NUM_LIGHTS_ON

	// make lights framerate independent, so accumulate frametime
	inc lightsStep#, dt#
	// get an integer frame counter that's 1 at 60 fps (don't round up, use floor)
	lsi = floor(lightsStep# / (1.0/60.0))
	// if FPS is > than 60, then wait till we get to 60 fps, i.e. lsi is >= 1
	// at 30 fps, lsi would be 2, etc.  lsi is the light step index
	if lsi < 1 then exitFunction
	// if the FPS is so low that the step is longer than the strip, then just step 1
	if lsi > strip then lsi = 1

	// Move the index for which light to turn on next
	dec lightsIndex, lsi
	// if there's underflow tnen wrap
	if lightsIndex < 0 then inc lightsIndex, strip
	
	// for each strip
	for i = 0 to UI_NUM_LIGHTS_ON-1
		// and for all lights in this lights step (1 at 60+ fps, more at lower fps)
		// This will do minimum 2 loops, 0 and 1 as lsi is always 1+
		for j = 0 to lsi
			// get an index to the light to set
			index = lightsIndex + j + strip * i
			// if that light is out of bounds, wrap it to be in-bounds
			if index > Frontend_lights.length then dec index, Frontend_lights.length+1
			// Set the 1st light to white
			if not j
				SetSpriteColor(Frontend_lights[index], 255, 255, 255, 255)
			else
				// and set all other lights in this step to red
				SetSpriteColor(Frontend_lights[index], 255, 0, 0, 255)
				SetSpriteVisible(Frontend_lights[index], 1)
			endif
		next j
	next i

	// reset the counter to make sure this does not run any faster than 60 fps
	lightsStep# = 0.0
	
endFunction

//----------------------------------------------------------------------------
// This code seems totally redicioulous, but that's all I could come up with
// the corners a, b, c and d of the marquee are a b
//                                              d c
function uiSortLights()
	
	local sort as integer[-1,-1]
	local i, x, y, dir as integer
	
	// Make a 2d sort
	level2DSortSpriteArray(Frontend_lights, sort)

	// start at the upper left and walk the 2D grid looking for the first light	
	y = 0
	x = 0
	while y <= sort.length 
		x = 0
		while not found and x < sort[y].length
			if sort[y,x]
				found = 1
				exit
			endif
			inc x
		endwhile
		if found then exit
		inc y
	endwhile
	
	// now walk the lights in a clockwise moveDir, assigning them back
	// into the frontend_lights array.  This code absolutely relies
	// on the data being correct.  dir is the moveDir to walk with
	// 0 being up, 1 = right, 2 = down and 3 = left
	// if the data isn't right this could crash or loop endlessly
	dir = 1
	// where to insert the next light
	i = 0
	// when the "found" light is the 1st (0th) light the circle is complete
	Frontend_lights[0] = -1
	// keep going till done (when the light found is the 1st light)
	while sort[y,x] <> Frontend_lights[0]
		// assign the light
		Frontend_lights[i] = sort[y,x]
		// ready for next light
		inc i
		// next light not found
		found = 0
		// loop till a light was found
		while not found
			
			// walk in the direction the next light is expected to be
			select dir
				
				case DIRECTION_UP
					// check extents - stay on the grid (I later learned that setting the length would have been easier and is safe)
					if y-1 >= 0
						// assumes this next edibleGrid (array length) is at least as long as the neighbours
						if sort[y-1,x]
							// walk up
							dec y
							// and say the next light was found
							found = 1
						endif
					endif
					// if there wasn't a light up, turn right (clockwise)
					if not found then dir = 1
				endcase
		
				case DIRECTION_RIGHT
					if x+1 <= sort[y].length
						if sort[y,x+1]
							inc x
							found = 1
						endif
					endif
					if not found then dir = 2
				endcase
	
				case DIRECTION_DOWN
					if y+1 <= sort.length
						if sort[y+1,x]
							inc y
							found = 1
						endif
					endif
					if not found then dir = 3
				endcase
				
				case DIRECTION_LEFT
					if x-1 >= 0
						if sort[y,x-1]
							dec x
							found = 1
						endif
					endif
					if not found then dir = 0
				endcase

			endselect

		endwhile
	endwhile
	
endFunction
