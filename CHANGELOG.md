# Battleground Win Conditions

## [v9.6.11](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v9.6.11) (2024-08-10)

- NEW Temple of Kotmogu feature that shows available orbs, and when an orb is taken it shows the damage taken increase percentage for that orb carrier
  - This new feature can be toggled on/off in the settings
- Lots of performance enhancements that aims to reduce and reuse duplicate code in loops and aura checking into helper functions
- All new Battleground Blitz support for the following maps with EXISTING features:
  - The Battle for Gilneas
  - Twin Peaks
  - Warsong Gulch
- Updates the default font-size to 14
- Prep work to add support for Battleground Blitz for the remaining maps
- Minor cleanup and fixes

## [v9.5.10](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v9.5.10) (2024-08-01)

- Lib updates
- TOC updates
- Refactor of the Win Conditions algorithm and incoming base info to be fully tick based and not time based which has TIE game implications and should provide more accurate results
- Updating the placeholder text win condition info
- Adds check upon joining game to ensure you're not in an 8v8 blitz mode game since that will have its own code and or addon
- Simplifying win/lose text on banner upon timer expiring
- Adding various win condition text info to help the user know in tricky situations what the loser wins with or not
- Adding simplified lose text upon timer expiring
- Refactor win condition table to only grab first win condition for performance reasons since bases can change all the time we don't need to process and store all future conditions if they never get used for the most part
- Triggering win condition prediction upon first win condition timer expiring based on new refactor
- Fixing flag map stack issues resetting after dropping then someone else picking up while stacks are counting
- Moving all flag stack logic to pvp channel messages instead of arena updates apis for consistency and reliability

## [v9.4.22](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v9.4.22) (2024-05-12)

- Fixing text anchor from not being set correctly after Temple of Kotmogu

## [v9.4.21](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v9.4.21) (2024-05-08)

- Added a new setting to be able to add a background to the info text
- Added a new setting to be able to change the info text color
- Added a new setting to be able to turn off Temple orb buff text
- Added a new setting to be able to turn off flag map info on EOTS
- Updated setting descriptions
- Fixed various bugs with turning off and on settings and combinations of settings to hide/show properly
- Fixing 10.2.7 bugs for incorrect setting of text justification
- Updated some file names to better match their usage
- Update toc

## [v9.3.21](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v9.3.21) (2024-04-18)

- Fixes incorrect stack syncing on flag maps
  - Removes the arena opponent api checks as they're unreliable and fire at times not just when someone picks
  - Fixes resetting the stack timer if the flag drops and someone else picks
  - Better ensures you're only tracking flag carriers and resetting only when needed
  - Falls back to timer based stacks when dead since UNIT_AURA doesn't track enemies while dead
- Adjusts the time to win on base maps when capping the first base or just a single base in general, time is now banner win time
- Enables the debuff info on flag map info incase people haven't seen that option yet

## [v9.3.20](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v9.3.20) (2024-04-07)

- Fixing slash commands
- Removing flag cap maximum stacks since there is no more limit from what i found in recent testing
- Removing the need for points on the board to see if you win or not in base maps, so now you can know immediately upon first cap
- Fixing incorrect stack resetting based on arena frame updates since it's not reliable and has the ability to mess with stack counts

## [v9.3.19](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v9.3.19) (2024-01-29)

- Fixing eots flags needed calculation when ahead in points and bases
- adding updated descriptions for individual map enabling toggles
- always clearing interface upon joining new games
- updating banner scale minimum

## [v9.3.18](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v9.3.18) (2024-01-29)

- Adding a new setting to turn off the GG Banner and only show the win text
- Updated some setting descriptions and labels
- Updating the minimums for banner scale and font size

## [v9.3.17](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v9.3.17) (2024-01-28)

- Fixing setting some vars once joining a game

## [v9.3.16](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v9.3.16) (2024-01-28)

- Complete overhaul of the settings options to include
  - Choosing your font size
  - Banner Scaling
  - Banner colors for TIE, WIN, LOSE
  - Font for TIE, WIN, LOSE
  - Enable or Disable by Map
  - Enable or Disable certain features on EOTS and Flag maps
- NEW flag map features
  - Shows a Next stack timer
  - Shows how many stacks are currently applied
  - Shows timer to 6 stacks
  - Shows healing received reduction %
  - Shows damage taken increase %
- NEW refactored EOTS flag text
  - Instead of showing the point value of a flag i now show how many flags you are either ahead or behind by so you know an additional win condition
- Refactored the win algorithm to be TICK based instead of TIME based to more accurately detect TIE games
- Performance improvements
- Win Timer bug fixes during incoming bases
- Complete refactor of the code setup and organization
- Move objective type code to only run based on maps that need that code to increase performance
- Adds AceConfig for new dialog support making it easier to add settings

## [v8.2.15](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.2.15) (2024-01-10)

