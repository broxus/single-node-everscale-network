FROM rust:latest AS builder

ARG TARGET

RUN apt-get update \
  && apt-get -y install pkg-config openssl clang-13 libzstd-dev libgoogle-perftools-dev

ADD ever-node local-ever-network

RUN git clone --single-branch --branch feature/full-config https://github.com/broxus/betterscale-tools.git \
    && cd betterscale-tools \
    && RUSTFLAGS='-C target-cpu=native' cargo build --release

RUN if [ "$TARGET" = "Venom" ] ; \
    then git clone --recursive --single-branch --branch master https://github.com/tonlabs/ever-node-venom.git ever-node && \
      cd ever-node && git apply ../local-ever-network/patches/venom/0001-Add-boot-config.patch && \
      RUSTFLAGS='-C target-cpu=native' cargo build --release --features venom ; \
    else git clone --recursive --single-branch --branch master https://github.com/tonlabs/ever-node.git && \
      cd ever-node && git apply ../local-ever-network/patches/everscale/0001-Add-boot-config.patch && \
      RUSTFLAGS='-C target-cpu=native' cargo build --release ; \
    fi

FROM debian:bullseye-slim as runtime

RUN apt-get update && apt-get -y install jq moreutils libgoogle-perftools-dev \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/

COPY --from=builder local-ever-network /var/everscale/local-ever-network
COPY --from=builder betterscale-tools/target/release/betterscale /var/everscale/betterscale-tools/target/release/betterscale
COPY --from=builder ever-node/target/release/ton_node /var/everscale/ever-node/target/release/ton_node

WORKDIR /var/everscale/local-ever-network

ENTRYPOINT ["./run.sh"]
