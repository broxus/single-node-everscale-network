FROM python:3.11

WORKDIR /app

# setup rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH /root/.cargo/bin:$PATH

RUN pip install nekoton

ADD giver/giver.py .
