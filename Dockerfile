# syntax=docker/dockerfile:1

# ---------- 构建阶段 ----------
FROM node:20-slim AS builder
WORKDIR /app

# 先拷依赖清单，利用缓存
COPY package.json package-lock.json ./
RUN npm ci

# 拷全部源码
COPY . .

# 跳过激活界面的关键环境变量（构建期内联）
ENV NEXT_PUBLIC_SELF_HOSTED_MODE=true
# 构建时给足内存
ENV NODE_OPTIONS=--max-old-space-size=4096

RUN npm run build

# ---------- 运行阶段 ----------
FROM node:20-slim AS runner
WORKDIR /app

ENV NODE_ENV=production
# 云端必须监听 0.0.0.0，端口 3001
ENV HOST=0.0.0.0
ENV PORT=3001
ENV NEXT_PUBLIC_SELF_HOSTED_MODE=true

# 拷构建产物与运行所需文件
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/package-lock.json ./package-lock.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/app ./app
COPY --from=builder /app/data ./data
COPY --from=builder /app/assets ./assets
COPY --from=builder /app/custom-apps ./custom-apps
COPY --from=builder /app/components ./components
COPY --from=builder /app/lib ./lib
COPY --from=builder /app/styles ./styles
COPY --from=builder /app/middleware.ts ./middleware.ts
COPY --from=builder /app/next.config.mjs ./next.config.mjs
COPY --from=builder /app/tsconfig.json ./tsconfig.json
COPY --from=builder /app/postcss.config.mjs ./postcss.config.mjs
COPY --from=builder /app/next-env.d.ts ./next-env.d.ts

EXPOSE 3001

CMD ["node", "scripts/local-next-server.mjs", "--prod"]
