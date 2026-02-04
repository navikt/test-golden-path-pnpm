FROM cgr.dev/chainguard/wolfi-base@sha256:2bdab5abde97a1487c667d3ffcc7265fa9abdeb5b2365bca9a64a5f3afc5a563 AS base

# Install Node.js and enable pnpm
RUN apk update && apk add --no-cache nodejs-20 npm && npm install -g corepack && corepack enable

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS builder

WORKDIR /app

# Copy package files and .npmrc
COPY package.json pnpm-lock.yaml* .npmrc ./

# Install dependencies with cache mount
RUN --mount=type=secret,id=NODE_AUTH_TOKEN \
    --mount=type=cache,id=pnpm,target=/pnpm/store \
    if [ -f /run/secrets/NODE_AUTH_TOKEN ]; then \
        export NODE_AUTH_TOKEN=$(cat /run/secrets/NODE_AUTH_TOKEN); \
    fi && \
    pnpm install --frozen-lockfile

# Copy source files and build
COPY . .
RUN pnpm run build

FROM cgr.dev/chainguard/wolfi-base@sha256:2bdab5abde97a1487c667d3ffcc7265fa9abdeb5b2365bca9a64a5f3afc5a563 AS runtime

# Install only Node.js runtime (no npm/corepack needed in runtime)
RUN apk update && apk add --no-cache nodejs-20

WORKDIR /app

COPY --from=builder /app/.next/standalone /app
COPY --from=builder /app/.next/static /app/.next/static
COPY --from=builder /app/public /app/public

EXPOSE 3000

ENV NODE_ENV=production

CMD ["node", "server.js"]
