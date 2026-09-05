
## What's New / App Updates

`lib/main.dart` reads `app_updates.json` at runtime and caches the last successful feed in SharedPreferences. The GitHub Pages build runs `tool/generate_app_updates.py` before building the web app, which starts with the curated `app_updates_seed.json` entries and adds recent Git commit subjects as app-change entries. This means future feature commits can automatically appear in What's New when the project is pushed and redeployed.

For best results, use descriptive Git commit messages such as `Add pediatric airway tool` or `Update Transfer Protocol layout` instead of generic messages such as `Upload files`.
