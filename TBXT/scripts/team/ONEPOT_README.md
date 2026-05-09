# onepot.ai automation (`onepot_query.py`)

Small Playwright script that submits SMILES to <https://www.onepot.ai/> and
writes a CSV with the result count + top-similarity %.

The site uses end-to-end encryption (RSA-OAEP + AES-256-GCM in the browser),
so we drive a real browser instead of hitting an HTTP API. Verified working
against the live site on 2026-05-09.

## Setup

```bash
# Use the project's tbxt conda env, or any Python ≥3.10
pip install playwright
playwright install chromium
```

### WSL2 / Linux only

The script needs a real graphics context — headless mode hangs because the
site does WebGL + heavy crypto work. On WSL2 use the WSLg display:

```bash
export DISPLAY=:0
```

If `playwright install chromium` complains about your distro (e.g. on
Ubuntu 26.04 "Resolute Raccoon"), the script auto-sets
`PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64` to pull a compatible
binary. Also install Chromium's runtime libs once:

```bash
sudo apt install -y libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
  libcups2 libdrm2 libxkbcommon0 libatspi2.0-0 libxcomposite1 \
  libxdamage1 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 \
  libcairo2 libasound2t64
```

## Run

```bash
# Default: 3 test SMILES, balanced depth, headed browser, 10s rate-limit
python TBXT/scripts/team/onepot_query.py

# Your own input — CSV with columns: id, smiles
python TBXT/scripts/team/onepot_query.py \
    --input  TBXT/report/final_4_picks.csv \
    --output TBXT/data/onepot_picks.csv

# Resume after a crash (skips ids already in output)
python TBXT/scripts/team/onepot_query.py --resume
```

## Output schema

| column | meaning |
|---|---|
| `id` | from input CSV |
| `smiles` | from input CSV |
| `status` | `ok` / `no_routes` / `error` / `skipped_placeholder` |
| `n_routes` | molecules returned by onepot at chosen depth |
| `top_route_score` | first similarity % shown (proxy for top-hit quality) |
| `raw_html_snippet` | first 500 chars of body text — for debugging |
| `timestamp` | UTC ISO |
| `error` | non-empty when `status=error` |

## Wall-time

~17 sec / SMILES at default `--rate-limit-s 10`. 60 picks ≈ 17 min.

## Caveats

- Selectors are scraped from the live site and may break on a Next.js redeploy.
  If the script suddenly returns `status=error` for everything, open
  https://www.onepot.ai/ in DevTools and reconfirm the selectors near the top
  of `onepot_query.py`.
- onepot.ai's depth selector (Quick / Balanced / Comprehensive) is not exposed
  on the homepage as of 2026-05-09 — the site default is "Balanced" (50
  results). The `--depth` flag is a no-op for now.
- Be polite: keep `--rate-limit-s ≥ 10` and don't scrape thousands of
  compounds without first emailing onepot.ai.
