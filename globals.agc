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
// States (should be enums if the language supported that)

// main states - Used in main - demo is really a play sub-state
#constant MAIN_STATE_UI               = 1
#constant MAIN_STATE_DEMO             = 2
#constant MAIN_STATE_PLAY             = 3

// ui states
#constant UI_STATE_INIT               = 1
#constant UI_STATE_LIGHTS_ON          = 2
#constant UI_STATE_NEXT_GUY           = 3
#constant UI_STATE_MOVE_TO_TURN       = 4
#constant UI_STATE_MOVE_FROM_TURN     = 5
#constant UI_STATE_MOVE_PACMAN        = 6
#constant UI_STATE_WAIT               = 7
#constant UI_STATE_CLEANUP            = 8

// playe states
#constant PLAY_STATE_INIT             = 1
#constant PLAY_STATE_LEVEL_INIT       = 2
#constant PLAY_STATE_PLAYER_INIT      = 3
#constant PLAY_STATE_GET_READY        = 4
#constant PLAY_STATE_RUN              = 5
#constant PLAY_STATE_LEVEL_CLEAR      = 6
#constant PLAY_STATE_DIED             = 7
#constant PLAY_STATE_CONVULSTIONS     = 8
#constant PLAY_STATE_PLAY_MORTIS      = 9
#constant PLAY_STATE_NEXT_PLAYER      = 10
#constant PLAY_STATE_GAME_OVER_PLAYER = 11
#constant PLAY_STATE_CLEANUP          = 12
#constant PLAY_STATE_RESTART          = 13

// AI Goal states
#constant STATE_AIGOAL_NONE            = 0                             // The BONUS fruit sometimes have no goal
#constant STATE_AIGOAL_USER            = 1                             // PAC MANs goal is to serve the user
#constant STATE_AIGOAL_HOLDING         = 2                             // Monsters in a cage - going down
#constant STATE_AIGOAL_EXIT            = 3                             // Monster leaving cage
#constant STATE_AIGOAL_ENTER           = 4                             // Eyes entering cage
#constant STATE_AIGOAL_WANDER          = 5                             // Ghost or Fruit random march
#constant STATE_AIGOAL_SEEK            = 6                             // Monster looking for PAC MAN

//----------------------------------------------------------------------------
// State Variables (Values are the state enums)
global mainState                      as integer
global uiState                        as integer
global playState                      as integer

//----------------------------------------------------------------------------
// game flow
global numCredits                     as integer
global startNewGame                   as integer

//----------------------------------------------------------------------------
// Everything needed to track a player
type PlayerInfo
	score                             as integer                      // total score for this player
	isAlive                           as integer                      // false when a life is needed to play
    lives                             as integer                      // total lives this player has left
    level                             as integer                      // level the player is on (not screen, but level)
    toEat                             as integer                      // how many dots can be eaten on this screen (oncl. power)
    eaten                             as integer                      // how many dots has been eaten
    edibleGrid                        as integer[-1,-1]               // 2D grid of dot & power sprites
	walkableGrid                      as integer[-1,-1]               // 2D grid with 1s where the characters can go, 0=no go
	livesSprites                      as integer[]                    // PacMan sprites to indicate lives
	bonusDisplaySprites               as integer[]                    // The last seen bonus sprites for this player
endType

//----------------------------------------------------------------------------
// Instances of players to keep track of
#constant MAX_PLAYERS                 = 2
global players                        as PlayerInfo[MAX_PLAYERS]

//----------------------------------------------------------------------------
// number of lives a player gets at the start of the game
#constant NUM_PLAYER_LIVES            = 3

//----------------------------------------------------------------------------
// Variables that hold the state/stats of the active player
global activePlayer                   as integer
global numActivePlayers               as integer
numActivePlayers                      = 1                             // For skipping the UI, then this is valid

// Scores appear 10x on screen as a 0 is appended
#constant SCORE_POWER_PELLET          = 5
#constant SCORE_1ST_GHOST             = 20
#constant EXTRA_LIFE_MIN_SCORE        = 1000
#constant EXTRA_LIFE_SCORE            = 500                           // Once past EXTRA_LIFE_MIN_SCORE, every this (10x) give a life

// The high score
global highScore                      as integer

