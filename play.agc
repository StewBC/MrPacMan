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
// Called from main - the state (machine) call function for play state
function playMain()
	
	// Flash the active player if not in demo mode, or GAME OVER when in demo mode
	if mainState <> MAIN_STATE_DEMO 
		if timerIsDone(textTimer) then SetTextVisible(textHandles[perPlayerNameIndex[activePlayer]], 1 - GetTextVisible(textHandles[TEXT_1UP+activePlayer]))
	else
		if timerIsDone(textTimer) then SetTextVisible(textHandles[TEXT_GAMEOVER], 1 - GetTextVisible(textHandles[TEXT_GAMEOVER]))
	endif
	
	select playState
		
		case PLAY_STATE_INIT
			playStateInit()
		endcase 
		
		case PLAY_STATE_LEVEL_INIT
			playStateLevelInit()
		endcase 
		
		case PLAY_STATE_PLAYER_INIT
			playStatePlayerInit()
		endcase 
		
		case PLAY_STATE_GET_READY
			playStateGetReady()
		endcase 
		
		case PLAY_STATE_RUN
			playStateRun()
		endcase 
		
		case PLAY_STATE_LEVEL_CLEAR
			playStateLevelClear()
		endcase 
		
		case PLAY_STATE_DIED
			playStateDied()
		endcase 
		
		case PLAY_STATE_CONVULSTIONS
			playStateConvulstions()
		endcase 
		
		case PLAY_STATE_PLAY_MORTIS
			playStateMortis()
		endcase 
		
		case PLAY_STATE_NEXT_PLAYER
			playStateNextPlayer()
		endcase 
		
		case PLAY_STATE_GAME_OVER_PLAYER
			playStateGameOverPlayer()
		endcase 
		
		case PLAY_STATE_CLEANUP
			playStateCleanup()
		endcase 
		
		case PLAY_STATE_RESTART
			playStateRestart()
		endcase 
	
	endselect 
		
endfunction

//----------------------------------------------------------------------------
// One time game init - give player's their lives, etc.
function playStateInit()
	
	local i, j as integer
	
	for i = 0 to numActivePlayers - 1
		players[i].isAlive = 0
		players[i].level = 0
		players[i].score = 0
		players[i].toEat = 0
		players[i].eaten = 0
		players[i].edibleGrid.length = -1
		players[i].walkableGrid.length = -1
		
		if mainState <> MAIN_STATE_DEMO
			// lives not the same for game and demo
			players[i].lives = NUM_PLAYER_LIVES
			for j = 1 to players[i].lives
				players[i].livesSprites.insert(playMakeLives(j))
			next j
			
			// Clean up the bonusDisplaySpriets
			for j = 0 to players[i].bonusDisplaySprites.length
				DeleteSprite(players[i].bonusDisplaySprites[j])
			next j
			players[i].bonusDisplaySprites.length = -1
	
		else
			// In demo mode, make sure there are enough lives to survive
			// the duration of the demo, so that demo cleanup runs,
			// not game over cleanup
			players[i].lives = 99
		endif
		
		// show the names and scores for participants
		SetTextVisible(textHandles[perPlayerNameIndex[i]], 1)
		SetTextVisible(textHandles[perPlayerScoreIndex[i]], 1)
	next i
	
	// Hide the names and scores for the unused players
	for i = numActivePlayers to MAX_PLAYERS-1
		SetTextVisible(textHandles[perPlayerNameIndex[i]], 0)
		SetTextVisible(textHandles[perPlayerScoreIndex[i]], 0)
	next i

	if mainState <> MAIN_STATE_DEMO
		// Hide the credits tags
		SetTextVisible(textHandles[TEXT_CREDITS], 0)
		SetTextVisible(textHandles[TEXT_NUMCREDITS], 0)
	endif
	
	// Player 1 (index 0) always starts
	activePlayer = 0

	SetTextVisible(textHandles[TEXT_HIGHSCORE], 1)
	textTimer = timerMakeWrap(TIME_TEXT_FLASH)

	playState = PLAY_STATE_LEVEL_INIT
	
endFunction

