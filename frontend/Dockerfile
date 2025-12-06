FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache libc6-compat

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .

EXPOSE 3015

CMD ["npm", "run", "dev", "--", "-p", "3015", "-H", "0.0.0.0"]
