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
// Called from playStateRun.  The "main" entry point for the AI
function aiMain(aCharacter ref as TypeCharacter)
	
	select aCharacter.aiGoal
		
		case STATE_AIGOAL_NONE
			// Nothing to do
		endcase
		
		case STATE_AIGOAL_USER
			aiGoalUser(aCharacter)
		endcase
		
		case STATE_AIGOAL_HOLDING
			aiGoalHolding(aCharacter)
		endcase 
		
		case STATE_AIGOAL_EXIT
			aiGoalExit(aCharacter)
		endcase 
		
		case STATE_AIGOAL_ENTER
			aiGoalEnter(aCharacter)
		endcase 

		case STATE_AIGOAL_WANDER
			aiGoalWander(aCharacter)
		endcase 
		
		case STATE_AIGOAL_SEEK
			aiGoalSeek(aCharacter)
		endcase 
		
	endselect

endfunction

//----------------------------------------------------------------------------
// The "AI" that listens to user input
function aiGoalUser(aCharacter ref as TypeCharacter)
	
	local arrived, blockForward as integer
	local moveResult as TypeMoveResult
	
	// if the user wants to U-Turn, it's always possible and happens immediately
	if desiredDirection = directionOpposite[aCharacter.moveDir] then characterReverse(aCharacter)

	// arrived is true if the character moved through a column/row crossing
	arrived = characterMove(aCharacter, moveResult)
	
	// A direction change is possible if character "arrived" at a crossing
	if arrived
	
		// get the cell (or tile) coordinates
		lx = moveResult.x# / MAZE_CELL_DIMENSIONS
		ly = moveResult.y# / MAZE_CELL_DIMENSIONS

		// if the user wants to, and can change direction, make it so
		if desiredDirection <> aCharacter.moveDir
			if levelGetBlockForward(desiredDirection, lx, ly) <> LEVEL_CLOSED 
				characterSetDirection(aCharacter, desiredDirection)
			endif
		endif 

		// see what's forward and what lies in the direction the user is travelling
		blockForward = levelGetBlockForward(aCharacter.moveDir, lx, ly)

		// stop the character if blocked or add in any overflow, and set the next destination
		if blockForward = LEVEL_CLOSED
			characterSetDirection(aCharacter, DIRECTION_NONE)
		else
			characterFixDestAndOverflow(aCharacter, moveResult)			
		endif
		
		// see if something is to be eaten in the next tile entered
		score = levelEatForward(aCharacter.moveDir, lx, ly)
		if score

			// slow down when eating dots
			aCharacter.moveSpeed = characterGetSpeed(SPEED_MODE_PACMAN_EATING)
		
			// If a power pill was eaten then activate ghost mode
			if score = SCORE_POWER_PELLET then aiGhostMode()
			
			// update the score
			aiUpdateScore(score)
			
		else

			// Nothing eaten, move at open grid speeds (faster)
			aCharacter.moveSpeed = characterGetSpeed(SPEED_MODE_PACMAN_OPEN)
			
		endif
		
	endif
	
	characterCheckCollisions(aCharacter)
	
endfunction

//----------------------------------------------------------------------------
// Bounce up and down in the holding cell
function aiGoalHolding(aCharacter ref as TypeCharacter)
	
	local y, arrived as integer
	local moveResult as TypeMoveResult
	
	arrived = characterMove(aCharacter, moveResult)
	y = moveResult.y#
	
	// make a timer to decide when to stop bouncing
	if not aCharacter.aiTimerID
		aCharacter.aiTimerID = timerMakeOneShot(characterGetHoldTime(aCharacter.characterType))
		// Set the dest based on direction - Inky starts opposite direction
		if aCharacter.moveDir = DIRECTION_UP then aCharacter.moveDest = y - AI_HOLDING_DISTANCE else aCharacter.moveDest = y + AI_HOLDING_DISTANCE
	else
		// See it's time to turn around
		if arrived
			if aCharacter.moveDir = DIRECTION_UP
				aCharacter.moveDest = y + 2 * AI_HOLDING_DISTANCE
				characterSetDirection(aCharacter, DIRECTION_DOWN)
			else
				aCharacter.moveDest = y - 2 * AI_HOLDING_DISTANCE
				characterSetDirection(aCharacter, DIRECTION_UP)
			endif
		endif
		
		// Once the timer goes, set monster to go to a known Y in cage, set sub-state to 0 and start goalExit
		if timerIsDone(aCharacter.aiTimerID)
			aCharacter.aiTimerID = 0
			aCharacter.aiInt1 = 0
			
			// Set up the Y to hit, in order to move to middle of cage
			aCharacter.moveDest = initialPositionsY[aCharacter.characterType] * MAZE_CELL_DIMENSIONS
			
			// Make sure character will hit Y
			if y < aCharacter.moveDest then characterSetDirection(aCharacter, DIRECTION_UP) else characterSetDirection(aCharacter, DIRECTION_DOWN)
			
			// Set the speed correctly
			if aCharacter.animIndex = ANIM_MONSTER_GHOSTING
				aCharacter.moveSpeed = characterGetSpeed(SPEED_MODE_GHOST)
			else
				aCharacter.moveSpeed = characterGetSpeed(SPEED_MODE_MONSTER)
			endif
			aCharacter.aiGoal = STATE_AIGOAL_EXIT
		endif
	endif
	
