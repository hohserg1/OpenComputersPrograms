# PlayerMonitoring
This is a distributed system program for logging of player visiting

Supported Computronics Radar and OpenSecurity Entity Detector

## Setup guide
1. Install HoverHelm
2. Setup device for radar
    + Device hardware must contains CPU, Memory 1.5 tier, Internet card, prepared EEPROM, any amount of `Radar`-s and `Entity Detector`-s
    + Download `radar.lua` to `/home/hoverhelm/devices/<RADAR DEVICE NAME>/programs/`
        * Open rserver.lua for edit
        * Create new secret gist and insert gist id to radar.lua configuration section
        * Create new OAuth token and insert to radar.lua configuration section
            - Visit https://github.com/settings/tokens
            - Press [Generate new token]
            - Turn off all options
            - Turn on "gist" option 
![help](https://github.com/hohserg1/OpenComputersPrograms/blob/master/player-monitoring/help1.png?raw=true)
            - Press [Generate token]
![help](https://github.com/hohserg1/OpenComputersPrograms/blob/master/player-monitoring/help2.png?raw=true)
        * Configure other options of rserver.lua
        
    + Copy `/lib/config.lua` from device_core to device folders of all radar devices
    + Configure autorun to `radar`
