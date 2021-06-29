FROM docker.io/debian:10.10-slim

ARG BISQ_VERSION=1.7.0
# overwriting xdg-desktop-menu to workaround "xdg-desktop-menu: No writable system menu directory found.".
# installing libgl1 to fix:
# > Loading library prism_es2 from resource failed: java.lang.UnsatisfiedLinkError: \
# > /home/bisq/.openjfx/cache/16/libprism_es2.so: libGL.so.1: cannot open shared object file: No such file or directory
# installing libgtk2* to fix:
# > Exception in thread "main" java.lang.UnsupportedOperationException: Internal Error
# > at com.sun.glass.ui.gtk.GtkApplication.lambda$new$6(GtkApplication.java:189)
# `useradd --create-home` for:
# > java.io.UncheckedIOException: Application data directory '/home/bisq/.local/share/Bisq' could not be created
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        curl \
        xdg-utils \
        libgl1 \
        libgtk2.0-0 \
        tini \
    && curl --output bisq.deb --location https://bisq.network/downloads/v${BISQ_VERSION}/Bisq-64bit-${BISQ_VERSION}.deb \
    && apt-get purge --yes --autoremove curl ca-certificates \
    && ln -sf /bin/true /usr/bin/xdg-desktop-menu \
    && apt-get install --yes ./bisq.deb \
    && rm bisq.deb \
    && useradd --create-home bisq \
    && find / -xdev -type f -perm /u+s -exec chmod -c u-s {} \; \
    && find / -xdev -type f -perm /g+s -exec chmod -c g-s {} \;
# TODO merge
# > [NetworkNode-9999] ERROR b.n.p2p.network.TorNetworkNode: Tor node creation failed: \
# > java.io.IOException: Cannot run program "ps": error=2, No such file or directory
# > [JavaFX Application Thread] ERROR bisq.core.app.P2PNetworkSetup: onSetupFailed
RUN apt-get install --yes --no-install-recommends procps
ARG BISQ_DATA_PATH=/home/bisq/.local/share/Bisq
RUN mkdir -p $BISQ_DATA_PATH \
    && chown -c bisq $BISQ_DATA_PATH
VOLUME $BISQ_DATA_PATH
# TODO clean apt

USER bisq
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/opt/bisq/bin/Bisq"]

# TODO --read-only
LABEL podman-run-x11="podman run --name bisq --rm -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v bisq_data:$BISQ_DATA_PATH --cap-drop ALL --security-opt no-new-privileges \${IMAGE}"

# https://github.com/opencontainers/image-spec/blob/v1.0.1/annotations.md
ARG REVISION=
LABEL org.opencontainers.image.title="bisq" \
    org.opencontainers.image.source="https://github.com/fphammerle/docker-bisq" \
    org.opencontainers.image.revision="$REVISION"
