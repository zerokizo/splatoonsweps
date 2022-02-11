
local ss = SplatoonSWEPs
if not ss then return end
local LUMP = { -- Lump names. most of these are unused in SplatoonSWEPs.
    ENTITIES                      =  0,
    PLANES                        =  1,
    TEXDATA                       =  2,
    VERTEXES                      =  3,
    VISIBLITY                     =  4,
    NODES                         =  5,
    TEXINFO                       =  6,
    FACES                         =  7,
    LIGHTING                      =  8,
    OCCLUSION                     =  9,
    LEAFS                         = 10,
    FACEIDS                       = 11,
    EDGES                         = 12,
    SURFEDGES                     = 13,
    MODELS                        = 14,
    WORLDLIGHTS                   = 15,
    LEAFFACES                     = 16,
    LEAFBRUSHES                   = 17,
    BRUSHES                       = 18,
    BRUSHSIDES                    = 19,
    AREAS                         = 20,
    AREAPORTALS                   = 21,
    PORTALS                       = 22, -- unused in version 20
    CLUSTERS                      = 23, --
    PORTALVERTS                   = 24, --
    CLUSTERPORTALS                = 25, -- unused in version 20
    DISPINFO                      = 26,
    ORIGINALFACES                 = 27,
    PHYSDISP                      = 28,
    PHYSCOLLIDE                   = 29,
    VERTNORMALS                   = 30,
    VERTNORMALINDICES             = 31,
    DISP_LIGHTMAP_ALPHAS          = 32,
    DISP_VERTS                    = 33,
    DISP_LIGHMAP_SAMPLE_POSITIONS = 34,
    GAME_LUMP                     = 35,
    LEAFWATERDATA                 = 36,
    PRIMITIVES                    = 37,
    PRIMVERTS                     = 38,
    PRIMINDICES                   = 39,
    PAKFILE                       = 40,
    CLIPPORTALVERTS               = 41,
    CUBEMAPS                      = 42,
    TEXDATA_STRING_DATA           = 43,
    TEXDATA_STRING_TABLE          = 44,
    OVERLAYS                      = 45,
    LEAFMINDISTTOWATER            = 46,
    FACE_MACRO_TEXTURE_INFO       = 47,
    DISP_TRIS                     = 48,
    PHYSCOLLIDESURFACE            = 49,
    WATEROVERLAYS                 = 50,
    LIGHTMAPEDGES                 = 51,
    LIGHTMAPPAGEINFOS             = 52,
    LIGHTING_HDR                  = 53, -- only used in version 20+ BSP files
    WORLDLIGHTS_HDR               = 54, --
    LEAF_AMBIENT_LIGHTING_HDR     = 55, --
    LEAF_AMBIENT_LIGHTING         = 56, -- only used in version 20+ BSP files
    XZIPPAKFILE                   = 57,
    FACES_HDR                     = 58,
    MAP_FLAGS                     = 59,
    OVERLAY_FADES                 = 60,
    OVERLAY_SYSTEM_LEVELS         = 61,
    PHYSLEVEL                     = 62,
    DISP_MULTIBLEND               = 63,
}
local TextureFilterBits = bit.bor(unpack {
    SURF_SKY,
    SURF_WARP,
    SURF_NOPORTAL,
    SURF_TRIGGER,
    SURF_NODRAW,
    SURF_HINT,
    SURF_SKIP,
})
local SurfaceArray = {}
local MapName = game.GetMap()
local BSPFilePath = string.format("maps/%s.bsp", MapName)
local BSPFile = file.Open(BSPFilePath, "rb", "GAME")
local BSP = {}

