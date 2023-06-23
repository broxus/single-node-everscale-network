FROM rust:latest AS builder

ARG TARGET

RUN apt-get update \
    && apt-get install -y libclang-dev cmake libsasl2-dev clang

RUN git clone --single-branch --branch master https://github.com/broxus/everscale-monitoring.git && \
    if [ "$TARGET" = "Everscale" ] ; \
    then cd everscale-monitoring && cargo update && RUSTFLAGS='-C target-cpu=native' cargo build --release ; \
    else exit 0 ; \
    fi

ADD monitoring monitoring

FROM ubuntu:20.04 as runtime

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates libssl-dev openssl libsasl2-2 wget \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/

RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod a+x /usr/local/bin/yq

#RUN wget http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.19_amd64.deb -P /tmp && \
#    dpkg -i /tmp/libssl1.1_1.1.1f-1ubuntu2.19_amd64.deb

COPY --from=builder monitoring /var/everscale/monitoring
COPY --from=builder everscale-monitoring/target/release/everscale-monitoring /usr/local/bin/everscale-monitoring

WORKDIR /var/everscale/monitoring

ENTRYPOINT ["./run.sh"]
