# GiuiceHunterPets

## Overview

GiuiceHunterPets is a World of Warcraft addon that lists all hunter pets in a custom frame. It provides a simple interface to view your hunter pets and their details, such as name, level, and active status. Additionally, it includes functionality to list all battle pets.

## Features

- Displays a list of all hunter pets with their name, level, and active status.
- ~~Displays a list of all battle pets with their name and level.~~ (not implemented yet maybe in future versions)
- Customizable frame with scroll functionality.
- Minimap button to open/close the petlist window.

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
- `GiuiceHunterPets.xml`: Frames, button templates
- `GiuiceHunterPetListItemMixin.lua`: Scripts for the templates
- `GiuiceTooltipEnhacement.lua`: Show pet info on tooltips, if it's tamable, family exotic...
- `Data.lua`: Some data that helps detecting pets
- `libs/`: Directory containing required libraries.

## Acknowledgments

- **Aspect of the Hunter Addon**: Some data and functionalities are inspired by the [Aspect of the Hunter](https://www.curseforge.com/wow/addons/aspect-of-the-hunter) addon. Special thanks for their valuable contributions to the community.

## Donations

If you find this addon helpful, consider supporting its development:

[![Pay me a Donut!](https://img.shields.io/badge/PayPal-Donate-yellow.svg)](https://www.paypal.com/donate/?hosted_button_id=9HWWVZPE8EKLU)


## Dependencies

- Ace(CallbackHandler, LibDataBroker,LibDBIcon, LibStub)


## License

This project is licensed under the MIT License. See the [LICENSE.txt](libs/LICENSE.txt) file for details.

## Author

Giuliano Lemes @giuice@gmail.com

## Notes

[GitHub](https://github.com/giuice/GiuiceHunterPets)