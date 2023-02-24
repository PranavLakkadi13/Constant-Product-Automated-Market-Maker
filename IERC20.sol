// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns(uint);
    function balanceOf(address tokenowner) external view returns(uint);
    function transfer(address to, uint256 tokens) external returns(bool);

    function transferFrom(address from, address to, uint256 tokens) external returns (bool);
    function approve(address spender, uint256 tokens) external returns (bool);
    function allowance(address tokenowner, address spender) external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenowner, address indexed spender, uint256 tokens);

}
