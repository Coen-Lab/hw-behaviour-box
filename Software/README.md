# Software

Three components:

- **Spinnaker SDK (SpinView)** — camera driver and configuration
- **FFmpeg** — video encoding, started by Bonsai for each recording
- **Bonsai** — acquisition, encoder recording, trigger control and data saving

Install them in that order: Bonsai cannot see the camera without the Spinnaker driver, and `Setup.cmd`
checks FFmpeg.

---

## Spinnaker SDK (SpinView)

Spinnaker is Teledyne FLIR's official package. It provides the camera driver and lets you configure
image size, exposure time, gain, frame rate and trigger mode.

Download it from
[Teledyne Vision Solutions](https://www.teledynevisionsolutions.com/support/support-center/software-firmware-downloads/iis/spinnaker-sdk-download/spinnaker-sdk--download-files/?pn=Spinnaker+SDK&vn=Spinnaker+SDK).
An account is needed, so this step cannot be scripted and must be done by hand.

> **Important**
>
> Bonsai works only with Spinnaker SDK **4.2.0.83**. Pick the version deliberately: the download page
> defaults to the latest.
>
> This is upstream's requirement, not a local quirk. `Bonsai.Spinnaker 0.9.1` states it in its package
> description and ships a matching `SpinnakerNET_v140.dll` at exactly 4.2.0.83. The package provides
> the managed wrapper while the SDK provides the native runtime, and the two are version-locked, so a
> mismatch fails at interop and shows up as the camera simply not appearing.

---

## Bonsai

Install FFmpeg first, which encodes the video: run `winget install --id Gyan.FFmpeg -e` and open a
new terminal so it is on PATH. That installs it for the current Windows account only; add
`--scope machine`, from an administrator terminal, if other accounts record on the same computer. Then run [`Setup.cmd`](Setup.cmd) once. It downloads Bonsai, restores
the packages listed in `Bonsai.config` from nuget.org and `local_packages/`, and checks that FFmpeg can
encode with Intel Quick Sync.

Then, because of compatibility patches in this project, open the workflow manually rather than
launching it directly:

1. Open **Bonsai**.
2. Select **File → Open**.
3. Open **`Behaviour_Box.bonsai`**.

With the workflow loaded, click the blank workspace to bring up the experiment settings in the
**Properties** panel on the right. Set before each recording:

- Save directory
- 8-digit camera serial number
- Session ID
- Subject ID
- Trial length (minutes)

The same panel also carries the settings you change rarely rather than per recording: `PortName`,
`ExposureTime`, `Gain`, `Binning`, `TrackingThreshold`, `CountsPerRev` and `WheelDiameterMm`. None
of them require opening a group.

Recording stops automatically at the trial length, saving a **CSV** of behavioural data and a
**video**.

### Serial port

One thing is set once per machine rather than per recording. The Harp Behaviour Board appears as a
COM port, and the workflow ships pointing at **COM3**, which will be wrong on most computers. Find
the board in Device Manager under **Ports (COM & LPT)**, then set **PortName** in the same
**Properties** panel.

Get this wrong and the workflow fails on startup without saying why.

### Data output

Each recording gets its own folder, built from the settings above:

```
<save directory>\sub-<SubjectId>\ses-<SessionId>_date-<yyyy-MM-ddTHH-mm-ss>
```

The date is the UTC time at which the workflow started, so a late-evening session in British
Summer Time files under the following day. The folder holds `LogData.csv` and
`VideoData_Camera.avi`, the video written as H.264 in an AVI container (see
[Video encoding](#video-encoding)).

The CSV has one row per camera frame, with a header:

| Column | Meaning |
|---|---|
| `Seconds` | Harp clock time of the frame trigger, in seconds |
| `Timestamp` | Camera chunk timestamp |
| `FrameID` | Camera frame counter |
| `ExposureTime` | Exposure set in the workflow (`ExposureTime` property), in microseconds |
| `MouseLocation.X` | Mouse centroid, pixels from the left edge of the image |
| `MouseLocation.Y` | Mouse centroid, pixels from the top edge of the image |
| `WheelDistance` | Cumulative distance run since the recording started, in cm |

The centroid is a `Point2f`, which Bonsai's CsvWriter splits into the two dotted columns above
rather than one combined field, so the file has seven columns. The origin is the top-left pixel and
Y increases downwards, following OpenCV.

`MouseLocation.X` and `MouseLocation.Y` are `NaN` on any frame where tracking found nothing. The
threshold segments pixels darker than 35, so an empty box gives `NaN` on every row, which is the
correct answer rather than a fault. Occasional `NaN` mid-session means the animal was momentarily
lost; a session that is entirely `NaN` with an animal present means the threshold needs raising for
the current lighting.

`Seconds` is the Harp board's own record of when it fired the trigger. Frames are matched to
triggers in the camera node itself (UclOpen's `TriggeredSpinnaker` with the trigger events as its
input): gaps in `FrameID` are filled before pairing, so a frame the computer drops leaves a gap in
`FrameID` and every later row keeps its correct `Seconds`. Only Harp `Event` messages count as
triggers, and the Harp starts triggering 5 s after **Start**, once the camera is armed, so the
first row is paired correctly too. To check a session, compare the camera's own `Timestamp` against
`Seconds`: the offset between the two clocks should be a straight line (the two clocks drift by
about 15 ppm), and a step of one frame period means the pairing has slipped.

The frame's `FrameID` and `Timestamp` are copied inside the camera callback. Reading the camera's
chunk data later, after Spinnaker has released the image, crashed Bonsai on the second or later
**Start** in a session, so do not go back to the `UclOpen.Devices:TriggeredSpinnaker.bonsai`
include, which does exactly that.

Acquisition constants, all set in the workflow:

| | Value |
|---|---|
| Frame rate | 50 Hz, camera hardware-triggered by the Harp board |
| Exposure | 10 ms |
| Gain | 5 dB |
| Binning | 1, so the full 1440 x 1080 sensor is recorded |
| Encoder counts per revolution | 4096 (1024 ppr, quadrature decoded x4) |
| Wheel diameter | 150 mm, so a circumference of 47.12 cm |
| Distance per encoder count | 0.0115 cm |

`WheelDistance` accumulates the per-sample encoder difference, with 16-bit counter wraparound
corrected, so it increases monotonically while the animal runs forwards and is not reset within a
session. Change `CountsPerRev` or `WheelDiameterMm` in the top-level **Properties** panel if you use
a different encoder or wheel, or the distances will be silently wrong.

The board is put in **Position** mode, so the encoder register reports an absolute count that the
workflow differences, unwraps and re-accumulates. UclOpen's own `RunningWheel` uses **Displacement**
mode instead, and that is deliberately not copied here: it reports differences already, so the same
chain would difference them twice and the distances would be meaningless.

---

## Camera settings

The workflow ships with recommended settings and should not need changing. If it does:

### Exposure time, gain and binning

Click the blank workspace at the top level. `ExposureTime`, `Gain` and `Binning` sit in the same
**Properties** panel as the per-recording settings, so there is no need to open the `metadata` group.

The order to tune them in is exposure first, then gain, then binning:

- **Exposure** buys image quality for free, so make it as long as the frame period allows. At 50 Hz
  a frame lasts 20 ms, and the shipped 10 ms leaves half the period spare, so this is the first
  thing to raise if the image is too dark. Going over the frame period does not slow the camera down
  gracefully: it drops triggers, and because frames are paired with trigger events in order, a
  dropped one shifts every timestamp after it.
- **Gain** amplifies noise along with signal, so keep it as low as the image allows. Reach for it
  only once exposure is maxed out and the picture is still too dark, and prefer adding IR
  illumination instead.
- **Binning** is the file-size control. It sums neighbouring pixels, so it brightens the image and
  cuts noise, at the cost of resolution. The box ships at binning 1, recording the full 1440 x 1080
  sensor. Binning 2 gives 720 x 540, quarters the data rate and brightens the image about fourfold,
  which is worth having if storage or the encoder become the limit.

### A cropped image

The workflow sets binning but not the region of interest, because `TriggeredSpinnaker` does not
expose one. `OffsetX`, `OffsetY`, `Width` and `Height` are therefore whatever is stored on the
camera, and Bonsai accepts them. A camera left with a small region records a cropped frame, and the
CSV looks identical either way.

The trap is that changing binning in SpinView does not re-expand the region. It stays at its old
pixel values, so the image crops rather than rescaling. To reset it, with Bonsai closed:

1. Set `OffsetX` and `OffsetY` to 0. The offsets must come down before the size can go up.
2. Set `Width` and `Height` to their maxima. At binning 1 that is 1440 x 1080.

To make it survive a power cycle, save it to the camera: set `UserSetSelector` to UserSet1, execute
`UserSetSave`, then set `UserSetDefault` to UserSet1. Otherwise the camera reverts to its stored
default whenever it loses power.

### Frame rate

The camera is hardware-triggered, so its frame rate is set by the Harp board rather than by the
camera. Changing it means changing three things together, or the recordings go wrong quietly:

1. **Trigger0Frequency** on the `CameraTriggerController` node, inside **metadata** then
   **BehaviorBoards**. This is the one that actually sets the rate.
2. The **frames-per-second multiplier** in the **logging** group, which turns the trial length in
   minutes into a frame count. If it disagrees with the trigger, recordings stop at the wrong
   length.
3. **FrameRate** on the `VideoWriter` node, inside **logging** then **LogVideo**. This only labels
   the AVI, but if it is wrong the video plays back at the wrong speed.

Check the exposure still fits inside the new frame period.

### Video encoding

The `VideoWriter` node in **logging** then **LogVideo** comes from `Bonsai.FFmpeg`. It does not
compress anything itself: it starts `ffmpeg.exe` and streams the raw frames to it, and ffmpeg encodes
H.264 on Intel Quick Sync, the hardware encoder in Intel's integrated graphics. `Bonsai.exe` is a
console program, so a black console window is open beside the editor from launch; ffmpeg shares it,
prints its progress there, and shows the reason there if encoding fails. Leave it open and do not
type in it. Pressing `q` in it stops ffmpeg alone, and the recording stops with "Pipe is broken".
Closing the window, or pressing Ctrl+C in it, kills Bonsai and ffmpeg together with no message: the
video up to that moment is finalised and plays, but the CSV loses its unwritten last second or so.
Pressing **Stop** in Bonsai is safe: ffmpeg finishes the file within a second. If ffmpeg is not
installed at all, the recording stops at once with "The system cannot find the file specified".
The package is a patched `Bonsai.FFmpeg` 0.2.0 from `local_packages/` (version `0.2.0-uniquepipe`):
the nuget.org build names its pipe after the video file, so pressing **Start** while the previous
recording was still being encoded failed with "All pipe instances are busy." and needed a Bonsai
restart.

Encoding used to happen inside Bonsai, on a single thread that needed most of a CPU core at 1440 x
1080 and 50 Hz. Whenever anything else was running it fell behind, the unwritten frames queued in
memory, and long sessions crashed once RAM filled. Quick Sync keeps up with CPU to spare.

The encoder settings are the node's `OutputArguments`:

```
-loglevel error -nostats -c:v h264_qsv -preset veryfast -global_quality 20 -bf 0 -pix_fmt nv12
```

`-global_quality` trades size against quality: lower is better and larger. On a machine without
Quick Sync, such as one with an AMD CPU, use the CPU encoder x264 instead, which spreads the work
across all cores and produces larger files:

```
-loglevel error -nostats -c:v libx264 -preset ultrafast -crf 18 -pix_fmt yuv420p
```

## Mouse centroid tracking

Position is estimated by **centroid tracking**. Compared with pose estimation or segmentation it is
computationally light, robust, and accurate enough for locomotion, which suits a standardised
screening platform.

The workflow thresholds each frame at `TrackingThreshold` and takes the centre of mass of every pixel
darker than it. There is no blob detection, so the position never jumps between pieces of the animal
when the body and a headstage or cable split apart against a wall. The flip side is that anything
dark in view pulls the centroid towards it, in proportion to its area: faeces, a dark cable, or a
corner the IR strip does not reach. Keep the box clean and evenly lit.

The centroid is in pixels, and nothing in the recording converts it to distance. The arena floor is
a 200 mm square, which gets you an approximate scale, but for anything quantitative calibrate your
own box: put a ruler or a printed grid on the floor, record a frame, and measure the millimetres per
pixel. The lens is a varifocal focused by hand, so the scale belongs to your box and changes the
moment anyone touches the zoom ring.

Nothing is classified online: if you need to know whether the animal was on the wheel or in the
arena, test the logged coordinates against a wheel region offline. Doing it after the fact means one
region definition applied identically to every session, rather than one drawn by hand per rig.

> **Note**
>
> The hardware and default parameters are optimised for **black mice**. For **white or light-coloured
> mice**, either:
>
> - Print the box in a darker colour to increase contrast, or
> - Adjust `TrackingThreshold` in the top-level **Properties** panel. It ships at 35 and segments
>   pixels *darker* than that value, so a light animal on a light floor needs the box inverted in
>   colour rather than the threshold nudged.