//----------------------------------------------------------------------------
// Setup a level to be played, sorting out walkable surfaces, etc.
function playStateLevelInit()
	
	local sort as integer[SCREEN_Y_ROWS,SCREEN_X_COLS]
	local x, y, toEat as integer 

	// Load the desired level
	toEat = levelSetupLevel(players[activePlayer].level, sort)
		
	// Create the player grid of dots
	if players[activePlayer].edibleGrid.length < 0
		// New level so set up the structures
		players[activePlayer].edibleGrid = sort
		players[activePlayer].toEat = toEat
		players[activePlayer].eaten = 0
	else
		// If the level is being re-initialized then delete the dots that were already eaten
		for y = 0 to players[activePlayer].edibleGrid.length
			for x = 0 to players[activePlayer].edibleGrid[y].length
				// Is the dot still visible
				if players[activePlayer].edibleGrid[y, x]
					players[activePlayer].edibleGrid[y, x] = sort[y, x]
				else
					DeleteSprite(sort[y, x])
				endif
			next x
		next y
	endif
	
	// Now add in the walkable areas
	levelSetupWalkable(levelGetLoadableLevel(players[activePlayer].level), sort)
		
	// Assign the walkable row to the player
	players[activePlayer].walkableGrid = sort
	
	playState = PLAY_STATE_PLAYER_INIT

endFunction

//----------------------------------------------------------------------------
// Setup the active player to start playing - init monsters, etc.
function playStatePlayerInit()
	
	timerData as TypeTimerData

	// Get pacman all the way to SUE ready
	for i = CHARACTER_PACMAN to CHARACTER_SUE
		// Set character to know base state
		characterSetup(characters[i], i)
		// in holding, characters don't move faster
		if characters[i].aiGoal = STATE_AIGOAL_HOLDING then characters[i].moveSpeed = SPEED_INITIAL_SPEED / 2.0
		// Position it for the game
		SetSpritePositionByOffset(characters[i].sprite, initialPositionsX[i] * MAZE_CELL_DIMENSIONS - GetSpriteOffsetX(characters[i].sprite), initialPositionsY[i] * MAZE_CELL_DIMENSIONS)
		// Have them (sprites) look in their initial directions
		characterSetFacing(characters[i], initialDirections[i])
		characters[i].moveDest = initialPositionsY[i] * MAZE_CELL_DIMENSIONS
		// Lock the characters in place anyway
		if initialDirections[i] = DIRECTION_UP or initialDirections[i] = DIRECTION_DOWN
			characters[i].moveDest = initialPositionsY[i] * MAZE_CELL_DIMENSIONS
		else
			characters[i].moveDest = initialPositionsX[i] * MAZE_CELL_DIMENSIONS - GetSpriteOffsetX(characters[i].sprite)
		endif
		// Make the sprite visible (characterSetup hides them)
		SetSpriteVisible(characters[i].sprite, 1)
	next i

	// Show the lives for the current player
	playShowLivesAndBonus(1)

	// Time till next state action
	oneShotTimer = timerMakeOneShot(TIME_WAIT_FOR_LIFE_POP)

	// The demo & game init a little differently
	if mainState <> MAIN_STATE_DEMO
	
		// If player isn't alive, hide pacman
		if not players[activePlayer].isAlive then SetSpriteVisible(characters[CHARACTER_PACMAN].sprite, 0)
		
		// It's a user controlling PACMAN
		characters[CHARACTER_PACMAN].aiGoal = STATE_AIGOAL_USER
		
		// PLAY_STATE_GET_READY has 1 sub-state, TIME_WAIT_FOR_LIFE_POP, done through timer
		timerData.userInt1 = 1
		timerSetTimerData(oneShotTimer, timerData)

		// Put the READY text on screen
		SetTextVisible(textHandles[TEXT_READY], 1)
		
	else
		// It's AI controlling PACMAN
		characters[CHARACTER_PACMAN].aiGoal = STATE_AIGOAL_WANDER
		// characters[CHARACTER_PACMAN].aiGoal = STATE_AIGOAL_SEEK
		characters[CHARACTER_PACMAN].aiInt1 = 0
	endif
	
	// Make sure there's no ghost score or bonus on-screen if it's a restart
	levelHideDynamicElements()

	// PACMAN always just goes left by default.
	desiredDirection = DIRECTION_LEFT
	
	// Go to next state while READY is shown
	playState = PLAY_STATE_GET_READY
	
endfunction

