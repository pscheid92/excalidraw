# Excalidraw for excalidraw.k.patrickscheid.de: alswl's fork, which adds an
# HTTP storage backend, so collaboration rooms, their images and share links
# are kept on our own server instead of excalidraw.com's Firebase.
#
# The addresses are compiled into the app, so this image only works for that
# host. The cluster side (room server, storage backend, nginx config) lives in
# pscheid92/k8s, apps/excalidraw.

# The fork's release, pinned to its commit: a moved tag fails the build.
ARG EXCALIDRAW_REF=v0.18.1-fork-b2
ARG EXCALIDRAW_SHA=704168cd6d1759b6393c827e2182dad71a2ac5ac

FROM --platform=$BUILDPLATFORM docker.io/library/node:22-bookworm-slim AS build
ARG EXCALIDRAW_REF
ARG EXCALIDRAW_SHA
RUN apt-get update && apt-get install --no-install-recommends -y git ca-certificates \
 && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch "$EXCALIDRAW_REF" https://github.com/alswl/excalidraw.git /src \
 && test "$(git -C /src rev-parse HEAD)" = "$EXCALIDRAW_SHA"
WORKDIR /src
RUN yarn --frozen-lockfile --network-timeout 600000

# Vite takes VITE_* from the environment over its .env files.
ARG ORIGIN=https://excalidraw.k.patrickscheid.de
ENV VITE_APP_WS_SERVER_URL=$ORIGIN \
    VITE_APP_STORAGE_BACKEND=http \
    VITE_APP_HTTP_STORAGE_BACKEND_URL=$ORIGIN/api/v2 \
    VITE_APP_BACKEND_V2_GET_URL=$ORIGIN/api/v2/scenes/ \
    VITE_APP_BACKEND_V2_POST_URL=$ORIGIN/api/v2/scenes/ \
    VITE_APP_FIREBASE_CONFIG={} \
    VITE_APP_ENABLE_TRACKING=false \
    VITE_APP_DISABLE_TRACKING=true
RUN yarn build:app:docker
# Fails the build if any of excalidraw.com's collaboration, share-link or
# Firebase addresses made it into the app. (The public library's submit
# address stays: it's only used when you publish a library there.)
RUN if grep -rEo ".{60}(excalidraw-room-persistence\.(firebaseapp|appspot|firebaseio)|oss-collab\.excalidraw\.com|json\.excalidraw\.com).{60}" excalidraw-app/build; then exit 1; fi

FROM docker.io/library/nginx:stable-alpine-slim
COPY --from=build /src/excalidraw-app/build /usr/share/nginx/html
