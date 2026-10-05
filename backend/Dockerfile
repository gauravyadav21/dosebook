# DoseBook backend for a container host (Render). See docs/05-delivery/deployment.md.
# One stage on purpose: the Prisma CLI is needed at start-up to apply migrations, and it is a dev dependency.
FROM node:20-slim

# Prisma's engines need OpenSSL.
RUN apt-get update && apt-get install -y --no-install-recommends openssl ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# The schema comes first: `npm ci` runs `prisma generate` in its postinstall step.
COPY package.json package-lock.json prisma.config.ts ./
COPY prisma ./prisma
RUN npm ci

COPY nest-cli.json tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN npm run build

ENV NODE_ENV=production
# Do not run as root.
USER node

EXPOSE 3000
# Brings the database up to the current migrations, then starts. PORT is set by the host.
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main.js"]