// The current ghost and the sprites to show them
global ghostScoreSprite               as integer
global ghostScoreSprites              as integer[3]                   // 0 is 200, 1 is 400, etc
global ghostScoreIndex                as integer                      // 0 shows 200, 1 400, etc
global ghostScores                    as integer[3]
ghostScores                           = [ 20,  40,  80, 160]          // amount added to score based on index

// The bonus score items
#constant NUM_BONUS_SCORES            = 7
global bonusScoreSprite               as integer
global bonusScoreSprites              as integer[NUM_BONUS_SCORES]    // 0 is 200, 1 is 400, etc
global bonusScores                    as integer[NUM_BONUS_SCORES]
                                                                      // amount added to score based on index
bonusScores                           = [  10,  30,  50, 70, 100, 200, 300, 500]

//----------------------------------------------------------------------------
// Time (tracking) related
global dt#                            as float                        // delta time, i.e. frame time

//----------------------------------------------------------------------------
// Resources

// Setup of the sprite pages
#constant MONSTERS_FRAMES_NUM         = 2                             // 2 frames per directions

// sizes of the sprites on the pages
#constant CHARACTER_SPRITE_WIDTH      = 64                            // all character sprites are 64x64
#constant CHARACTER_SPRITE_HEIGHT     = 64

// sprite sorting order
#constant SPRITE_DEPTH_SCORE          = 100
#constant SPRITE_DEPTH_PACMAN         = 110
#constant SPRITE_DEPTH_MONSTERS       = 120

// The sprite image pages
#constant IMAGE_FONT                  = 0
#constant IMAGE_PACMAN                = 1
#constant IMAGE_MONSTERS              = 2
#constant IMAGE_SCORES                = 3
#constant IMAGE_BONUS                 = 4
#constant IMAGE_MAX_IMAGES            = 4

// Names of images to load
global imageNames$                    as string[IMAGE_MAX_IMAGES]
imageNames$                           = ["font.png", "pacman.png", "monsters.png", "scores.png", "bonus.png"]

// List of handles to images once loaded
global images                         as integer[IMAGE_MAX_IMAGES]

//----------------------------------------------------------------------------
// Text strings and handles
#constant TEXT_1UP                    = 0
#constant TEXT_2UP                    = 1
#constant TEXT_SCORE2                 = 2
#constant TEXT_HSCORELBL              = 3
#constant TEXT_SCORE1                 = 4
#constant TEXT_HIGHSCORE              = 5
#constant TEXT_CREDITS                = 6
#constant TEXT_NUMCREDITS             = 7
#constant TEXT_READY                  = 8
#constant TEXT_GAMEOVER               = 9
#constant TEXT_GAME_TITLE             = 10
#constant TEXT_STARRING               = 11
#constant TEXT_WITH                   = 12
#constant TEXT_BLINKY                 = 13
#constant TEXT_PINKY                  = 14
#constant TEXT_INKY                   = 15
#constant TEXT_SUE                    = 16
#constant TEXT_MRPACMAN               = 17
#constant TEXT_DEMO                   = 18
#constant TEXT_ENDOFTEXT              = 18

global textStrings$                   as string[TEXT_ENDOFTEXT]
global textHandles                    as integer[TEXT_ENDOFTEXT]
global textX                          as integer[TEXT_ENDOFTEXT]
global textY                          as integer[TEXT_ENDOFTEXT]
global textV                          as integer[TEXT_ENDOFTEXT]

// All user facing text
textStrings$                          = [
    "1UP",
    "2UP",
    "     00",
    "HIGH SCORE",
    "     00",
    "     00",
    "CREDITS",
    " 0",
    "READY!",
    "GAME  OVER",
    '"MR PAC-MAN"',
    "STARRING",
    "WITH",
    "BLINKY",
     "PINKY",
    "INKY",
    "SUE",
    "MR PAC-MAN",
    "DEMO"]

// the X and Y of the text, and the starting visibility
textX                                 = [  3, 22, 19, 8, 0, 9, 2 , 10, 11, 9 , 9, 9 , 9 , 12, 12, 12, 13, 9 , 12]
textY                                 = [  0, 0 , 1 , 0, 1, 1, 34, 34, 20, 20, 7, 13, 13, 16, 16, 16, 16, 16, 2 ]
textV                                 = [  1, 1 , 0 , 1, 1, 0, 0 , 0 , 0 , 0 , 0, 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ]

