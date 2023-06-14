FROM rust:latest AS builder

ARG TARGET

RUN apt-get update \
    && apt-get install -y libclang-dev cmake libsasl2-dev clang

RUN git clone --single-branch --branch feature/full-jrpc-api https://github.com/broxus/ton-kafka-producer.git && \
    if [ "$TARGET" = "Venom" ] ; \
    then cd ton-kafka-producer && RUSTFLAGS='-C target-cpu=native' cargo build --release --features venom ; \
    else cd ton-kafka-producer && RUSTFLAGS='-C target-cpu=native' cargo build --release ; \
    fi

ADD jrpc-api jrpc-api

FROM debian:sid-slim as runtime

RUN apt-get update && apt-get install -y --no-install-recommends openssl ca-certificates libsasl2-2 wget \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/


RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod a+x /usr/local/bin/yq

COPY --from=builder jrpc-api /var/everscale/jrpc-api
COPY --from=builder ton-kafka-producer/target/release/ton-kafka-producer /usr/local/bin/ton-kafka-producer

WORKDIR /var/everscale/jrpc-api

ENTRYPOINT ["./run.sh"]
