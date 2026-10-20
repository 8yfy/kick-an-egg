# Blender source: none needed

**No Blender MCP was connected in this session.** No Blender tools were available to the session, so none was used.

The approved art direction (memory: "classic studded bricks") also rules out shipped meshes. Blender is only for design
previews.

So every weather centrepiece is a native-part brick recipe in Luau: `src/shared/VFX/WeatherFx/Sky.luau`. It uses
studded Plastic blocks, with Neon only for glow, and round shapes built as stepped voxel rows. The recipes are:

- `sun`
- `rainbow`
- `clouds`
- `aurora` (Beam ribbons)
- `eclipse`
- `halo`
- `portal` (Void Rift)
- `pylons` (Thunder Surge)
- `blooms` (Toxic Bloom)

They move with one `BulkMoveTo` per frame. They never collide, touch or block raycasts.

`Exported_Models/` is empty for the same reason.
