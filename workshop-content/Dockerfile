FROM docker.io/antora/antora as builder

ARG CONSOLE_URL
ARG GIT_URL

ADD . /antora/

# Generate ui bundle if necessary - only necessary if we are not loading the
# ui bundle from github
#
#RUN if [ ! -f "./ui/build/ui-bundle.zip" ]; then cd ui; yarn install; npm install -g gulp-cli; gulp bundle; fi

# get rid of Edit this Page
ENV CI=true

RUN \
  apk add git \
  && \
  git config --global user.email "user@example.com" \
  && \
  git config --global user.name "Example User" \
  && \
  git init \
  && \
  git commit --allow-empty -m 'init' \
  && \
  antora generate --attribute console_url=$CONSOLE_URL --attribute git_url=$GIT_URL --stacktrace site.yml

FROM registry.access.redhat.com/rhscl/httpd-24-rhel7

COPY --from=builder /antora/gh-pages/ /var/www/html/