- fixing bugs on eots

## [v8.2.14](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.2.14) (2024-01-10)

- refactoring the predictor code to be its own function so it can be called on base update events and not just score updates
- removing old unused code for cleanup
- fixing a drag issue upon locking

## [v8.1.13](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.1.13) (2024-01-05)

- fixing potential win time algorithm

## [v8.1.12](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.1.12) (2024-01-02)

- refactor update check to fix an issue where the it wasn't properly getting the the correct incoming base counts

## [v8.1.11](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.1.11) (2024-01-01)

- updating implementation of new version handling
- main file event re-order to remove hoisting
- win info variable cleanup
- update slash commands to all be toggle based

## [v8.1.10](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.1.10) (2023-12-30)

- fixing a bug where the enemy base timer wasn't getting reset when you got a base back them before it finished capping or if you stole a base from them mid-cap

## [v8.1.9](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.1.9) (2023-12-30)

- fixing TIE game support
- making sure you cant click the anchor when its set to hidden while locked
- adding all new slash commands (see description for info)
- major code cleanup on code warnings to make things as clean and performant as possible
- refactoring some of the algorithm based on recent testing and bugs found to reduce code and sync mid-cap to end of cap data
- refactoring the all of the event for base tracking, flag tracking, and score tracking to use a single event UPDATE_UI_WIDGET
- added new support for mid-game loading where i make an initial call to get active bases by mapID instead of widgetID
- fixed a bug related to the algorithm to ensure the correct minimum bases you need to hold
- fixed missing variable assignments in the score trigger checks
- clearing the interface upon joining any pvp game in order to hide it on maps that aren't yet supported or in arena
- removed unused code and some remnants of the old ways of getting bases and handling bars
- adding foundational code for silvershard mines, warsong gulch, and twin peaks
- update to mod events in the new cleanup
- making some remaining static strings config variables to be fully dynamic

## [v8.0.8](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.0.8) (2023-12-18)

- adding support for TIE games
- adding WoW Interface project ID
- update the user experience for the anchor

## [v8.0.7](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.0.7) (2023-12-17)

- providing an option to be able to only show the win banner if desired
- abstracting out all global functions and utils possible to local vars for performance

## [v8.0.6](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.0.6) (2023-12-16)

- making sure future need info during an assault matches what you need after the bases cap over and become owned

## [v8.0.5](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.0.5) (2023-12-16)

- removing the check for if you're in a random eots game as it produced incorrect results, and realistically we dont need to exclude eots from incoming base code because there will never trigger an incoming base on eots as that mechanism doesn't exist there, and on rated eots we always want the normal code anyways so its a win win to just remove the extra logic

## [v8.0.4](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.0.4) (2023-12-15)

- resetting game info when leaving battleground
- update the user experience for the anchor

## [v8.0.3](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.0.3) (2023-12-12)

- update toc

## [v8.0.2](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.0.2) (2023-12-12)

- fixing orb buff timer team name color

## [v8.0.1](https://github.com/rbgdevx/battleground-win-conditions/releases/tag/v8.0.1) (2023-12-12)

- addon uploaded to github + curseforge

## [v7.6.19](https://wago.io/T4RgFidZB/7.6.19) (2023-12-11)

- updates to timers and win condition logic

## [v7.5.18](https://wago.io/T4RgFidZB/7.5.18) (2023-11-13)

- removing support for blitz bgs (for now)

## [v7.5.17](https://wago.io/T4RgFidZB/7.5.17) (2023-11-12)

- fixing low timer bug

## [v7.5.16](https://wago.io/T4RgFidZB/7.5.16) (2023-11-10)

- fixing eots bug

## [v7.5.15](https://wago.io/T4RgFidZB/7.5.15) (2023-11-09)

- fixing final score

## [v7.5.14](https://wago.io/T4RgFidZB/7.5.14) (2023-11-06)

- handles updates on incoming bases explicitly now as well

## [v7.5.13](https://wago.io/T4RgFidZB/7.5.13) (2023-11-05)

- major bugfixes

## [v7.4.12](https://wago.io/T4RgFidZB/7.4.12) (2023-10-31)

- minor bugfixes

## [v7.4.11](https://wago.io/T4RgFidZB/7.4.11) (2023-10-31)

- removing time cap in win con

## [v7.4.10](https://wago.io/T4RgFidZB/7.4.10) (2023-10-31)

- fixing broken zone conditions

## [v7.4.9](https://wago.io/T4RgFidZB/7.4.9) (2023-10-30)

- fixing errors from variable being passed with current time

## [v7.4.8](https://wago.io/T4RgFidZB/7.4.8) (2023-10-30)

- removing prints logging messages

## [v7.4.7](https://wago.io/T4RgFidZB/7.4.7) (2023-10-30)

- timing bug fixes

