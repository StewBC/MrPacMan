/*------------------------------------------------------------------------------*\

   Mr Pac Man - Arcade game "remake"

   Created by Stefan Wessels.
   Copyright (c) 2019 Wessels Consulting Ltd. All rights reserved.

   This software is provided 'as-is', without any express or implied warranty.
   In no event will the authors be held liable for any damages arising from the use of this software.

   Permission is granted to anyone to use this software for any purpose,
   including commercial applications, and to alter it and redistribute it freely.

\*------------------------------------------------------------------------------*/

#constant    KEY_ESCAPE       27
#constant    KEY_ENTER        13
#constant    KEY_5            53
#constant    KEY_1            49
#constant    KEY_2            50
#constant    KEY_D            68
#constant    KEY_LEFT         37
#constant    KEY_UP           38
#constant    KEY_RIGHT        39
#constant    KEY_DOWN         40
#constant    KEY_F1           112 // SQW - Debug

//----------------------------------------------------------------------------
// Returns 1 when ESC is pressed to quit the game, otherwise sets flags as needed
function inputProcess()

	local quit, updateCredits as integer
	local joyX#, joyY#, joyCoin as float
	
	updateCredits = 0
	startNewGame = 0
	joyCoin = 0
	
	// Joystic handling
	if joyStick
	
		joyCoin = GetRawJoystickButtonPressed(joyStick, JOY_COIN_BUTTON)
		startNewGame = GetRawJoystickButtonPressed(joyStick, JOY_START_BUTTON)

		joyX# = GetRawJoystickX(joyStick)
		joyY# = GetRawJoystickY(joyStick)
		
		if GetRawJoystickButtonState(joyStick, JOY_DIGITAL_UP)    then desiredDirection = DIRECTION_UP
		if GetRawJoystickButtonState(joyStick, JOY_DIGITAL_RIGHT) then desiredDirection = DIRECTION_RIGHT
		if GetRawJoystickButtonState(joyStick, JOY_DIGITAL_DOWN)  then desiredDirection = DIRECTION_DOWN
		if GetRawJoystickButtonState(joyStick, JOY_DIGITAL_LEFT)  then desiredDirection = DIRECTION_LEFT
		
		if joyY# < -JOYSTICK_DZ   then desiredDirection = DIRECTION_UP
		if joyX# >  JOYSTICK_DZ   then desiredDirection = DIRECTION_RIGHT
		if joyY# >  JOYSTICK_DZ   then desiredDirection = DIRECTION_DOWN
		if joyX# < -JOYSTICK_DZ   then desiredDirection = DIRECTION_LEFT
	endif

	// Keyboard
	if GetRawKeyState(KEY_ESCAPE) then quit = 1
	if GetRawKeyState(KEY_1)      then startNewGame = 1
	if GetRawKeyState(KEY_2)      then startNewGame = 2
	if GetRawKeyState(KEY_UP)     then desiredDirection = DIRECTION_UP
	if GetRawKeyState(KEY_RIGHT)  then desiredDirection = DIRECTION_RIGHT
	if GetRawKeyState(KEY_DOWN)   then desiredDirection = DIRECTION_DOWN
	if GetRawKeyState(KEY_LEFT)   then desiredDirection = DIRECTION_LEFT
	if GetRawKeyPressed(KEY_F1)   then inputDebugShow()

	// Enter or 5 adds a credit
	if GetRawKeyPressed(KEY_ENTER) or GetRawKeyPressed(KEY_5) or joyCoin
		inc numCredits
		if numCredits > 99 then numCredits = 99
		updateCredits = 1
	endif

	// If a new game is desired, and the user has the credits, set the flow for that
	if startNewGame and numCredits >= startNewGame and mainState <> MAIN_STATE_PLAY 
		updateCredits = 1
		dec numCredits, startNewGame 
		numActivePlayers = startNewGame
		if mainState = MAIN_STATE_UI then uiState = UI_STATE_CLEANUP else playState = PLAY_STATE_RESTART
	endif
	
	// If the credits have changed, update the display
	if updateCredits then SetTextString(textHandles[TEXT_NUMCREDITS], right(" " + Str(numCredits),2))

endFunction quit

//----------------------------------------------------------------------------
// This is the F1 debug show toggle - shows the destinations of the AIs
function inputDebugShow()
	
	local i as integer
	
	showTargetSprites = 1 - showTargetSprites
	for i = 1 to targetSprites.length
		SetSpriteVisible(targetSprites[i], showTargetSprites)
	next i
	
endfunction
