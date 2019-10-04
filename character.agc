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
// Move the character framerate independent.  Set the XY to be "clipped" to
// row/column intersections so turn decisions can be made,  The "overflow"
// is preserved so that the AI can add the overflow post decision (if pacman,
// for example, wants to turn at 90, the overflow is applied in the new
// direction.)
function characterMove(aCharacter ref as TypeCharacter, moveResult ref as TypeMoveResult)

	local x#, y#, distance# as float
	local arrived as integer
	
	// becomes true when going through a col/row crossing
	arrived = 0
	
	// init to current coords - will be passed back to AI wherher changed or not
	x# = GetSpriteXByOffset(aCharacter.sprite)
	y# = GetSpriteYByOffset(aCharacter.sprite)

	// If not moving then don't process move code
	if aCharacter.moveDir <> DIRECTION_NONE
		
		// See how far to move
		distance# = aCharacter.moveSpeed * aCharacter.moveMult# * dt#

		// This lets the characters hit every block even at horrendous frame rates (like when debugging ;)
		if distance# > MAZE_CELL_DIMENSIONS then distance# = MAZE_CELL_DIMENSIONS
		
		select aCharacter.moveDir
			
			case DIRECTION_UP
				dec y#, distance#
				if y# < aCharacter.moveDest
					moveResult.overflow# = aCharacter.moveDest - y#
					y# = aCharacter.moveDest
					arrived = 1
				endif
			endcase
			
			case DIRECTION_RIGHT
				// Move 
				inc x#, distance#
				// snap to destination if overshot by a bit
				if x# > aCharacter.moveDest 
					moveResult.overflow# = x# - aCharacter.moveDest
					x# = aCharacter.moveDest
					arrived = 1
				endif

				// check to see if character needs to teleport to the other end of the screen
				if x# >= (SCREEN_X_COLS+1) * MAZE_CELL_DIMENSIONS
					x# = -MAZE_CELL_DIMENSIONS
					aCharacter.moveDest = MAZE_CELL_DIMENSIONS
				endif
			endcase
			
			case DIRECTION_DOWN
				inc y#, distance#
				if y# > aCharacter.moveDest
					moveResult.overflow# = y# - aCharacter.moveDest
					y# = aCharacter.moveDest
					arrived = 1
				endif 
			endcase
			
			case DIRECTION_LEFT
				dec x#, distance#
				if x# < aCharacter.moveDest
					moveResult.overflow# = aCharacter.moveDest - x#
					x# = aCharacter.moveDest
					arrived = 1
				endif
				
				if x# <= -MAZE_CELL_DIMENSIONS
					x# = (SCREEN_X_COLS+1) * MAZE_CELL_DIMENSIONS
					aCharacter.moveDest = x# - MAZE_CELL_DIMENSIONS
				endif
			endcase
			
		endselect

		SetSpritePositionByOffset(aCharacter.sprite, x#, y#)

	else 
		
		// If not moving then must have arrived
		arrived = 1
		
		// Not moving or dying so force a shut-mouth right now, and when the timer fires
		if aCharacter.animIndex <> ANIM_PACMAN_DYING
			aCharacter.animFrame = animations[aCharacter.animIndex].length
			SetSpriteFrame(aCharacter.sprite, animations[aCharacter.animIndex, 0] + aCharacter.animFacing + aCharacter.animOffset)
		else
			// This is pacman, and if the death animation is done playing, hide pacman
			if aCharacter.animFrame = animations[ANIM_PACMAN_DYING].length then SetSpriteVisible(aCharacter.sprite, 0)
		endif
		
	endif 
	
	// return the post move coords for AI use
	moveResult.x# = x#
	moveResult.y# = y#

	if aCharacter.animIndex >= 0 and timerIsDone(animTimer)
		inc aCharacter.animFrame
		if aCharacter.animFrame > animations[aCharacter.animIndex].length then aCharacter.animFrame = 0
		SetSpriteFrame(aCharacter.sprite, animations[aCharacter.animIndex, aCharacter.animFrame] + aCharacter.animFacing + aCharacter.animOffset)
	endif

endFunction arrived

// Update the moveDest for the character, based in the X#/y# in the moveResult, and then
// update the character position to also include the overflow#
function characterFixDestAndOverflow(aCharacter ref as TypeCharacter, moveResult ref as TypeMoveResult)
	
	// update the next stop based on the direction of travel, and fix the overflow
	select aCharacter.moveDir
			
		case DIRECTION_UP
			aCharacter.moveDest = moveResult.y# - MAZE_CELL_DIMENSIONS
			dec moveResult.y#, moveResult.overflow#
		endcase
		
		case DIRECTION_RIGHT
			aCharacter.moveDest = moveResult.x# + MAZE_CELL_DIMENSIONS
			inc moveResult.x#, moveResult.overflow#
		endcase
		
		case DIRECTION_DOWN
			aCharacter.moveDest = moveResult.y# + MAZE_CELL_DIMENSIONS
			inc moveResult.y#, moveResult.overflow#
		endcase
		
		case DIRECTION_LEFT
			aCharacter.moveDest = moveResult.x# - MAZE_CELL_DIMENSIONS
			dec moveResult.x#, moveResult.overflow#
		endcase
	
	endselect
	
	SetSpritePositionByOffset(aCharacter.sprite, moveResult.x#, moveResult.y#)
	
endfunction

//----------------------------------------------------------------------------
// See if PacMan collided with a ghost
function characterCheckCollisions(aCharacter ref as TypeCharacter)
	
	local i, index as integer
	local timerData as TypeTimerData
	
	// see if pacman was caught by a monster, or has caught a ghost
	for i = CHARACTER_BLINKY to CHARACTER_BONUS
		// Can't collide with invisible items (bonus is just left where eaten, so skip colliding with it)
		if GetSpriteVisible(characters[i].sprite)
			if GetSpriteCollision(aCharacter.sprite, characters[i].sprite)
			
				if characters[i].characterType = CHARACTER_BONUS

					// hide the bonus
					SetSpriteVisible(characters[CHARACTER_BONUS].sprite, 0)
					characters[CHARACTER_BONUS].aiGoal = STATE_AIGOAL_NONE
					
					// Start the timer for the next bonus fruit
					bonusFruitTimer = timerMakeOneShot(TIME_TO_NEXT_FRUIT)
					
					// Add the score
					index = GetSpriteCurrentFrame(characters[CHARACTER_BONUS].sprite) - 1
					if mainState <> MAIN_STATE_DEMO then aiUpdateScore(bonusScores[index])

					// Get the score up on screen start a timer for hiding it
					bonusScoreSprite = bonusScoreSprites[index]
					SetSpritePositionByOffset(bonusScoreSprite, GetSpriteXByOffset(characters[i].sprite), GetSpriteYByOffset(characters[i].sprite))
					SetSpriteVisible(bonusScoreSprite, 1)
					bonusScoreTimer = timerMakeOneShot(TIME_HOLD_BONUS_SCORE)
					
				elseif characters[i].animIndex = ANIM_MONSTERS_MOVING
					playState = PLAY_STATE_DIED
				elseif characters[i].animIndex <> ANIM_MONSTER_GHOSTEYES
					
					// Add score for the ghost eaten
					if mainState <> MAIN_STATE_DEMO then aiUpdateScore(ghostScores[ghostScoreIndex])
					
					// Get the ghost eyes running home
					characters[i].animIndex = ANIM_MONSTER_GHOSTEYES
					characters[i].animOffset = (CHARACTER_GHOST_EYES - CHARACTER_BLINKY) * MONSTERS_FRAMES_NUM * 4
					characters[i].aiGoal = STATE_AIGOAL_SEEK
					characters[i].aiTarget = AI_TARGET_HOME
					characters[i].moveSpeed = characterGetSpeed(SPEED_MODE_EYES)
					
					// Get the score up
					ghostScoreSprite = ghostScoreSprites[ghostScoreIndex]
					SetSpritePositionByOffset(ghostScoreSprite, GetSpriteXByOffset(characters[i].sprite), GetSpriteYByOffset(characters[i].sprite))
					SetSpriteVisible(ghostScoreSprite, 1)
					inc ghostScoreIndex

					// Hide PACMAN and the monster so the score can be seen
					SetSpriteVisible(aCharacter.sprite, 0)
					SetSpriteVisible(characters[i].sprite, 0)
					
					// Use a timer - but could use 2 variables
					ghostScoreTimer = timerMakeOneShot(TIME_HOLD_GHOST_SCORE)
					timerData.userInt1 = i 
					timerSetTimerData(ghostScoreTimer, timerData)
					
					// now quit the loop because you can only fire on one character at a time
					exit
				endif
			endif
		endif
	next i

endfunction

//----------------------------------------------------------------------------
// Return the motion speed for the requested type, but modified to speed up
// as the player progresses
function characterGetSpeed(mode as integer)
	
	local levelBoost#, speed# as float
	
	select mode
		
		case SPEED_MODE_PACMAN_OPEN
			speed# = SPEED_INITIAL_SPEED * SPEED_PACMAN_OPEN_MOD
			endcase
			
		case SPEED_MODE_PACMAN_EATING
			speed# = SPEED_INITIAL_SPEED * SPEED_PACMAN_EATING_MOD
			endcase
			
		case SPEED_MODE_MONSTER
			speed# = SPEED_INITIAL_SPEED
			endcase
			
		case SPEED_MODE_GHOST
			speed# = SPEED_INITIAL_SPEED * SPEED_GHOST_MOD
			endcase
			
		case SPEED_MODE_EYES
			speed# = SPEED_INITIAL_SPEED * SPEED_EYES_MOD
			endcase
			
		case SPEED_MODE_BONUS
			speed# = SPEED_INITIAL_SPEED * SPEED_BONUS_MOD
			endcase
			
	endselect
	
	// Don't do the level boost in the UI and demo mode
	if mainState = MAIN_STATE_PLAY
		// limit the boost level to max at level SPEED_BOOSTED_LEVELS
		levelBoost# = players[activePlayer].level 
		if levelBoost# > SPEED_BOOSTED_LEVELS then levelBoost# = SPEED_BOOSTED_LEVELS
		
		// Normalize the boost level to 0->1, and multiply by the gain amount (SPEED_BOOSTED_AMOUNT) to get a gain fraction
		// add 1.0 to get a positive (bigger) mulitiplier between 1.0 and upper limit (SPEED_BOOSTED_AMOUNT)
		speed# = speed# * (1.0 + (levelBoost# / (SPEED_BOOSTED_LEVELS - 1.0)) * SPEED_BOOSTED_AMOUNT)
	endif
	
endfunction speed#

//----------------------------------------------------------------------------
// Return a time to hold the monsters before they move.  Level based
function characterGetHoldTime(characterType as integer)
	
	local holdTime# as float
	local level as integer

	level = players[activePlayer].level 
	if level > SPEED_BOOSTED_LEVELS then level = SPEED_BOOSTED_LEVELS

endfunction aiHoldTimes[characterType, level]

//----------------------------------------------------------------------------
// Send a monster in the opposite direction (when becoming a ghost)
function characterReverse(aCharacter ref as TypeCharacter)
	
	// just turn around, it's possible
	characterSetDirection(aCharacter, directionOpposite[aCharacter.moveDir])
	
	// set the new target, based on the new direction
	select aCharacter.moveDir
		
		case DIRECTION_UP
			dec aCharacter.moveDest, MAZE_CELL_DIMENSIONS
		endcase
		
		case DIRECTION_RIGHT
			inc aCharacter.moveDest, MAZE_CELL_DIMENSIONS
		endcase
		
		case DIRECTION_DOWN
			inc aCharacter.moveDest, MAZE_CELL_DIMENSIONS
		endcase
		
		case DIRECTION_LEFT
			dec aCharacter.moveDest, MAZE_CELL_DIMENSIONS
		endcase
		
	endselect
	
endfunction

//----------------------------------------------------------------------------
// Create the sprite, set pivot, collision and call setup
function characterMake(aCharacter ref as TypeCharacter, characterType as integer, image as integer, width as integer, height as integer)
	
	// Make the sprite
	aCharacter.sprite = CreateSprite(image)
	
	// Do the one-time sprite setup
	SetSpriteAnimation(aCharacter.sprite, width, height, (GetImageWidth(image) / width) * (GetImageHeight(image) / height))
	SetSpriteOffset(aCharacter.sprite, width / 4.0, height / 4.0)
	
	// Make the sprite collision a circle that's smaller than the visible 
	// sprite so the user has "close shaves" and doesn't feel cheated (32 wide, like a tile)
	SetSpriteShapeCircle(aCharacter.sprite, width / 4.0, height / 4.0, width / 4.0)
	
	// Put PACMAN in front of the monsters - so the death animation can be seen clearly 
	if characterType = CHARACTER_PACMAN then SetSpriteDepth(aCharacter.sprite, SPRITE_DEPTH_PACMAN) else SetSpriteDepth(aCharacter.sprite, SPRITE_DEPTH_MONSTERS)

	// Set up the other data structures that can be reset
	characterSetup(aCharacter, characterType)
	
endfunction

//----------------------------------------------------------------------------
// Set the base values to known defaults
function characterSetup(aCharacter ref as TypeCharacter, characterType as integer)

	aCharacter.characterType = characterType

	// PacMan and the bonus character get the same setup
	if characterType = CHARACTER_PACMAN
		aCharacter.animIndex = ANIM_PACMAN_MOVING
		aCharacter.animOffset = 0
		aCharacter.moveSpeed = characterGetSpeed(SPEED_MODE_PACMAN_OPEN)
	elseif characterType = CHARACTER_BONUS
		aCharacter.animIndex = -1
		aCharacter.animOffset = 0
		aCharacter.moveSpeed = characterGetSpeed(SPEED_MODE_BONUS)
	else 
		aCharacter.animIndex = ANIM_MONSTERS_MOVING
		aCharacter.animOffset = (characterType - CHARACTER_BLINKY) * MONSTERS_FRAMES_NUM * 4
		aCharacter.moveSpeed = characterGetSpeed(SPEED_MODE_MONSTER)
	endif

	aCharacter.animFrame = 0
	characterSetFacing(aCharacter, DIRECTION_UP)
	characterSetDirection(aCharacter, DIRECTION_NONE)
	aCharacter.moveMult# = 1.0
	aCharacter.moveDest = 0
	aCharacter.aiGoal = characterInitialGoals[characterType]
	aCharacter.aiTarget = AI_TARGET_CORNER
	aCharacter.aiTimerID = 0

	SetSpriteVisible(aCharacter.sprite, 0)

Endfunction

//----------------------------------------------------------------------------
// Sets the travel direction and calls the setup of the sprite facing angle
function characterSetDirection(aCharacter ref as TypeCharacter, newDir as integer)
	
	aCharacter.moveDir = newDir
	characterSetFacing(aCharacter, newDir)
	
endfunction

//----------------------------------------------------------------------------
// Set the facing angle of the sprite
function characterSetFacing(aCharacter ref as TypeCharacter, newDir as integer)

	// if the character stops (none) the last direction facing stays
	if newDir <> DIRECTION_NONE
		aCharacter.animFacing = newDir
		// Update sprite right now - don't wait for update interval in move
		// if animIndex = -1 then this sprite holds a frame and doesn't animate (bonus fruit character)
		if aCharacter.animIndex >= 0 then SetSpriteFrame(aCharacter.sprite, animations[aCharacter.animIndex, aCharacter.animFrame] + aCharacter.animFacing + aCharacter.animOffset)
	endif

endfunction