## [v7.3.6](https://wago.io/T4RgFidZB/7.3.6) (2023-10-09)

- bug fixes

## [v7.2.5](https://wago.io/T4RgFidZB/7.2.5) (2023-09-23)

- big bugfix on some future math type shit

## [v7.1.4](https://wago.io/T4RgFidZB/7.1.4) (2023-09-22)

- making sure the future win time includes incoming base win time increase so it reflects accurately and doesn't mess up other math + visuals

## [v7.0.3](https://wago.io/T4RgFidZB/7.0.3) (2023-09-05)

- removed print

## [v7.0.2](https://wago.io/T4RgFidZB/7.0.2) (2023-09-05)

- meta info updates

## [v7.0.1](https://wago.io/T4RgFidZB/7.0.1) (2023-09-05)

- complete re-write from the ground up
  - foundational code that detects when to run the code again
  - new trigger to run code off of
  - closely follows capping addon methodology for familiarity and accuracy
  - future score calculations based off of time instead of score
  - conditional rendering in message display for much greater clarity on win condition
- separate and NEW win timer bar that very clearly indicates if you win or lose and when
- NEW temple of kotmogu 4 orb buff timer and text
- accurate times and info on EOTS as the new foundational code updates with flag captures

## [v6.0.8](https://wago.io/T4RgFidZB/6.0.8) (2023-08-23)

- removing eots check since this version shouldnt have it right now

## [v6.0.7](https://wago.io/T4RgFidZB/6.0.7) (2023-08-06)

- updating load zone ids

## [v6.0.6](https://wago.io/T4RgFidZB/6.0.6) (2023-08-06)

- removing extra function

## [v6.0.5](https://wago.io/T4RgFidZB/6.0.5) (2023-08-06)

- fixing remaining lua check warnings

## [v6.0.4](https://wago.io/T4RgFidZB/6.0.4) (2023-08-06)

- updating some global usages

## [v6.0.3](https://wago.io/T4RgFidZB/6.0.3) (2023-08-06)

- fixing 1 lua check

## [v6.0.2](https://wago.io/T4RgFidZB/6.0.2) (2023-08-06)

- removing extra variable from display

## [v6.0.1](https://wago.io/T4RgFidZB/6.0.1) (2023-08-06)

- timer overhaul to show real time updates (every second)
- fixes various bugs
- bases the conditions off of CURRENT game ONLY like how capping does
- performance improvements
- updates trigger/untrigger and variable usage

## [v5.1.25](https://wago.io/T4RgFidZB/5.1.25) (2023-07-09)

- fixing movability

## [v5.1.24](https://wago.io/T4RgFidZB/5.1.24) (2023-07-09)

- making moveable

## [v5.1.23](https://wago.io/T4RgFidZB/5.1.23) (2023-07-09)

- fixes cache clearing between bgs
- removes eots logging

## [v5.1.22](https://wago.io/T4RgFidZB/5.1.22) (2023-06-22)

- handling for nil lose min base count

## [v5.1.21](https://wago.io/T4RgFidZB/5.1.21) (2023-06-22)

- N/A

## [v5.1.20](https://wago.io/T4RgFidZB/5.1.20) (2023-06-22)

- fixes resetting data after each game ends

## [v5.1.19](https://wago.io/T4RgFidZB/5.1.19) (2023-06-19)

- adding options defaults back in, for outside of game only

## [v5.1.18](https://wago.io/T4RgFidZB/5.1.18) (2023-06-18)

- minor updates

## [v5.1.17](https://wago.io/T4RgFidZB/5.1.17) (2023-06-18)

- removing prints

## [v5.1.16](https://wago.io/T4RgFidZB/5.1.16) (2023-06-18)

- removing print

## [v5.1.15](https://wago.io/T4RgFidZB/5.1.15) (2023-06-18)

- code cleanup
- performance updates
- removing the options feature for now as i ran into a bug on repeat maps

## [v5.1.14](https://wago.io/T4RgFidZB/5.1.14) (2023-06-18)

- cleanup

## [v5.1.13](https://wago.io/T4RgFidZB/5.1.13) (2023-06-18)

- minor updates

## [v5.1.12](https://wago.io/T4RgFidZB/5.1.12) (2023-06-17)

- adding arathi basin comp stomp support
- fixing some ids in the env vars

## [v5.1.11](https://wago.io/T4RgFidZB/5.1.11) (2023-06-11)

- removing remaining cap time text from random bg eots

## [v5.1.10](https://wago.io/T4RgFidZB/5.1.10) (2023-06-09)

- fixing current zone setting code

## [v5.1.9](https://wago.io/T4RgFidZB/5.1.9) (2023-06-08)

- update current zone with multiple events

## [v5.1.8](https://wago.io/T4RgFidZB/5.1.8) (2023-06-07)

- fixing the lose/win "You" "They" text setting