endfunction

//----------------------------------------------------------------------------
// Get out of the holding cell
function aiGoalExit(aCharacter ref as TypeCharacter)
	
	local x, y, arrived as integer
	local moveResult as TypeMoveResult
	
	arrived = characterMove(aCharacter, moveResult)

	x = moveResult.x#
	y = moveResult.y#

	select aCharacter.aiInt1
		
		// This is while waiting for monster to get to known Y in cage
		case 0
			if arrived
				// arrived at known Y so set up a lateral move to the middle
				inc aCharacter.aiInt1
				aCharacter.moveDest = initialPositionsX[CHARACTER_PACMAN] * MAZE_CELL_DIMENSIONS - GetSpriteOffsetX(aCharacter.sprite)
				if x > aCharacter.moveDest then characterSetDirection(aCharacter, DIRECTION_LEFT) else characterSetDirection(aCharacter, DIRECTION_RIGHT)
			endif
		endcase
		
		// This is while waiting for monster to get to known X (centre of screen)
		case 1
			if arrived
				// arrived at centre of the screen, now set up a move up, out of the box
				inc aCharacter.aiInt1
				aCharacter.moveDest = initialPositionsY[CHARACTER_BLINKY] * MAZE_CELL_DIMENSIONS
				characterSetDirection(aCharacter, DIRECTION_UP)
			endif
		endcase

		// This is while waiting for monster to get to known Y outside cage - also where Blinky starts
		case 2
			if arrived
				// arrived above the box (blinky start position)
				aCharacter.aiInt1 = 0
				// Go left or right when exiting
				if Random2(0,1)
					characterSetDirection(aCharacter, DIRECTION_LEFT)
					aCharacter.moveDest = x - GetSpriteOffsetX(aCharacter.sprite)
				else
					characterSetDirection(aCharacter, DIRECTION_RIGHT)
					aCharacter.moveDest = x + GetSpriteOffsetX(aCharacter.sprite)
				endif
				
				// If ghosting, run, otherwise assume the target mode
				if aCharacter.animIndex = ANIM_MONSTER_GHOSTING
					aCharacter.aiGoal = STATE_AIGOAL_WANDER
				else
					aCharacter.aiGoal = STATE_AIGOAL_SEEK
					// Take on the global targeting mode in this monster
					aCharacter.aiTarget = aiTargetMode
				endif

			endif
		endcase
		
	endselect 

endfunction

//----------------------------------------------------------------------------
// Re-enter the holding cell (eyes of eaten ghosts only)
function aiGoalEnter(aCharacter ref as TypeCharacter)
	
	local x, y, arrived as integer
	local moveResult as TypeMoveResult
	
	arrived = characterMove(aCharacter, moveResult)
	
	if not arrived then exitFunction

	x = moveResult.x#
	y = moveResult.y#
	
	characterSetup(aCharacter, aCharacter.characterType)
	SetSpritePositionByOffset(aCharacter.sprite, x, y)
	SetSpriteVisible(aCharacter.sprite, 1)
	characterSetDirection(aCharacter, DIRECTION_UP)
	aCharacter.moveDest = initialPositionsY[CHARACTER_BLINKY] * MAZE_CELL_DIMENSIONS// - GetSpriteOffsetX(aCharacter.sprite)
	aCharacter.aiGoal = STATE_AIGOAL_EXIT
	aCharacter.aiInt1 = 2

