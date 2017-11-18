# ZR_Transparency
Humans in close proximity become transparent <br>

<br><br>
## Convars:
```
sm_transparency_distance
Default value "100.0"
Description - Distance within which the player is made transparent
```
```
sm_transparency_check
Default value "0.5"
Description - Time (in seconds) between checking opaque player distance
```
```
sm_transparency_undo
Default value "2.0"
Description - Time (in seconds) between checking transparent player distance
```
```
sm_transparency_alpha
Default value "145"
Description - Alpha value for transparency (0 being transparent, 255 being opaque)
```
**Further Details:** <br>
Zombies will immediately become visible upon infection, and remain fully opaque. Humans will only be checked when they send any kind of input, there are no timers in this plugin. There is an optimization delay of 0.5 second between checks (between opaque players) and 2 seconds (between transparent players). This places a priority on checking visible (opaque) players, while letting transparent players roam for some time before resetting them.
