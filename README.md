<a name="readme-top"></a>

<div align="center">
  <a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3365382068">
    <img src="https://github.com/user-attachments/assets/71ce18d0-aab0-4ed1-8047-4b99a6bb56e4" alt="Logo" width="30%">
  </a>
  <h3 align="center">Project X.E.N.O.</h3>
  <p align="center">
    A traitor weapon for the popular game mode TTT in Garry's Mod.
    <br />
    <br />
    <a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3365382068">View Steam Workshop</a>
    ·
    <a href="https://github.com/dennisabrams/xeno/issues">Report Bug</a>
    ·
    <a href="https://github.com/dennisabrams/xeno/issues">Request Feature</a>
  </p>
</div>

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#introduction">Introduction</a></li>
    <li><a href="#features">Features</a></li>
    <li><a href="#program-explanation">Program Explanation</a></li>
    <li><a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#convars">ConVars</a></li>
    <li><a href="#development">Development</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

## Introduction

![xeno](https://github.com/user-attachments/assets/59a97235-a228-4525-81b3-ef6d9244f428)

**Project X.E.N.O** is a custom weapon addon for Trouble in Terrorist Town (TTT) in Garry's Mod. It allows Traitors to summon a mutated Combine Dropship, codenamed **"X.E.N.O"** (Xtreme Explosive Neutralization Organism), which targets and follows the nearest Innocent player while dropping grenades to create chaos. Designed in a modular way, this weapon offers great flexibility for server admins to configure the difficulty and impact of X.E.N.O.

## Features
- Summons a custom Combine Dropship to target Innocent players.
- Drops grenades autonomously, creating a dynamic gameplay experience.
- Fully configurable using server ConVars for custom balancing.
- Modular Lua script structure for easy customization and extension.

## Program Explanation

The **Project X.E.N.O** weapon is fully scripted in Lua and integrates seamlessly into the TTT game mode. Upon activation, a mutated Combine Dropship is summoned, autonomously following Innocent players while dropping grenades. Server admins can use the provided ConVars to tune gameplay balance, such as adjusting health, active duration, and grenade damage.

![bild6-min](https://github.com/user-attachments/assets/56a336b0-36b2-4760-bbb3-d514737e904f)

## Getting Started

### Prerequisites
- Garry's Mod
- Trouble in Terrorist Town (TTT) game mode

### Installation
1. Clone or download the repository to your Garry's Mod server:
   ```bash
   git clone https://github.com/dennisabrams/xeno xeno
   ```
2. Place the **"xeno"** folder in the following path:
   ```
   garrysmod/addons/xeno
   ```
3. Restart your server for the addon to load.

## Usage

In TTT mode, Traitors can purchase the **Project X.E.N.O** weapon from the Traitor shop. After throwing the activation core, the dropship will be summoned and will follow the nearest Innocent player, dropping grenades in its path.

## ConVars

Below is a list of server-side ConVars that can be used to customize the behavior of **Project X.E.N.O**. These can be configured in your server's configuration file.

| ConVar                       | Default Value | Description                                        |
|------------------------------|---------------|----------------------------------------------------|
| `ttt_xeno_announce_target`   | 0             | Set to 1 to announce the target in chat, 0 to keep silent. |
| `ttt_xeno_health`            | 800           | The health of X.E.N.O.                             |
| `ttt_xeno_duration`          | 45            | How long X.E.N.O. stays active (in seconds).       |
| `ttt_xeno_spawndamage`       | 100           | Damage dealt by X.E.N.O upon spawning.             |
| `ttt_xeno_deathdamage`       | 50            | Damage dealt by X.E.N.O upon death.                |
| `ttt_xeno_grenade_damage`    | 70            | Explosion damage of grenades dropped by X.E.N.O.   |
| `ttt_xeno_grenade_interval_min` | 0.1       | Minimum interval for dropping grenades (in seconds).|
| `ttt_xeno_grenade_interval_max` | 0.8       | Maximum interval for dropping grenades (in seconds).|

Feel free to adjust these settings in your server configuration to match your play style. Whether you want X.E.N.O. to be a durable menace or a fleeting surprise, these ConVars give you full control.

![xeno2](https://github.com/user-attachments/assets/b07ae6f0-1417-452b-87c7-65ab3bcf87ea)

## Development


The project includes several Lua files:

- **init.lua**: Main weapon initialization file.
- **config/settings.lua**: Contains the weapon settings (e.g., name, model, etc.).
- **modules/**: Holds the separate logic files.
  - **core_logic.lua**: Spawm functionality.
  - **bomber.lua**: Handles the dropship's behavior.
  - **grenade_logic.lua**: Handles grenade dropping mechanics.

Feel free to contribute or fork this project. PRs are always welcome.

![xeno3](https://github.com/user-attachments/assets/0a386314-fa13-4fa3-8567-7eb8fa9216a6)

## License

Distributed under the MIT License. See [`LICENSE`](https://github.com/dennisabrams/xeno/blob/main/LICENSE)  for more information.

## Contact

Dennis Abrams - [hello@dennis-abrams.com](mailto:contact@dennis-abrams.com)

**Project Link**: [https://github.com/dennisabrams/xeno](https://github.com/dennisabrams/xeno)

<p align="right"><a href="#readme-top">back to top ⬆</a></p>
