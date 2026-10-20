# Kick an Egg — shared development rules

Read `docs/DEVELOPMENT_HANDOFF.md`, then inspect Git status and the relevant diff before working. Read `CLAUDE.md` for repository conventions, but verify older gameplay descriptions against current source. Follow the user's current instructions when they supersede older plans.

## Project and collaboration
- GitHub `8yfy/kick-an-egg` is the source of truth. Check local worktrees for unsaved/uncommitted progress before choosing a checkpoint. `main` holds the latest assembled game (since #50), but check open PRs and branches for newer work.
- Work on a separate feature branch/worktree. Preserve other developers' changes; never force-push or automatically merge. Shared contracts (`Config/*`, `Remotes`, builder APIs) require a focused, coordinated change.
- Keep generated builds, scratch files and credentials out of commits. Preserve Rojo mappings and imported assets.
- The game targets a continuous 20-zone track and a catalog of 79 pets with corresponding eggs. Treat those as design targets; inspect current content before claiming completeness.
- Existing systems include kicking, sack training, egg chases, player pens, pets and progression. Do not alter unrelated gameplay during art, UI, audio, animation or VFX work.

## Art and implementation
- Preserve approved assets. Use classic blocky Roblox silhouettes, selective studs, vibrant colors, stylized materials, smooth animation and playful, poppy audio.
- Custom Blender models are allowed when appropriate; preserve the existing egg/pet block-data pipeline unless a change is approved. Avoid generic smooth fantasy shapes, stiff motion and excessive particles.
- Reuse rigs, modular geometry, materials, animation systems and effects. Save editable `.blend` sources; validate exports and Roblox integration. Never invent asset IDs or present placeholders as finished.
- Follow server-authoritative gameplay, data-driven balance, Luau strict typing and existing Init/Start patterns.

## Efficient execution
- Classify substantial tasks as low/medium/high complexity. High-complexity work needs checkpoints and one representative validated sample before batches.
- Locate files with focused `rg`/Git searches; read only relevant sections and dependencies. Load the smallest relevant skill set, not the entire catalog.
- Reuse documented findings, and update them when source changes. Do not repeatedly inspect unchanged files or regenerate approved assets.
- Diagnose actual errors, make a focused fix and retest. Change approach after repeated failures without new evidence.
- Validate in order: relevant syntax/static/unit checks, integration checks, then required Studio playtests and visual review. Do not skip necessary final checks to save usage.
- Preserve the user's model/reasoning settings; do not invent token percentages. Keep updates concise and factual. No subagents unless requested.
- Update the handoff after meaningful milestones: branch/commit, modifications, tests, limitations, pending uploads and next steps. Mark inherited test reports separately from tests performed this session.

## Tools
- Use installed Rojo 7.7.1 and the repository's existing project configuration. Do not replace the project layout.
- Studio MCP: select the correct instance, inspect its state, and use read-only checks before mutation. Do not overwrite an open place from a stale checkout.
- Blender MCP: use the existing Blender installation/add-on, localhost connection and disabled telemetry. Verify a persistent GUI scene before modeling. Avoid concurrent mutation by Claude and Codex; finish/save one client's operation before the other takes over.
- Consult `docs/CODEX_SETUP.md` for verified local setup and outstanding connection requirements.
