#!/bin/sh
set -e

# Run database migrations if needed
echo "Running database migrations..."
node ./node_modules/@strapi/strapi/bin/strapi.js db:migrate

# Start the application
echo "Starting Strapi application..."
exec node ./node_modules/@strapi/strapi/bin/strapi.js start
