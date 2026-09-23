return function(Types,Motion)
    local checks=0
    local function check(value,message) assert(value,message);checks+=1 end
    check(Types.Baby.speed>Types.Regular.speed,'Baby must be faster')
    check(Types.Baby.health<Types.Regular.health,'Baby must be fragile')
    check(Types.Mutant.health>Types.Regular.health*3,'Mutant must be durable')
    check(Types.Mutant.damage==0,'Do not stack invisible contact damage on the slam')
    check(Types.Slam.impact<.55 and Types.Slam.impact>Types.Slam.windup,'Short readable windup')
    check(Types.Slam.cooldown>Types.Slam.recovery,'Slam must have chase time between attacks')
    check(Types.forSlot(2)=='Baby' and Types.forSlot(5)=='Mutant','Starter wave contains both new types')
    local center=Vector3.zero
    check(Types.inSlam(center,Vector3.new(0,3,0)),'A player inside the circle should be hit')
    check(not Types.inSlam(center,Vector3.new(Types.Slam.radius+.01,3,0)),'Outside circle rejected')
    check(not Types.inSlam(center,Vector3.new(0,Types.Slam.maxHeight+.01,0)),'Different elevation rejected')
    check(Types.inSlam(center,Vector3.new(-Types.Slam.radius,0,0)),'Circle must work in all directions')
    for _,kind in {'Regular','Baby','Mutant'} do
        for i=0,120 do
            local poses=Motion.pose(kind,i*.13,1,1,i/60,kind=='Mutant' and i/120 or nil)
            local count=0
            for _,pose in poses do
                count+=1
                for _,v in {pose:GetComponents()} do check(v==v and math.abs(v)<100,'Finite bounded pose') end
            end
            check(count==15,'All articulated joints posed')
        end
    end
    for _,stride in {0,1} do
        local x=Motion.pose('Mutant',0,stride,1,0).Waist:ToOrientation()
        check(x<math.rad(-20),'Mutant should remain hunched while still and moving')
    end
    local a=Motion.slam(0).LeftShoulder.UpVector.Y
    local b=Motion.slam(Types.Slam.windup).LeftShoulder.UpVector.Y
    check(a>.5 and b<-.5,'Raise both arms overhead')
    local rest=Motion.pose('Mutant',0,0,1,0).Waist
    local ending=Motion.slam(Types.Slam.recovery).Waist
    check((rest.Position-ending.Position).Magnitude<.001,'Return to hunched rest height')
    return {checks=checks,types=3,poseSamples=363}
end
