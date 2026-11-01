# Material setup (Roblox)

Each pet has up to three mesh kinds. The mesh name ends in its kind: `<Name>_<Bone>_Solid`, `_Glow` or `_Crystal`.
Every kind samples a palette texture: a 256 × 256 grid of 32 px colour cells. The UVs point at cell centres, so the
colours stay crisp down to an 8 × 8 mip, and one mesh can carry many colours.

| Mesh kind | Blender material | Roblox setup |
|---|---|---|
| Solid | `M_<Name>_Solid`: colour, metalness and roughness images | MeshPart with a **SurfaceAppearance**: ColorMap = `Textures/<Name>_Color.png`, MetalnessMap = `<Name>_Metalness.png`, RoughnessMap = `<Name>_Roughness.png`. MeshPart.Color stays white. |
| Glow | `M_<Name>_Glow`: emission from `<Name>_GlowColor.png` | MeshPart with **Material = Neon**, TextureID = `Textures/<Name>_GlowColor.png`, Color white. |
| Crystal (Seraph) | `M_<Name>_Crystal`: colour plus alpha 0.75 from `<Name>_CrystalColor.png`, glossy | MeshPart with a **SurfaceAppearance**: ColorMap = `Textures/<Name>_CrystalColor.png`, **AlphaMode = Transparency**. Or Material = Glass, Transparency 0.2. |

## Metal values (Solid palette)

| Pet | Metallic colours | Metalness / roughness |
|---|---|---|
| Heavenly Lion | gold `E2B04A`, deep gold `C9932E` | 0.75 / 0.30-0.36 |
| Prism Seraph | gold `E0B24E`, deep gold `C4932F`, platinum `DCD8E6` | 0.75 / 0.30-0.36 (platinum 0.5 / 0.3) |
| Clockwork Titan | brass `C9A24E`, `A8823A`, light brass `F3D98C`; iron `34302D`, `4A4440` | brass 0.75 / 0.35-0.45; iron 0.6 / 0.55-0.6 |

Everything else (ivory, pearl, banner burgundy, ink) is dielectric at roughness 0.55.

## Fallbacks

- **Neon ignores the texture.** If a Neon MeshPart doesn't show its TextureID in your Roblox version (to be confirmed
  on the first import), set its Color to the main glow colour instead:
  - Lion `FFD966`;
  - Seraph `FFE38A`;
  - Titan `FFB84A`.
- **Glass looks too dark.** If the crystals read too dark under Glass, use the SurfaceAppearance route, which keeps
  the six prism hues.
- **Vertex colours.** The meshes also carry them (attribute `Col`). Any vertex-coloured MeshPart, including the
  EditableMesh preview, needs Color = white, because the part colour multiplies them.
