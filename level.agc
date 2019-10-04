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
// Map a user "level" number to a level "scene"
function levelGetLoadableLevel(levelIn as integer)
	
	levelOut as integer
	
	levelOut = mod(levelIn / TIMES_LEVEL_REPEATS, (NUM_LEVEL_FILES+1))
	
endfunction levelOut

//----------------------------------------------------------------------------
// Turn the random list of level sprites into a grid of sprites by X, Y positions
function level2DSortSpriteArray(in ref as integer[], out ref as integer[][])
	
	local i, j, index, length as integer
	
	for i = 0 to in.length
		
		index = in[i]
		if index = 0 then continue
		
		y = GetSpriteY(index) / GetSpriteHeight(index)
		x = GetSpriteX(in[i])  / GetSpriteWidth(index)
		
		if x < 0 then continue

		// Setting the lengths of the out array is essential but
		// Initializing the elements in the j loop is maybe paranoid
		if y > out.length
			length = out.length + 1
			out.length = y
			// Set the col lengths of all the new rows to 0
			for j = length to y
				out[j].length = -1
			next j
		endif
		
		if(x > out[y].length)
			length = out[y].length + 1
			out[y].length = x
			// Set the new col sprites to 0
			for j = length to x
				out[y, j] = 0
			next j
		endif
		
		out[y, x] = index
		
	next i
	
endfunction

//----------------------------------------------------------------------------
// Set every sprite in the in array to the rgba colours
function levelSetColorInSpriteArray(in ref as integer[], r, g, b, a)
	
	local i as integer
	
	for	i = 0 to in.length
		SetSpriteColor(in[i], r, g, b, a)
	next i
		
endfunction

//----------------------------------------------------------------------------
// Set the pivot for all sprites in the in array to their centre
function levelCentrePivotsForSpriteArray(in ref as integer[])
	
	local i as integer
	
	for	i = 0 to in.length
		SetSpriteOffset(in[i], GetSpriteWidth(in[i]) / 2.0, GetSpriteHeight(in[i]) / 2.0)
	next i
		
endfunction

//----------------------------------------------------------------------------
// Set up a pulse effect for all sprites in the in array
function levelSetupPulseEffect(in ref as integer[])

	local i as integer
	effect as TypeEffect
	
	effect.isa = EFFECT_TYPE_PULSE
	
	for	i = 0 to in.length
		effect.spr = in[i]
		effect.one# = 0.75
		effect.two# = 1.25
		effect.dir = 1
		effects.insert(effect)
	next i

endfunction

