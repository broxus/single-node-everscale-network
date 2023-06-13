FROM rust:latest AS builder

RUN apt-get update \
    && apt-get install -y libclang-dev cmake libsasl2-dev clang

RUN git clone --single-branch --branch feature/full-jrpc-api https://github.com/broxus/ton-kafka-producer.git \
    && cd ton-kafka-producer \
    && RUSTFLAGS='-C target-cpu=native' cargo build --release

ADD jrpc-api/configs configs

FROM debian:sid-slim as runtime

RUN apt-get update &&  apt-get install -y --no-install-recommends openssl ca-certificates libsasl2-2 netcat-traditional curl \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/

COPY --from=builder configs/config.yaml /etc/ton-kafka-producer/config.yaml
COPY --from=builder configs/ton-global.config.json /etc/ton-kafka-producer/ton-global.config.json
COPY --from=builder ton-kafka-producer/target/release/ton-kafka-producer /usr/local/bin/ton-kafka-producer

EXPOSE 30000

ENTRYPOINT ["ton-kafka-producer"]
