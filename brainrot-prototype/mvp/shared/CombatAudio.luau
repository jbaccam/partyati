-- Free Creator Store recordings by ProSoundEffects, discovered 2026-09-10.
-- Provenance: AUDIO_ASSETS.md. No default Roblox movement/UI samples.
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local ContentProvider=game:GetService("ContentProvider")
local Audio={}
Audio.Assets=table.freeze({
 SwishA="rbxassetid://9120972321",SwishB="rbxassetid://9120972444",
 Air="rbxassetid://9126047777",Wood="rbxassetid://9120888980",
 Heavy="rbxassetid://9126267420",Step="rbxassetid://9120880067",
 Hit="rbxassetid://9119321317",Blast="rbxassetid://9119236749",
})
local profiles={
 Whoosh={keys={"SwishA","SwishB"},volume=.23,duration=.48,pitch=1.3},
 Hit={keys={"Hit","Wood"},volume=.3,duration=.38,pitch=1.15},
 Bite={keys={"Hit"},volume=.25,duration=.3,pitch=1.1},
 Chomp={keys={"Heavy"},volume=.34,duration=.52,pitch=.9},
 Beat={keys={"Wood","Heavy"},volume=.35,duration=.52,pitch=1},
 Slam={keys={"Heavy"},volume=.42,duration=.62,pitch=.86},
 Blast={keys={"Blast"},volume=.32,duration=1.05,pitch=1.1},
 Launch={keys={"Air"},volume=.24,duration=.3,pitch=.9},
 Splash={keys={"SwishB"},volume=.16,duration=.4,pitch=.9},
 Step={keys={"Step"},volume=.085,duration=.22,pitch=1.25},
 Jump={keys={"Air"},volume=.16,duration=.28,pitch=1.1},
 AirJump={keys={"Air"},volume=.2,duration=.26,pitch=1.25},
 Land={keys={"Step"},volume=.15,duration=.28,pitch=.95},
}
local sequence=0
local active={}
local throttles={}
local function allowed(id)
 for _,asset in Audio.Assets do if asset==id then return true end end
 return false
end
function Audio.PlayRaw(parent,position,id,pitch,volume,options)
 if not parent or not parent.Parent or not allowed(id) then return end
 options=options or {}
 local camera=workspace.CurrentCamera
 if camera and (camera.CFrame.Position-position).Magnitude>85 then return end
 local now=os.clock()
 for i=#active,1,-1 do if not active[i].Parent then table.remove(active,i) end end
 if #active>=24 then active[1]:Destroy();table.remove(active,1) end
 local emitter=Instance.new("Part");emitter.Name="FighterAudioEmitter";emitter.Size=Vector3.one*.1;emitter.Transparency=1
 emitter.Anchored=true;emitter.CanCollide=false;emitter.CanQuery=false;emitter.CanTouch=false;emitter.CastShadow=false;emitter.Position=position;emitter.Parent=parent
 local sound=Instance.new("Sound");sound.Name="FighterCue";sound.SoundId=id;sound.PlaybackSpeed=math.clamp(pitch or 1,.6,1.8)
 sound.Volume=math.clamp(volume or .2,0,.55);sound.RollOffMinDistance=6;sound.RollOffMaxDistance=70;sound.RollOffMode=Enum.RollOffMode.InverseTapered
 sound:SetAttribute("BrainrotCustomAudio",true);sound.Parent=emitter
 -- Flat profile; the source recordings, not extreme EQ, establish the timbre.
 local eq=Instance.new("EqualizerSoundEffect");eq.Parent=sound
 sound:Play();table.insert(active,emitter)
 local duration=math.clamp(options.duration or .5,.08,1.5)
 task.delay(math.max(.02,duration-.06),function()
  if sound.Parent then TweenService:Create(sound,TweenInfo.new(.06),{Volume=0}):Play() end
 end)
 Debris:AddItem(emitter,duration+.08)
 return sound
end
function Audio.Play(parent,position,kind,fighterId,gain)
 local profile=profiles[kind] or profiles.Whoosh
 local now=os.clock()
 local bucket=kind..":"..math.floor(position.X/4)..":"..math.floor(position.Z/4)
 if now-(throttles[bucket] or -math.huge)<.045 then return end
 throttles[bucket]=now
 if sequence%64==0 then for key,at in throttles do if now-at>3 then throttles[key]=nil end end end
 sequence+=1
 local pitch=profile.pitch+(sequence%3-1)*.035
 if fighterId=="bombardiro" then pitch*=.91 elseif fighterId=="ballerina" then pitch*=1.08 end
 return Audio.PlayRaw(parent,position,Audio.Assets[profile.keys[(sequence-1)%#profile.keys+1]],pitch,profile.volume*(gain or 1),{duration=profile.duration})
end
function Audio.Preload()
 local assets={};for _,id in Audio.Assets do table.insert(assets,id) end
 task.spawn(function() pcall(function() ContentProvider:PreloadAsync(assets) end) end)
end
return Audio