endfunction

//----------------------------------------------------------------------------
// random maze coverage ai
function aiGoalWander(aCharacter ref as TypeCharacter)
	
	local x, y, arrived, lx, ly, forward, left, right as integer 
	local block as integer[3]
	local moveResult as TypeMoveResult
	
	arrived = characterMove(aCharacter, moveResult)

	x = moveResult.x#
	y = moveResult.y#
	
	// Decision time since the character has fully aligned with a row and column
	if arrived
	
		lx = x / MAZE_CELL_DIMENSIONS
		ly = y / MAZE_CELL_DIMENSIONS

		// going forward, assume going in same direction		
		forward = aCharacter.moveDir
		
		// see what lies ahead
		block[forward] = levelGetBlockForward(forward, lx, ly)
		
		// 70% chance of sticking to the current path
		if block[forward] = LEVEL_CLOSED or random2(1,10) > 7
		
			// decided to consider a turn, see what options there are
			left = directionLeft[forward]
			right = directionRight[forward]
			block[left] = levelGetBlockForward(left, lx, ly)
			block[right] = levelGetBlockForward(right, lx, ly)
			
			if block[left] <> LEVEL_CLOSED and block[right] <> LEVEL_CLOSED
				// 50:50 chance of going left or right if both available
				if random2(1, 10) > 5 then forward = right else forward = left
			elseif block[left] <> LEVEL_CLOSED
				forward = left
			elseif block[right] <> LEVEL_CLOSED
				forward = right
			elseif block[forward] = LEVEL_CLOSED
				forward = directionOpposite[forward]
				block[forward] = levelGetBlockForward(forward, lx, ly)
			endif
		
			// if no branch taken then forward is the default
			characterSetDirection(aCharacter, forward)
			
			// Monsters go slow through the slow zones
			if aCharacter.characterType >= CHARACTER_BLINKY and aCharacter.characterType <= CHARACTER_SUE
				if block[forward] = 1 then aCharacter.moveMult# = 1.0 else aCharacter.moveMult# = SPEED_SLOW_MOD
			endif
		endif

		// If this is PACMAN then eat dots
		if aCharacter.characterType = CHARACTER_PACMAN
			// If the dot scored SCORE_POWER_PELLET then it's ghost mode
			if levelEatForward(aCharacter.moveDir, lx, ly) = SCORE_POWER_PELLET then aiGhostMode()
		endif

		// update the next stop based on the direction of travel
		select aCharacter.moveDir
			
			case DIRECTION_UP
				aCharacter.moveDest = y - MAZE_CELL_DIMENSIONS
			endcase
			
			case DIRECTION_RIGHT
				aCharacter.moveDest = x + MAZE_CELL_DIMENSIONS
			endcase
			
			case DIRECTION_DOWN
				aCharacter.moveDest = y + MAZE_CELL_DIMENSIONS
			endcase
			
			case DIRECTION_LEFT
				aCharacter.moveDest = x - MAZE_CELL_DIMENSIONS
			endcase
			
		endselect
			
	endif
	
	if aCharacter.characterType = CHARACTER_PACMAN then characterCheckCollisions(aCharacter)

endfunction

