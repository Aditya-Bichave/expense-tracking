# Stage 1: Build
FROM ubuntu:latest AS build

# Prerequisites
RUN apt-get update && apt-get install -y curl git unzip

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable web
RUN flutter config --enable-web

WORKDIR /app
COPY . .

# Get dependencies
RUN flutter pub get

# Build
RUN flutter build web --release

# Stage 2: Serve
FROM nginx:alpine

# Copy build artifacts
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