local function MakeBrushSurface(verts, disp)
    assert(#verts >= 3, "Splatoon SWEPs: Given surface has less than 3 vertices!")
    local normal = Vector()
    local center = Vector()
    for i, v in ipairs(verts) do
        local v0 = verts[(#verts + i - 2) % #verts + 1] -- preceding vertex
        local v2 = verts[i % #verts + 1] -- succeeding vertex
        local n = (v0 - v):Cross(v2 - v):GetNormalized() -- normal around v0<-v->v2
        center = center + v
        normal = normal + n
    end
    center = center / #verts
    normal = normal / #verts
    normal:Normalize()

    local maxminverts = disp and disp.Vertices or verts
    local max, min = maxminverts[1], maxminverts[1]
    for i = 2, #maxminverts do -- bounding box using vertices or disp
        max = ss.MaxVector(max, maxminverts[i])
        min = ss.MinVector(min, maxminverts[i])
    end

    local angle = normal:Angle()
    local verts2D = {}
    for i, v in ipairs(verts) do
        verts2D[i] = ss.To2D(v, center, angle)
    end

    local function GetRotatedAABB(v2d, ang)
        local mins = Vector(math.huge, math.huge)
        local maxs = -mins
        for _, v in ipairs(v2d) do
            v = Vector(v)
            v:Rotate(ang)
            mins = ss.MinVector(mins, v)
            maxs = ss.MaxVector(maxs, v)
        end

        return mins, maxs
    end

    local area, bound, minangle, minmins = math.huge, nil, nil, nil
    for i, v in ipairs(verts2D) do -- Get minimum AABB with O(n^2)
        local segment = verts2D[i % #verts2D + 1] - v -- succeeding vertex - v
        local degrees = -math.deg(math.atan2(segment.y, segment.x))
        local ang = Angle(0, degrees + 90, 0)
        local mins, maxs = GetRotatedAABB(verts2D, ang)
        local size = maxs - mins
        if area > size.x * size.y then
            if size.x < size.y then
                ang.yaw = degrees
                minmins, maxs = GetRotatedAABB(verts2D, ang)
            else
                minmins = mins
            end

            minangle = -ang
            bound = maxs - minmins
            area = bound.x * bound.y
        end
    end

    if area == 0 then return end
    minmins:Rotate(minangle)
    center = ss.To3D(minmins, center, angle)
    angle:RotateAroundAxis(normal, minangle.yaw)
    bound.z = minangle.yaw

    return {
        AABB = {
            maxs = max,
            mins = min,
        },
        Angles = angle,
        Area = area,
        Bound = bound,
        DefaultAngles = minangle.yaw,
        Displacement = disp,
        InkSurfaces = {},
        Normal = normal,
        Origin = center,
        PropMesh = propmesh,
        Vertices = verts,
    }
end

local function IsExposed(verts, normal)
    local issolid = true
    local center = Vector()
    for _, v in ipairs(verts) do center:Add(v) end
    center = center / #verts
    local sample_points = {center}
    for i = 1, #verts do
        local v1 = verts[i]
        local v2 = verts[i % #verts + 1]
        sample_points[#sample_points + 1] = center * 0.001 + v1 * 0.999
        sample_points[#sample_points + 1] = center * 0.500 + v1 * 0.500
        sample_points[#sample_points + 1] = center * 0.250 + v1 * 0.750
        sample_points[#sample_points + 1] = (center + v1 + v2) / 3
    end

    for _, sp in ipairs(sample_points) do
        local c = util.PointContents(sp + normal * 0.05)
        issolid = issolid and bit.band(c, MASK_VISIBLE) > 0
        if not issolid then return true end
    end
end

local function read(arg)
    if isstring(arg) then
        if arg == "SignedByte" then
            local n = BSPFile:ReadByte()
            return n - (n > 127 and 256 or 0)
        elseif arg == "ShortVector" then
            local x = BSPFile:ReadShort()
            local y = BSPFile:ReadShort()
            local z = BSPFile:ReadShort()
            return Vector(x, y, z)
        elseif arg == "Vector" then
            local x = BSPFile:ReadFloat()
            local y = BSPFile:ReadFloat()
            local z = BSPFile:ReadFloat()
            return Vector(x, y, z)
        else
            return ss.ProtectedCall(BSPFile["Read" .. arg], BSPFile)
        end
    else
        return BSPFile:Read(arg)
    end
end

local function ReadBSPHeader()
    BSPFile:Seek(8)
    BSP.Header = {}
    BSP.Data = {}
    for i = 0, 63 do
        BSP.Data[i] = {}
        BSP.Header[i] = {}
        BSP.Header[i].offset = read "Long"
        BSP.Header[i].length = read "Long"
        BSPFile:Skip(8)
    end
end

local function ReadPlanes()
    local size = 20
    local header = BSP.Header[LUMP.PLANES]
    local lump = BSP.Data[LUMP.PLANES]
    BSPFile:Seek(header.offset)
    header.num = math.min(math.floor(header.length / size) - 1, 65536 - 1)
    for i = 0, header.num do
        lump[i] = {}
        lump[i].normal = read "Vector"
        lump[i].distance = read "Float"
        BSPFile:Skip(4) -- type
    end
end

local function ReadVertexes()
    local size = 12
    local header = BSP.Header[LUMP.VERTEXES]
    local lump = BSP.Data[LUMP.VERTEXES]
    BSPFile:Seek(header.offset)
    header.num = math.min(math.floor(header.length / size) - 1, 65536 - 1)
    for i = 0, header.num do lump[i] = read "Vector" end
end

local function ReadEdges()
    local size = 4
    local header = BSP.Header[LUMP.EDGES]
    local lump = BSP.Data[LUMP.EDGES]
    BSPFile:Seek(header.offset)
    header.num = math.min(math.floor(header.length / size) - 1, 256000 - 1)
    for i = 0, header.num do
        lump[i] = {}
        lump[i][1] = read "UShort"
        lump[i][2] = read "UShort"
    end
end

local function ReadSurfEdges()
    local size = 4
    local header = BSP.Header[LUMP.SURFEDGES]
    local lump = BSP.Data[LUMP.SURFEDGES]
    local vertexes = BSP.Data[LUMP.VERTEXES]
    local edges = BSP.Data[LUMP.EDGES]
    BSPFile:Seek(header.offset)
    header.num = math.min(math.floor(header.length / size) - 1, 512000 - 1)
    for i = 0, header.num do
        local n = read "Long"
        local absn = math.abs(n)
        local e = edges[absn]
        local v1, v2 = e[1], e[2]
        lump[i] = vertexes[n < 0 and v2 or v1]
    end
end

local function ReadTexData()
    local size = 32
    local header = BSP.Header[LUMP.TEXDATA]
    local lump = BSP.Data[LUMP.TEXDATA]
    local strdata = BSP.Header[LUMP.TEXDATA_STRING_DATA]
    local strtable = BSP.Header[LUMP.TEXDATA_STRING_TABLE]
    BSPFile:Seek(header.offset)
    header.num = math.min(math.floor(header.length / size) - 1, 2048 - 1)
    for i = 0, header.num do
        lump[i] = {}
        BSPFile:Skip(12) -- reflectivity
        local strID = read "Long" * 4
        lump[i].name = ""

        local here = BSPFile:Tell() + 8 + 8 -- width, height, view_width, view_height
        BSPFile:Seek(strtable.offset + strID)
        local stroffset = read "Long"
        BSPFile:Seek(strdata.offset + stroffset)
        for _ = 1, 128 do
            local chr = read(1)
            if chr == "\x00" then break end
            lump[i].name = lump[i].name .. chr
        end

        BSPFile:Seek(here)
    end
end

local function ReadTexInfos()
    local size = 72
    local TexData = BSP.Data[LUMP.TEXDATA]
    local header = BSP.Header[LUMP.TEXINFO]
    local lump = BSP.Data[LUMP.TEXINFO]
    BSPFile:Seek(header.offset)
    header.num = math.min(math.floor(header.length / size) - 1, 12288 - 1)
    for i = 0, header.num do
        BSPFile:Skip(32)
        lump[i] = {}
        lump[i].LightmapVecS = read "Vector"
        lump[i].LightmapOffsetS = read "Float"
        lump[i].LightmapVecT = read "Vector"
        lump[i].LightmapOffsetT = read "Float"
        lump[i].flags = read "Long"
        local texID = read "Long"
        if texID >= 0 then lump[i].TexData = TexData[texID] end
    end
end

local function ReadFaces()
    local size = 56 -- FACE Lump structure size
    local header = BSP.Header[LUMP.FACES]
    local lump = BSP.Data[LUMP.FACES]
    local planes = BSP.Data[LUMP.PLANES]
    local surfedges = BSP.Data[LUMP.SURFEDGES]
    local texinfo = BSP.Data[LUMP.TEXINFO]
    local dispinfooffset = BSP.Header[LUMP.DISPINFO].offset
    local dispvertsoffset = BSP.Header[LUMP.DISP_VERTS].offset

    BSPFile:Seek(header.offset)
    header.num = math.min(math.floor(header.length / size) - 1, 65536 - 1)
    for _ = 0, header.num do
        local face = {}
        local planeIndex = read "UShort"
        local PlaneTable = planes[planeIndex]
        local normal = PlaneTable.normal
        BSPFile:Skip(2)
        local firstedge = read "Long"
        local numedges = read "Short" - 1
        local TexInfoTable = texinfo[read "Short"]
        local dispinfo = read "Short"
        BSPFile:Skip(6) -- short surfaceFogVolumeID, byte[4] styles
        local lightofs = read "Long"
        read "Float" -- area
        local LightmapMinsU = read "Long"
        local LightmapMinsV = read "Long"
        local LightmapSizeU = read "Long"
        local LightmapSizeV = read "Long"
        BSPFile:Skip(12)
        local rawverts = {unpack(surfedges, firstedge, firstedge + numedges)}
        local verts = {}
        local center = Vector()
        for i, v in ipairs(rawverts) do
            local v0 = rawverts[(#rawverts + i - 2) % #rawverts + 1] -- preceding vertex
            local v2 = rawverts[i % #rawverts + 1] -- succeeding vertex
            local n = (v0 - v):Cross(v2 - v):GetNormalized() -- v0<-v->v2
            if normal:Dot(n) > 0 then
                verts[#verts + 1] = v
                center:Add(v)
            end
        end

        center = center / #verts
        local texname = TexInfoTable.TexData.name
        local texlow = texname:lower()
        local invalid = texlow:find "tools/" or texlow:find "water"
        or bit.band(TexInfoTable.flags, TextureFilterBits) ~= 0
        or Material(texname):GetString "$surfaceprop" == "metalgrate"
        or #verts < 3

        local contents = util.PointContents(center - normal * 0.05)
        local issolid = bit.band(contents, MASK_SOLID) > 0
        local isdisplacement = dispinfo >= 0
        if not invalid and (issolid or isdisplacement) then
            face.Vertices = verts
            face.LightmapOffset = lightofs
            face.LightmapMins = Vector(LightmapMinsU, LightmapMinsV)
            face.LightmapSize = Vector(LightmapSizeU, LightmapSizeV)
            face.LightmapVecS = TexInfoTable.LightmapVecS
            face.LightmapOffsetS = TexInfoTable.LightmapOffsetS
            face.LightmapVecT = TexInfoTable.LightmapVecT
            face.LightmapOffsetT = TexInfoTable.LightmapOffsetT
            if isdisplacement then
                local here = BSPFile:Tell()
                BSPFile:Seek(dispinfooffset + dispinfo * 176)
                local startPosition = read "Vector"
                local DispVertStart = read "Long" - 1
                BSPFile:Skip(4) -- DispTriStart
                local power = 2^read "Long" + 1
                local numdists = power^2
                local dispverts = {}
                for k = 1, numdists do
                    BSPFile:Seek(dispvertsoffset + 20 * (DispVertStart + k))
                    dispverts[k] = {}
                    dispverts[k].vec = read "Vector"
                    dispverts[k].dist = read "Float"
                end
                BSPFile:Seek(here)

                -- DispInfo.startPosition isn't always equal to verts[1] so find correct one
                local i, min, start = {}, math.huge, 0
                for k, v in ipairs(verts) do
                    local dist = startPosition:DistToSqr(v)
                    if dist < min then
                        start, min = k, dist
                    end
                end

                for k = 1, 4 do i[k] = (k + start - 2) % 4 + 1 end
                verts[1], verts[2], verts[3], verts[4] = verts[i[1]], verts[i[2]], verts[i[3]], verts[i[4]]

                local disp = {
                    Triangles = {},
                    Vertices = {},
                    VerticesGrid = {},
                }
                local u1 = verts[4] - verts[1]
                local v1, v2 = verts[2] - verts[1], verts[3] - verts[4]
                for k, v in ipairs(dispverts) do -- Get the world positions of the displacements
                    local x = (k - 1) % power -- 0 <= x <= power
                    local y = math.floor((k - 1) / power) -- 0 <= y <= power
                    local div1 = v1 * y / (power - 1)
                    local div2 = u1 + v2 * y / (power - 1) - div1
                    v.origin = div1 + div2 * x / (power - 1)
                    v.pos = startPosition + v.origin + v.vec * v.dist
                    v.posgrid = v.pos - normal * normal:Dot(v.vec * v.dist)
                    disp.Vertices[#disp.Vertices + 1] = v.pos
                    disp.VerticesGrid[#disp.VerticesGrid + 1] = v.posgrid
                    local invert = Either(k % 2 == 1, 1, 0)
                    if x < power - 1 and y < power - 1 then -- Generate triangles from displacement mesh.
                        disp.Triangles[#disp.Triangles + 1] = {k + power + invert, k + 1, k}
                        disp.Triangles[#disp.Triangles + 1] = {k + 1 - invert, k + power, k + power + 1}
                    end
                end

                face.Displacement = disp
            end

            lump[#lump + 1] = face
        end
    end
end

local function ReadGameLump()
    local header = BSP.Header[LUMP.GAME_LUMP]
    local lump = BSP.Data[LUMP.GAME_LUMP]
    BSPFile:Seek(header.offset)

    local lumpCount = read "Long"
    local headers = {}
    for i = 1, lumpCount do
        headers[i] = {}
        headers[i].id = read "Long"
        headers[i].flags = read "UShort"
        headers[i].version = read "UShort"
        headers[i].fileofs = read "Long"
        headers[i].filelen = read "Long"
    end

    local Axes = {x = {"y", "z"}, y = {"x", "z"}, z = {"x", "y"}}
    local function GetInfo(solidtype, modelname, origin, angles)
        if solidtype ~= SOLID_VPHYSICS then return end
        if not modelname then return end
        if not file.Exists(modelname, "GAME") then return end
        if not file.Exists(modelname:sub(1, -4) .. "phy", "GAME") then return end
        local mdl = ents.Create "prop_physics"
        if not IsValid(mdl) then return end
        mdl:SetModel(modelname)
        mdl:Spawn()
        local ph = mdl:GetPhysicsObject()
        local mat = IsValid(ph) and ph:GetMaterial()
        local physmesh = IsValid(ph) and ph:GetMeshConvexes()
        mdl:Remove()

        if not IsValid(ph) then return end
        if mat:find "chain" or mat:find "grate" then return end
        for _, convex in ipairs(physmesh) do
            local projection_planes = {}
            for _, n in ipairs {
                Vector(1, 0, 0), Vector(-1, 0, 0),
                Vector(0, 1, 0), Vector(0, -1, 0),
                Vector(0, 0, 1), Vector(0, 0, -1),
            } do
                projection_planes[tostring(n)] = {
                    axis_n = nil, -- normal = "x", "y", or "z"
                    axis_t = nil, -- tangent
                    axis_b = nil, -- binormal
                    component_n = nil, -- base plane components
                    max_t = nil, min_t = nil, -- tangent max, min
                    max_b = nil, min_b = nil, -- binormal max, min
                    Vertices = {},
                    VerticesGrid = {},
                    Triangles = {},
                }
            end

            local vertices_absolute = {}
            local convex_center = Vector()
            for i, v in ipairs(convex) do
                local worldpos = LocalToWorld(v.pos, angle_zero, origin, angles)
                vertices_absolute[i] = worldpos
                convex_center:Add(worldpos)
            end

            convex_center = convex_center / #convex

            for i = 1, #convex, 3 do
                local v1 = vertices_absolute[i]
                local v2 = vertices_absolute[i + 1]
                local v3 = vertices_absolute[i + 2]
                local v2v1 = v1 - v2
                local v2v3 = v3 - v2
                local n = v2v1:Cross(v2v3) -- normal around v1<-v2->v3
                if n:LengthSqr() < 4000 then continue end -- normal is valid then
                n:Normalize() -- normalize the normal
                if not IsExposed({v1, v2, v3}, n) then continue end
                local component_sign, normal -- detect the appropriate projection plane
                local max_component = 0
                local projection_normal = Vector()
                for axis in pairs(Axes) do
                    local abs_component = math.abs(n[axis])
                    if abs_component > max_component then
                        component_sign = n[axis] > 0 and 1 or -1
                        max_component = abs_component
                        normal = axis
                    end
                end

                projection_normal[normal] = component_sign
                local minmax = component_sign > 0 and math.min or math.max
                local plane = projection_planes[tostring(projection_normal)]
                local verts = plane.Vertices
                local tris = plane.Triangles
                verts[#verts + 1] = v1
                verts[#verts + 1] = v2
                verts[#verts + 1] = v3
                tris[#tris + 1] = {#verts - 2, #verts - 1, #verts}
                plane.axis_n = normal
                plane.axis_t = Axes[plane.axis_n][1]
                plane.axis_b = Axes[plane.axis_n][2]
                plane.component_n = minmax(unpack {
                    v1[plane.axis_n],
                    v2[plane.axis_n],
                    v3[plane.axis_n],
                    plane.component_n,
                })
                plane.max_t = math.max(unpack {
                    v1[plane.axis_t],
                    v2[plane.axis_t],
                    v3[plane.axis_t],
                    plane.max_t,
                })
                plane.max_b = math.max(unpack {
                    v1[plane.axis_b],
                    v2[plane.axis_b],
                    v3[plane.axis_b],
                    plane.max_b,
                })
                plane.min_t = math.min(unpack {
                    v1[plane.axis_t],
                    v2[plane.axis_t],
                    v3[plane.axis_t],
                    plane.min_t,
                })
                plane.min_b = math.min(unpack {
                    v1[plane.axis_b],
                    v2[plane.axis_b],
                    v3[plane.axis_b],
                    plane.min_b,
                })
            end

            for n, p in pairs(projection_planes) do
                if p.axis_n then
                    local vertices = {Vector(), Vector(), Vector(), Vector()}
                    for _, v in ipairs(vertices) do v[p.axis_n] = p.component_n end
                    vertices[1][p.axis_t] = p.min_t
                    vertices[1][p.axis_b] = p.min_b
                    vertices[2][p.axis_t] = p.min_t
                    vertices[2][p.axis_b] = p.max_b
                    vertices[3][p.axis_t] = p.max_t
                    vertices[3][p.axis_b] = p.max_b
                    vertices[4][p.axis_t] = p.max_t
                    vertices[4][p.axis_b] = p.min_b

                    local v2v1 = vertices[1] - vertices[2]
                    local v2v3 = vertices[3] - vertices[2]
                    local n_test = v2v1:Cross(v2v3)
                    if n_test:Dot(Vector(n)) < 0 then -- correct vertex order (cw/ccw)
                        vertices[2], vertices[4] = vertices[4], vertices[2]
                    end

                    for i, v in ipairs(p.Vertices) do
                        p.VerticesGrid[i] = Vector(v)
                        p.VerticesGrid[i][p.axis_n] = p.component_n
                    end

                    lump[#lump + 1] = MakeBrushSurface(vertices, p)
                end
            end
        end
    end

    for _, l in ipairs(headers) do
        if l.id == 1936749168 then -- id == "scrp", Static Prop Gamelump
            BSPFile:Seek(l.fileofs)
            local nextlump = l.fileofs + l.filelen
            local entries = read "Long"
            local modelnames = {} -- Model name dictionary
            for i = 1, entries do
                modelnames[i] = ""
                for _ = 1, 128 do
                    local c = read(1)
                    modelnames[i] = modelnames[i] .. (c ~= "\x00" and c or "")
                end
            end

            BSPFile:Skip(read "Long" * 2) -- Leaf Indices
            entries = read "Long"
            local here = BSPFile:Tell()
            local remaining = nextlump - here
            local entrysize = math.floor(remaining / entries)
            for i = 0, entries - 1 do
                BSPFile:Seek(here + entrysize * i)
                local origin = read "Vector"
                local angles = read "Vector" -- (x, y, z) -> (pitch, yaw, roll)
                angles = Angle(angles.x, angles.y, angles.z)
                angles:Normalize()
                local proptype = read "UShort"
                BSPFile:Skip(4)
                local solidtype = read "Byte"
                local mdlname = Model(modelnames[proptype + 1])
                GetInfo(solidtype, mdlname, origin, angles)
            end

            return
        end
    end
end

local function ReadLeafs()
    local size = 32 -- LEAF Lump structure size
    local header = BSP.Header[LUMP.LEAFS]
    local lump = BSP.Data[LUMP.LEAFS]
    BSPFile:Seek(header.offset)
    header.num = math.floor(header.length / size) - 1
    for i = 0, header.num do
        local leaf = {}
        leaf.contents = read "Long"
        leaf.cluster = read "Short"
        local areaflags = read "UShort"
        leaf.area = bit.band(areaflags, 0x01FF)
        leaf.flags = bit.band(bit.rshift(areaflags, 9), 0x007F)
        leaf.mins = read "ShortVector"
        leaf.maxs = read "ShortVector"
        leaf.firstleafface = read "UShort"
        leaf.numleaffaces = read "UShort"
        leaf.firstleafbrush = read "UShort"
        leaf.numleafbrushes = read "UShort"
        leaf.leafWaterDataID = read "Short"
        read "Short" -- padding
        lump[i + 1] = leaf
    end
end

util.TimerCycle()
ReadBSPHeader()
ReadPlanes()
ReadVertexes()
ReadEdges()
ReadSurfEdges()
ReadTexData()
ReadTexInfos()
ReadFaces()
ReadLeafs()
ReadGameLump()

local NumDisplacements = 0
for _, face in ipairs(BSP.Data[LUMP.FACES]) do
    if face.Vertices then
        SurfaceArray[#SurfaceArray + 1] = MakeBrushSurface(face.Vertices, face.Displacement)
        SurfaceArray[#SurfaceArray].LightmapInfo = {
            Offset = face.LightmapOffset,
            Mins = face.LightmapMins,
            Size = face.LightmapSize,
            VecS = face.LightmapVecS,
            OffsetS = face.LightmapOffsetS,
            VecT = face.LightmapVecT,
            OffsetT = face.LightmapOffsetT,
        }
        if face.Displacement then
            NumDisplacements = NumDisplacements + 1
        end
    end
end

for _, lump in ipairs(BSP.Data[LUMP.LEAFS]) do
    local area = lump.area
    if area > 0 then
        if not ss.MinimapAreaBounds[area] then
            ss.MinimapAreaBounds[area] = { mins = ss.vector_one * 16384, maxs = ss.vector_one * -16384 }
        end

        ss.MinimapAreaBounds[area].mins = ss.MinVector(ss.MinimapAreaBounds[area].mins, lump.mins)
        ss.MinimapAreaBounds[area].maxs = ss.MaxVector(ss.MinimapAreaBounds[area].maxs, lump.maxs)
    end
end

table.Add(SurfaceArray, BSP.Data[LUMP.GAME_LUMP])

local SurfIndicesRoot = {}
for i, s in ipairs(SurfaceArray) do
    SurfIndicesRoot[i] = i
    s.Index = i
end

BSPFile:Close()

-- End building linear array of surfaces ---------------------------------------

-- Begin constructing AABB-tree ------------------------------------------------
-- Reference: Ingo Wald, et al., 2007,
-- "Ray Tracing Deformable Scenes using Dynamic Bounding Volume Hierarchies",
-- and its Japanese explaination
-- https://qiita.com/omochi64/items/9336f57118ba918f82ec
local function EmptyAABB()
    return {
        maxs = ss.vector_one * -math.huge,
        mins = ss.vector_one * math.huge,
    }
end

local function SurfaceAreaAABB(x)
    local diff = x.maxs - x.mins
    return 2 * (diff.x * diff.y + diff.x * diff.z + diff.y * diff.z)
end

local function MergeAABB(a, b)
    return {
        maxs = ss.MaxVector(a.maxs, b.maxs),
        mins = ss.MinVector(a.mins, b.mins),
    }
end

local function CreateWholeAABB(AABBs)
    local AABB = EmptyAABB()
    for _, a in ipairs(AABBs) do
        AABB = MergeAABB(AABB, SurfaceArray[a].AABB)
    end

    return AABB
end

local AABBTree = {}
local used_node_count = 2
local Axes = {{"x", "y", "z"}, {"y", "z", "x"}, {"z", "x", "y"}}
local function ConstructAABBTree(Tree, AABBs, nodeIndex)
    Tree[nodeIndex] = Tree[nodeIndex] or {}
    local node = Tree[nodeIndex]
    node.AABB = CreateWholeAABB(AABBs)
    local bestCost = #AABBs
    local bestAxis = nil
    local bestSplitIndex = -1
    local SurfaceAreaRoot = SurfaceAreaAABB(node.AABB)
    local SortedAABBs = {}
    local axis_sort = 1
    local function sortfunc(a, b)
        a, b = SurfaceArray[a], SurfaceArray[b]
        local a_center = a.AABB.maxs + a.AABB.mins
        local b_center = b.AABB.maxs + b.AABB.mins
        for i = 1, 3 do
            local ai = a_center[Axes[i][axis_sort]]
            local bi = b_center[Axes[i][axis_sort]]
            if ai ~= bi then return ai < bi end
        end
    end

    for axis = 1, 3 do
        SortedAABBs[axis] = table.Copy(AABBs)
        axis_sort = axis
        table.sort(SortedAABBs[axis], sortfunc)

        local total = #SortedAABBs[axis]
        local split1, split2 = {}, SortedAABBs[axis]
        local testAABB = EmptyAABB()
        local split1SurfaceAreas, split2SurfaceAreas = {}, {}
        for i = 1, total do
            split1SurfaceAreas[i] = math.huge
            split2SurfaceAreas[i] = math.huge
        end

        for i = 1, total do
            split1SurfaceAreas[i] = SurfaceAreaAABB(testAABB)
            split1[#split1 + 1] = ss.tablepop(split2)
            testAABB = MergeAABB(testAABB, SurfaceArray[split1[#split1]].AABB)
        end

        testAABB = EmptyAABB()
        for i = total, 1, -1 do
            split2SurfaceAreas[i] = SurfaceAreaAABB(testAABB)
            local cost = 2 + (split1SurfaceAreas[i] * #split1 + split2SurfaceAreas[i] * #split2) / SurfaceAreaRoot
            if cost < bestCost then
                bestCost = cost
                bestAxis = axis
                bestSplitIndex = i + 1
            end

            ss.tablepush(split2, split1[#split1])
            testAABB = MergeAABB(testAABB, SurfaceArray[split1[#split1]].AABB)
            split1[#split1] = nil
        end
    end

    if not bestAxis then
        node.SurfIndices = AABBs
        return
    end

    node.Children = {used_node_count, used_node_count + 1}
    used_node_count = used_node_count + 2

    local leftAABBs, rightAABBs = {}, {}
    for i, a in ipairs(SortedAABBs[bestAxis]) do
        if i < bestSplitIndex then
            leftAABBs[#leftAABBs + 1] = a
        else
            rightAABBs[#rightAABBs + 1] = a
        end
    end

    ConstructAABBTree(Tree, leftAABBs, node.Children[1])
    ConstructAABBTree(Tree, rightAABBs, node.Children[2])
end

ConstructAABBTree(AABBTree, SurfIndicesRoot, 1)
print("MAKE", util.TimerCycle())

ss.AABBTree = AABBTree
ss.NumDisplacements = NumDisplacements
ss.SurfaceArray = SurfaceArray
for _, s in ipairs(SurfaceArray) do
    ss.AreaBound = ss.AreaBound + s.Area
    ss.AspectSum = ss.AspectSum + s.Bound.y / s.Bound.x
    ss.AspectSumX = ss.AspectSumX + s.Bound.x
    ss.AspectSumY = ss.AspectSumY + s.Bound.y
end