//----------------------------------------------------------------------------
// AI to seek to pacman or to the cage for eyes
function aiGoalSeek(aCharacter ref as TypeCharacter)
	
	local x, y, tx, ty, arrived, lx, ly, forward, seekDesire as integer
	local block as integer[3]
	local moveResult as TypeMoveResult
	local targetPoint as TypePoint2d

	// Start by moving the character
	arrived = characterMove(aCharacter, moveResult)
	
	// then get the current x, y which, if the character crossed a col/row intersction, will be that point
	x = moveResult.x#
	y = moveResult.y#

	// Figure out where the character wants to go
	aiTargetSelect(aCharacter, targetPoint)
	tx = targetPoint.x
	ty = targetPoint.y

	// If the character is heading home (eyes) handle that
	if aCharacter.aiTarget = AI_TARGET_HOME
		if y = ty 
			// and moving horizontally
			if aCharacter.moveDir = DIRECTION_LEFT or aCharacter.moveDir = DIRECTION_RIGHT
				// and within a block of home, then adjust the seek point to be exactly home
				if abs(aCharacter.moveDest - tx) <= MAZE_CELL_DIMENSIONS then aCharacter.moveDest = tx
			endif
		endif
		if tx = x and ty = y
			characterSetDirection(aCharacter, DIRECTION_DOWN)
			aCharacter.moveDest = initialPositionsY[CHARACTER_PINKY] * MAZE_CELL_DIMENSIONS
			aCharacter.aiGoal = STATE_AIGOAL_ENTER
			exitFunction
		endif
	// If the character is a bonus fruit, handle that
	elseif aCharacter.aiTarget = AI_TARGET_BONUS
		if abs(tx - x) < MAZE_CELL_DIMENSIONS and abs(ty - y) < MAZE_CELL_DIMENSIONS
			inc aCharacter.aiInt1
			if aCharacter.aiInt1 > bonusPath.length + 2 // path + prexit + door = done
				aCharacter.aiGoal = STATE_AIGOAL_NONE
				SetSpriteVisible(aCharacter.sprite, 0)
				bonusFruitTimer = timerMakeOneShot(TIME_TO_NEXT_FRUIT)
				exitFunction
			endif
		endif
	endif

	// SQW - target sprite debug
	if showTargetSprites
		SetSpritePosition(targetSprites[aCharacter.characterType], tx, ty)
		DrawLine(x, y, tx, ty, GetColorRed(characterColours[aCharacter.characterType]),
			GetColorGreen(characterColours[aCharacter.characterType]),
			GetColorBlue(characterColours[aCharacter.characterType]))
	endif

	// Decision time since the character has fully aligned with a row and column
	if arrived
	
		// Get the cell coordinates
		lx = x / MAZE_CELL_DIMENSIONS
		ly = y / MAZE_CELL_DIMENSIONS

		// going forward, assume going in same direction		
		forward = aCharacter.moveDir
		seekDesire = forward
		
		// Get a delta to the seek destination (target)
		dx = x - tx
		dy = y - ty

		// See what's up ahead in each direction
		block[DIRECTION_UP] = levelGetBlockForward(DIRECTION_UP, lx, ly)
		block[DIRECTION_RIGHT] = levelGetBlockForward(DIRECTION_RIGHT, lx, ly)
		block[DIRECTION_DOWN] = levelGetBlockForward(DIRECTION_DOWN, lx, ly)
		block[DIRECTION_LEFT] = levelGetBlockForward(DIRECTION_LEFT, lx, ly)
		
		 // is distance in x > distance away in y, then favor X over Y
		if abs(dx) > abs(dy)
		
			//if travelling away from tx then turn, try to minimize dy
			if (tx < x and forward = DIRECTION_RIGHT) or (tx > x and forward = DIRECTION_LEFT)
				// is up closer in y, and if so, is it available
				if ty < y and block[DIRECTION_UP] <> LEVEL_CLOSED
					seekDesire = DIRECTION_UP
				// if not closer or maybe not available, is down wvailable
				elseif block[DIRECTION_DOWN] <> LEVEL_CLOSED
					seekDesire = DIRECTION_DOWN
				// if down isn't available then try up (in case it wasn't closer but was available)
				else 
					seekDesire = DIRECTION_UP
				endif
				
			//else if travelling up or down then want to turn if possible, towards dx 
			elseif forward = DIRECTION_UP or forward = DIRECTION_DOWN
				if tx < x then seekDesire = DIRECTION_LEFT else seekDesire = DIRECTION_RIGHT
				
			// otherwise already travelling towards tx so if forward is closed turn, try to minimize dy
			else 
				if block[forward] = LEVEL_CLOSED
					// is up closer in y, and if so, is it available
					if ty < y and block[DIRECTION_UP] <> LEVEL_CLOSED
						seekDesire = DIRECTION_UP
					// if not closer or maybe not available, is down wvailable
					elseif block[DIRECTION_DOWN] <> LEVEL_CLOSED
						seekDesire = DIRECTION_DOWN
					// if down isn't available then try up (in case it wasn't closer but was available)
					else 
						seekDesire = DIRECTION_UP
					endif
				endif 
			endif 
			
		// favor Y over X
		else
		
			//if travelling away from ty then turn, try to minimize dx
			if (ty < y and forward = DIRECTION_DOWN) or (ty > y and forward = DIRECTION_UP)
				// is up closer in x, and if so, is it available
				if tx < x and block[DIRECTION_LEFT] <> LEVEL_CLOSED
					seekDesire = DIRECTION_LEFT
				// if not closer or maybe not available, is down wvailable
				elseif block[DIRECTION_RIGHT] <> LEVEL_CLOSED
					seekDesire = DIRECTION_RIGHT
				// if down isn't available then try up (in case it wasn't closer but was available)
				else 
					seekDesire = DIRECTION_LEFT
				endif
				
			//else if travelling up or down then want to turn if possible, towards dy 
			elseif forward = DIRECTION_LEFT or forward = DIRECTION_RIGHT
				if ty < y then seekDesire = DIRECTION_UP else seekDesire = DIRECTION_DOWN
				
			// otherwise already travelling towards ty so if forward is closed turn, try to minimize dx
			else 
				if block[forward] = LEVEL_CLOSED
					// is up closer in x, and if so, is it available
					if tx < x and block[DIRECTION_LEFT] <> LEVEL_CLOSED
						seekDesire = DIRECTION_LEFT
					// if not closer or maybe not available, is down available
					elseif block[DIRECTION_RIGHT] <> LEVEL_CLOSED
						seekDesire = DIRECTION_RIGHT
					// if down isn't available then try up (in case it wasn't closer but was available)
					else 
						seekDesire = DIRECTION_LEFT
					endif
				endif 
			endif 
			
		endif
		
		// if desire is open, go
		if block[seekDesire] <> LEVEL_CLOSED
			characterSetDirection(aCharacter, seekDesire)
		// if forward is not open, then the opposite of desire must be open
		elseif block[forward] = LEVEL_CLOSED
			characterSetDirection(aCharacter, directionOpposite[seekDesire])
		endif 
		
		// The monsters move slower through the slow zones (passages to portals)
		if aCharacter.characterType >= CHARACTER_BLINKY and aCharacter.characterType <= CHARACTER_SUE
			if block[aCharacter.moveDir] = 1 then aCharacter.moveMult# = 1.0 else aCharacter.moveMult# = SPEED_SLOW_MOD
		endif
		
		// Finally, make sure the new dest is set, and fix the overflow
		characterFixDestAndOverflow(aCharacter, moveResult)

	endif
	
