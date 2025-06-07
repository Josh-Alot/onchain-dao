source .env &&
forge create src/CryptoDevsDAO.sol:CryptoDevsDAO \
--verbosity \
--broadcast \
--verify \
--private-key $PRIVATE_KEY \
--constructor-args 0x0748524ce96d631b0bb42f352688c4ca4dc0badf 0xac99274c19025f48711434ef2bdbb23167e8fcbc \
--value 0.01ether