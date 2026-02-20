# ---------- Build stage ----------
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Copy project files
COPY . .

# Install deps
RUN flutter pub get

# Build Flutter web release
ARG API_BASE_URL
# Use --no-wasm-dry-run to suppress warnings about dart:ffi which is not supported on web
# Use quoted dart-define to handle spaces/empty values safely
RUN flutter build web --release --no-wasm-dry-run "--dart-define=API_BASE_URL=${API_BASE_URL}"

# ---------- Run stage ----------
FROM nginx:alpine

# Replace nginx config to support SPA routing + good caching
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built web output
COPY --from=build /app/build/web /usr/share/nginx/html

# EXPOSE $PORT  <-- Render sets PORT env var. Nginx must listen on it.
CMD ["/bin/sh", "-c", "sed -i 's/listen 80;/listen '\"${PORT:-80}\"';/g' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
