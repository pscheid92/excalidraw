# excalidraw

Excalidraw for [excalidraw.k.patrickscheid.de](https://excalidraw.k.patrickscheid.de),
with collaboration fully self-hosted.

The image is [alswl/excalidraw](https://github.com/alswl/excalidraw)
(a fork that adds an HTTP storage backend) built with this host's addresses
compiled in:

| What | Where |
|---|---|
| Live collaboration (WebSocket) | `/socket.io` → [kitsteam/excalidraw-room](https://github.com/kitsteam/excalidraw-room) |
| Room scenes, images, share links | `/api/v2` → [kitsteam/excalidraw-storage-backend](https://github.com/kitsteam/excalidraw-storage-backend) on Postgres |
| The app | everything else → this image |

Everything is end-to-end encrypted in the browser: the key is in the part of
the link after `#`, which never reaches the server.

The Kubernetes side lives in `pscheid92/k8s`, `apps/excalidraw`.

## Images

Every push to `main` builds `ghcr.io/pscheid92/excalidraw:YYYYMMDD-HHMMSS-<sha>`;
Flux in the cluster picks up the newest tag by itself.

## Updating the fork

Set `EXCALIDRAW_REF` and `EXCALIDRAW_SHA` in the `Dockerfile` to the fork's new
release tag and its commit, read its changes since the last one, and push.
The build fails if the tag doesn't point at that commit, or if the build still
contains excalidraw.com's collaboration or Firebase addresses.

## Our changes to the fork

`patches/self-hosted.patch`, applied before the build:

- All fonts come from this host. Upstream loads them from Excalidraw's CDN (DigitalOcean, New York) and warms up connections to Google Fonts, which tells both every visitor's address. The build fails if any of those addresses is left in the app.
- The main menu links the operator's legal notice and privacy policy on patrickscheid.de ("Legal notice", "Privacy").

To change it: clone the fork at `EXCALIDRAW_REF`, apply the patch, edit, and write `git diff` back into the file.
