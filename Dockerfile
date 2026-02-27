# Base Python for mkdocs
FROM python:3.11-alpine AS base
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Node base for app
FROM node:18-alpine AS app-base
WORKDIR /app
COPY app/package.json app/yarn.lock ./
COPY app/spec ./spec
COPY app/src ./src

# Run tests
FROM app-base AS test
RUN yarn install
RUN yarn test

# Create zip of the app
FROM app-base AS app-zip-creator
COPY --from=test /app/package.json /app/yarn.lock ./
COPY app/spec ./spec
COPY app/src ./src
RUN apk add --no-cache zip && zip -r /app.zip /app

# Dev container
FROM base AS dev
CMD ["mkdocs", "serve", "-a", "0.0.0.0:8000"]

# Build the mkdocs site
FROM base AS build
COPY . .
RUN mkdocs build

# Final Nginx container to serve static content
FROM nginx:alpine
COPY --from=app-zip-creator /app.zip /usr/share/nginx/html/assets/app.zip
COPY --from=build /app/site /usr/share/nginx/html