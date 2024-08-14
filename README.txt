Use `./deploy-local.sh` to test locally (assuming you are using a forked Ethereum mainnet, created via `anvil`

Use `./deploy.sh` to deploy to Harmony mainnet. Note that because Harmony RPC is no longer fully spec-compliant (for `eth_` endpoints), you would be stuck at waiting for a receipt. Just copy the transaction hash and look up the transaction on the explorer to verify whether deployment is successful.

Make your own .env and .env.deploy-local based on the given examples


A UniswapV3TWAP oracle will be provided soon.