# Use Debian-based Node instead of Alpine to avoid sharp issues
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
RUN pnpm run build
RUN pnpm prune --prod

# Production stage
FROM node:20-slim AS production

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    libvips42 \
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Create non-root user
RUN groupadd -g 1001 nodejs && useradd -r -u 1001 -g nodejs strapi

# Copy built application with correct ownership
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
