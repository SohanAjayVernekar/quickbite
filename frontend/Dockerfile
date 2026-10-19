FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build
WORKDIR /app
ENV CI=true FLUTTER_SUPPRESS_ANALYTICS=true
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get --enforce-lockfile
COPY . .
ARG API_BASE_URL=http://localhost:8000
RUN flutter build web --release --no-pub --no-web-resources-cdn --no-wasm-dry-run --dart-define=API_BASE_URL=${API_BASE_URL}
FROM nginx:1.28.0-alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s CMD wget -q -O /dev/null http://127.0.0.1/healthz || exit 1
