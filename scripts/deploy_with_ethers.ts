// This script can be used to deploy the "Storage" contract using ethers.js library.
// Please make sure to compile "./contracts/1_Storage.sol" file before running this script.
// And use Right click -> "Run" from context menu of the file to run the script. Shortcut: Ctrl+Shift+S

import { deploy } from './ethers-lib'

(async () => {
  try {
    const bandOracleAddress = '0xA55d9ef16Af921b70Fed1421C1D298Ca5A3a18F1';
    const base = 'ETH';
    const quote = 'USD';
    const updateFee = 0;
    const result = await deploy('BandOracleReader', [bandOracleAddress, base, quote, updateFee])
    console.log(`BandOracleReader address: ${result.address}`, "base:", base)
  } catch (e) {
    console.log(e.message)
  }
})()