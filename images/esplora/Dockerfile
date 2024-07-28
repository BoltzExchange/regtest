FROM node:20 AS builder

WORKDIR /app

RUN git clone https://github.com/Blockstream/esplora.git .

RUN npm ci

ENV API_URL=http://localhost:4002/api
RUN npm run dist

FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 4002
