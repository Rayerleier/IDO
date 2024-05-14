pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {IDO} from "../src/IDO.sol";
import {RAINToken} from "../src/RAINToken.sol";
import {IProject} from "../src/interface/IProject.sol";

contract TestIDO is Test {
    address IDOowner = makeAddr("IDOowner");
    uint256 tokenOwnerPrivateKey = 123456;
    address tokenOwner = vm.addr(tokenOwnerPrivateKey);
    uint256 funderPrivateKey = 78985;
    address funder = vm.addr(funderPrivateKey);
    RAINToken raintoken;
    address tokenCA;
    IDO ido;
    IProject.IDOProject _project =
        IProject.IDOProject({
            owner: tokenOwner,
            price: 1e18,
            min: 1_000_000,
            max: 21_000_000,
            timeEnd: 1 days,
            tokenTotal: 21_000_000 * 1e18
        });

    function setUp() public {
        vm.startPrank(IDOowner);
        ido = new IDO();
        vm.stopPrank();
        vm.startPrank(tokenOwner);
        raintoken = new RAINToken();
        vm.stopPrank();
        tokenCA = address(raintoken);
    }

    function test_addIDOProject() public {
        addIDOProject();
        assertEq(ido.IDOProjectOf(tokenCA).owner, tokenOwner);
    }

    function addIDOProject() internal {
        vm.startPrank(tokenOwner);
        raintoken.approve(address(ido), _project.tokenTotal);
        ido.addIDOProject(tokenCA, _project);
        vm.stopPrank();
    }

    function test_preSale() public {
        addIDOProject();
        vm.startPrank(funder);
        uint256 min_price = 1_000_000 * 1e18;
        preSale(funder, min_price);
        assertEq(ido.IDOProjectAmountOf(tokenCA), min_price);
        assertEq(ido.IDOProjectLedgerOf(tokenCA, funder), min_price);
        vm.stopPrank();
        address funder2 = makeAddr("funder2");
        uint256 exceeding_price = 31_000_000 * 1e18;
        vm.deal(funder2, exceeding_price);
        vm.startPrank(funder2);
        // vm.expectRevert();
        // preSale(funder2, exceeding_price);
    }

    function preSale(address user, uint256 price) internal {
        vm.deal(user, price);
        ido.preSale{value: price}(tokenCA);
    }

    function test_refund() public {
        addIDOProject();
        uint256 insuffcientPrice = 2 * 1e18;
        vm.deal(funder, insuffcientPrice);

        vm.startPrank(funder);
        preSale(funder, insuffcientPrice);
        // vm.expectRevert();
        // ido.refund(tokenCA);
        vm.warp(block.timestamp + 2 days);
        ido.refund(tokenCA);
        assertEq(ido.IDOProjectLedgerOf(tokenCA, funder), 0);
        uint256 sufficientPrice = 11_000_000 * 1e18;

    }

    function test_claim() public {
        addIDOProject();
        uint256 price = 11_000_000 * 1e18;
        vm.startPrank(funder);
        preSale(funder ,price);
        vm.stopPrank();
        vm.warp(block.timestamp + 3 days);
        vm.prank(tokenOwner);
        ido.claim(tokenCA);
        vm.prank(funder);
        ido.claim(tokenCA);
        assertEq(RAINToken(tokenCA).balanceOf(funder), 11_000_000);
        assertEq(address(tokenOwner).balance, 11_000_000 * 1e18);
    }
}