// lookup arrays to find the appropriate entries to turn on/off, per player
global perPlayerScoreIndex            as integer[MAX_PLAYERS]
perPlayerScoreIndex                   = [TEXT_SCORE1, TEXT_SCORE2]
global perPlayerNameIndex             as integer[MAX_PLAYERS]
perPlayerNameIndex                    = [TEXT_1UP, TEXT_2UP]

//----------------------------------------------------------------------------
// Maze related
#constant NUM_LEVEL_FILES             = 4                             // Actual number -1 since 0 based
#constant TIMES_LEVEL_REPEATS         = 2                             // How many times each level is played before advancing to next
#constant TIMES_LEVEL_REPEATS_MIN_1   = 1                             // I wish the language supported constant expressions

// The size of a maze tile (square)
#constant MAZE_CELL_DIMENSIONS        = 32                            // Square pixels that make up a tile

// The power dots are put in a group for differentiation when eaten
#constant SPRITE_GROUP_POWER          = 1

// the play colours [x,n] and the Flashing Maze alternate colour [x,n+1], per level [x]
global wallColours                    as integer[NUM_LEVEL_FILES, TIMES_LEVEL_REPEATS]

//Level 1
wallColours[0,0]                      = MakeColor(31 , 143, 255, 255) // 1st occurance
wallColours[0,1]                      = MakeColor(31 , 31 , 255, 255) // 2nd occurance
wallColours[0,2]                      = MakeColor(222, 222, 255, 255) // flash colour when cleared

//Level 2
wallColours[1,0]                      = MakeColor(255, 180, 170, 255)
wallColours[1,1]                      = MakeColor(255, 89 , 66, 255)
wallColours[1,2]                      = MakeColor(255, 20 , 20 , 255)

//Level 3
wallColours[2,0]                      = MakeColor(60 , 180, 255, 255)
wallColours[2,1]                      = MakeColor(0  , 101, 163, 255)
wallColours[2,2]                      = MakeColor(200, 215, 250, 255)

//Level 4
wallColours[3,0]                      = MakeColor(237, 180, 123, 255)
wallColours[3,1]                      = MakeColor(186, 102, 23 , 255)
wallColours[3,2]                      = MakeColor(225, 210, 215, 255)

//Level 5
wallColours[4,0]                      = MakeColor(102, 115, 255, 255)
wallColours[4,1]                      = MakeColor(0  , 15 , 179, 255)
wallColours[4,2]                      = MakeColor(240, 180, 135, 255)

global dotColours                     as integer[NUM_LEVEL_FILES, TIMES_LEVEL_REPEATS_MIN_1]

//Level 1
dotColours[0,0]                       = MakeColor(255, 185, 175, 255) // 1st occurance
dotColours[0,1]                       = MakeColor(255, 140, 122, 255) // 2nd occurance

//Level 2
dotColours[1,0]                       = MakeColor(173, 173, 255, 255)
dotColours[1,1]                       = MakeColor(224, 224, 255, 255)

//Level 3
dotColours[2,0]                       = MakeColor(255, 255, 5  , 255)
dotColours[2,1]                       = MakeColor(209, 209, 0  , 255)

//Level 4
dotColours[3,0]                       = MakeColor(215, 45 , 25 , 255)
dotColours[3,1]                       = MakeColor(168, 37 , 20 , 255)

//Level 5
dotColours[4,0]                       = MakeColor(235, 235, 255, 255)
dotColours[4,1]                       = MakeColor(184, 184, 255, 255)

//----------------------------------------------------------------------------
// Characters
type TypeCharacter
// who
    characterType                     as integer                      // CHARACTER_ type value
// how it looks (animates, etc)
    sprite                            as integer                      // handle to the sprite
    animIndex                         as integer                      // index into animations array
    animFrame                         as integer                      // frame in the animation pointed to by animIndex
    animFacing                        as integer                      // direction the character's sprite is facing
    animOffset                        as integer                      // for monsters - frames to skip to get to their colour
