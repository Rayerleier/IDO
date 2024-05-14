pragma solidity ^0.8.0;


import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract RAINToken is ERC20Permit{
    string private constant _name = "RAINToken";
    string private constant _symbol = "RAIN";
    uint256 private constant _total = 21_000_000 * 1e18;
    constructor()ERC20Permit(_name)ERC20(_name,_symbol){
        _mint(msg.sender, _total);
    }

}