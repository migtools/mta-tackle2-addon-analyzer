FROM registry.redhat.io/ubi9/go-toolset:1.23 AS builder
COPY --chown=1001:0 . /workspace

WORKDIR /workspace
# Avoid using Makefile as it performs GOIMPORTS and fails downstream
ENV GOEXPERIMENT strictfipsruntime
RUN go fmt ./... && go vet ./cmd/... ./builder/... && CGO_ENABLED=1 go build -tags strictfipsruntime -ldflags="-w -s" -o bin/addon github.com/konveyor/tackle2-addon-analyzer/cmd

FROM brew.registry.redhat.io/rh-osbs/mta-mta-analyzer-lsp-rhel9:8.0.0
RUN dnf -y install glibc-langpack-en openssh-clients openssl subversion git tar && dnf -y clean all

RUN sed -i 's/^LANG=.*/LANG="en_US.utf8"/' /etc/locale.conf
ENV LANG=en_US.utf8
RUN echo "addon:x:1001:1001:addon user:/addon:/sbin/nologin" >> /etc/passwd
RUN echo -e "StrictHostKeyChecking no" \
 "\nUserKnownHostsFile /dev/null" > /etc/ssh/ssh_config.d/99-konveyor.conf

ENV HOME=/addon ADDON=/addon
COPY --from=builder /workspace/bin/addon /usr/bin
COPY --from=builder /workspace/LICENSE /licenses/

WORKDIR /addon

ENTRYPOINT ["/usr/bin/addon"]

LABEL \
        description="Migration Toolkit for Applications - Analyzer Addon" \
        io.k8s.description="Migration Toolkit for Applications - Analyzer Addon" \
        io.k8s.display-name="MTA - Analyzer Addon" \
        io.openshift.maintainer.project="MTA" \
        io.openshift.tags="migration,modernization,mta,tackle,konveyor" \
        summary="Migration Toolkit for Applications - Analyzer Addon"
