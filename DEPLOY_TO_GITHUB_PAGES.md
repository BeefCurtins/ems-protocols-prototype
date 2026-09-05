# Publish the EMS Protocols prototype

This project is prepared to publish the Flutter web prototype to GitHub Pages.

## 1. Create a GitHub repository

Create a new repository on GitHub. For a private prototype, a GitHub plan that supports Pages for private repositories is required. A public repository can use GitHub Free.

Suggested repository name:

`ems-protocols-prototype`

## 2. Upload this project

Upload the contents of this ZIP to the repository's `main` branch, keeping the `.github/workflows/deploy.yml` file in place.

The easiest method on Windows is GitHub Desktop, but the GitHub website can also be used for smaller projects.

## 3. Enable GitHub Pages

In the repository:

Settings → Pages → Build and deployment → Source → **GitHub Actions**

## 4. Deploy

Push/commit the files to `main`. The included GitHub Actions workflow will:

- install Flutter
- run `flutter pub get`
- build the release web app
- configure the correct repository base path
- publish `build/web` to GitHub Pages

GitHub will show the published URL under Settings → Pages after the workflow completes.

The resulting address will normally look like:

`https://YOUR-GITHUB-USERNAME.github.io/ems-protocols-prototype/`

## 5. Use it on your iPhone

Open that URL in Safari. You can then use Safari's Share menu → **Add to Home Screen** for a convenient prototype icon.

## Important

This is a prototype deployment of the Flutter web version, not a native iOS application. The protocol data bundled in the project remains client-side; the site does not require a separate protocol database or API.
