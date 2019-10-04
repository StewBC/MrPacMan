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
#insert "globals.agc"
#include "input.agc"
#include "timer.agc"
#include "level.agc"
#include "character.agc"
#include "ui.agc"
#include "ai.agc"
#include "play.agc"
#include "frontEnd.scene"
#include "screen1.scene"
#include "screen2.scene"
#include "screen3.scene"
#include "screen4.scene"
#include "screen5.scene"

//----------------------------------------------------------------------------
// The main execution of the game starts here
mainInitialize()

// loop forever (or at least till ESC pressed)
do

    //Print( ScreenFPS() )
	
	dt# = GetFrameTime()
 
	// returns 1 to quit the game
	if inputProcess() then exit
	
	if timerIsDone(effectsTimer)
		levelEffectsUpdate()
	endif

	// Catching a ghost stops the whole game while the score is displayed
	if not ghostScoreTimer
	
		updateTimers()
	
		select mainState
			
			case MAIN_STATE_UI
				uiMain()
			endcase
			
			case MAIN_STATE_DEMO
				playStateDemoMain()
			endcase
			
			case MAIN_STATE_PLAY
				playMain()
			endcase

		endselect
		
	else

		local timerData as TypeTimerData
		
		// Find the game timer
		timerGetTimerData(ghostScoreTimer, timerData)
		// manually tick it, because timers are also stopped
		dec gameTimers[timerData.index].time, dt#
		// if it should fire, act on it
		if gameTimers[timerData.index].time <= 0
			// clear the timer handle
			ghostScoreTimer = 0
			// Hide the score
			SetSpriteVisible(ghostScoreSprite, 0)
			ghostScoreSprite = 0
			// Show pacman
			SetSpriteVisible(characters[CHARACTER_PACMAN].sprite, 1)
			// show the monster (now eyes)
			SetSpriteVisible(characters[timerData.userInt1].sprite, 1)
		endif
		
		aiMoveEyes()
		
	endif
		
	Sync()
    
loop

// exit the app
end

