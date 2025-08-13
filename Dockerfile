# PRODUCTION-READY DOCKERFILE FOR STRAPI
FROM node:20-slim AS base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    libvips-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN corepack enable

# Dependencies stage
FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
RUN pnpm install --frozen-lockfile

# Build stage
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NODE_ENV=production

# Rebuild native dependencies for the current platform
RUN npm rebuild sharp
RUN npm rebuild better-sqlite3

RUN pnpm run build

# Production stage
FROM node:20-slim AS production

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libvips42 \
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create user with home directory FIRST
RUN groupadd -g 1001 nodejs && \
    useradd -r -u 1001 -g nodejs -m -d /home/strapi strapi && \
    chown -R strapi:nodejs /app

# Copy application files
COPY --from=build --chown=strapi:nodejs /app/build ./build
COPY --from=build --chown=strapi:nodejs /app/node_modules ./node_modules
COPY --from=build --chown=strapi:nodejs /app/package.json ./
COPY --from=build --chown=strapi:nodejs /app/config ./config
COPY --from=build --chown=strapi:nodejs /app/database ./database
COPY --from=build --chown=strapi:nodejs /app/src ./src
COPY --from=build --chown=strapi:nodejs /app/public ./public

# Switch to strapi user
USER strapi

# Set environment variables for production
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=1337

EXPOSE 1337

# Start application
CMD ["dumb-init", "node", "node_modules/@strapi/strapi/bin/strapi.js", "start"]
