# GiuiceHunterPets

## Overview

GiuiceHunterPets is a World of Warcraft addon that lists all hunter pets in a custom frame. It provides a simple interface to view your hunter pets and their details, such as name, level, and active status. Additionally, it includes functionality to list all battle pets.

## Features

- Displays a list of all hunter pets with their name, level, and active status.
- Displays a list of all battle pets with their name and level.
- Customizable frame with scroll functionality.
- Toggle the pet list frame with a slash command.

## Installation

1. Download the addon files.
2. Extract the files to your World of Warcraft AddOns directory: World of Warcraft/retail/Interface/AddOns/GiuiceHunterPets/
3. Restart World of Warcraft or reload the UI.

## Usage

- To toggle the hunter pet list frame, use the slash command: /hunterpets
- To toggle the battle pet list frame, use the slash command: /petlist

## Files

- `GiuiceHunterPets.lua`: Main Lua file for the hunter pets functionality.
- `GiuiceBattlePets.lua`: Lua file for the battle pets functionality.
- `GiuiceHunterPets.toc`: Table of contents file for the addon.
- `libs/`: Directory containing required libraries.

## Dependencies

- AceGUI-3.0
- LibSharedMedia-3.0

## Code Structure

### GiuiceHunterPets.lua

- Creates the main frame for displaying hunter pets.
- Defines the `ListHunterPets` function to list all hunter pets.
- Sets up the slash command `/hunterpets` to toggle the hunter pet list frame.

### GiuiceBattlePets.lua

- Creates the main frame for displaying battle pets.
- Defines the `ListAllPets` function to list all battle pets.
- Sets up the slash command `/petlist` to toggle the battle pet list frame.

### GiuiceHunterPets.toc

- Specifies metadata for the addon.
- Lists the Lua files and dependencies required by the addon.

## License

This project is licensed under the MIT License. See the [LICENSE.txt](libs/LICENSE.txt) file for details.

## Author

Giuliano Lemes @giuice@gmail.com

## Notes

- Ensure that the `Interface` version in the `.toc` file matches the current WoW version.
- Customize the frame size and position as needed.
git