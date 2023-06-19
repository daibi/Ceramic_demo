// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { Split } from "@thirdweb-dev/contracts/Split.sol";

contract SwitchablePaymentSplit is Split  {

    bytes32 public constant DEFAULT_PAYEE_ROLE = bytes32(uint256(0x01));

    constructor(
        address _defaultAdmin,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address[] memory _payees,
        uint256[] memory _shares
    ) initializer {
         // Initialize inherited contracts: most base -> most derived
        __ERC2771Context_init(_trustedForwarders);
        __PaymentSplitter_init(_payees, _shares);

        contractURI = _contractURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);        
        for (uint256 i = 0; i < _payees.length; i++) {
            _setupRole(DEFAULT_PAYEE_ROLE, _payees[i]);
        }
    }

    function release(address payable account) public virtual override {
        // check if current account is payee role
        require(hasRole(DEFAULT_PAYEE_ROLE, _msgSender()), "release: current account is not of PAYEE Role");
        super.release(account);
    }

    function release(IERC20Upgradeable token, address account) public virtual override { 
        // check if current account is payee role
        require(hasRole(DEFAULT_PAYEE_ROLE, _msgSender()), "release IERC20: current account is not of PAYEE Role");
        super.release(token, account);
    }

    /**
     * @dev Release the owed amount of token to all of the payees.
     */
    function distribute() public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 count = payeeCount();
        for (uint256 i = 0; i < count; i++) {
            if (hasRole(DEFAULT_PAYEE_ROLE, payee(i))) {
                _release(payable(payee(i)));
            }
        }
    }

    /**
     * @dev Release owed amount of the `token` to all of the payees.
     */
    function distribute(IERC20Upgradeable token) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 count = payeeCount();
        for (uint256 i = 0; i < count; i++) {
            if (hasRole(DEFAULT_PAYEE_ROLE, payee(i))) {
                _release(token, payee(i));
            }
        }
    }
}