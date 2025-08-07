# Bulletproof Netlify Deploy (Self-hosted snapshot)

This setup **ignores wget 404 exit codes** and performs a **fallback copy** so the
`public/` folder is always present. It mirrors flypenguin.org and publishes the snapshot.

- `build.sh` may return `8` (wget 404s). That's OK.
- `netlify.toml` still assembles `/public` from `mirror/flypenguin.org` and publishes it.
