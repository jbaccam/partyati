-- In-memory run economy. No DataStores, Robux, client prices or client-owned inventory.
local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local Http=game:GetService('HttpService')
local combat=RS:WaitForChild('RogueliteCombat')
local E=require(combat.EconomyConfig)
local Catalog=require(combat.ShopCatalog)
local Characters=require(script.Parent.CharacterService)
local Shards=require(script.Parent.ShardDropService)
local XP=require(combat.RunXP)
local S={states={},wave=1,phase='Shop'}
local rng=Random.new()
local serial=0
local function token() serial+=1;return tostring(serial) end
local run=RS:FindFirstChild('RogueliteRunState') or Instance.new('Folder')
run.Name='RogueliteRunState';run.Parent=RS
run:SetAttribute('Phase','Shop');run:SetAttribute('Wave',1)
combat:SetAttribute('ZombiesEnabled',false)
local remote=combat:WaitForChild('ShopAction')
local function living(p) local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid');return h and h.Health>0 end
local function slots(p) return Characters.states[p].folder end
local function owned(p)
 local result={}
 for i=1,6 do local f=slots(p)['Slot'..i]
  result[i]={slot=i,id=f:GetAttribute('WeaponId') or '',copy=f:GetAttribute('CopyId') or '',tier=f:GetAttribute('Tier') or 1,paid=f:GetAttribute('FinalPurchasePrice') or 0,basePrice=f:GetAttribute('BasePrice') or 0,wave=f:GetAttribute('WavePurchased') or 0}
 end
 for _,weapon in result do
  for _,other in result do
   if weapon.id~='' and weapon.tier<4 and weapon.slot~=other.slot and weapon.id==other.id and weapon.tier==other.tier then weapon.canCombine=true;weapon.combineSlot=other.slot;break end
  end
 end
 return result
end
local function clearWeapon(f)
 f:SetAttribute('WeaponId','');f:SetAttribute('CopyId',token());f:SetAttribute('FinalPurchasePrice',0);f:SetAttribute('PurchasePrice',0);f:SetAttribute('BasePrice',0);f:SetAttribute('Tier',1);f:SetAttribute('WavePurchased',0)
end
local function upgradeWeapon(f,paid)
 local tier=(f:GetAttribute('Tier') or 1)+1
 f:SetAttribute('FinalPurchasePrice',(f:GetAttribute('FinalPurchasePrice') or 0)+paid)
 f:SetAttribute('PurchasePrice',f:GetAttribute('FinalPurchasePrice'))
 f:SetAttribute('BasePrice',Catalog.ById['weapon_'..f:GetAttribute('WeaponId')..'_'..tier].basePrice)
 f:SetAttribute('CopyId',token());f:SetAttribute('Tier',tier)
end
function S.publish(p,message)
 local s=S.states[p];if not s or not Characters.states[p] then return end
 local data={shards=s.shards,wave=S.wave,phase=S.phase,rerolls=s.rerolls,rerollPrice=E.reroll(S.wave,s.rerolls),offers=s.offers,items=s.items,weapons=owned(p),ready=s.ready,revision=s.revision,message=message or s.message or '',modifier=E.modifier(Characters.states[p].stats),debug=RunService:IsStudio() and E.DEBUG_CURRENCY_ENABLED}
 s.message=data.message;slots(p):SetAttribute('Shards',s.shards)
 slots(p):SetAttribute('RunLevel',s.level);slots(p):SetAttribute('RunXP',s.xp)
 slots(p):SetAttribute('RunXPRequired',XP.required(s.level))
 slots(p):SetAttribute('PendingLevelUps',s.pendingLevels)
 slots(p):SetAttribute('ShopSnapshot',Http:JSONEncode(data))
end
local function reprice(p)
 local s=S.states[p];local modifier=E.modifier(Characters.states[p].stats)
 for _,o in s.offers do if not o.locked and not o.sold then o.price=E.price(Catalog.ById[o.id].basePrice,S.wave,modifier) end end
