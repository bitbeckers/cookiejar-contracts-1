// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC20Mintable} from "test/utils/ERC20Mintable.sol";
import {TestAvatar} from "@gnosis.pm/zodiac/contracts/test/TestAvatar.sol";
import {IPoster} from "@daohaus/baal-contracts/contracts/interfaces/IPoster.sol";

import {ZodiacCloneSummoner, ZodiacERC721CookieJarHarnass} from "test/utils/ZodiacCloneSummoner.sol";
import {Test, Vm} from "forge-std/Test.sol";

contract ERC721CookieJarTest is ZodiacCloneSummoner {
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    ZodiacERC721CookieJarHarnass internal cookieJar;
    ERC20Mintable internal cookieToken = new ERC20Mintable("Mock", "MCK");
    TestAvatar internal testAvatar = new TestAvatar();

    ERC721 internal gatingERC721 = new ERC721("Gate", "GATE");

    uint256 internal cookieAmount = 2e6;

    string internal reason = "CookieJar: Testing";

    event Setup(bytes initializationParams);
    event GiveCookie(address indexed cookieMonster, uint256 amount);

    function setUp() public virtual {
        // address _safeTarget,
        // uint256 _periodLength,
        // uint256 _cookieAmount,
        // address _cookieToken,
        // address _erc721Addr,
        // uint256 _threshold,
        bytes memory initParams =
            abi.encode(address(testAvatar), 3600, cookieAmount, address(cookieToken), gatingERC721);

        cookieJar = getERC721CookieJar(initParams);

        // Enable module
        testAvatar.enableModule(address(cookieJar));

        vm.mockCall(0x000000000000cd17345801aa8147b8D3950260FF, abi.encodeWithSelector(IPoster.post.selector), "");
    }

    function testIsAllowed() external {
        assertFalse(cookieJar.exposed_isAllowList(msg.sender));

        vm.mockCall(address(gatingERC721), abi.encodeWithSelector(ERC721.balanceOf.selector), abi.encode(true));
        assertTrue(cookieJar.exposed_isAllowList(msg.sender));
    }

    function testReachInJar() external {
        // No gating token balance so expect fail
        vm.expectRevert(bytes("not a member"));
        cookieJar.reachInJar(reason);

        // No cookie balance so expect fail
        vm.mockCall(address(gatingERC721), abi.encodeWithSelector(ERC721.balanceOf.selector), abi.encode(1));
        vm.expectRevert(bytes("call failure setup"));
        cookieJar.reachInJar(reason);

        // Put cookie tokens in jar
        cookieToken.mint(address(testAvatar), cookieAmount);

        // Alice puts her hand in the jar
        vm.startPrank(alice);
        // GiveCookie is not the last emitted event so we drill down the logs
        // vm.expectEmit(false, false, false, true);
        // emit GiveCookie(alice, cookieAmount, CookieUtils.getCookieJarUid(address(cookieJar)));
        cookieJar.reachInJar(reason);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries[3].topics[0], keccak256("GiveCookie(address,uint256,string)"));
    }

}
