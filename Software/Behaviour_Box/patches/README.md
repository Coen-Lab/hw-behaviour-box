# Patches behind the modified packages in `local_packages/`

Two packages in `local_packages/` carry DLLs built from upstream source with a small patch. The patches are here so the DLLs can be rebuilt, checked or dropped once upstream has the fix.

| Package | Upstream base | Patch | What it changes | DLL SHA-256 |
|---|---|---|---|---|
| `Bonsai.FFmpeg.0.2.0-uniquepipe` | [bonsai-rx/ffmpeg](https://github.com/bonsai-rx/ffmpeg) tag `v0.2.0` = `ee403aeca3d6ecb214487a5c41d94b2f2b541526` | `bonsai-ffmpeg-unique-pipe.patch` | `VideoWriter` names its pipe after the file stem plus a GUID, so a **Start** while the previous recording's ffmpeg is still draining no longer fails with "All pipe instances are busy." | `ecb50c0d0618e5e31969d9c7a45a1b82a7f362db97a5cc831e884087433a5403` |
| `UclOpen.Video.0.0.0-sandbox-fullframe` | [ucl-open/ucl-open](https://github.com/ucl-open/ucl-open) `c3dc68bf2fa752a75f25591c55c640138f6afd4f` | `ucl-open-triggered-spinnaker-full-frame.patch` | `TriggeredSpinnaker` resets `OffsetX`/`OffsetY` to 0 and `Width`/`Height` to their maxima after setting binning, so a camera with a smaller stored region records the full sensor | `f6a26abad20632ae3e6f10535b46d073d34668a21d9575bd7b6e2088dc713cf3` |

Each DLL was built with `dotnet build -c Release` (.NET SDK 8.0.426) from the base commit with its patch applied (`git apply <patch>`), then put into the package from nuget.org (`Bonsai.FFmpeg` 0.2.0, signature removed) or from ucl-open's own build (`UclOpen.Video`), with a distinct version so a machine that already has the unpatched package restores the patched one instead of keeping its old folder. Licences are in `THIRD-PARTY-NOTICES.md` at the repository root.

When upstream ships the fix, switch `Bonsai.config` back to the upstream package and delete the patched `.nupkg` and its patch here.