end
local function roll(p,previous,kind)
 local s=S.states[p];local pool={};local wantWeapon=kind=='Weapon' or (not kind and rng:NextNumber()<.5)
 -- Wave-dependent rarity mix is disclosed, independent of Luck and purchases.
 local n=rng:NextNumber();local tier=n<.55 and 1 or n<.85 and 2 or n<.97 and 3 or 4
 if S.wave>=6 and tier==1 and rng:NextNumber()<.25 then tier=2 end
 for _,entry in Catalog.List do
  if (entry.kind=='Weapon')==wantWeapon and entry.tier==tier and entry.id~=previous then
   local count=0;for _,it in s.items do if it.id==entry.id then count=it.count end end
   if entry.kind=='Weapon' or count<entry.cap then table.insert(pool,entry) end
  end
 end
 if #pool==0 then for _,entry in Catalog.List do if entry.kind=='Weapon' and entry.id~=previous then table.insert(pool,entry) end end end
 local entry=pool[rng:NextInteger(1,#pool)]
 return {id=entry.id,token=token(),price=E.price(entry.basePrice,S.wave,E.modifier(Characters.states[p].stats)),locked=false,sold=false}
end
function S.bonuses(p)
 local s=S.states[p];local cs=Characters.states[p];if not s or not cs then return end
 cs.itemBonuses={};cs.itemPercent={}
 for _,item in s.items do local entry=Catalog.ById[item.id]
  for id,value in entry.modifiers do cs.itemBonuses[id]=(cs.itemBonuses[id] or 0)+value*item.count end
  for id,value in entry.percent do cs.itemPercent[id]=(cs.itemPercent[id] or 0)+value*item.count end
 end
 Characters.refresh(p)
end
function S.attach(p)
 local s={shards=E.STARTING_SHARDS,level=1,xp=0,pendingLevels=0,rerolls=0,offers={},items={},ready=false,revision=1,lastRequest=-1e6}
 S.states[p]=s
 for i=1,6 do local f=slots(p)['Slot'..i];f:SetAttribute('Tier',1);f:SetAttribute('FinalPurchasePrice',0);f:SetAttribute('BasePrice',0);f:SetAttribute('WavePurchased',0);f:SetAttribute('CopyId',token()) end
 for i=1,E.OFFER_COUNT do s.offers[i]=roll(p,nil,i==1 and 'Weapon' or i==2 and 'Item' or nil) end
 S.publish(p)
 p.CharacterAdded:Connect(function() task.defer(function() if S.states[p] then s.ready=false;S.publish(p) end end) end)
end
local function beginWave()
 if S.phase~='Shop' then return end
 local count=0
 for p,s in S.states do if living(p) then count+=1;if not s.ready then return end end end
 if count==0 then return end
 S.phase='Combat';run:SetAttribute('Phase','Combat');run:SetAttribute('WaveEndsAt',workspace:GetServerTimeNow()+E.WAVE_SECONDS)
 combat:SetAttribute('ZombieCount',combat:GetAttribute('TestZombieCountOverride') or math.min(100,5+(S.wave-1)*2));combat:SetAttribute('ZombiesEnabled',true)
 for p in S.states do local cs=Characters.states[p];cs.blocks=1;cs.folder:SetAttribute('BlocksRemaining',cs.stats.FirstHitBlock);S.publish(p,'Wave started') end
end
function S.stopWave()
 -- Abort a Studio test, not a wave clear: no reward, advancement or reroll.
 if not RunService:IsStudio() or S.phase~='Combat' then return false end
 S.phase='Shop';run:SetAttribute('Phase','Shop');run:SetAttribute('WaveEndsAt',nil)
 combat:SetAttribute('ZombiesEnabled',false)
 Shards.clear(false)
 for p,s in S.states do
  s.ready=false;s.revision+=1
  S.publish(p,'Wave stopped · restart this wave when ready')
 end
 return true
end
function S.finishWave()
 if S.phase~='Combat' then return false end
 Shards.clear(true)
 combat:SetAttribute('ZombiesEnabled',false);S.phase='Shop';S.wave+=1
 run:SetAttribute('Phase','Shop');run:SetAttribute('Wave',S.wave);run:SetAttribute('WaveEndsAt',nil)
 for p,s in S.states do
  if living(p) then s.shards=math.min(E.MAX_SHARDS,s.shards+E.WAVE_REWARD_BASE+(S.wave-1)*E.WAVE_REWARD_SCALE) end
  s.rerolls=0;s.ready=false;s.revision+=1
  for i,o in s.offers do if not o.locked or o.sold then s.offers[i]=roll(p,o.id) end end
  S.publish(p,'Next shop · reroll cost reset')
 end
 return true
end
function S.request(p,action,revision,arg,extra)
 local s=S.states[p];local cs=Characters.states[p]
 if not s or not cs or not living(p) or type(action)~='string' then return false end
 if os.clock()-s.lastRequest<.12 then return false end;s.lastRequest=os.clock()
 local function fail(msg) S.publish(p,msg);return false end
 if revision~=s.revision then return fail('Shop changed. Please try again.') end
 if action=='Shards' then
  if not RunService:IsStudio() or not E.DEBUG_CURRENCY_ENABLED then return fail('Developer control unavailable') end
  if not E.integer(extra,-E.MAX_SHARDS,E.MAX_SHARDS) or (arg~='Set' and arg~='Add') then return fail('Enter a whole shards amount') end
  local value=arg=='Set' and extra or s.shards+extra
  if not E.integer(value,0,E.MAX_SHARDS) then return fail('Shards must be between 0 and '..E.MAX_SHARDS) end
  s.shards=value
 elseif S.phase~='Shop' then return fail('Shop actions are available between waves')
 elseif action=='Buy' or action=='Lock' then
  if not E.integer(arg,1,E.OFFER_COUNT) then return fail('Invalid offer') end
  local o=s.offers[arg];if not o or o.token~=extra or o.sold then return fail('Offer is no longer available') end
  if action=='Lock' then o.locked=not o.locked
  else
   local entry=Catalog.ById[o.id]
   if s.shards<o.price then return fail('Not enough shards') end
   if entry.kind=='Weapon' then
    if not combat.WeaponTemplates:FindFirstChild(entry.weaponId) then return fail('Weapon asset unavailable') end
    local free
    for i=1,6 do if slots(p)['Slot'..i]:GetAttribute('WeaponId')=='' then free=slots(p)['Slot'..i];break end end
    local merge
    if not free and entry.tier<4 then
     for i=1,6 do local f=slots(p)['Slot'..i]
      if f:GetAttribute('WeaponId')==entry.weaponId and f:GetAttribute('Tier')==entry.tier then merge=f;break end
     end
    end
    if not free and not merge then return fail('Six weapons equipped. Combine a matching pair or recycle one first.') end
    if merge then upgradeWeapon(merge,o.price) else
    free:SetAttribute('BasePrice',entry.basePrice);free:SetAttribute('FinalPurchasePrice',o.price);free:SetAttribute('PurchasePrice',o.price)
    free:SetAttribute('Tier',entry.tier);free:SetAttribute('WavePurchased',S.wave);free:SetAttribute('CopyId',token());free:SetAttribute('WeaponId',entry.weaponId)
    end
   else
    local existing
    for _,it in s.items do if it.id==entry.id then existing=it end end
    if existing and existing.count>=entry.cap then return fail('Item copy limit reached') end
    if not existing and #s.items>=E.ITEM_CAPACITY then return fail('Item inventory full') end
    if existing then existing.count+=1 else table.insert(s.items,{id=entry.id,count=1}) end
   end
   s.shards-=o.price;o.sold=true;o.locked=false
   S.bonuses(p)
  end
 elseif action=='Reroll' then
  local available=false;for _,o in s.offers do if not o.locked or o.sold then available=true end end
  if not available then return fail('Unlock an offer before rerolling') end
  local price=E.reroll(S.wave,s.rerolls);if s.shards<price then return fail('Not enough shards to reroll') end
  s.shards-=price;s.rerolls+=1
  for i,o in s.offers do if not o.locked or o.sold then s.offers[i]=roll(p,o.id) end end
 elseif action=='Combine' then
  if not E.integer(arg,1,6) then return fail('Invalid weapon slot') end
  local f=slots(p)['Slot'..arg];local id=f:GetAttribute('WeaponId');local tier=f:GetAttribute('Tier') or 1
  if id=='' or f:GetAttribute('CopyId')~=extra then return fail('Weapon changed; select it again') end
  if tier>=4 then return fail('Legendary is the highest tier') end
  local partner
  for i=1,6 do local other=slots(p)['Slot'..i]
   if i~=arg and other:GetAttribute('WeaponId')==id and other:GetAttribute('Tier')==tier then partner=other;break end
  end
  if not partner then return fail('Combine needs two identical weapons of the same tier') end
  upgradeWeapon(f,partner:GetAttribute('FinalPurchasePrice') or 0)
  clearWeapon(partner);S.bonuses(p)
 elseif action=='Sell' then
  if not E.integer(arg,1,6) then return fail('Invalid weapon slot') end
  local f=slots(p)['Slot'..arg]
  if f:GetAttribute('WeaponId')=='' or f:GetAttribute('CopyId')~=extra then return fail('Weapon changed; select it again') end
  s.shards=math.min(E.MAX_SHARDS,s.shards+E.refund(f:GetAttribute('FinalPurchasePrice') or 0))
  clearWeapon(f)
 elseif action=='Start' then s.ready=true
 else return fail('Unknown shop action') end
 if action~='Start' then s.ready=false end
 local count=0;for i=1,6 do if slots(p)['Slot'..i]:GetAttribute('WeaponId')~='' then count+=1 end end;slots(p):SetAttribute('EquippedCount',count)
 s.revision+=1;reprice(p);S.publish(p,action=='Start' and 'Ready · waiting for other living players' or '')
 if action=='Start' then beginWave() end
 return true
end
remote.OnServerEvent:Connect(S.request)
Characters.onStatsChanged=function(p) if S.states[p] then reprice(p);S.states[p].revision+=1;S.publish(p) end end
Shards.configure(Characters,function() return S.phase=='Combat' end,function(p,amount,pickedUp)
 local s=S.states[p]
 if not s or not living(p) or not E.integer(amount,1,E.MAX_SHARDS) then return false end
 s.shards=math.min(E.MAX_SHARDS,s.shards+amount)
 if pickedUp then
  local level,xp,gained=XP.add(s.level,s.xp,amount*XP.XP_PER_SHARD)
  s.level=level;s.xp=xp;s.pendingLevels+=gained
 end
 S.publish(p);return true
end)
require(combat.ZombieDeath).onDeath=function(npc,position)
 Shards.spawn(npc,position)
end
Players.PlayerRemoving:Connect(function(p) S.states[p]=nil;task.defer(beginWave) end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.2 then return end;elapsed=0
 if S.phase=='Shop' then beginWave() end
 if S.phase=='Combat' and not run:GetAttribute('BossAlive') and workspace:GetServerTimeNow()>=(run:GetAttribute('WaveEndsAt') or math.huge) then S.finishWave() end
end)
return S
