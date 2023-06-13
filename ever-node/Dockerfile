FROM rust:latest AS builder

RUN apt-get update \
  && apt-get -y install pkg-config openssl clang-13 libzstd-dev libgoogle-perftools-dev

RUN git clone --single-branch --branch feature/full-config https://github.com/broxus/betterscale-tools.git \
    && cd betterscale-tools \
    && RUSTFLAGS='-C target-cpu=native' cargo build --release

RUN git clone --recursive --single-branch --branch feature/boot-config https://github.com/pashinov/ever-node.git \
    && cd ever-node \
    && RUSTFLAGS='-C target-cpu=native' cargo build --release

ADD ever-node local-ever-network

FROM debian:bullseye-slim as runtime

RUN apt-get update \
  && apt-get -y install jq moreutils libgoogle-perftools-dev curl

COPY --from=builder local-ever-network /var/everscale/local-ever-network
COPY --from=builder betterscale-tools/target/release/betterscale /var/everscale/betterscale-tools/target/release/betterscale
COPY --from=builder ever-node/target/release/ton_node /var/everscale/ever-node/target/release/ton_node

WORKDIR /var/everscale/local-ever-network

EXPOSE 30000

ENTRYPOINT ["./run.sh"]