// its movement
    moveSpeed                         as integer                      // how fast this character moves per second
	moveMult#                         as float                        // multiplied onto the moveSpeed (as a modifier for going slow through portal)
    moveDir                           as integer                      // direction the character wants to move in
	moveDest                          as integer                      // if sprite hits this coord, it stops on the coord [n] - 0 = y; 1 = x axis
// its AI
	aiTimerID                         as integer                      // AI timer to time actions - use only OneShot timers for auto-destroy
    aiGoal                            as integer                      // what's it trying to do
	aiTarget                          as integer                      // When seeking, where is it seeking to?
    aiInt1                            as integer                      // General purpose variable 1 - used to track some sub-states
endType

// character types
#constant CHARACTER_PACMAN            = 0
#constant CHARACTER_BLINKY            = 1
#constant CHARACTER_PINKY             = 2
#constant CHARACTER_INKY              = 3
#constant CHARACTER_SUE               = 4
#constant NUM_SENTIENT_CHARACTERS     = 4                             // CHARACTER_PACMAN[0]++monsters[1-4]+...
#constant CHARACTER_BONUS             = 5                             // The marching fuit character - dynamically added to characters[]
#constant NUM_CHARACTERS              = 5                             // include the bonus fruit character
#constant CHARACTER_GHOST_BLUE        = 5                             // pseudo characters, for sprite image calculations
#constant CHARACTER_GHOST_WHITE       = 6
#constant CHARACTER_GHOST_EYES        = 7

// animation related - all animations characters can have
#constant ANIM_NO_ANIMATION           = -1
#constant ANIM_PACMAN_MOVING          = 0
#constant ANIM_MONSTERS_MOVING        = 1
#constant ANIM_MONSTER_GHOSTING       = 2
#constant ANIM_MONSTER_GHOSTEND       = 3
#constant ANIM_MONSTER_GHOSTEYES      = 4
#constant ANIM_PACMAN_DYING           = 5
#constant ANIM_NUM_ANIMS              = 5

// list of frames, per animation in the "animations" array / table
global animations                     as integer[ANIM_NUM_ANIMS, -1]
animations[ANIM_PACMAN_MOVING    ]    = [  1,  7, 13, 7                     ]
animations[ANIM_MONSTERS_MOVING  ]    = [  1,  5                            ]
animations[ANIM_MONSTER_GHOSTING ]    = [  1,  5                            ]
animations[ANIM_MONSTER_GHOSTEND ]    = [  1,  5,  9,  13                   ]
animations[ANIM_MONSTER_GHOSTEYES]    = [  1,  1,  5,  5                    ]
animations[ANIM_PACMAN_DYING     ]    = [  1,  7, 13,  5, 11, 17,  6, 12, 18]

// Targets
#constant AI_TARGET_PACMAN            = 1                             // Monster seeking for PAC MAN
#constant AI_TARGET_CORNER            = 2                             // Monster seeking a corner
#constant AI_TARGET_HOME              = 3                             // Monster eyes seeking home 
#constant AI_TARGET_BONUS             = 4                             // Bonus fruit going walkabout

global aiTargetMode                   as integer                      // Level wide target mode, can be overridden locally
global aiTargetLevel                  as integer                      // 1st index into aiTargetModeTimings, based on level player's at
global aiTargetModeTimings            as integer[2,-1]                // timings for switching seek modes
global cornerTargetsX                 as integer[NUM_SENTIENT_CHARACTERS]
global cornerTargetsY                 as integer[NUM_SENTIENT_CHARACTERS]

// The modes are corner, seek, corner...  If the last number is corner (and it always is), at the end
// of that time, the game will switch to seek and hold seek forever
aiTargetModeTimings[0]                = [ 7, 20, 7, 20, 5 , 20, 5 ]   // level 0
aiTargetModeTimings[1]                = [ 7, 20, 7, 20, 5         ]   // level 1 2 3 4
aiTargetModeTimings[2]                = [ 5, 20, 5, 20, 5         ]   // level 5+
cornerTargetsX                        = [ 0, 27, 1, 27, 1         ]
cornerTargetsY                        = [ 0, 3 , 3, 34, 34        ]

// all characters live in this array
global characters                     as TypeCharacter[NUM_CHARACTERS]

