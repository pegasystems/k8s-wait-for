FROM alpine:3.16.2 AS builder

ARG TARGETARCH

RUN apk add --update --no-cache ca-certificates curl jq=1.6-r1 \
    && KUBECTL_LATEST_STABLE_VERSION=$(curl -L https://dl.k8s.io/release/stable.txt) \
    && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_LATEST_STABLE_VERSION}/bin/linux/$TARGETARCH/kubectl -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

FROM alpine:3.16.2

ARG VCS_REF
ARG BUILD_DATE

# Metadata
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/pegasystems/k8s-wait-for" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.docker.dockerfile="/Dockerfile"

COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl

# Replace for non-root version
ENV USER=k8swatcher
ENV UID=1100
ENV GID=1100

RUN apk -U --no-cache upgrade && \
    apk add --update --no-cache jq=1.6-r1 && \
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
