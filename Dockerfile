# Stage 1: Build Stage
FROM node:12 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
# RUN npm run build

# Stage 2: Production Stage
FROM node:12-slim AS production
WORKDIR /app
COPY --from=builder /app/package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY --from=builder /app/app.js ./app.js
COPY --from=builder /app/views/ ./views
EXPOSE 8000
CMD ["node", "app.js"] 
