FROM registry.access.redhat.com/ubi8/ubi:8.8-1067.1697633337
LABEL \
  maintainer="kin.wai.koo@gmail.com" \
  io.k8s.description="Demo web server written in Go" \
  io.openshift.expose-services="8080:http"

ARG PACKAGE
COPY --chown=1001:0 --chmod=555 simpleweb /simpleweb
USER 1001
EXPOSE 8080
ENTRYPOINT ["/simpleweb"]
