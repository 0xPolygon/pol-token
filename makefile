# !!! commands do not include --broadcast !!!
# it should be manually and intentionally added only when a real deployment takes place

# PRIVATE_KEY has to be set in .env
# rpc-url synonyms are in foundry.toml, which points to .env as well
upgrade-emission-manager-testnet:
	forge script script/1.2.0/UpgradeEmissionManager.s.sol --verify --rpc-url testnet

upgrade-emission-manager-MAINNET:
	forge script script/1.3.0/UpgradeEmissionManager.s.sol --verify --rpc-url mainnet
