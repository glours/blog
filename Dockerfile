# syntax=docker/dockerfile:1

ARG HUGO_VERSION=0.154.2
ARG ALPINE_VERSION=3.21

# hugo downloads the Hugo binary
FROM alpine:${ALPINE_VERSION} AS hugo
ARG TARGETARCH
ARG HUGO_VERSION
WORKDIR /out
RUN apk add --no-cache wget tar
ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${TARGETARCH}.tar.gz .
RUN tar xvf hugo_extended_${HUGO_VERSION}_linux-${TARGETARCH}.tar.gz

# build-base is the base stage for development
FROM alpine:${ALPINE_VERSION} AS build-base
RUN apk add --no-cache \
    git \
    gcompat \
    libstdc++ \
    libgcc
WORKDIR /project
COPY --from=hugo /out/hugo /usr/local/bin/hugo
# Copy theme submodule first (less likely to change)
COPY themes themes
# Copy configuration
COPY config.yml .
# Copy static files
COPY static static
COPY layouts layouts
COPY archetypes archetypes
COPY assets assets
# Copy content last (most likely to change)
COPY content content

# development server with live reload
FROM build-base AS development
EXPOSE 1313
CMD ["hugo", "server", "--bind", "0.0.0.0", "--buildDrafts", "--disableFastRender"]

# production build
FROM build-base AS build
ARG HUGO_ENV="production"
ENV HUGO_ENV=${HUGO_ENV}
RUN hugo --gc --minify

# final production image (nginx)
FROM nginx:alpine AS production
COPY --from=build /project/public /usr/share/nginx/html
EXPOSE 80