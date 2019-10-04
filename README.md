# MrPacMan
 Pac Man and Ms Pac Man combo remake in AGK Tier 1 Basic


1. INTRODUCTION


I bought the AppGameKit Studio (Sequel to the AppGameKit) and wanted to try the
built-in level editor.  I wanted to build a maze, so I decided to try and build
the Pac Man level, just to try out the tool.  That led to me making this whole
game.

Mr Pac-Man is not really a remake of Pac Man or Ms Pac Man, but it also is, in
a way.  The game has the Pac Man level, and all the Ms Pac Man levels.  The AI
is close to the Pac Man AI.  The Bonus Fruit is based on the Pac Man fruit but
walks around the way it did in Ms Pac Man.  The timings of AI mode switches are
Pac Man like.  Some things (timings specifically) I just made up.

The levels are configured like this - you play the Pac Man level twice, then
the four Ms Pac Man levels, each twice as well.  The second version of each
level is done in a slightly darker colour than its first occurrence.  After you
have seen all 5 levels, the cycle repeats.  

With every level the game gets faster till it reaches a maximum - 1.5x the
starting speed.  It's currently tuned to be very hard, too hard for me to have
any hope of getting through the later levels. 

There are 8 pieces of bonus "fruit".  Each level introduces a new one.  Once
you have seen all 8, they appear randomly in the level.

Extra lives at 10,000 points, and then every 5,000 points after that.

There's a video of the game on YouTube at https://youtu.be/pFb6vqTuDvM


2. CURRENT STATUS


The game is done - it just has no Audio.  I do all this stuff time-boxed and my
time for this game is now up.  Since I don't know anything about audio, I left
it for the end.  I really did want to try and make audio for this game, but
alas, not happening.  Not now, anyway.  I also didn't make the screen that
appears in Ms Pac Man when you add a credit.


3. KEYS and JOYSTICK


Credits are added with ENTER or the 5 key (5 key is like Mame).  1 player game
starts with the 1 key, and 2 players with the 2 key (again, like Mame).  The
character is controlled using the cursor keys.

A Joystick can be used but is only detected when the game starts.  There's no
Joystick config, so buttons 7 & 8 add credits and start a 1 player game.  The
dead zone is set to 0.5 on the analog stick, so the analog stick needs to be
moved halfway or more to move the character.  The digital (d-pad) buttons are
13, 14, 15 and 16 for left, up, right and down.

All of this was quite arbitrarily chosen, but I used an XBox One controller for
testing.


4. THE FILES


* readme.txt        - This file
* Mr Pac Man.agk    - Project file for App Game Studio
* globals.agc       - Global variables, constants, tunables, etc.  Start here.
* main.agc          - Where the game starts.  Includes all other files
* ui.agc            - The intro screen logic, that presents the characters
* character.agc     - Sets the state (operates on) characters
* play.agc          - The main loop during gameplay and most play logic
* ai.agc            - Subset of play - the user and monster control
* level.agc         - Operates on the levels - colour, dot locations, etc
* input.agc         - Keyboard and Joystick handling
* timer.agc         - Helper class that tracks frame time as countdown timers
* frontend.scene    - Shouldn't exist.  Just the marquee.
* screen1.scene     - Pac Man Level
* screen2.scene     - Ms Pac Man level #1
* screen3.scene     - Ms Pac Man level #2
* screen4.scene     - Ms Pac Man level #3
* screen5.scene     - Ms Pac Man level #4

Methods (functions) in the code are prefixed with the name of the file in which
they reside.  Play, character and ai all contain the code that make the game,
and the delineation between the files isn't clear cut, but I think it worked
out okay.


5. CREDITS


* Pac Man was made by Namco and release in 1980
* Ms Pac Man was made General Computer Corporation, published by Midway and 
released in 1982
* The AppGameKit Studio is made by theGameCreators.  www.thegamecreators.com
* The Pac Man AI is very well explained in "Pac-Man Ghost AI Explained" by 
"Retro Game Mechanics Explained", here https://youtu.be/ataGotQ7ir8
* All the sprites were made in Gimp.  It's pretty good and free :)


6. CONTACT


Feel free to contact me at swessels@email.com if you have thoughts or
suggestions.

Thank you
Stefan Wessels
4 October 2019 - Initial Revision
