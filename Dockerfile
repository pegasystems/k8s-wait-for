FROM alpine:3.22 AS builder

ARG TARGETARCH

RUN apk add --update --no-cache ca-certificates curl jq \
    && KUBECTL_LATEST_STABLE_VERSION=$(curl -L https://dl.k8s.io/release/stable.txt) \
    && echo "kubectl version: ${KUBECTL_LATEST_STABLE_VERSION}" \
    && curl -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$TARGETARCH/kubectl" -o /usr/local/bin/kubectl \
    && ls -al /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

FROM alpine:3.22
ARG VCS_REF
ARG BUILD_DATE

# Metadata
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/chandra-prakash-reddy/k8s-wait-for" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile"

COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl

# Replace for non-root version
ENV USER=k8swatcher
ENV UID=1100
ENV GID=1100

# Workaround suggested by https://nvd.nist.gov/vuln/detail/CVE-2023-4807
ENV OPENSSL_ia32cap=:~0x200000

RUN apk -U --no-cache upgrade && \
    apk add --update --no-cache jq && \
    addgroup -g $GID $USER && \
    adduser \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --ingroup "$USER" \
    --no-create-home \
    --uid "$UID" \
    "$USER"

USER $UID

ADD --chown=$UID:$GID wait_for.sh /usr/local/bin/wait_for.sh

ENTRYPOINT ["wait_for.sh"]
