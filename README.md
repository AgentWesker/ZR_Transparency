# ZR_Transparency
Humans in close proximity become transparent
<br><br>
## Convars:
```
sm_transparency_distance
Default value "200.0"
Description - Distance within which the player is made transparent
```

**Further Details:** <br>
Zombies will immediately become visible upon infection, and remain fully opaque. Humans will only be checked when they send any kind of input, there are no timers in this plugin. There is an optimization delay of 1 second between checks (between opaque players) and 3 seconds (between transparent players). This places a priority on checking visible (opaque) players, while letting transparent players roam for some time before resetting them.