## [v5.1.7](https://wago.io/T4RgFidZB/5.1.7) (2023-06-04)

- event updates

## [v5.1.6](https://wago.io/T4RgFidZB/5.1.6) (2023-06-04)

- minor update

## [v5.1.5](https://wago.io/T4RgFidZB/5.1.5) (2023-06-04)

- minor update

## [v5.1.4](https://wago.io/T4RgFidZB/5.1.4) (2023-06-04)

- adding new starter trigger event

## [v5.1.3](https://wago.io/T4RgFidZB/5.1.3) (2023-06-04)

- major performance updates
- handles entering and exiting battlegrounds
- fixes setting of you/they wording

## [v5.0.2](https://wago.io/T4RgFidZB/5.0.2) (2023-06-02)

- full re-write to consolidate it all into a single aura and change variables based on zoneID
- made the messaging more clear as it relates to what you need to win
- added a new line of text that coincides with the messaging clarity

## [v4.1.2](https://wago.io/T4RgFidZB/4.1.2) (2023-05-28)

- function cleanup
- var updates
- make min lose score and time the same, both are tied to owned bases not included bases but then updates once caps over to reflect live needs

## [v4.1.1](https://wago.io/T4RgFidZB/4.1.1) (2023-05-28)

- Added support for Eye of the Storm
- cleaned up unused vars
- formatting cleanup
- added new event trigger "BATTLEGROUND_OBJECTIVES_UPDATE"
- moved max bases and zone id vars to each maps group section

## [v4.0.3](https://wago.io/T4RgFidZB/4.0.3) (2023-05-27)

- fixes battle for gilneas
- moves max bases to grouped by areas by map

## [v4.0.2](https://wago.io/T4RgFidZB/4.0.2) (2023-05-26)

- updating ceils and floors

## [v4.0.1](https://wago.io/T4RgFidZB/4.0.1) (2023-05-26)

- Maintaining a separate amount of owned based vs incoming bases
- final score, and min bases to win for both teams are based on owned and incoming bases combined now
- needed by score and needed by time are based on only owned bases for stability since points accrued are only coming from owned so the math doesn't math if we include incoming and it feels broken as needed score goes up until it caps over
- provides stable winning defaults, max wins with base count to max base count
- and some additional failure checks

## [v3.0.2](https://wago.io/T4RgFidZB/3.0.2) (2023-05-23)

- moving winning time placement
- adding time to default ui

## [v3.0.1](https://wago.io/T4RgFidZB/3.0.1) (2023-05-23)

- Switching to only count owned bases as that feels the most stable for now, might re-visit assaulted in the future

## [v2.0.5](https://wago.io/T4RgFidZB/2.0.5) (2023-05-20)

- Fixing the ability to be able to move everything
- Setting defaults for out of game

## [v2.0.4](https://wago.io/T4RgFidZB/2.0.4) (2023-05-20)

- Fixes the winning and losing team names

## [v2.0.3](https://wago.io/T4RgFidZB/2.0.3) (2023-05-20)

- Fixes the winning and losing team names

## [v2.0.2](https://wago.io/T4RgFidZB/2.0.2) (2023-05-20)

- Fixes the winning and losing team names

## [v2.0.1](https://wago.io/T4RgFidZB/2.0.1) (2023-05-20)

- event refactor
- refactor: moves area information to only be updated on "AREA_POIS_UPDATED"
- refactor: moves all base and score updates to only be updated on "BATTLEGROUND_POINTS_UPDATE" and "UPDATE_UI_WIDGET", these events are also where the time is being set in the display
- refactor: moves the final score, min lose/win team bases needed and lose team score needed to only be updated on "CHAT_MSG_BG_SYSTEM_HORDE" and "CHAT_MSG_BG_SYSTEM_ALLIANCE"
- leverages built in apis to get base count by team in a much simpler and more dynamic way

## [v1.0.6](https://wago.io/T4RgFidZB/1.0.6) (2023-05-17)

- adding tick rate as a custom variable to be managed outside of the main reused code

## [v1.0.5](https://wago.io/T4RgFidZB/1.0.5) (2023-05-17)

- Fixing Gilneas

## [v1.0.4](https://wago.io/T4RgFidZB/1.0.4) (2023-05-17)

- Making it so nothing happens until after points start accumulating

## [v1.0.3](https://wago.io/T4RgFidZB/1.0.3) (2023-05-17)

- adding support for Deepwind Gorge and Battle for Gilneas

## [v1.0.2](https://wago.io/T4RgFidZB/1.0.2) (2023-05-17)

- Fixing final score losing team when getting 5 capped on but has points

## [v1.0.1](https://wago.io/T4RgFidZB/1.0.1) (2023-05-17)

- making sure final score is right

## [v1.0.0](https://wago.io/T4RgFidZB/1.0.0) (2023-05-17)

- N/A
