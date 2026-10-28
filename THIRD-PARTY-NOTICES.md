# Third-party notices

Everything in this repository is covered by the [MIT License](LICENSE) except the components listed
below, which are redistributed under their own terms.

## UclOpen packages

`Software/Behaviour_Box/local_packages/` contains five NuGet packages, redistributed as
binaries because they are not published on nuget.org and the workflow will not restore without them:

- `UclOpen.Core.0.0.0-sandbox`
- `UclOpen.Devices.0.0.0-sandbox`
- `UclOpen.Logging.0.0.0-sandbox`
- `UclOpen.Video.0.0.0-sandbox-fullframe`
- `UclOpen.Vision.0.0.0-sandbox`

They come from [ucl-open/ucl-open](https://github.com/ucl-open/ucl-open) at commit
`27892d3ee53b8297eeede92571668fed8c425248`, and each carries the licence text below in its own
`LICENSE` file. The `UclOpen.Video` package is modified and renamed `0.0.0-sandbox-fullframe`: its
DLL is a build of ucl-open commit `c3dc68bf2fa752a75f25591c55c640138f6afd4f` with a patch that
resets the camera region to the full sensor after setting binning
(`Software/Behaviour_Box/patches/ucl-open-triggered-spinnaker-full-frame.patch`).

```
BSD 3-Clause License

Copyright 2026 (c) University College London and Contributors

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

## Bonsai.FFmpeg

`Software/Behaviour_Box/local_packages/Bonsai.FFmpeg.0.2.0-uniquepipe.nupkg` is a modified copy of
[Bonsai.FFmpeg](https://github.com/bonsai-rx/ffmpeg) 0.2.0 (commit
`ee403aeca3d6ecb214487a5c41d94b2f2b541526`). The change gives each recording its own named pipe, so
starting a recording while the previous one is still being encoded no longer fails with "All pipe
instances are busy." The patch is `Software/Behaviour_Box/patches/bonsai-ffmpeg-unique-pipe.patch`.
It is redistributed under the MIT License, carried in the package's `LICENSE` file:

```
Copyright (c) Bonsai Foundation CIC and Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Not redistributed here

`Software/Setup.cmd` downloads Bonsai and restores the packages listed in `Bonsai.config` from
nuget.org at install time. None of those are stored in this repository, and each remains under its
own licence. Bonsai itself is MIT, copyright the Bonsai Foundation CIC and Contributors.

The Spinnaker SDK is installed by hand from Teledyne and is not redistributed in any form.
