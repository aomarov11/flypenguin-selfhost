# Netlify Mirror — Bulletproof + Querystring Fix

Fixes the Netlify deploy error:
> Invalid filename '...airline-logo.png?v1.1' (no '?' allowed)

How it works:
1) `build.sh` mirrors the site (wget may exit 8; ignored).
2) `postprocess.sh` copies mirror to `public/`, **renames files with `?`** to the clean name, **rewrites references** in HTML/CSS/JS, localizes Google Fonts if present, and strips Yandex Metrica.
3) `netlify.toml` runs both steps and publishes `public/`.

Deploy:
- Push these files to your repo and redeploy.
