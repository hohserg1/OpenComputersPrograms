# Player Monitoring
This is a distributed system program for logging of player visiting
Supported Computronics Radar and OpenSecurity Entity Detector
## Setup guide
1. Install HoverHelm
2. Setup devices for regular radars
  1) Device hardware must contains CPU, Memory 1.5 tier, Wireless(or wired) network card 2 tier, prepared EEPROM, any amount of `Radar`-s and `Entity Detector`-s
  2) Download `radar-client.lua` to `/home/hoverhelm/device_core/programs/`
  3) Copy `/lib/config.lua` from device_core to device folders of all radar devices
  4) Configure autorun to `radar-client`
3. Setup device for radar server
  1) Device hardware must contains CPU, Memory 1 tier x2, Wireless(or wired) network card 2 tier, prepared EEPROM, GPU, Screen, one `Entity Detector`
  2) Download `rserver.lua` to `/home/hoverhelm/devices/<RADAR SERVER DEVICE NAME>/programs/`
    1) Open rserver.lua for edit
    2) Create new secret gist and insert gist id to rserver.lua configuration section
    3) Create new OAuth token and insert to rserver.lua configuration section
      1. Visit https://github.com/settings/tokens
      2. Press [Generate new token]
      3. Turn off all options
      4. Turn on "gist" option 
     ![help](https://github.com/hohserg1/OpenComputersPrograms/blob/master/player-monitoring/help1.png?raw=true)
      5. Press [Generate token]
     ![help](https://github.com/hohserg1/OpenComputersPrograms/blob/master/player-monitoring/help2.png?raw=true)
    4) Configure other options of rserver.lua
  3) Copy `/lib/config.lua` from device_core to radar server folder
  4) Configure autorun to `rserver`