//----------------------------------------------------------------------------
// Load images, create characters and other helpersprites and init any
// elements that need a one-time init
function mainInitialize()
	
	local i, j, image as integer

	// show all errors
	SetErrorMode(2)
	
	// set window properties
	SetWindowTitle( "Mr Pac Man" )
	SetWindowSize( 896, 1152, 0 )
	SetWindowAllowResize( 1 ) // allow the user to resize the window
	
	// set display properties
	SetVirtualResolution( 896, 1152 ) // doesn't have to match the window
	SetOrientationAllowed( 1, 1, 1, 1 ) // allow both portrait and landscape on mobile devices
	SetSyncRate( DESIRED_FPS, 0 )
	SetScissor( 0,0,0,0 ) // use the maximum available screen space, no black borders
	UseNewDefaultFonts( 1 )
	
	// Load the image resources
	for i = 0 to imageNames$.length
		images[i] = LoadImage(imageNames$[i])
	next i
	
	// Create the font
	SetTextDefaultFontImage(images[IMAGE_FONT])

	// Create the text strings
	for i = 0 to textStrings$.length
		textHandles[i] = CreateText(textStrings$[i])
		SetTextFontImage(textHandles[i], images[IMAGE_FONT])
		SetTextSize(textHandles[i], MAZE_CELL_DIMENSIONS)
		SetTextPosition(textHandles[i], MAZE_CELL_DIMENSIONS*textX[i], MAZE_CELL_DIMENSIONS*textY[i])
		SetTextVisible(textHandles[i], textV[i])
	next i

	// Set up some text colours
	SetTextColor(textHandles[TEXT_GAME_TITLE], 
		GetColorRed(characterColours[CHARACTER_SUE]),
		GetColorGreen(characterColours[CHARACTER_SUE]),
		GetColorBlue(characterColours[CHARACTER_SUE]),
		GetColorAlpha(characterColours[CHARACTER_SUE]))
		
	SetTextColor(textHandles[TEXT_MRPACMAN], 
		GetColorRed( characterColours[CHARACTER_PACMAN]),
		GetColorGreen( characterColours[CHARACTER_PACMAN]),
		GetColorBlue( characterColours[CHARACTER_PACMAN]),
		GetColorAlpha( characterColours[CHARACTER_PACMAN]))
		
	SetTextColor(textHandles[TEXT_GAMEOVER], 255, 0, 0 ,255)

	// Make Mr Pac Man
	characterMake(characters[CHARACTER_PACMAN], CHARACTER_PACMAN, images[IMAGE_PACMAN], CHARACTER_SPRITE_WIDTH, CHARACTER_SPRITE_HEIGHT)
	
	// Make a "bonus" character
	characterMake(characters[CHARACTER_BONUS], CHARACTER_BONUS, images[IMAGE_BONUS], CHARACTER_SPRITE_WIDTH, CHARACTER_SPRITE_HEIGHT)
	
	// Make the monsters
	for i = CHARACTER_BLINKY to CHARACTER_SUE
		characterMake(characters[i], i, images[IMAGE_MONSTERS], CHARACTER_SPRITE_WIDTH, CHARACTER_SPRITE_HEIGHT)
		// Set the names of the monsters to the colours of the monsters
		SetTextColor(textHandles[TEXT_BLINKY+i-CHARACTER_BLINKY],GetColorRed(characterColours[i]), GetColorGreen(characterColours[i]), GetColorBlue(characterColours[i]), GetColorAlpha(characterColours[i]))
	next i

	// Set up the ghost scores
	for i = 0 to 3
		image = images[IMAGE_SCORES]
		ghostScoreSprites[i] = CreateSprite(image)
		SetSpriteAnimation(ghostScoreSprites[i], CHARACTER_SPRITE_WIDTH, CHARACTER_SPRITE_HEIGHT, (GetImageWidth(image) / CHARACTER_SPRITE_WIDTH) * (GetImageHeight(image) / CHARACTER_SPRITE_HEIGHT))
		SetSpriteOffset(ghostScoreSprites[i], CHARACTER_SPRITE_WIDTH / 4.0, CHARACTER_SPRITE_HEIGHT / 4.0)
		SetSpriteFrame(ghostScoreSprites[i], 1 + i)
		SetSpriteDepth(ghostScoreSprites[i], SPRITE_DEPTH_SCORE)
		SetSpriteColor(ghostScoreSprites[i], 0, 0, 255, 255)
		SetSpriteVisible(ghostScoreSprites[i], 0)
	next i
	
	// Set up the bonus scores
	for i = 0 to bonusScores.length
		image = images[IMAGE_SCORES]
		bonusScoreSprites[i] = CreateSprite(image)
		SetSpriteAnimation(bonusScoreSprites[i], CHARACTER_SPRITE_WIDTH, CHARACTER_SPRITE_HEIGHT, (GetImageWidth(image) / CHARACTER_SPRITE_WIDTH) * (GetImageHeight(image) / CHARACTER_SPRITE_HEIGHT))
		SetSpriteOffset(bonusScoreSprites[i], CHARACTER_SPRITE_WIDTH / 4.0, CHARACTER_SPRITE_HEIGHT / 4.0)
		SetSpriteFrame(bonusScoreSprites[i], 5 + i)
		SetSpriteDepth(bonusScoreSprites[i], SPRITE_DEPTH_SCORE)
		SetSpriteColor(bonusScoreSprites[i], 220, 220, 220, 255)
		SetSpriteVisible(bonusScoreSprites[i], 0)
	next i

	// Reset the highscore
	highScore = 0
	
	// no coins
	numCredits = 0
	
	// no ghosts being caught, no bonus being displayed
	ghostScoreTimer = 0
	ghostScoreSprite = 0
	bonusScoreTimer = 0
	bonusScoreSprite = 0
	demoTimer = 0

	// Look for a joystick only at startup, use the 1st one found
	CompleteRawJoystickDetection()
	joyStick = 0
	for i = 1 to 7
		if GetRawJoystickExists(i)
			joyStick = i
			exit
		endif
	next i

	
	// This timer is always running and it is how fast the sprites animate
	animTimer = timerMakeWrap(ANIM_FRAME_RATE)
	effectsTimer = timerMakeWrap(ANIM_FRAME_RATE)

	// Initialize the state variables
	mainState = MAIN_STATE_UI // MAIN_STATE_UI for ui, MAIN_STATE_PLAY to skip UI, MAIN_STATE_DEMO for demo mode
	uiState = UI_STATE_INIT
	playState = PLAY_STATE_INIT
	
	// Show collision boxes
	// SetPhysicsDebugOn()
	
endFunction