//----------------------------------------------------------------------------
// Manage the flow till ready disappears, then setup for gameplay
function playStateGetReady()
	
	local timerData as TypeTimerData
	
	// do nothing till the timer expires
	if not timerIsDoneAndGetTimerData(oneShotTimer, timerData) then exitFunction
	
	// end of first state? then pop a life onto the screen and wait some more
	// Not set for demo, just for playing
	if timerData.userInt1
	
		if not players[activePlayer].isAlive
			DeleteSprite(players[activePlayer].livesSprites[players[activePlayer].livesSprites.length])
			SetSpriteVisible(characters[CHARACTER_PACMAN].sprite, 1)
			players[activePlayer].livesSprites.remove()
			players[activePlayer].isAlive = 1
		endif
		
		// set up for the next sub-state and set a timer to end that sub-state
		dec timerData.userInt1
		oneShotTimer = timerMakeOneShot(TIME_WAIT_FOR_READY)
		timerSetTimerData(oneShotTimer, timerData)

		// Do nothing more for the current sub-state
		exitFunction
		
	endif
	
	// Because blinky and pacman start between dots, 1st order is to get them grid aligned
	// The other mosters need to stay till they are until they want to exit
	dec characters[CHARACTER_BLINKY].moveDest, GetSpriteOffsetX(characters[CHARACTER_BLINKY].sprite)
	dec characters[CHARACTER_PACMAN].moveDest, GetSpriteOffsetX(characters[CHARACTER_PACMAN].sprite)
	
	// Set PACMAN and all the monsters going	
	for i = CHARACTER_PACMAN to CHARACTER_SUE
		characterSetDirection(characters[i], initialDirections[i])
	next i

	// The ghosts ai will start by going to the corners
	aiTargetMode = AI_TARGET_CORNER
	
	// figure out what target level timings to use
	aiTargetLevel = players[activePlayer].level
	if aiTargetLevel > 1 and aiTargetLevel <= 4 then aiTargetLevel = 1
	if aiTargetLevel > 4 then aiTargetLevel = 2
	
	// Start the timer for ai mode switching
	aiTargetModeTimer = timerMakeOneShot(aiTargetModeTimings[aiTargetLevel, 0])
	timerData.userInt1 = 0
	timerSetTimerData(aiTargetModeTimer, timerData)
	
	// Start the timer for the bonus fruit
	bonusFruitTimer = timerMakeOneShot(TIME_TO_FIRST_FRUIT)
	
	// Hide the ready text and start the game
	SetTextVisible(textHandles[TEXT_READY], 0)
	playState = PLAY_STATE_RUN
	
endfunction

//----------------------------------------------------------------------------
// Normal execution loop - call AI, oversee ghost and seek mode and test for end of level
function playStateRun()
	
	local i as integer

	// Process all of the ai
	for i = 0 to characters.length 
		aiMain(characters[i])
	next i 

	// if ghosting active, see if it is expiring
	if ghostTimer
		if timerIsDoneAndGetTimerData(ghostTimer, timerData)
		
			if timerData.userInt1
				dec timerData.userInt1
				ghostTimer = timerMakeOneShot(TIME_GHOST_END_FLASH)
				timerSetTimerData(ghostTimer, timerData)
				aiGhostFlash()
			else
				ghostTimer = 0
				aiGhostEnd()
			endif 
			
		endif
	endif

	// if still in mode switch phase, see if it's time to switch
	if aiTargetModeTimer
		if timerIsDoneAndGetTimerData(aiTargetModeTimer, timerData)
			// go to next window
			inc timerData.userInt1
			// switch modes
			aiReverseAllRoamingMonsters()
			if aiTargetMode = AI_TARGET_CORNER then aiTargetMode = AI_TARGET_PACMAN else aiTargetMode = AI_TARGET_CORNER
			aiSetTargetOnRoamingMonsters(aiTargetMode)
			// if there is a duration on this window, start a timer otherwise hold this mode forever
			if timerData.userInt1 <= aiTargetModeTimings[aiTargetLevel].length
				aiTargetModeTimer = timerMakeOneShot(aiTargetModeTimings[aiTargetLevel, timerData.userInt1])
				timerSetTimerData(aiTargetModeTimer, timerData)
			else
				aiTargetModeTimer = 0
			endif
		endif
	endif
	
	// If there's still going to be bonus fruit, see if it's time to spawn
	if bonusFruitTimer
		if timerIsDone(bonusFruitTimer)
			playSpawnBonus()
			bonusFruitTimer = 0
		endif
	endif
	
	if bonusScoreTimer
		if timerIsDone(bonusScoreTimer)
			SetSpriteVisible(bonusScoreSprite, 0)
			bonusScoreSprite = 0
			bonusScoreTimer = 0
		endif
	endif

	// Test for end of Level
	if players[activePlayer].eaten = players[activePlayer].toEat
		local timerData as TypeTimerData
		
		// Stop everything
		for i = 0 to characters.length 
			characters[i].moveSpeed = 0
		next i
		// Close PACMANs mouth
		characterSetDirection(characters[CHARACTER_PACMAN], DIRECTION_NONE)
		
		// Set a timer to flash the maze
		timerData.userInt1 = MAZE_FLASH_ITERATIONS
		timerSetTimerData(animTimer, timerData)
		playState = PLAY_STATE_LEVEL_CLEAR
	endif
	
