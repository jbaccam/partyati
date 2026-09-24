-- Astra-authored upload-free fallback for CrystalShard.fbx / .glb.
-- create(parent, name?, height?) -> Model with centered invisible PrimaryPart.
-- 24 facets / 48 anchored WedgeParts, no scripts, lighting, particles or aura.
local CrystalShardVisual = {}

local palette = {
    Color3.fromRGB(19, 92, 186), Color3.fromRGB(28, 130, 214),
    Color3.fromRGB(51, 171, 230), Color3.fromRGB(94, 201, 240),
    Color3.fromRGB(36, 145, 219), Color3.fromRGB(135, 217, 242),
}
local indices = {4,1,2,5,3,2,1,4,5,3,4,2,5,3,2,1,6,3,2,5,3,1,5,4}
local offsets = {.075, -.045, .015, -.07, .06, -.03}

local function triangle(model, a, b, c, color, thickness)
    local ab, ac, bc = b-a, c-a, c-b
    local ab2, ac2, bc2 = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
    if ab2 > ac2 and ab2 > bc2 then
        c, a = a, c
    elseif ac2 > ab2 and ac2 > bc2 then
        a, b = b, a
    end
    ab, ac, bc = b-a, c-a, c-b
    local right = ac:Cross(ab).Unit
    local back = bc.Unit
    local up = bc:Cross(right).Unit
    local h = math.abs(ab:Dot(up))
    local function wedge(size, cf)
        local part = Instance.new('WedgePart')
        part.Name = 'AzureFacet'
        part.Size = size
        part.CFrame = cf
        part.Color = color
        part.Material = Enum.Material.SmoothPlastic
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = false
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Parent = model
    end
    wedge(Vector3.new(thickness, h, math.abs(ab:Dot(back))), CFrame.fromMatrix((a+b)/2, right, up, back))
    wedge(Vector3.new(thickness, h, math.abs(ac:Dot(back))), CFrame.fromMatrix((a+c)/2, -right, up, -back))
end

function CrystalShardVisual.create(parent, name, height)
    height = height or 1.25
    assert(type(height) == 'number' and height > 0 and height < math.huge, 'height must be positive and finite')
    local scale = height / 3
    local vertices = {Vector3.new(.035, 1.5, .025) * scale}
    for _, ring in ipairs({{.47, .51, 0, -.025}, {-.49, .435, .16, .025}}) do
        for i = 0, 5 do
            local angle = i * math.pi / 3 + ring[3]
            table.insert(vertices, Vector3.new(math.cos(angle)*ring[2]+ring[4], ring[1]+offsets[i+1], -math.sin(angle)*ring[2]*.78)*scale)
        end
    end
    table.insert(vertices, Vector3.new(.025, -1.5, -.015)*scale)
    local model = Instance.new('Model')
    model.Name = name or 'CrystalShard'
    local root = Instance.new('Part')
    root.Name = 'ShardRoot'
    root.Size = Vector3.new(.1, .1, .1)
    root.Transparency = 1
    root.Anchored = true
    root.CanCollide = false
    root.CanTouch = false
    root.CanQuery = false
    root.CastShadow = false
    root.Parent = model
    model.PrimaryPart = root
    local facet = 0
    for i = 0, 5 do
        local j = (i+1)%6
        for _, face in ipairs({{1,2+i,2+j},{2+i,8+i,8+j},{2+i,8+j,2+j},{14,8+j,8+i}}) do
            facet += 1
            triangle(model, vertices[face[1]], vertices[face[2]], vertices[face[3]], palette[indices[facet]], math.max(.001, height*.002))
        end
    end
    model:SetAttribute('AssetKind', 'CrystalShard')
    model:SetAttribute('AssetAuthor', 'Astra')
    model:SetAttribute('NominalHeight', height)
    model.Parent = parent
    return model
end

return CrystalShardVisual
