
local ss = SplatoonSWEPs
if not ss then return end

-- local IMAGE_FORMAT_BGRA5551 = 21
-- local IMAGE_FORMAT_BGRA4444 = 19
local rt = ss.RenderTarget
local MAX_TRIANGLES = math.floor(32768 / 3) -- mesh library limitation
local INK_SURFACE_DELTA_NORMAL = .8 -- Distance between map surface and ink mesh
if ss.SplatoonMapPorts[game.GetMap()] then INK_SURFACE_DELTA_NORMAL = 2 end
function ss.BuildInkMesh()
    local numsurfs = #ss.SurfaceArray
    local rtsize = rt.BaseTexture:Width()
    local rtmargin = 4 / rtsize -- Render Target margin
    local dumb = ss.AreaBound * ss.AspectSum / numsurfs * ss.AspectSumX / ss.AspectSumY / 2500 + numsurfs
    local arearatio = 41.3329546960896 / rtsize * dumb ^ .523795515713613 -- arearatio[units/pixel], Found by Excel bulldozing
    local convertunit = rtsize * arearatio -- convertunit[units/pixel], A[pixel] * units/pixel -> A[units]
    local sortedsurfs, movesurfs = {}, {}
    local NumMeshTriangles, nummeshes, dv, divuv, half = 0, 1, 0, 1
    local u, v, nv, bu, bv, bk = 0, 0, 0 -- cursor(u, v), shelf height, rectangle size(u, v), beginning of k
    for _, s in SortedPairsByMemberValue(ss.SurfaceArray, "Area", true) do -- Placement of map polygons by Next-Fit algorithm.
        sortedsurfs[#sortedsurfs + 1] = s.Index
        NumMeshTriangles = NumMeshTriangles + #s.Vertices - 2

        bu, bv = s.Bound.x / convertunit, s.Bound.y / convertunit
        nv = math.max(nv, bv)
        if u + bu > 1 then -- Creating a new shelf
            if v + nv + rtmargin > 1 then
                movesurfs[#movesurfs + 1] = {id = bk, v = v}
            end

            u, v, nv = 0, v + nv + rtmargin, bv
        end

        if u == 0 then bk = #sortedsurfs end -- Storing the first element of current shelf
        for i, vert in ipairs(s.Vertices) do -- Get UV coordinates
            local meshvert = vert + s.Normal * INK_SURFACE_DELTA_NORMAL
            local UV = ss.To2D(vert, s.Origin, s.Angles) / convertunit
            s.Vertices[i] = {pos = meshvert, u = UV.x + u, v = UV.y + v}
        end

        if s.Displacement then
            NumMeshTriangles = NumMeshTriangles + #s.Displacement.Triangles - 2
            for i, vt in ipairs(s.Displacement.Vertices) do
                local UV = ss.To2D(s.Displacement.VerticesGrid[i], s.Origin, s.Angles) / convertunit
                s.Displacement.Vertices[i] = {pos = vt, u = UV.x + u, v = UV.y + v}
            end
        end

        s.u, s.v = u, v
        u = u + bu + rtmargin -- Advance U-coordinate
    end

    if v + nv > 1 and #movesurfs > 0 then -- RT could not store all polygons
        local min, halfv = math.huge, movesurfs[#movesurfs].v / 2 + .5
        for _, m in ipairs(movesurfs) do -- Then move the remainings to the left
            local diffv = math.abs(m.v - halfv)
            if diffv < min then min, half = diffv, m end
        end

        dv = half.v - 1 - rtmargin
        divuv = math.max(half.v, v + nv - dv) -- Shrink RT
        arearatio = arearatio * divuv
        convertunit = convertunit * divuv
    end

    print("SplatoonSWEPs: Total mesh triangles = ", NumMeshTriangles)
    ss.PixelsToUnits = arearatio
    ss.UVToUnits = convertunit
    ss.UVToPixels = rtsize
    ss.UnitsToPixels = 1 / ss.PixelsToUnits
    ss.UnitsToUV = 1 / ss.UVToUnits
    ss.PixelsToUV = 1 / ss.UVToPixels
    ss.SortedSurfaceIDs = sortedsurfs

    for _ = 1, math.ceil(NumMeshTriangles / MAX_TRIANGLES) do
        ss.IMesh[#ss.IMesh + 1] = Mesh(ss.RenderTarget.Material)
    end

    -- Building MeshVertex
    if #ss.IMesh == 0 then return end
    mesh.Begin(ss.IMesh[nummeshes], MATERIAL_TRIANGLES, math.min(NumMeshTriangles, MAX_TRIANGLES))
    local function ContinueMesh()
        if mesh.VertexCount() < MAX_TRIANGLES * 3 then return end
        mesh.End()
        mesh.Begin(ss.IMesh[nummeshes + 1], MATERIAL_TRIANGLES,
        math.min(NumMeshTriangles - MAX_TRIANGLES * nummeshes, MAX_TRIANGLES))
        nummeshes = nummeshes + 1
    end

    for sortedID, k in ipairs(ss.SortedSurfaceIDs) do
        local s = ss.SurfaceArray[k]
        if half and sortedID >= half.id then -- If current polygon is moved
            s.u, s.v = s.v - dv, 1 - s.u - s.Bound.x / convertunit * divuv
            s.Moved = true
            for _, vert in ipairs(s.Vertices) do
                vert.u, vert.v = vert.v - dv, 1 - vert.u
            end

            if s.Displacement then
                for _, vert in ipairs(s.Displacement.Vertices) do
                    vert.u, vert.v = vert.v - dv, 1 - vert.u
                end
            end
        end

        s.u, s.v = s.u / divuv, s.v / divuv
        if s.Displacement then
            local verts = s.Displacement.Vertices
            for _, p in ipairs(verts)      do p.u, p.v = p.u / divuv, p.v / divuv end
            for _, p in ipairs(s.Vertices) do p.u, p.v = p.u / divuv, p.v / divuv end
            for _, t in ipairs(s.Displacement.Triangles) do
                local tv = {verts[t[1]], verts[t[2]], verts[t[3]]}
                local n = (tv[1].pos - tv[2].pos):Cross(tv[3].pos - tv[2].pos):GetNormalized()
                for _, p in ipairs(tv) do
                    mesh.Normal(n)
                    mesh.Position(p.pos + n * INK_SURFACE_DELTA_NORMAL)
                    mesh.TexCoord(0, p.u, p.v)
                    mesh.TexCoord(1, p.u, p.v)
                    mesh.AdvanceVertex()
                end

                ContinueMesh()
            end
        else
            for t, p in ipairs(s.Vertices) do
                p.u, p.v = p.u / divuv, p.v / divuv
                if t <= 2 then continue end
                for _, i in ipairs {t - 1, t, 1} do
                    local q = s.Vertices[i]
                    mesh.Normal(s.Normal)
                    mesh.Position(q.pos)
                    mesh.TexCoord(0, q.u, q.v)
                    mesh.TexCoord(1, q.u, q.v)
                    mesh.AdvanceVertex()
                end

                ContinueMesh()
            end
        end
    end
    mesh.End()
end

function ss.BuildWaterMesh()
    local NumMeshTriangles, nummeshes = 0, 1
    for _, f in ipairs(ss.WaterSurfaces) do
        NumMeshTriangles = NumMeshTriangles + #f.Vertices - 2
    end
    for _ = 1, math.ceil(NumMeshTriangles / MAX_TRIANGLES) do
        ss.WaterMesh[#ss.WaterMesh + 1] = Mesh(ss.GetWaterMaterial())
    end

    if #ss.WaterMesh == 0 then return end
    mesh.Begin(ss.WaterMesh[nummeshes], MATERIAL_TRIANGLES, math.min(NumMeshTriangles, MAX_TRIANGLES))
    local function ContinueMesh()
        if mesh.VertexCount() < MAX_TRIANGLES * 3 then return end
        mesh.End()
        mesh.Begin(ss.WaterMesh[nummeshes + 1], MATERIAL_TRIANGLES,
        math.min(NumMeshTriangles - MAX_TRIANGLES * nummeshes, MAX_TRIANGLES))
        nummeshes = nummeshes + 1
    end
    local function PushVertex(pos)
        mesh.Normal(vector_up)
        mesh.Position(pos + vector_up * INK_SURFACE_DELTA_NORMAL)
        mesh.TexCoord(0, pos.x, pos.y)
        mesh.TexCoord(1, pos.x, pos.y)
        mesh.AdvanceVertex()
    end

    for _, f in ipairs(ss.WaterSurfaces) do
        local v = f.Vertices
        for i = 2, #v - 1 do
            PushVertex(v[1])
            PushVertex(v[i])
            PushVertex(v[i + 1])
            ContinueMesh()
        end
    end
    mesh.End()
end

function ss.PrepareInkSurface(data)
    ss.AABBTree = ss.DesanitizeJSONLimit(data.AABBTree)
    ss.MinimapAreaBounds = ss.DesanitizeJSONLimit(data.MinimapAreaBounds)
    ss.SurfaceArray = ss.DesanitizeJSONLimit(data.SurfaceArray)
    ss.WaterSurfaces = ss.DesanitizeJSONLimit(data.WaterSurfaces)
    ss.AreaBound  = data.UVInfo.AreaBound
    ss.AspectSum  = data.UVInfo.AspectSum
    ss.AspectSumX = data.UVInfo.AspectSumX
    ss.AspectSumY = data.UVInfo.AspectSumY
    ss.SURFACE_ID_BITS = select(2, math.frexp(#ss.SurfaceArray))
    ss.BuildInkMesh()
    ss.BuildWaterMesh()
    ss.ClearAllInk()
    ss.InitializeMoveEmulation(LocalPlayer())
    net.Start "SplatoonSWEPs: Ready to splat"
    net.WriteString(LocalPlayer():SteamID64() or "")
    net.SendToServer()
    ss.WeaponRecord[LocalPlayer()] = util.JSONToTable(
    util.Decompress(file.Read "splatoonsweps/record/stats.txt" or "") or "") or {
        Duration = {},
        Inked = {},
        Recent = {},
    }

    ss.RenderTarget.Ready = true
    collectgarbage "collect"
end
