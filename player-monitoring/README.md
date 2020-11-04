# PlayerMonitoring
This is a distributed system program for logging of player visiting

Supported Computronics Radar and OpenSecurity Entity Detector

## Setup guide
1. Install HoverHelm
2. Setup devices for regular radars
    + Device hardware must contains CPU, Memory 1.5 tier, Wireless(or wired) network card 2 tier, prepared EEPROM, any amount of `Radar`-s and `Entity Detector`-s
    + Download `radar-client.lua` to `/home/hoverhelm/device_core/programs/`
    + Copy `/lib/config.lua` from device_core to device folders of all radar devices
    + Configure autorun to `radar-client`
3. Setup device for radar server
    + Device hardware must contains CPU, Memory 1 tier x2, Wireless(or wired) network card 2 tier, prepared EEPROM, GPU, Screen, one `Entity Detector`
    + Download `rserver.lua` to `/home/hoverhelm/devices/<RADAR SERVER DEVICE NAME>/programs/`
        * Open rserver.lua for edit
        * Create new secret gist and insert gist id to rserver.lua configuration section
        * Create new OAuth token and insert to rserver.lua configuration section
            - Visit https://github.com/settings/tokens
            - Press [Generate new token]
            - Turn off all options
            - Turn on "gist" option 
![help](https://github.com/hohserg1/OpenComputersPrograms/blob/master/player-monitoring/help1.png?raw=true)
            - Press [Generate token]
![help](https://github.com/hohserg1/OpenComputersPrograms/blob/master/player-monitoring/help2.png?raw=true)
        * Configure other options of rserver.lua
    + Copy `/lib/config.lua` from device_core to radar server folder
    + Configure autorun to `rserver`
