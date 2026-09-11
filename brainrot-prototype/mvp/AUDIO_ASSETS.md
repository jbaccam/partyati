# Fighter audio sources

Selected from the free Roblox Creator Store **ProSoundEffects** publisher on 2026-09-10. Search result descriptions explicitly identify these as sound effects courtesy of Pro Sound Effects. They are referenced in Roblox through their asset IDs; no audio files were downloaded, copied, or redistributed. Creator Store availability is not a license for use outside Roblox.

| ID / source | Recording | Use |
| --- | --- | --- |
| [9120972321](https://create.roblox.com/store/asset/9120972321) | Wood Whoosh Slicing Air Quick Swings 4; 0.8 s | Attack swish variation |
| [9120972444](https://create.roblox.com/store/asset/9120972444) | Wood Whoosh Slicing Air Quick Swings 1; 0.8 s | Attack swish variation |
| [9126047777](https://create.roblox.com/store/asset/9126047777) | Synth Air Whoosh Cheesy Karate Style Swishes; 0.3 s | Jump / air jump / launch |
| [9120888980](https://create.roblox.com/store/asset/9120888980) | Wood Hits Board Impacts On Fence Post 7; 0.6 s | Wooden strike / drum beat |
| [9126267420](https://create.roblox.com/store/asset/9126267420) | Wood Hit Giant Wood Beam Dull Thuds Knocks; 0.9 s | Heavy chomp / slam |
| [9120880067](https://create.roblox.com/store/asset/9120880067) | Wood Grab Muted Thuds 15; 1.4 s | Quiet dry foot contact / landing |
| [9119321317](https://create.roblox.com/store/asset/9119321317) | Soccer Ball Kicks Bounces 1; 0.9 s | Rounded body impact |
| [9119236749](https://create.roblox.com/store/asset/9119236749) | Small Explosion 1; 2.9 s | Croc bomb |

All eight IDs passed live Studio client preloading (`IsLoaded=true`) in this place during the implementation check. This verifies access and decoding, not subjective sound quality. No model-side audio audition was available; the user's listening review remains necessary. These replace, rather than re-EQ, the previous bundled Roblox jumping, falling, swimming, footstep, and explosion samples. No unauthorized reuploads or game-ripped sounds from other search results were selected.

CombatAudio limits local simultaneous voices to 24, coalesces same-kind nearby events within 45 ms, and keeps footsteps significantly quieter than impacts. Movement sounds are one-shots measured by distance traveled, not a permanently looping running sound. The default character sound instances are locally muted only while a brainrot is active; their volume is restored on unmorph/cleanup. General UI and menu sounds are untouched.