endFunction

//----------------------------------------------------------------------------
// All dots eaten, flash the maze and when done go to next level
function playStateLevelClear()
	
	local index as integer
	local timerData as TypeTimerData
	
	if not timerIsDoneAndGetTimerData(animTimer, timerData) then exitfunction
	
	dec timerData.userInt1
	
	if Not timerData.userInt1
	
		levelUnloadLevel()
		players[activePlayer].edibleGrid.length = -1
		inc players[activePlayer].level
		playState = PLAY_STATE_LEVEL_INIT
		
	else
		
		// Set wall to alternating colours, i.e. flash the wall colour
		if timerData.userInt1 && 1
			index = TIMES_LEVEL_REPEATS
		else
			index = mod(players[activePlayer].level, TIMES_LEVEL_REPEATS)
		endif
		levelSetWallColor(levelGetLoadableLevel(players[activePlayer].level), index)
		
	endif
	
	timerSetTimerData(animTimer, timerData)
	
endFunction

//----------------------------------------------------------------------------
// Mark the player as dead, stop the monsters and setup wait for death anim
function playStateDied()
	
	local i as integer 
	
	// Stop pacman animating
	characterSetDirection(characters[CHARACTER_PACMAN], DIRECTION_NONE)
	
	// mark the player has having died
	players[activePlayer].isAlive = 0
	
	for i = CHARACTER_PACMAN to CHARACTER_BONUS
		characters[i].moveSpeed = 0 // Keep them ghosts animating but stop them (and pacman) moving
	next i

	oneShotTimer = timerMakeOneShot(WAIT_FOR_CONVULTIONS)
	playState = PLAY_STATE_CONVULSTIONS

endfunction

//----------------------------------------------------------------------------
// Wait (pause) before and then start the pacman die animation
function playStateConvulstions()
	
	if not timerIsDone(oneShotTimer) then exitfunction
	
	// Start the death animation
	characters[CHARACTER_PACMAN].animIndex = ANIM_PACMAN_DYING
	characters[CHARACTER_PACMAN].animFrame = 0
	characterSetFacing(characters[CHARACTER_PACMAN], DIRECTION_UP)
	
	playState = PLAY_STATE_PLAY_MORTIS
	
endfunction

//----------------------------------------------------------------------------
// Wait for pacman to be hidden and then update lives and maybe switch players
// or go to game over
function playStateMortis()
	
	local moveResult as TypeMoveResult

	// Have to call move to update the animations - playing out the dying animation here
	characterMove(characters[CHARACTER_PACMAN], moveResult)

	// pacman is hidden by characterMove when the death animation is done playing
	if GetSpriteVisible(characters[CHARACTER_PACMAN].sprite) then exitfunction
	
	// Set the animation to be played back to move
	characters[CHARACTER_PACMAN].animIndex = ANIM_PACMAN_MOVING
	
	// Kill off one player
	dec players[activePlayer].lives
	if players[activePlayer].lives
		playState = PLAY_STATE_NEXT_PLAYER
	else
		SetTextVisible(textHandles[TEXT_GAMEOVER], 1)
		oneShotTimer = timerMakeOneShot(TIME_WAIT_FOR_GAME_OVER)
		playState = PLAY_STATE_GAME_OVER_PLAYER
	endif
	
endFunction

