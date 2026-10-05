# CLAUDE.md

Open-source hardware and software for a mouse behaviour box: 3D-printed parts plus a Bonsai workflow that records 50 Hz video and running-wheel distance on one Harp clock. There is no application code, only CAD exports, Markdown docs, one Bonsai workflow and a Windows setup script.

## Layout

| Path | Holds | Go here for |
|---|---|---|
| `README.md` | Overview, bill of materials (with cost total), computer minimum spec, build guide, install order, run procedure, troubleshooting, licence | Part or price changes, run steps, troubleshooting text |
| `Assembly/README.md` | Print settings, assembly steps 1-5, tools | Print or assembly instructions |
| `Assembly/Wiring.md` | Camera, encoder (RJ45 Port 2) and Harp board connections | Wiring changes |
| `Assembly/Parts/*.stl` | One STL per unique printed part (five files, six prints) | Geometry updates |
| `Assembly/Parts/README.md` | Table of parts, print counts, dimensions | Keep in step with the STLs |
| `Assembly/Behaviour_Box_Complete.stl` / `.step` | Whole-box reference mesh (not printable) and the editable multi-component solid model | Design source and reference |
| `Assembly/Pictures/` | JPG and PNG used by the READMEs | Images referenced from the docs |
| `Software/README.md` | Spinnaker and Bonsai setup, settings, CSV format, acquisition constants, camera tuning, tracking | Anything about recorded data or settings |
| `Software/Setup.cmd` | Entry point that runs the setup script | Setup behaviour |
| `Software/Behaviour_Box/.bonsai/` | The Bonsai working folder: `Behaviour_Box.bonsai` (workflow XML), `Bonsai.config` (pinned packages), `NuGet.config`, `Setup.ps1`, `Settings/.bonsai/Behaviour_Box.editor` and `.layout` | Workflow, package or setup changes |
| `Software/Behaviour_Box/local_packages/` | Five `UclOpen.*.0.0.0-sandbox.nupkg` binaries, a NuGet source | Do not edit |
| `THIRD-PARTY-NOTICES.md` | Licence terms for the redistributed packages | Update if `local_packages/` changes |

## Build, run, test

There is no build system, test suite or CI in the repo (no package.json, pyproject, Makefile or workflows). The only executable path is Windows setup:

- `Software\Setup.cmd` runs `Setup.ps1` from `Software/Behaviour_Box/.bonsai/` with `powershell -ExecutionPolicy Bypass`. It checks the Spinnaker SDK version, checks `local_packages/` is non-empty, downloads Bonsai if `Bonsai.exe` is absent, then restores packages with `Bonsai.exe --no-editor`.
- Run the workflow by starting Bonsai, then File, Open, `Behaviour_Box.bonsai`. Never launch the `.bonsai` file directly.
- Verification is manual: open the workflow, check the live camera preview, record a short session, inspect `LogData.csv`.

## Conventions

- Docs are Markdown with one paragraph per line in the Software and Assembly files; keep tables aligned with the prose that cites them.
- The workflow exposes per-recording and rare settings on the top-level Properties panel through `ExternalizedMapping` entries in `Behaviour_Box.bonsai` (save directory, camera serial, subject ID, session ID, trial length, `PortName`, `ExposureTime`, `Gain`, `Binning`, `TrackingThreshold`, `CountsPerRev`, `WheelDiameterMm`). The workflow is organised in `metadata` and `logging` groups (`BehaviorBoards`, `LogVideo`, `RunningWheel`, `TotalFrame`, `FormatFileName`, `WheelDistanceCm` among the named nodes).
- Output folder pattern is `<save dir>\sub-<SubjectId>\ses-<SessionId>_date-<UTC timestamp>` holding `LogData.csv` and `VideoData_Camera.avi`.
- Constants quoted in several docs must stay consistent with the workflow: 50 Hz, 10 ms exposure, 5 dB gain, binning 1 (1440 x 1080), `CountsPerRev` 4096, wheel 150 mm, tracking threshold 35, default `PortName` COM3, Spinnaker 4.2.0.83.
- Part names and dimensions appear in `Assembly/README.md`, `Assembly/Parts/README.md` and the main README build table; update all together.

## Traps

- Spinnaker SDK must be exactly 4.2.0.83 (Bonsai.Spinnaker 0.9.1 is version-locked to it). The version appears in `Setup.ps1` (`$requiredSpinnaker`), `README.md` and `Software/README.md`; change all three.
- Changing the encoder or wheel means changing `CountsPerRev` or `WheelDiameterMm`, otherwise `WheelDistance` is silently wrong. The BOM notes and `Software/README.md` quote the alternatives (1440 for the 360 ppr Omron).
- Changing frame rate needs three edits together: `Trigger0Frequency` on `CameraTriggerController`, the frames-per-second multiplier in the `logging` group, and `FrameRate` on `VideoWriter`. Check exposure still fits the frame period.
- The encoder board mode is Position, deliberately; the workflow differences, unwraps and accumulates. Do not switch to Displacement.
- Frames are paired with Harp trigger events by arrival order, so a dropped trigger shifts later timestamps; the first CSV row is expected to be wrong.
- `.gitignore` excludes `**/.bonsai/Packages/`, `**/.bonsai/Bonsai.exe` and `Bonsai.exe.settings`. `local_packages/` must stay committed because nothing restores without it. Do not commit `Bonsai.exe`.
- `NuGet.config` is moved aside and restored around the Bonsai zip extraction in `Setup.ps1`, because the zip would overwrite it. Keep that ordering if editing the script.
- `Bonsai.config` pins package versions; the Bonsai download version is read from its `Bonsai` entry (currently 2.9.1).
- Bonsai rewrites `.editor` and `.layout` files in `Settings/.bonsai/` when the workflow is saved, so expect noisy diffs; the `.bonsai` XML is hand-editable but safest edited in the Bonsai editor.
- The STLs keep assembly coordinates (not centred), so they load away from the plate; this is documented, not a defect. `Behaviour_Box_Complete.stl` cannot be printed.
- Binary and large files (`.stl`, `.step`, `.nupkg`, images) are not diffable; do not read them wholesale.
- Windows only: the setup uses PowerShell, the registry for the Spinnaker check, and Bonsai.exe.

## Deeper docs

- Install order and run procedure: `README.md` sections "Installing the software" and "How to run the workflow".
- CSV columns, NaN handling, acquisition constants, camera region reset, frame rate, tracking: `Software/README.md`.
- Printing and assembly: `Assembly/README.md`; wiring: `Assembly/Wiring.md`; licences: `THIRD-PARTY-NOTICES.md`.
