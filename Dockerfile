# -----------------------------
# Stage 1: Python base for mkdocs
# -----------------------------
FROM python:3.11-alpine AS base

WORKDIR /app

# Install system dependencies (for pip packages if needed)
RUN apk add --no-cache gcc musl-dev libffi-dev

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


# -----------------------------
# Stage 2: Node base for frontend app
# -----------------------------
FROM node:18-alpine AS app-build

WORKDIR /app

# Copy only necessary app files
COPY app/package.json app/yarn.lock ./
RUN yarn install

COPY app/src ./src
COPY app/spec ./spec

# Optional: run tests
RUN yarn test || true


# -----------------------------
# Stage 3: Create zip file
# -----------------------------
FROM node:18-alpine AS app-zip

WORKDIR /app

RUN apk add --no-cache zip

COPY --from=app-build /app /app

RUN zip -r /app.zip /app


# -----------------------------
# Stage 4: Build mkdocs site
# -----------------------------
FROM base AS build

WORKDIR /app
COPY . .

RUN mkdocs build


# -----------------------------
# Stage 5: Final Nginx Image
# -----------------------------
FROM nginx:alpine

# Create assets directory
RUN mkdir -p /usr/share/nginx/html/assets

# Copy built static site
COPY --from=build /app/site /usr/share/nginx/html

# Copy app zip
COPY --from=app-zip /app.zip /usr/share/nginx/html/assets/app.zip

EXPOSE 80