//----------------------------------------------------------------------------
// Find the next player that has lives, or if none, end it all
function playStateNextPlayer()
	
	local nextPlayer as integer
	
	nextPlayer = activePlayer

	// Make sure the name of the player that dies is now on-screen visible
	SetTextVisible(textHandles[perPlayerNameIndex[activePlayer]], 1)
	
	// loop over all players looking for one with lives left	
	repeat 
		nextPlayer = MOD(nextPlayer + 1, numActivePlayers)
		if players[nextPlayer].lives then exit
	until nextPlayer = activePlayer
	
	if nextPlayer <> activePlayer
		// Switch players so load the level for the new player
		levelUnloadLevel()
		// Hide the lives of the inactive player
		playShowLivesAndBonus(0)
		activePlayer = nextPlayer
		playState = PLAY_STATE_LEVEL_INIT
	elseif players[activePlayer].lives
		// Same player, same level and level state
		playState = PLAY_STATE_PLAYER_INIT
	else
		// same player, no lives, so all players have lost all their lives
		levelUnloadLevel()
		playState = PLAY_STATE_CLEANUP
	endif
	
endFunction

//----------------------------------------------------------------------------
// Hold Game Over on screen and when over, hide it and go to next player
function playStateGameOverPlayer()
	
	if not timerIsDone(oneShotTimer) then exitfunction
	
	SetTextVisible(textHandles[TEXT_GAMEOVER], 0)
	playState = PLAY_STATE_NEXT_PLAYER
	
endFunction

//----------------------------------------------------------------------------
// It's all over, unload the level, set up for next game and go to UI
function playStateCleanup()
	
	// Clean up all dynamic text
	levelHideDynamicElements()
	
	// Clean up the timer
	timerDeleteTimer(textTimer)
	
	// Forget the timers if they were active
	ghostScoreTimer = 0
	aiTargetModeTimer = 0
	bonusScoreTimer = 0
	demoTimer = 0
	
	// Clean up own state
	playState = PLAY_STATE_INIT
	
	// Go back to the UI
	mainState = MAIN_STATE_UI
	
endFunction

//----------------------------------------------------------------------------
// SQW - should go to other UI screen but now if a player starts a game in
// demo mode, just restart the level not in demo but in play mode
function playStateRestart()
	
	levelUnloadLevel()
	playStateCleanup()
	mainState = MAIN_STATE_PLAY
	
endFunction

//----------------------------------------------------------------------------
// Wrap the playMain function with a timed Demo timer
function playStateDemoMain()
	
	if not demoTimer
		demoTimer = timerMakeOneShot(TIME_DEMO_DURATION)
	elseif timerIsDone(demoTimer)
		levelUnloadLevel()
		playStateCleanup()
	else
		playMain()
	endif
	
endfunction

