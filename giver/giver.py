import argparse
import asyncio
import nekoton as nt
import sys
import time

# Giver
GIVER_ADDRESS = nt.Address('-1:1111111111111111111111111111111111111111111111111111111111111111')

# Default recipient
RECIPIENT_ADDRESS = '0:a7ea815e38a2165776cd9e328908f8f0ff9b0ff0ae9f9531337ee781a2f2b8be'

giver_abi = nt.ContractAbi("""{
    "ABI version": 1,
    "functions": [{
        "name": "sendGrams",
        "inputs": [
            {"name": "dest", "type": "address"},
            {"name": "amount", "type": "uint64"}
        ],
        "outputs": []
    }],
    "events": []
}""")

send_grams = giver_abi.get_function("sendGrams")
assert send_grams is not None


class Giver:
    def __init__(self, transport: nt.Transport, address: nt.Address):
        self._transport = transport
        self._address = address

    @property
    def address(self) -> nt.Address:
        return self._address

    async def give(self, target: nt.Address, amount: nt.Tokens):
        # Prepare external message
        message = send_grams.encode_external_message(
            self._address,
            input={
                "dest": target,
                "amount": amount,
            },
            public_key=None
        ).without_signature()

        # Send external message
        tx = await self._transport.send_external_message(message)
        if tx is None:
            raise RuntimeError("Message expired")

        # Wait until all transactions are produced
        # await self._transport.trace_transaction(tx).wait()


class ArgParser(argparse.ArgumentParser):
    def error(self, message):
        self.print_help()
        sys.stderr.write('error: %s\n' % message)
        sys.exit(2)


async def main():
    time.sleep(310)

    parser = ArgParser()

    parser.add_argument('-a', '--amount', default=1_000_000, type=int, help='Amount to receive (default 1_000_000)')
    parser.add_argument('-r', '--recipient', default=RECIPIENT_ADDRESS,
                        help='Recipient address (default {})'.format(RECIPIENT_ADDRESS))

    args = parser.parse_args()

    transport = nt.JrpcTransport('http://jrpc-api:8081/rpc')

    giver = Giver(transport, GIVER_ADDRESS)

    await giver.give(nt.Address(args.recipient), nt.Tokens(args.amount))

    print("Done")

if __name__ == "__main__":
    asyncio.run(main())
