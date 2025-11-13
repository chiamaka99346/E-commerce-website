# Multi-stage build for optimized image size

# Stage 1: Build stage (if needed for any preprocessing)
FROM node:18-alpine AS builder

WORKDIR /build

# Copy all app files
COPY app/ .

# No build step needed for static HTML, but keeping this stage for future use
# If you add a build tool like npm/webpack later, add build commands here

# Stage 2: Production stage with Nginx
FROM nginx:1.25-alpine

# Remove default Nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy static files from app directory
COPY app/ /usr/share/nginx/html/

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Run Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
