# ---------- Build stage ----------
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Copy project files
COPY . .

# Install deps
RUN flutter pub get

# Build Flutter web release
ARG API_BASE_URL
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ---------- Run stage ----------
FROM nginx:alpine

# Replace nginx config to support SPA routing + good caching
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built web output
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
