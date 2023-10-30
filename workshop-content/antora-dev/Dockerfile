FROM docker.io/antora/antora

RUN \
  apk add git \
  && \
  yarn install \
  && \
  npm install -g gulp-cli

CMD ["gulp"]
