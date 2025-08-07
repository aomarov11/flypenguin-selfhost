# FlyPenguin Self-Hosted Mirror (Netlify)

This repo builds a **self-hosted** (fonts + images + CSS/JS) copy of `https://flypenguin.org/` on Netlify and **removes analytics (Yandex Metrica)** at build time.

## One-time setup (GitHub + Netlify)
1. Create a new GitHub repo (e.g., `flypenguin-selfhost`).
2. Upload these files (`netlify.toml`, `build.sh`) to the repo and push to GitHub.
3. In Netlify: **Add new site → Import from Git** → choose your repo.
4. Netlify will auto-detect `netlify.toml`:
   - Build command: `bash build.sh`
   - Publish dir: `public`
5. Click **Deploy**. Netlify will mirror the origin, collate Google Fonts locally, and publish everything under your new `*.netlify.app` domain.

## How it works
- Uses `wget` to mirror the origin + all page requisites (images, CSS, JS), and to fetch any Google Fonts CSS/WOFF2.
- Rewrites Google Fonts CSS to point to local `/assets/fonts/gstatic/...` files and swaps the `<link href="https://fonts.googleapis.com/...">` tag in `index.html` with a local `/assets/fonts/fonts.css` reference.
- Removes **Yandex Metrica** (`mc.yandex.ru`) `<script>` + `<noscript>` beacons from HTML.
- Publishes the sanitized, self-hosted site from the `public/` directory.

## Notes
- If the origin changes, just trigger a new Netlify deploy; it will pull the latest content.
- If additional external assets are referenced (e.g., icon sets, other CDNs), you can extend the `--domains=` list and add another rewrite block similar to the Google Fonts step.
- This build uses only standard Linux CLI tools available on Netlify build images.

## Local test (optional)
```bash
bash build.sh
npx serve public  # or python3 -m http.server -d public 8080
```

---
*This project is for demonstration/testing purposes. Respect third-party content and branding rights.*