endfunction

//----------------------------------------------------------------------------
// Find the destination that the character is seeking to
function aiTargetSelect(aCharacter ref as TypeCharacter, targetPoint ref as TypePoint2d)
	
	local i, tx, ty, bx, by as integer
	
	// Get the coordinates of the target
	select aCharacter.aiTarget
			
		case AI_TARGET_PACMAN
			tx = GetSpriteXByOffset(characters[CHARACTER_PACMAN].sprite)
			ty = GetSpriteYByOffset(characters[CHARACTER_PACMAN].sprite)
			select aCharacter.characterType
				// case CHARACTER_BLINKY
				// 	// no modifications
				// endcase 
				
				case CHARACTER_PINKY
					// 4 tiles in front of pacman
					select characters[CHARACTER_PACMAN].moveDir
						case DIRECTION_UP
							dec ty, MAZE_CELL_DIMENSIONS * 4
						endcase
							
						case DIRECTION_RIGHT
							inc tx, MAZE_CELL_DIMENSIONS * 4
						endcase
							
						case DIRECTION_DOWN
							inc ty, MAZE_CELL_DIMENSIONS * 4
						endcase
							
						case DIRECTION_LEFT
							dec tx, MAZE_CELL_DIMENSIONS * 4
						endcase
					endselect
				endcase 
				
				case CHARACTER_INKY
					// 4 tiles behind pacman
					select characters[CHARACTER_PACMAN].moveDir
						case DIRECTION_UP
							inc ty, MAZE_CELL_DIMENSIONS * 4
						endcase
							
						case DIRECTION_RIGHT
							dec tx, MAZE_CELL_DIMENSIONS * 4
						endcase
							
						case DIRECTION_DOWN
							dec ty, MAZE_CELL_DIMENSIONS * 4
						endcase
							
						case DIRECTION_LEFT
							inc tx, MAZE_CELL_DIMENSIONS * 4
						endcase
					endselect
				endcase 
				
				case CHARACTER_SUE
					// 2 steps - step 1 is 2 tiles ahead of pacman
					select characters[CHARACTER_PACMAN].moveDir
						case DIRECTION_UP
							dec ty, MAZE_CELL_DIMENSIONS * 2
						endcase
							
						case DIRECTION_RIGHT
							inc tx, MAZE_CELL_DIMENSIONS * 2
						endcase
							
						case DIRECTION_DOWN
							inc ty, MAZE_CELL_DIMENSIONS * 2
						endcase
							
						case DIRECTION_LEFT
							dec tx, MAZE_CELL_DIMENSIONS * 2
						endcase
					endselect
					
					// step 2 is relative to blinky
					bx = GetSpriteXByOffset(characters[CHARACTER_BLINKY].sprite)
					by = GetSpriteYByOffset(characters[CHARACTER_BLINKY].sprite)
					
					// SQW - debug
					if showTargetSprites
						DrawLine(tx, ty, tx + tx - bx, ty + ty - by, GetColorRed(characterColours[CHARACTER_PACMAN]),
							GetColorGreen(characterColours[CHARACTER_PACMAN]),
							GetColorBlue(characterColours[CHARACTER_PACMAN]))
					endif
					
					// but rotated by 180 degrees - this caused a "pinch" between Blinky and Sue
					inc tx, tx - bx
					inc ty, ty - by
				endcase 
				
			endselect
		endcase
		
		case AI_TARGET_CORNER
			tx = cornerTargetsX[aCharacter.characterType] * MAZE_CELL_DIMENSIONS
			ty = cornerTargetsY[aCharacter.characterType] * MAZE_CELL_DIMENSIONS
		endcase
		
		case AI_TARGET_HOME
			// The X is between two tiles - the middle of the screen
			tx = initialPositionsX[CHARACTER_BLINKY] * MAZE_CELL_DIMENSIONS - GetSpriteOffsetX(aCharacter.sprite)
			ty = initialPositionsY[CHARACTER_BLINKY] * MAZE_CELL_DIMENSIONS
		endcase
		
		case AI_TARGET_BONUS
			// Walk the path
			if aCharacter.aiInt1 <= bonusPath.length
				tx = bonusPath[aCharacter.aiInt1].x
				ty = bonusPath[aCharacter.aiInt1].y - GetSpriteOffsetY(aCharacter.sprite)
			// Then go to preexit at the end of the path
			// preexit is needed so that the monsters find the door
			// without they could get caught in a cycle in the maze
			elseif aCharacter.aiInt1 = bonusPath.length + 1
				// Match/find which preexit with the door that's going to be used to exit
				for i = 0 to preExit.length
					// first match the Y
					if preExit[i].y = doorPositions[1].y
						// then the left/right half of the screen with the door that's on the left or right
						if doorPositions[1].x > (SCREEN_X_COLS * MAZE_CELL_DIMENSIONS) / 2
							if preExit[i].x - (SCREEN_X_COLS * MAZE_CELL_DIMENSIONS) / 2 > 0
								tx = preExit[i].x
								ty = preExit[i].y - GetSpriteOffsetY(aCharacter.sprite)
								exit
							endif
						else
							if (SCREEN_X_COLS * MAZE_CELL_DIMENSIONS) / 2 - preExit[i].x > 0
								tx = preExit[i].x
								ty = preExit[i].y - GetSpriteOffsetY(aCharacter.sprite)
								exit
							endif
						endif
					endif
				next i
			// and after preexit, go to the door
			else
				tx = doorPositions[1].x
				ty = doorPositions[1].y
			endif
		endcase
		
	endselect
	
	targetPoint.x = tx
	targetPoint.y = ty
	
