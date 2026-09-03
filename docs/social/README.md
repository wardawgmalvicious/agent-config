# Social preview

The GitHub **social preview** card for this repo — the image GitHub
serves as the Open Graph / Twitter-card thumbnail when a link to the
repo is unfurled in Slack, Teams, a browser tab preview, or a social
post. It is not shown anywhere on the repo page itself, so the only way
to check it is to unfurl a link.

| File | What it is |
| --- | --- |
| `social-preview.html` | The design, as source. Edit this, not the PNG. |
| `social-preview.png` | The rendered card, 1280x640. What gets uploaded. |

The PNG is committed because it is the deliverable, but it is
**generated** — treat it as build output that happens to be tracked, and
never touch it by hand. Re-render after any edit to the HTML.

## Re-rendering

Headless Edge, which is present on any Windows 11 box, so this needs no
install step. From the repo root, in `pwsh`:

```powershell
$edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
$src  = (Resolve-Path docs/social/social-preview.html).Path
$out  = (Join-Path (Get-Location) 'docs/social/social-preview.png')
& $edge --headless=new --disable-gpu --hide-scrollbars `
        --window-size=1280,640 --screenshot="$out" "file:///$src"
```

Edge writes the file and prints `N bytes written to file ...`. Confirm
the dimensions afterwards — a wrong `--window-size` fails silently by
producing a correct-looking image at the wrong size:

```powershell
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($out); "$($img.Width)x$($img.Height)"; $img.Dispose()
```

The renderer is Edge only because it is already installed; nothing in
the design depends on it. Any Chromium `--screenshot` produces the same
output, and the fonts (`Segoe UI`, `Cascadia Code`) are Windows
built-ins with declared fallbacks, so a render on another OS degrades to
a substituted typeface rather than breaking.

## Uploading it

GitHub does not read this file — it is not a magic path, and there is no
convention that picks it up. The card has to be uploaded by hand:

**Settings → General → Social preview → Edit → Upload an image.**

So a re-render is only half the job; the upload is the other half, and
nothing warns when the committed PNG and the uploaded one have drifted
apart.

## Design constraints

- **1280x640** is GitHub's recommended size, and the upload is capped at
  **1 MB**.
- Keep everything meaningful inside a **40pt safe border**. Consumers
  crop the card to their own aspect ratios, and what gets trimmed is the
  edges. Content here is inset 100px horizontally and 76-84px
  vertically, well clear of it.
- **Assume it is read at thumbnail size.** Most unfurls render it around
  half these dimensions or smaller, which is why the repo name is set at
  96px and the smallest text on the card is 19px.
- **No logos.** Neither GitHub's mark nor the Microsoft product logos
  appear, deliberately: reproducing either on a promotional card is a
  trademark question rather than a design one, and the card reads fine
  without them.
- **No counts.** The card names the payload directories but never says
  how many skills or rules exist. Those numbers drift, a committed image
  is the worst possible place to keep a number current, and the repo
  already treats a restated count as a defect — see the activation
  contract note in the root `CLAUDE.md`.
