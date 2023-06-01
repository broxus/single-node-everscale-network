## local-ever-network

A simple script to test consensus locally.

Based on [original scripts](https://github.com/tonlabs/ever-node/tree/master/tests/test_run_net).

### How to use

```
Usage: run.sh --node-path PATH --betterscale-tools-path PATH --output PATH --zerostate PATH

Options:
  -h,--help                               Print this help message and exit
  --node-path PATH                        Path to the node repo
  --betterscale-tools-path PATH           Path to the betterscale-tools repo
  --zerostate PATH                        Path to zerostate config
  --rebuild-node                          Build node repo before running the network
  --output PATH                           Output directory with nodes
```

Example:
```bash
git clone https://github.com/Rexagon/local-ever-network.git
cd local-ever-network

./run.sh \
    --node-path ../ever-node \
    --betterscale-tools-path ../betterscale-tools \
    --configs configs/zerostate-config.json \
    --output nodes \
    --rebuild-betterscale-tools \
    --rebuild-node
```
