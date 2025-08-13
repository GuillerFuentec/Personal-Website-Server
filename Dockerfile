# Use multi-stage build for optimization
FROM node:20-alpine AS base
WORKDIR /app
RUN corepack enable
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# Dependencies stage
FROM base AS deps
RUN pnpm install --frozen-lockfile --prod=false

# Build stage
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NODE_ENV=production
RUN pnpm run build
RUN pnpm prune --prod

# Production stage
FROM node:20-alpine AS production
WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S strapi -u 1001

# Copy built application
COPY --from=build --chown=strapi:nodejs /app/dist ./dist
COPY --from=build --chown=strapi:nodejs /app/build ./build
COPY --from=build --chown=strapi:nodejs /app/node_modules ./node_modules
COPY --from=build --chown=strapi:nodejs /app/package.json ./package.json
COPY --from=build --chown=strapi:nodejs /app/public ./public
COPY --from=build --chown=strapi:nodejs /app/config ./config
COPY --from=build --chown=strapi:nodejs /app/database ./database
COPY --from=build --chown=strapi:nodejs /app/src ./src

# Set proper permissions
RUN chown -R strapi:nodejs /app

USER strapi

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:1337/_health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

EXPOSE 1337

# Use dumb-init for proper signal handling
CMD ["dumb-init", "node", "./node_modules/@strapi/strapi/bin/strapi.js", "start"]