// These arrays hold setup information.  Can't assign "type" arrays statically
global characterTypes                 as integer[]

characterTypes                        = [
    CHARACTER_PACMAN,
    CHARACTER_BLINKY,
    CHARACTER_PINKY,
    CHARACTER_INKY,
    CHARACTER_SUE]

global aiHoldTimes                    as float[CHARACTER_SUE, SPEED_BOOSTED_LEVELS]
aiHoldTimes[CHARACTER_PINKY]          = [1.0 , 0.0 , 1.0 , 0.0, 1.0, 0.0, 1.0, 0.5, 1.0, 0.0]
aiHoldTimes[CHARACTER_INKY]           = [5.0 , 3.0 , 4.0 , 4.0, 4.0, 2.0, 3.0, 1.0, 3.0, 0.3]
aiHoldTimes[CHARACTER_SUE]            = [15.0, 12.0, 13.0, 8.0, 8.0, 8.0, 6.0, 4.0, 4.0, 0.6]

// Rate at which sprites animate (1 second / times per second to update)
#constant ANIM_FRAME_RATE             = 1.0/13.0

// Directions in which characters can move, none being standing still
#constant DIRECTION_UP                = 0
#constant DIRECTION_RIGHT             = 1
#constant DIRECTION_DOWN              = 2
#constant DIRECTION_LEFT              = 3
#constant DIRECTION_NONE              = 4

// direction && 1 is the axis, except for none, of course
#constant AXIS_Y                      = 0
#constant AXIS_X                      = 1

global initialPositionsX              as integer[]
global initialPositionsY              as integer[]
global initialDirections              as integer[]
global characterInitialGoals          as integer[]

initialPositionsX                     = [14, 14, 14, 12, 16]
initialPositionsY                     = [26, 14, 17, 17, 17]
initialDirections                     = [
    DIRECTION_LEFT,
    DIRECTION_LEFT,
    DIRECTION_UP,
    DIRECTION_DOWN,
    DIRECTION_UP]

characterInitialGoals                 = [
	STATE_AIGOAL_USER,                                                // Pacman STATE_AIGOAL_USER when not in demo
	STATE_AIGOAL_SEEK,                                                // Blinky
	STATE_AIGOAL_HOLDING,                                             // Pinky
	STATE_AIGOAL_HOLDING,                                             // Inky
	STATE_AIGOAL_HOLDING,                                             // Sue
	STATE_AIGOAL_NONE]                                                // Bonus Fruit

// Base speeds at which characters move - scaled modified based on level
#constant SPEED_INITIAL_SPEED         = 250                           // pixels per second
#constant SPEED_PACMAN_OPEN_MOD       = 1.1                           // when not eating dots, pacman is faster
#constant SPEED_PACMAN_EATING_MOD     = 0.9                           // when eating dots, pacman is slower
#constant SPEED_GHOST_MOD             = 0.7                           // ghsosts are way slower
#constant SPEED_EYES_MOD              = 2.0                           // eyes are way faster
#constant SPEED_BONUS_MOD             = 0.6                           // eyes are way faster
#constant SPEED_SLOW_MOD              = 0.5                           // crossing as a monster is slow

// Speed scale modifiers
#constant SPEED_BOOSTED_LEVELS        = 9                             // range over which speed boost happens.
#constant SPEED_BOOSTED_AMOUNT        = 0.5                           // 0 = 0% is no boost, 1 = 100% is twice as fast

// Parameters to the function that returns the relevant speed after modified per level
#constant SPEED_MODE_PACMAN_OPEN      = 1
#constant SPEED_MODE_PACMAN_EATING    = 2
#constant SPEED_MODE_MONSTER          = 3
#constant SPEED_MODE_GHOST            = 4
#constant SPEED_MODE_EYES             = 5
#constant SPEED_MODE_BONUS            = 6

//----------------------------------------------------------------------------
// Monsters (ghosts)
#constant NUM_MONSTERS                = 3                             // is 4 [0-3]

