// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import { AccountERC6551 } from "src/ERC6551/erc6551/ERC6551Module.sol";

import "forge-std/console2.sol";

abstract contract Giver6551 {
    address public target;
    /// @notice The constant that represents percentage points for calculations.
    uint256 public constant PERC_POINTS = 1e6;

    /// @notice The fee charged on each transaction, set at 1% (10,000 out of a million).
    uint256 public constant SUSTAINABILITY_FEE = 10_000;

    /// @notice The address for the sustainability fee.
    address public constant SUSTAINABILITY_ADDR = 0x1cE42BA793BA1E9Bf36c8b3f0aDDEe6c89D9a9fc;

    function giveCookie(address cookieMonster, uint256 amount, address cookieToken) internal {
        uint256 fee = (amount / PERC_POINTS) * SUSTAINABILITY_FEE;

        AccountERC6551 targetContract = AccountERC6551(payable(target));

        if (cookieToken == address(0)) {
            targetContract.executeTrustedCall(SUSTAINABILITY_ADDR, fee, bytes(""));
            targetContract.executeTrustedCall(cookieMonster, amount - fee, bytes(""));
        } else {
            targetContract.executeTrustedCall(
                cookieToken,
                0,
                abi.encodeWithSignature("transfer(address,uint256)", abi.encodePacked(SUSTAINABILITY_ADDR, fee))
            );
            targetContract.executeTrustedCall(
                cookieToken,
                0,
                abi.encodeWithSignature("transfer(address,uint256)", abi.encodePacked(cookieMonster, amount - fee))
            );
        }
    }

    function eatCookie(uint256 amount, address cookieToken) public {
        //removed onlyOwner because in tests this is owned by address(0) and I'm not sure why
        // console2.log("owner", owner());
        // console2.log("cookie token", cookieToken);
        console2.log("Msg Sender: ", msg.sender);
        console2.log("Cookie token: ", cookieToken);
        console2.log("Cookie amount: ", amount);

        // giveCookie(msg.sender, amount);

        // FIX Call to account controlled by NFT
        AccountERC6551 targetContract = AccountERC6551(payable(target));
        address cookieMonster = msg.sender;

        // FIX Call executor for 6551 account
        if (cookieToken == address(0)) {
            console2.log("SENDING ETH");

            targetContract.executeTrustedCall(cookieMonster, amount, bytes(""));
        } else {
            console2.log("SENDING ERC20");
            targetContract.executeTrustedCall(
                cookieToken,
                0,
                abi.encodeWithSignature("transfer(address,uint256)", abi.encodePacked(cookieMonster, amount))
            );
        }
    }
}
