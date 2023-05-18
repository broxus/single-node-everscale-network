## local-ever-network

A simple script to test consensus locally.

Based on [original scripts](https://github.com/tonlabs/ever-node/tree/master/tests/test_run_net).

### How to use

```
Usage: run.sh --node-path PATH --tools-path PATH [OPTIONS]

Options:
  -h,--help             Print this help message and exit
  -n,--nodes N          Number of nodes to run
  --node-path PATH      Path to the ever-node repo
  --tools-path PATH     Path to the ever-node-tools repo
  --rebuild-node        Build node before running the network
  --rebuild-tools       Build tools before running the network
```

Example:
```bash
git clone https://github.com/tonlabs/ever-node.git --recursive
git clone https://github.com/tonlabs/ever-node-tools.git --recursive

git clone https://github.com/Rexagon/local-ever-network.git
cd local-ever-network

./run.sh \
    --node-path ../ever-node \
    --tools-path ../ever-node-tools \
    --rebuild-node \
    --rebuild-tools
```