endfunction 

//----------------------------------------------------------------------------
// Call aiGoalSeek on characters that are currently eyes
function aiMoveEyes()
	
	local i as integer
	local moveResult as TypeMoveResult
	
	for i = 0 to characters.length
		// Only if eyes, and visible, run the AI
		if characters[i].animIndex = ANIM_MONSTER_GHOSTEYES and GetSpriteVisible(characters[i].sprite) then aiMain(characters[i])
	next i
	
endfunction

//----------------------------------------------------------------------------
// PacMan ate a power pellet so turn monsters to ghosts
function aiGhostMode()
	
	local i as integer
	local timerData as TypeTimerData
	
	ghostTimer = timerMakeOneShot(aiGetGhostTime())
	timerData.userInt1 = 1
	timerSetTimerData(ghostTimer, timerData)
	ghostScoreIndex = 0
	
	for i = CHARACTER_BLINKY to CHARACTER_SUE
		if not (characters[i].aiGoal = STATE_AIGOAL_SEEK and characters[i].aiTarget = AI_TARGET_HOME)
		
			if characters[i].aiGoal <> STATE_AIGOAL_HOLDING then characters[i].moveSpeed = characterGetSpeed(SPEED_MODE_GHOST)
			if characters[i].aiGoal = STATE_AIGOAL_SEEK then characters[i].aiGoal = STATE_AIGOAL_WANDER
			if characters[i].aiGoal = STATE_AIGOAL_WANDER then characterReverse(characters[i])

			characters[i].animIndex = ANIM_MONSTER_GHOSTING
			characters[i].animOffset = (CHARACTER_GHOST_BLUE - CHARACTER_BLINKY) * MONSTERS_FRAMES_NUM * 4
			characters[i].animFrame = 0
			
		endif
	next i
	