//----------------------------------------------------------------------------
// Start the Bonus Character walking around
function playSpawnBonus()
	
	local whichBonus, sprite, i as integer
	
	// Shuffle the doors and path points to make it appear random
	levelShufflePointArray(doorPositions)
	levelShufflePointArray(bonusPath)

	// Get the character to a known state
	characterSetup(characters[CHARACTER_BONUS], CHARACTER_BONUS)
	characters[CHARACTER_BONUS].aiGoal = STATE_AIGOAL_SEEK
	characters[CHARACTER_BONUS].aiTarget = AI_TARGET_BONUS
	characters[CHARACTER_BONUS].aiInt1 = 0

	// Enter from left or right
	if doorPositions[0].x <= 0
		characterSetDirection(characters[CHARACTER_BONUS], DIRECTION_RIGHT)
		characters[CHARACTER_BONUS].moveDest = doorPositions[0].x + MAZE_CELL_DIMENSIONS + GetSpriteOffsetX(characters[CHARACTER_BONUS].sprite)
		SetSpritePositionByOffset(characters[CHARACTER_BONUS].sprite, doorPositions[0].x + GetSpriteOffsetX(characters[CHARACTER_BONUS].sprite), doorPositions[0].y - GetSpriteOffsetY(characters[CHARACTER_BONUS].sprite))
	else
		characterSetDirection(characters[CHARACTER_BONUS], DIRECTION_LEFT)
		characters[CHARACTER_BONUS].moveDest = doorPositions[0].x - MAZE_CELL_DIMENSIONS - GetSpriteOffsetX(characters[CHARACTER_BONUS].sprite)
		SetSpritePositionByOffset(characters[CHARACTER_BONUS].sprite, doorPositions[0].x - GetSpriteOffsetX(characters[CHARACTER_BONUS].sprite), doorPositions[0].y - GetSpriteOffsetY(characters[CHARACTER_BONUS].sprite))
	endif

	// which fruit depeds on the level
	whichBonus = players[activePlayer].level + 1
	if whichBonus > bonusScores.length + 1 then whichBonus = Random2(1, 8)
	SetSpriteFrame(characters[CHARACTER_BONUS].sprite, whichBonus)
	SetSpriteVisible(characters[CHARACTER_BONUS].sprite, 1)
	
	// If this bonus is already the last one, don't add to display
	if players[activePlayer].bonusDisplaySprites.length >= 0
		if whichBonus = GetSpriteCurrentFrame(players[activePlayer].bonusDisplaySprites[players[activePlayer].bonusDisplaySprites.length]) then exitfunction
	endif

	// Only update the bonus fruit display (bottom of screen) if not in demo mode
	if mainState <> MAIN_STATE_DEMO
		// Put the new fruit in the display area, tacked on at the end (start of row, in visual terms)
		sprite = CloneSprite(characters[CHARACTER_BONUS].sprite)
		SetSpritePositionByOffset(sprite, 
			SCREEN_X_COLS * MAZE_CELL_DIMENSIONS - CHARACTER_SPRITE_WIDTH * (players[activePlayer].bonusDisplaySprites.length + 2), 
			(SCREEN_Y_ROWS -4) * MAZE_CELL_DIMENSIONS + GetSpriteOffsetY(sprite))
		players[activePlayer].bonusDisplaySprites.Insert(sprite)
		SetSpriteVisible(sprite, 1)
		
		// If the sprite is #8 (0 based is index 7) in the display (only 7 allowed), then "scroll" the sprites to the right and drop the right-most (oldest) one
		if players[activePlayer].bonusDisplaySprites.length = 7
			for i = players[activePlayer].bonusDisplaySprites.length to 1 step -1
				SetSpritePositionByOffset(players[activePlayer].bonusDisplaySprites[i], GetSpriteXByOffset(players[activePlayer].bonusDisplaySprites[i-1]), GetSpriteYByOffset(players[activePlayer].bonusDisplaySprites[i-1]))
			next i
			DeleteSprite(players[activePlayer].bonusDisplaySprites[0])
			players[activePlayer].bonusDisplaySprites.Remove(0)
		endif
	endif

endfunction

//----------------------------------------------------------------------------
// Create the icon (pacman) for a life banked, in the status section
function playMakeLives(life as integer)
	
	local sprite, image as integer
	
	image = images[IMAGE_PACMAN]
	sprite = CreateSprite(image)
	SetSpriteAnimation(sprite, CHARACTER_SPRITE_WIDTH, CHARACTER_SPRITE_WIDTH, (GetImageWidth(image) / CHARACTER_SPRITE_WIDTH) * (GetImageHeight(image) / CHARACTER_SPRITE_WIDTH))
	// PACMAN moving animation, mouth slightly open is 1, and facing right
	SetSpriteFrame(sprite, animations[ANIM_PACMAN_MOVING, 1] + DIRECTION_RIGHT)
	SetSpritePosition(sprite, life * CHARACTER_SPRITE_WIDTH, (SCREEN_Y_ROWS - 4) * MAZE_CELL_DIMENSIONS)
	SetSpriteVisible(sprite, 0)
	
endfunction sprite

//----------------------------------------------------------------------------
// Show / Hide the lives remaining for the active player, as well as 
// the last bonus' seen in the display area
function playShowLivesAndBonus(show as integer)
	
	local i as integer

	// Lives
	for i = 0 to players[activePlayer].livesSprites.length
		SetSpriteVisible(players[activePlayer].livesSprites[i], show)
	next i 
	
	// Bonus Display sprites
	for i = 0 to players[activePlayer].bonusDisplaySprites.length
		SetSpriteVisible(players[activePlayer].bonusDisplaySprites[i], show)
	next i 

endfunction

//----------------------------------------------------------------------------
// Add one banked life to the active player
function playAwardExtraLife()
	
	if players[activePlayer].lives < 6
		players[activePlayer].livesSprites.insert(playMakeLives(players[activePlayer].lives))
		inc players[activePlayer].lives
	endif
	playShowLivesAndBonus(1)
	
endfunction