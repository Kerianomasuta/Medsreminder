#BASE PHRASE
FROM node:24-alpine AS base
WORKDIR /app
COPY package*.json ./

#ENV DEV PHRASE
FROM base AS development

    #cai toan bo thu vien bao gom ca dependency
RUN npm install
    #copy src code vao container
COPY . .

    #lay ten app va setup hot-reload(reload server moi khi load code moi)
ARG APP_NAME
ENV APP_NAME_ENV=${APP_NAME}
CMD ["npm", "run", "start:dev"]

#BUILD CODE PHRASE
FROM base AS builder
RUN npm install
COPY . .

    #build app duoc chi dinh
ARG APP_NAME
RUN npm run build ${APP_NAME}

#PRODUCTION PHRASE
FROM node:24-alpine AS production
WORKDIR /app
ENV NODE_ENV=production

COPY package*.json ./
    #ignore dev dependencies
RUN npm ci --omit=dev

    #dem code da build tu phrase build
COPY --from=builder /app/dist ./dist

    #lay ten app de chay file main.ts
ARG APP_NAME
ENV APP_MAIN_FILE=dist/apps/${APP_NAME}/main.js
CMD node ${APP_MAIN_FILE}