endfunction

//----------------------------------------------------------------------------
// Calculate how long a monster will be a ghost, based on the current level
function aiGetGhostTime()

	holdTime# = SPEED_BOOSTED_LEVELS - players[activePlayer].level
	if holdtime# < 0.0 then holdTime# = 0.0

endfunction holdTime#

//----------------------------------------------------------------------------
// Set all ghosts to a state where they will start flashing
function aiGhostFlash()

	local i as integer

	for i = CHARACTER_BLINKY to CHARACTER_SUE
		if characters[i].animIndex = ANIM_MONSTER_GHOSTING
			characters[i].animIndex = ANIM_MONSTER_GHOSTEND
		endif
	next i
	
endfunction

//----------------------------------------------------------------------------
// Set flashing ghosts back to monsters
function aiGhostEnd()

	local i as integer

	for i = CHARACTER_BLINKY to CHARACTER_SUE
		if characters[i].animIndex = ANIM_MONSTER_GHOSTEND
			characters[i].aiGoal = STATE_AIGOAL_SEEK
			characters[i].aitarget = aiTargetMode
			characters[i].animIndex = ANIM_MONSTERS_MOVING
			characters[i].animOffset = (characters[i].characterType - CHARACTER_BLINKY) * MONSTERS_FRAMES_NUM * 4
			characters[i].animFrame = 0
			characters[i].moveSpeed = characterGetSpeed(SPEED_MODE_MONSTER)
		endif
	next i

endfunction

//----------------------------------------------------------------------------
// Switch the targeting mode on monsters that aren't targeting HOME 
function aiSetTargetOnRoamingMonsters(newTarget as integer)
	
	local i as integer 
	
	for i = CHARACTER_BLINKY to CHARACTER_SUE
		if characters[i].aiTarget <> AI_TARGET_HOME then characters[i].aiTarget = newTarget
	next i

endfunction

//----------------------------------------------------------------------------
// Reverse all monsters that are seeking and aren't eyes
function aiReverseAllRoamingMonsters()

	local i as integer

	for i = CHARACTER_BLINKY to CHARACTER_SUE
		if characters[i].aiGoal = STATE_AIGOAL_SEEK
			if characters[i].aiTarget <> AI_TARGET_HOME then characterReverse(characters[i])
		endif
	next i 
	
endfunction

//----------------------------------------------------------------------------
// Update the score and high-score if score > high score
// All scores are 10x smaller than the display score
function aiUpdateScore(score as integer)
	
	local pre, post as integer
	
	pre = players[activePlayer].score / EXTRA_LIFE_SCORE
	// add the score to the player
	inc players[activePlayer].score, score
	post = players[activePlayer].score / EXTRA_LIFE_SCORE

	// if adding the score crossed the extra life threshold, add a life
	if players[activePlayer].score >= EXTRA_LIFE_MIN_SCORE and pre <> post then playAwardExtraLife()
	
	// update the score display
	SetTextString(textHandles[perPlayerScoreIndex[activePlayer]], right("     " + Str(players[activePlayer].score), 6)+"0")
	
	// see if this is a highscore and if it is, update that display
	if players[activePlayer].score > highScore
		highScore = players[activePlayer].score
		SetTextString(textHandles[TEXT_HIGHSCORE], right("     " + Str(highScore), 6)+"0")
	endif
	
endfunction
