# REPO-TODO.md

Short list of things to work on for the game template.

### Todo (Template)

The template will encompass a basic project structure, some bootstrapped Global
management singletons, and basic menu system.

- [ ] Make menu system nicer for panel transitions
- [ ] Handle UI focus / non-mouse navigation
- [ ] Make dropdown directory selection for "Game Scenes" / Templates (Asteroids should be one of these)
- [ ] Make secondary "Game Scene"
- [ ] Fix mini menu options overlay visuals


### Todo (Asteroid)

Asteroids is an example of a game that could exist within godot framework.
It is meant to be a playable example of a contained scene/game environment.

- [ ] add level difficulty / increase with progression
- [ ] bug where player state is stuck in "moving" while respawning
- [ ] Make and hook up Credits panel

### In Progress



### Done ✓

March 2025
- [x] Upgrade to godot 4.4
- [x] Remove initial non-generalized menus and scripts
- [x] Replace hard coded paths with UID refs where appropriate
- [x] Restructure Asteroids into examples folder
- [x] Exit to Desktop Button

February 2025
- [x] Basic scene transition Global
- [x] Audio bus globals
- [x] asteroid base game
  - [x] asteroid generation
  - [x] player instantiation
  - [x] game over state
  - [x] basic collision detection
  - [x] pause menu
  - [x] screen wrapping for ship and asteroids
  - [x] bullet firing and detection and garbage collection
- [x] Create Options menu
  - [x] Add master audio bus volume level control to options page
  - [x] Add sfx audio bus volume level control to options page
  - [x] Add music audio bus volume level control to options page
- [x] handle score appropriately
- [x] add level completion state
- [x] make nicer looking (slightly)
- [x] handle player death better
  - [x] added respawn hitbox, will not allow respawn with asteroids actively in area to prevent respawn deaths
- [x] Update credits (added back button)
