FROM cgr.dev/chainguard/wolfi-base@sha256:1d95114038f76513a9ace6fca107d5582b08c65981f81f61cb56bf7fd2ef216d AS base

# Install Node.js and enable pnpm
RUN apk update && apk add --no-cache nodejs-24 npm && npm install -g corepack && corepack enable

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

FROM base AS builder

WORKDIR /app

ENV CI=true

# Copy package files and .npmrc
COPY package.json pnpm-lock.yaml* pnpm-workspace.yaml* .npmrc ./

# Install dependencies with cache mount
RUN --mount=type=secret,id=NODE_AUTH_TOKEN \
    --mount=type=cache,id=pnpm,target=/pnpm/store \
    if [ -f /run/secrets/NODE_AUTH_TOKEN ]; then \
        echo "//npm.pkg.github.com/:_authToken=$(cat /run/secrets/NODE_AUTH_TOKEN)" > /root/.npmrc; \
    fi && \
    pnpm install --frozen-lockfile

# Copy source files and build
COPY . .
RUN pnpm run build

FROM cgr.dev/chainguard/wolfi-base@sha256:1d95114038f76513a9ace6fca107d5582b08c65981f81f61cb56bf7fd2ef216d AS runtime

# Install only Node.js runtime (no npm/corepack needed in runtime)
RUN apk update && apk add --no-cache nodejs-24

WORKDIR /app

COPY --from=builder /app/.next/standalone /app
COPY --from=builder /app/.next/static /app/.next/static
COPY --from=builder /app/public /app/public

EXPOSE 3000

ENV NODE_ENV=production

CMD ["node", "server.js"]