//----------------------------------------------------------------------------
// Update all the sprites in the effects array based on their effect settings
function levelEffectsUpdate()
	
	local i as integer
	local scale# as float
	effect as TypeEffect
	
	for	i = 0 to effects.length
		if GetSpriteExists(effects[i].spr)
			select effects[i].isa 
				case 0
					scale# = GetSpriteScaleX(effects[i].spr) + (effects[i].two# - effects[i].one#) * (ANIM_FRAME_RATE * 1.5) * effects[i].dir 
					if scale# > effects[i].two# 
						scale# = effects[i].two#
						effects[i].dir = -effects[i].dir
					elseif scale# < effects[i].one# 
						scale# = effects[i].one# 
						effects[i].dir = -effects[i].dir
					endif
					SetSpriteScaleByOffset(effects[i].spr, scale#, scale#)
				endcase
			endselect
		endif
	next i 
	
endfunction

//----------------------------------------------------------------------------
// Extract the coordinates of the sprites from in, as points in array out
function levelProcessPath(in ref as integer[], out ref as TypePoint2d[])
	
	local i as integer
	local point as TypePoint2d 
	
	for	i = 0 to in.length
		point.x = GetSpriteXByOffset(in[i])
		point.y = GetSpriteYByOffset(in[i])
		out.insert(point)
	next i

endfunction

//----------------------------------------------------------------------------
// Delete all sprites in the array and set array lenth to -1
function levelCleanSpriteArray(in ref as integer[])
	
	local i as integer
	
	for	i = 0 to in.length
		DeleteSprite(in[i])
	next i
	
	in.length = -1

endfunction

//----------------------------------------------------------------------------
// Shuffle the elements of the array
function levelShufflePointArray(in ref as TypePoint2d[])
	
	local i, l, r as integer
	point as TypePoint2d
	
	l = in.length
	for	i = 0 to l 
		r = Random2(0, l)
		point = in[i] 
		in[i] = in[r]
		in[r] = point
	next i

endfunction

//----------------------------------------------------------------------------
// Initialize a level for play
function levelSetupLevel(level as integer, sort ref as integer[][])
	
	local index as integer 
	
	doorPositions.length = -1
	preExit.length = -1
	bonusPath.length = -1
	
	index = mod(level, TIMES_LEVEL_REPEATS)
	level = levelGetLoadableLevel(level)
	
	select level 
		
		case 0
			// Call the scene setup function
			screen1_setup()
			
			// Colour the walls, power and dots the needed colour
			levelSetWallColor(level, index)
			levelSetColorInSpriteArray(screen1_dots, GetColorRed(dotColours[0, index]), GetColorGreen(dotColours[0, index]), GetColorBlue(dotColours[0, index]), GetColorAlpha(dotColours[0, index]))
			levelSetColorInSpriteArray(screen1_power, GetColorRed(dotColours[0, index]), GetColorGreen(dotColours[0, index]), GetColorBlue(dotColours[0, index]), GetColorAlpha(dotColours[0, index]))

			// Deal with the power dots - make it so they can pulse and put them in a group for collision detection
			levelCentrePivotsForSpriteArray(screen1_power)
			levelSetupPulseEffect(screen1_power)
			levelPowerToGroup(screen1_power)
			
			// Sort the dots and power into 2D arrays so the locations/order are known
			level2DSortSpriteArray(screen1_dots, sort)
			level2DSortSpriteArray(screen1_power, sort)

			// Make the door covers black - only matters when there's screen realestate next to the level
			levelSetColorInSpriteArray(screen1_doors, 0, 0, 0, 255)

			// Extract the door positions for the fruit walk ai
			levelProcessPath(screen1_exit, doorPositions)
			levelCleanSpriteArray(screen1_exit)

			// Extract the positions of the hallways to the doors - needed so seek always finds door
			levelProcessPath(screen1_preexit, preExit)
			levelCleanSpriteArray(screen1_preexit)

			// extract the points that make the path the fruit will (random order) walk
			levelProcessPath(screen1_bonuspath, bonusPath)
			levelCleanSpriteArray(screen1_bonuspath)
			
			// Finally, note how many dots and power dots need to be eaten to clear the level
			toEat = (screen1_dots.length + 1) + (screen1_power.length + 1)
		endcase

		case 1
			screen2_setup()

			levelSetWallColor(level, index)
			levelSetColorInSpriteArray(screen2_dots, GetColorRed(dotColours[1, index]), GetColorGreen(dotColours[1, index]), GetColorBlue(dotColours[1, index]), GetColorAlpha(dotColours[1, index]))
			levelSetColorInSpriteArray(screen2_power, GetColorRed(dotColours[1, index]), GetColorGreen(dotColours[1, index]), GetColorBlue(dotColours[1, index]), GetColorAlpha(dotColours[1, index]))

			levelCentrePivotsForSpriteArray(screen2_power)
			levelSetupPulseEffect(screen2_power)
			levelPowerToGroup(screen2_power)
			
			level2DSortSpriteArray(screen2_dots, sort)
			level2DSortSpriteArray(screen2_power, sort)

			levelSetColorInSpriteArray(screen2_doors, 0, 0, 0, 255)

			levelProcessPath(screen2_exit, doorPositions)
			levelCleanSpriteArray(screen2_exit)

			levelProcessPath(screen2_preexit, preExit)
			levelCleanSpriteArray(screen2_preexit)

			levelProcessPath(screen2_bonuspath, bonusPath)
			levelCleanSpriteArray(screen2_bonuspath)
			
			toEat = (screen2_dots.length + 1) + (screen2_power.length + 1)
		endcase

		case 2
			screen3_setup()

			levelSetWallColor(level, index)
			levelSetColorInSpriteArray(screen3_dots, GetColorRed(dotColours[2, index]), GetColorGreen(dotColours[2, index]), GetColorBlue(dotColours[2, index]), GetColorAlpha(dotColours[2, index]))
			levelSetColorInSpriteArray(screen3_power, GetColorRed(dotColours[2, index]), GetColorGreen(dotColours[2, index]), GetColorBlue(dotColours[2, index]), GetColorAlpha(dotColours[2, index]))

			levelCentrePivotsForSpriteArray(screen3_power)
			levelSetupPulseEffect(screen3_power)
			levelPowerToGroup(screen3_power)
			
			level2DSortSpriteArray(screen3_dots, sort)
			level2DSortSpriteArray(screen3_power, sort)

			levelSetColorInSpriteArray(screen3_doors, 0, 0, 0, 255)

			levelProcessPath(screen3_exit, doorPositions)
			levelCleanSpriteArray(screen3_exit)

			levelProcessPath(screen3_preexit, preExit)
			levelCleanSpriteArray(screen3_preexit)

			levelProcessPath(screen3_bonuspath, bonusPath)
			levelCleanSpriteArray(screen3_bonuspath)
			
			toEat = (screen3_dots.length + 1) + (screen3_power.length + 1)
		endcase

		case 3
			screen4_setup()

			levelSetWallColor(level, index)
			levelSetColorInSpriteArray(screen4_dots, GetColorRed(dotColours[3, index]), GetColorGreen(dotColours[3, index]), GetColorBlue(dotColours[3, index]), GetColorAlpha(dotColours[3, index]))
			levelSetColorInSpriteArray(screen4_power, GetColorRed(dotColours[3, index]), GetColorGreen(dotColours[3, index]), GetColorBlue(dotColours[3, index]), GetColorAlpha(dotColours[3, index]))

			levelCentrePivotsForSpriteArray(screen4_power)
			levelSetupPulseEffect(screen4_power)
			levelPowerToGroup(screen4_power)
			
			level2DSortSpriteArray(screen4_dots, sort)
			level2DSortSpriteArray(screen4_power, sort)

			levelSetColorInSpriteArray(screen4_doors, 0, 0, 0, 255)

			levelProcessPath(screen4_exit, doorPositions)
			levelCleanSpriteArray(screen4_exit)

			levelProcessPath(screen4_preexit, preExit)
			levelCleanSpriteArray(screen4_preexit)

			levelProcessPath(screen4_bonuspath, bonusPath)
			levelCleanSpriteArray(screen4_bonuspath)
			
			toEat = (screen4_dots.length + 1) + (screen4_power.length + 1)
		endcase

		case 4
			screen5_setup()

			levelSetWallColor(level, index)
			levelSetColorInSpriteArray(screen5_dots, GetColorRed(dotColours[4, index]), GetColorGreen(dotColours[4, index]), GetColorBlue(dotColours[4, index]), GetColorAlpha(dotColours[4, index]))
			levelSetColorInSpriteArray(screen5_power, GetColorRed(dotColours[4, index]), GetColorGreen(dotColours[4, index]), GetColorBlue(dotColours[4, index]), GetColorAlpha(dotColours[4, index]))

			levelCentrePivotsForSpriteArray(screen5_power)
			levelSetupPulseEffect(screen5_power)
			levelPowerToGroup(screen5_power)
			
			level2DSortSpriteArray(screen5_dots, sort)
			level2DSortSpriteArray(screen5_power, sort)

			levelSetColorInSpriteArray(screen5_doors, 0, 0, 0, 255)

			levelProcessPath(screen5_exit, doorPositions)
			levelCleanSpriteArray(screen5_exit)

			levelProcessPath(screen5_preexit, preExit)
			levelCleanSpriteArray(screen5_preexit)

			levelProcessPath(screen5_bonuspath, bonusPath)
			levelCleanSpriteArray(screen5_bonuspath)
			
			toEat = (screen5_dots.length + 1) + (screen5_power.length + 1)
		endcase

	endselect

endfunction toEat

//----------------------------------------------------------------------------
// Process the walkable zones
function levelSetupWalkable(level as integer, sort ref as integer[][])
	
	// Now add in the walkable areas
	select level
		
		case 0
			levelManageWalkable(screen1_walkable, sort)
			levelManageSlowZone(screen1_slow, sort)
		endcase
		
		case 1
			levelManageWalkable(screen2_walkable, sort)
			levelManageSlowZone(screen2_slow, sort)
		endcase
		
		case 2
			levelManageWalkable(screen3_walkable, sort)
			levelManageSlowZone(screen3_slow, sort)
		endcase
		
		case 3
			levelManageWalkable(screen4_walkable, sort)
			levelManageSlowZone(screen4_slow, sort)
		endcase
		
		case 4
			levelManageWalkable(screen5_walkable, sort)
			levelManageSlowZone(screen5_slow, sort)
		endcase
		
	endselect
	
endfunction 

//----------------------------------------------------------------------------
// Discard a level
function levelUnloadLevel()

	// Discard all effects
	effects.length = -1

	// now unload the loaded level
	select levelGetLoadableLevel(players[activePlayer].level)
		
		case 0
			screen1_cleanup()
		endcase

		case 1
			screen2_cleanup()
		endcase
		
		case 2
			screen3_cleanup()
		endcase
		
		case 3
			screen4_cleanup()
		endcase
		
		case 4
			screen5_cleanup()
		endcase
		
	endselect

endfunction

//----------------------------------------------------------------------------
// Set the wallks of a level to the end of level flash colour
function levelSetWallColor(level as integer, index as integer)
	
	select level
			
		case 0
			levelSetColorInSpriteArray(screen1_walls, GetColorRed(wallColours[0,index]), GetColorGreen(wallColours[0,index]), GetColorBlue(wallColours[0,index]), GetColorAlpha(wallColours[0,index]))
		endcase

		case 1
			levelSetColorInSpriteArray(screen2_walls, GetColorRed(wallColours[1,index]), GetColorGreen(wallColours[1,index]), GetColorBlue(wallColours[1,index]), GetColorAlpha(wallColours[1,index]))
		endcase
		
		case 2
			levelSetColorInSpriteArray(screen3_walls, GetColorRed(wallColours[2,index]), GetColorGreen(wallColours[2,index]), GetColorBlue(wallColours[2,index]), GetColorAlpha(wallColours[2,index]))
		endcase
		
		case 3
			levelSetColorInSpriteArray(screen4_walls, GetColorRed(wallColours[3,index]), GetColorGreen(wallColours[3,index]), GetColorBlue(wallColours[3,index]), GetColorAlpha(wallColours[3,index]))
		endcase
		
		case 4
			levelSetColorInSpriteArray(screen5_walls, GetColorRed(wallColours[4,index]), GetColorGreen(wallColours[4,index]), GetColorBlue(wallColours[4,index]), GetColorAlpha(wallColours[4,index]))
		endcase
		
	endselect
	
endfunction

//----------------------------------------------------------------------------
// Given the x and y and a direction, see what is in the next block from
// x,y in the direction that direction points at
function levelGetBlockForward(direction, x, y)
	
	local open as integer

	Inc x, gridStepX[direction]
	Inc y, gridStepY[direction]
	
	// The edges are always open in the direction of the edge, because the character
	// is then in a portal on that edge and can travel through the edge
	if x < 0 or x >= SCREEN_X_COLS
		if direction = DIRECTION_LEFT or direction = DIRECTION_RIGHT
			open = 2
		else
			open = LEVEL_CLOSED
		endif
	// There are no up/down teleport levels
	// elseif y < 0 or y > SCREEN_Y_ROWS
	// 	if direction = DIRECTION_UP or direction = DIRECTION_DOWN
	// 		open = LEVEL_OPEN
	// 	else
	// 		open = !LEVEL_OPEN
	// 	endif
	else
		open = players[activePlayer].walkableGrid[y, x]
	endif
	
endfunction open

//----------------------------------------------------------------------------
// from x,y in the diretion of direction, "eat" the block.  If there was a 
// dot or power, award score accordingly
function levelEatForward(direction, x, y)
	
	local sprite, score as integer
	
	Inc x, gridStepX[direction]
	Inc y, gridStepY[direction]

	// assume 0 for edge cases :)
	score = 0
	
	// There's never score in a portal/edge
	if not (x < 0 or x > SCREEN_X_COLS /*or y < 0 or y > SCREEN_Y_ROWS*/)
		sprite = players[activePlayer].edibleGrid[y, x]
		if sprite
			if GetSpriteGroup(sprite) then score = SCORE_POWER_PELLET else score = 1
			DeleteSprite(sprite)
			players[activePlayer].edibleGrid[y, x] = 0
			inc players[activePlayer].eaten
		endif
	endif
	
endfunction score

//----------------------------------------------------------------------------
// Sort the sprites from the in array into the out array, but replace 
// sprites with a 1 and the lack of sprites with a 0.  Clear the in array
// (i.e. delete all sprites in it and set its length to -1)
function levelManageWalkable(in ref as integer[], out ref as integer[][])

	local x, y as integer
	
	// build the walkable level array
	level2DSortSpriteArray(in, out)
	
	for y = 0 to out.length
		for x = 0 to out[y].length
			if out[y,x] then out[y,x] = 1 else out[y,x] = 0
		next x 
	next y

	// Clear the sprites in array
	for x = 0 to in.length
		DeleteSprite(in[x])
	next x

	// clear the array also
	in.length = -1

endfunction 

//----------------------------------------------------------------------------
// Sort the sprites from the in array into the out array, but replace 
// sprites with a 2. Clear the in array (i.e. delete all sprites in it
// and set its length to -1)
function levelManageSlowZone(in ref as integer[], out ref as integer[][])

	local x, y as integer
	local interim as integer[-1,-1]
	
	// build the walkable level array
	level2DSortSpriteArray(in, interim)
	
	for y = 0 to interim.length
		for x = 0 to interim[y].length
			if interim[y,x] then out[y,x] = 2
		next x 
	next y

	// Clear the sprites in array
	for x = 0 to in.length
		DeleteSprite(in[x])
	next x

	// clear the array also
	in.length = -1

endfunction 

//----------------------------------------------------------------------------
// Add the sprites in the in array to a sprite group (SPRITE_GROUP_POWER)
function levelPowerToGroup(in ref as integer[])
	
	local i as integer
	
	for i = 0 to in.length
		SetSpriteGroup(in[i], SPRITE_GROUP_POWER)
	next i
	
endfunction 

//----------------------------------------------------------------------------
// Hide text and sprite that may be on-screen at a transition
function levelHideDynamicElements()
	
	local i as integer 
	
	// Hide all of the dynamic text
	for i = TEXT_READY to TEXT_ENDOFTEXT
		SetTextVisible(textHandles[i], 0)
	next i
	
	// hide the ghost and bonus scores, should they be visible
	if ghostScoreSprite 
		SetSpriteVisible(ghostScoreSprite, 0)
		ghostScoreSprite = 0
	endif
	
	if bonusScoreSprite 
		SetSpriteVisible(bonusScoreSprite, 0)
		bonusScoreSprite = 0
	endif
	
	// Hide the bonus character should it be visible
	SetSpriteVisible(characters[CHARACTER_BONUS].sprite, 0)

endfunction