global characterColours               as integer[NUM_CHARACTERS]
characterColours[CHARACTER_PACMAN]    = MakeColor(249, 247, 13 , 255)
characterColours[CHARACTER_BLINKY]    = MakeColor(255, 0  , 0  , 255)
characterColours[CHARACTER_PINKY]     = MakeColor(255, 150, 255, 255)
characterColours[CHARACTER_INKY]      = MakeColor(  0, 254, 255, 255)
characterColours[CHARACTER_SUE]       = MakeColor(255, 164, 0  , 255)
characterColours[CHARACTER_BONUS]     = MakeColor(  0, 255, 0  , 255)

//----------------------------------------------------------------------------
// UI related
#constant UI_MONSTER_INITIAL_X        = 896+64                        // CHARACTER_SPRITE_WIDTH is 64, plus MAZE_CELL_DIMENSIONS
#constant UI_MONSTER_INITIAL_Y        = 640                           // row 20
#constant UI_MONSTER_TURN_X           = 160-8                         // col 4.75
#constant UI_PACMAN_STOP_X            = 896/2.0                       // middle of screen in X
#constant UI_MONSTER_SPEED            = 250                           // pixels / sec
#constant UI_NUM_LIGHTS_ON            = 6                             // how many marquee lights on at any time

global activeCharacter                as integer                      // index to monster that's moving
global lightsIndex                    as integer                      // which light in a marquee strip is on
global lightsStep#                    as float                        // which light in a marquee strip is on

//----------------------------------------------------------------------------
// GameTimers
global animTimer                      as integer                      // always running, times anim frame updates
global oneShotTimer                   as integer                      // re-used for various things
global textTimer                      as integer                      // used to flash text (1up, game over, etc)
global demoTimer                      as integer                      // used to time a play demo cycle
global aiTargetModeTimer              as integer                      // switches ai seek mode
global ghostTimer                     as integer                      // how long ghost mode is active for
global ghostScoreTimer                as integer                      // how long to hold the score on-screen, and the game paused
global bonusFruitTimer                as integer                      // when to spawn bonus fruit
global bonusScoreTimer                as integer                      // how long to hold the bonus score on-screen
global effectsTimer                   as integer                      // how often the effects should update

// Times used for event timings (used on timers)
#constant TIME_WAIT_FOR_LIGHTS        = 1.0                           // seconds
#constant TIME_WAIT_FOR_DEMO          = 2.0                           // How long to hold starrting mr pac-man
#constant TIME_DEMO_DURATION          = 20.0                          // How long a demo play cycle lasts
#constant WAIT_FOR_CONVULTIONS        = 1.0
#constant TIME_WAIT_FOR_GAME_OVER     = 2.0
#constant TIME_WAIT_FOR_LIFE_POP      = 1.0
#constant TIME_WAIT_FOR_READY         = 1.0
#constant TIME_GHOST_END_FLASH        = 2.0
#constant TIME_HOLD_GHOST_SCORE       = 1.0
#constant TIME_HOLD_BONUS_SCORE       = 1.0
#constant TIME_TO_FIRST_FRUIT         = 10.0
#constant TIME_TO_NEXT_FRUIT          = 8.0
#constant TIME_MAZE_FLASH             = 0.1                           // tenth of a second
#constant TIME_TEXT_FLASH             = 0.5                           // 1/2 second
#constant MAZE_FLASH_ITERATIONS       = 1.0/0.1                       // seconds / TIME_MAZE_FLASH = counter

//----------------------------------------------------------------------------
// AI related
#constant AI_HOLDING_DISTANCE         = 16                            // Monsters in holding move this much up and down

// Can pass by reference to return multiple values from a function
type TypeMoveResult
	x# as float
	y# as float
	overflow# as float
endtype

//----------------------------------------------------------------------------
// Timer related (see timer.agc)

// User data that can be stored with timers
type TypeTimerData
    index                             as integer
    userInt1                          as integer
endtype

//----------------------------------------------------------------------------
// The actual timer "class"
type TypeTimer
    ID                                as integer
    timerFlag                         as integer
    time                              as float
    setTime                           as float
    fire                              as integer
    timerData                         as TypeTimerData
endType

//----------------------------------------------------------------------------
// Flags that govern timer behaviour
#constant TIMER_FLAG_DESTROY          = 0
#constant TIMER_FLAG_WRAP             = 1

//----------------------------------------------------------------------------
// The GLOBAL list of timers and a variable that keeps timers unique
global gameTimerNextID                as integer
global gameTimers                     as TypeTimer[]
gameTimerNextID                       = 1                             // 0 is reserved for inactive timer handles

