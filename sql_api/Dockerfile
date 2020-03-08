# vim:set ft=dockerfile:
FROM node:10-alpine AS build

ARG APP_ENV=production
ARG SQL_API_VERSION=5.0.1

ENV NODE_ENV=$APP_ENV \
    PATH=$PATH:/vendor/bin \
    APP_ROOT=/app

RUN apk add --no-cache --update build-base \
                                git \
                                python \
                                py2-pip \
                                postgresql-dev \
                                nodejs \
                                tzdata \
                                git \
                                icu-dev \
                                curl \
                                ca-certificates && \
    git clone https://github.com/CartoDB/CartoDB-SQL-API.git /app && \
    cd /app && \
    git checkout $SQL_API_VERSION && \
    mkdir -p /app/logs && \
    npm config set loglevel info && \
    npm install --verbose

WORKDIR /app


COPY ./docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["sh", "-c", "node app.js $APP_ENV"]
