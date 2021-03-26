# OreSense
## Overview 
This program allows you to see location of the ore around.
How it works:
A tablet with a geolizer and a network map scans the area around the player and sends information about the found blocks to the stationary computer.
The stationary computer with the OpenGlasses2 terminal and the network map receives information about the blocks and draws highlights to these blocks.

## Features
+ Using methodic of @zgyr which allow to detect ores very exactly
+ Configurable parameters
    * with validation and correction
    * save to file after exit
+ Simple ui
+ Highlight of scaning area
+ Using only two widgets - fps decreaced less
+ For OpenComputers 1.12.2 with OpenGlasses2

## Screenshots
![](https://raw.githubusercontent.com/hohserg1/OpenComputersPrograms/master/oresense/gui-screenshot.png)
![](https://raw.githubusercontent.com/hohserg1/OpenComputersPrograms/master/oresense/2021-03-24_16.30.02.png)
![](https://raw.githubusercontent.com/hohserg1/OpenComputersPrograms/master/oresense/2021-03-24_17.32.42.png)
## Video
[![](http://img.youtube.com/vi/m0JKtMSZ6q8/0.jpg)](http://www.youtube.com/watch?v=m0JKtMSZ6q8 "Video Title")

## Install
Minimal tablet build
![](https://raw.githubusercontent.com/hohserg1/OpenComputersPrograms/master/oresense/min-requirements-tablet.png)

Recomended tablet build
![](https://raw.githubusercontent.com/hohserg1/OpenComputersPrograms/master/oresense/recomended-requirements-tablet.png)

Stationary computer build
![](https://raw.githubusercontent.com/hohserg1/OpenComputersPrograms/master/oresense/min-requirements-server.png)
![](https://raw.githubusercontent.com/hohserg1/OpenComputersPrograms/master/oresense/min-requirements-server-2.png)

## Usage
Connect AR glasses to terminal and equip it.
Run oresense_server
Run oresense_tablet. Blue fieldsis editable. Big red button for start scaning. Do not move throughout of sccaning process.
Look around after scaning - orewill be highlighted by frame cubes.

## Credits
Thx @zgyr and other for article about geolizer principles
Thx @Zer0Galaxy for library forms
Thx @BrightYC for gui review
Thx @Sainthozier for gui review
Thx @Fingercomp for function of indexing coords
Thx peoples fromirc #cc.ru for support with OC andLua