//----------------------------------------------------------------------------
// Level related
#constant LEVEL_CLOSED                = 0                             // wall areas = 0, walkable areas marked with 1+

// lookup for the direction that's to the left, right or opposite of the index'd direction
global directionLeft                  as integer[4]
global directionRight                 as integer[4]
global directionOpposite              as integer[4]
directionLeft                         = [DIRECTION_LEFT , DIRECTION_UP  , DIRECTION_RIGHT, DIRECTION_DOWN, DIRECTION_NONE ]
directionRight                        = [DIRECTION_RIGHT, DIRECTION_DOWN, DIRECTION_LEFT , DIRECTION_UP, DIRECTION_NONE   ]
directionOpposite                     = [DIRECTION_DOWN , DIRECTION_LEFT, DIRECTION_UP   , DIRECTION_RIGHT, DIRECTION_NONE]

// look up, by direction how X or Y changed to travel in that direction
global gridStepX                      as integer[4]
global gridStepY                      as integer[4]
gridStepX                             = [  0,  1,  0, -1,  0]
gridStepY                             = [ -1,  0,  1,  0,  0]

// track the path of the bonus fruit
type TypePoint2d
	x                                 as integer 
	y                                 as integer
endtype

// Helper arrays for fruit marching across screen - driven from the level data
global bonusPath                      as TypePoint2d[]                // The points the fruit will pass through
global doorPositions                  as TypePoint2d[]                // Where the fruit starts and ends
global preExit                        as TypePoint2d[]                // Each door has a "helper" node that helps the fruit find the door

//----------------------------------------------------------------------------
// Resolution and framerate related
#constant SCREEN_X_COLS               = 28                            // the screen has 28 cols of MAZE_CELL_DIMENSIONS pixels wide
#constant SCREEN_Y_ROWS               = 38                            // the screen has 36 rows of MAZE_CELL_DIMENSIONS pixels high
#constant DESIRED_FPS                 = 60                            // passed to SetSyncRate in mainInitialize

//----------------------------------------------------------------------------
// Effects related

// Struct that holds effects parameters - Only effect in this game is the pulsing power pills
type TypeEffect
	isa                               as integer                      // What type of effect
	one#                              as float                        // 1st bookend value
	two#                              as float                        // 2nd bookend value
	dir                               as integer                      // ping-pong direction
	spr                               as integer                      // the sprite the effect is acting on
endtype

// List of all running effects
global effects                        as TypeEffect[]

// Effect (isa) types that are supported
#constant EFFECT_TYPE_PULSE           = 0                             // Ping-Pong the size between one# and two#

//----------------------------------------------------------------------------
// Input related
global desiredDirection               as integer                      // the direction the user wants to move
// These values should all come from a Joystick Config screen which does not exist
global joyStick                       as integer                      // when non-zero, a joystic was found
#constant JOYSTICK_DZ                 = 0.5                           // The joystick dead zone
#constant JOY_COIN_BUTTON             = 8                             // Button # on joystic to add a coing
#constant JOY_START_BUTTON            = 7                             // Button # on joystic to start the game
#constant JOY_DIGITAL_UP              = 14                            // Digital button movement (d-pad)
#constant JOY_DIGITAL_RIGHT           = 15                            // Digital button movement (d-pad)
#constant JOY_DIGITAL_DOWN            = 16                            // Digital button movement (d-pad)
#constant JOY_DIGITAL_LEFT            = 13                            // Digital button movement (d-pad)

// SQW - for debugging only - Press F1 to see where monsters are targeting
global showTargetSprites              as integer = 0
global targetSprites                  as integer[NUM_CHARACTERS]
for i = CHARACTER_PACMAN to CHARACTER_BONUS
	targetSprites[i] = CreateSprite(0)
	// SetSpriteOffset(targetSprites[i], 5, 5)
	SetSpriteColor(targetSprites[i],
		GetColorRed(characterColours[i]),
		GetColorGreen(characterColours[i]),
		GetColorBlue(characterColours[i]),
		GetColorAlpha(characterColours[i]))
	SetSpriteVisible(targetSprites[i], showTargetSprites)
next i 
