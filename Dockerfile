# Multi-stage build optimized for Strapi + Sharp on Alpine
FROM node:20-alpine AS base

# Install system dependencies required for native modules
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    vips-dev \
    pkgconfig \
    libc6-compat

WORKDIR /app
RUN corepack enable

# Dependencies stage
FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
RUN pnpm install --frozen-lockfile
# Force install sharp for Alpine Linux specifically
RUN pnpm add sharp@latest --platform=linuxmusl --arch=x64

# Build stage
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NODE_ENV=production
RUN pnpm run build
RUN pnpm prune --prod

# Production stage
FROM node:20-alpine AS production
RUN apk add --no-cache dumb-init vips

WORKDIR /app

# Create user
RUN addgroup -g 1001 -S nodejs && adduser -S strapi -u 1001

# Copy application
COPY --from=build --chown=strapi:nodejs /app/build ./build
COPY --from=build --chown=strapi:nodejs /app/node_modules ./node_modules
COPY --from=build --chown=strapi:nodejs /app/package.json ./
COPY --from=build --chown=strapi:nodejs /app/config ./config
COPY --from=build --chown=strapi:nodejs /app/database ./database
COPY --from=build --chown=strapi:nodejs /app/src ./src
COPY --from=build --chown=strapi:nodejs /app/public ./public

USER strapi
EXPOSE 1337

CMD ["dumb-init", "node", "node_modules/@strapi/strapi/bin/strapi.js", "start"]
