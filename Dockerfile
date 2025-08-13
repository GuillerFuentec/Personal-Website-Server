# Use the official Node.js 18 image as base
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Enable corepack for pnpm support
RUN corepack enable

# Copy package files first for better caching
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the application
COPY . .

# Set NODE_ENV to production
ENV NODE_ENV=production

# Build the Strapi admin panel
RUN pnpm run build

# Expose the port that Strapi will run on
EXPOSE 1337

# Create a non-root user for security
RUN addgroup -g 1001 -S nodejs
RUN adduser -S strapi -u 1001

# Change ownership of the app directory to the strapi user
RUN chown -R strapi:nodejs /app
USER strapi

# Start the application
CMD ["pnpm", "start"]
