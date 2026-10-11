-- Studio Command Bar helper. Run AFTER importing the 20 GLBs using File > Import.
-- Finds imported models in Workspace. Moves and renames them into
-- ReplicatedStorage > SackAssets > Meshes > Sack_01 .. Sack_20.
-- Does NOT import any files from disk (Lua cannot read your PC files).
local RS=game:GetService("ReplicatedStorage")
local Selection=game:GetService("Selection")
local assets=RS:FindFirstChild("SackAssets") or Instance.new("Folder")
assets.Name="SackAssets";assets.Parent=RS
local meshes=assets:FindFirstChild("Meshes") or Instance.new("Folder")
meshes.Name="Meshes";meshes.Parent=assets
local seen={}
local function tierFrom(name)
    local n=name:lower():match("kick[%s_%-]*sack[%s_%-]*0?(%d%d?)") or name:lower():match("^sack[%s_%-]*0?(%d%d?)")
    n=tonumber(n)
    if n and n>=1 and n<=20 then return n end
end
local picked=Selection:Get()
if #picked==0 then
    picked={}
    for _,inst in ipairs(workspace:GetChildren()) do
        if inst:IsA("Model") then table.insert(picked,inst) end
    end
end
for _,item in ipairs(picked) do
    if item:IsA("Model") then
        local n=tierFrom(item.Name)
        if n then
            local dest=string.format("Sack_%02d",n)
            if meshes:FindFirstChild(dest) then
                warn("Already exists, skipping "..dest)
            else
                item.Name=dest
                item.Parent=meshes
                seen[n]=true
                print("Prepared",dest)
            end
        end
    end
end
for i=1,20 do
    if not meshes:FindFirstChild(string.format("Sack_%02d",i)) then warn(string.format("Missing sack model: Sack_%02d",i)) end
end
print("Import setup checked. Mesh folder:",meshes:GetFullName())
