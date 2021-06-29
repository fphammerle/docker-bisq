FROM docker.io/debian:10.10-slim

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl
# TODO merge
ARG BISQ_VERSION=1.7.0
RUN curl --output bisq.deb --location https://bisq.network/downloads/v${BISQ_VERSION}/Bisq-64bit-${BISQ_VERSION}.deb
RUN apt-get purge --yes --autoremove curl ca-certificates
RUN apt-get install --yes strace
# > xdg-desktop-menu: No writable system menu directory found.
RUN apt-get install --yes --no-install-recommends xdg-utils
RUN ln -sf /bin/true /usr/bin/xdg-desktop-menu \
    && xdg-desktop-menu
RUN apt-get install --yes ./bisq.deb && rm bisq.deb
# > Loading library prism_es2 from resource failed: java.lang.UnsatisfiedLinkError: \
# > /home/bisq/.openjfx/cache/16/libprism_es2.so: libGL.so.1: cannot open shared object file: No such file or directory
RUN apt-get install --yes --no-install-recommends libgl1
# RUN mkdir /usr/share/desktop-directories /usr/share/gnome/apps -p
# RUN ln -sf /bin/true /usr/local/bin/update-desktop-database
# # RUN sleep 30 && xdg-desktop-menu install /opt/bisq/lib/bisq-Bisq.desktop
# RUN apt-get install --fix-broken
# > Exception in thread "main" java.lang.UnsupportedOperationException: Internal Error
# > at com.sun.glass.ui.gtk.GtkApplication.lambda$new$6(GtkApplication.java:189)
RUN apt-get install --yes --no-install-recommends libgtk2.0-0
# > java.io.UncheckedIOException: Application data directory '/home/bisq/.local/share/Bisq' could not be created
RUN apt-get install --yes --no-install-recommends tini \
    && useradd --create-home bisq \
    && find / -xdev -type f -perm /u+s -exec chmod -c u-s {} \; \
    && find / -xdev -type f -perm /g+s -exec chmod -c g-s {} \;

USER bisq

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/bisq/bin/Bisq"]

# TODO
#LABEL podman-run-x11="podman run --name bisq --rm --init -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix --read-only --cap-drop ALL --security-opt no-new-privileges \${IMAGE}"

# TODO
# https://github.com/opencontainers/image-spec/blob/v1.0.1/annotations.md
#ARG REVISION=
#LABEL org.opencontainers.image.title="bisq" \
#    org.opencontainers.image.source="https://github.com/fphammerle/docker-bisq" \
#    org.opencontainers.image.revision="$REVISION"
