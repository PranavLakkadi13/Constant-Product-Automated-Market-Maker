// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract CPAMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint public reserve0; // internal balanceof token0
    uint public reserve1; // internal balanceof token1 

    uint public totalSupply;  // to see the total supply of shares 
    mapping(address => uint) public balanceOf;  // to map the shares of a specific address

    constructor(address _token0, address _token1){
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    function _mint(address _to,uint _amount) private { // to mint the shares 
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    function _burn(address _from,uint _amount) private { // to burn the shares 
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    function _update(uint _reserve0, uint _reserve1) private { // to update the reserves
        reserve0 = reserve1;
        reserve1 = _reserve1;
    }

    function swap(address _tokenIn, uint _amountIn) external returns(uint _amountOut){
        // Pull in tokenIn
        // calculate tokenOut, iuncluding fees, 0.3% fee
        // transfer tokenOut to msg.sender
        // update the reserves
        require(_tokenIn == address(token0) || _tokenIn == address(token1),"Invalid input token");
        require(_amountIn > 0, "Input amount too low");

        bool istoken0 = _tokenIn == address(token0);

        (IERC20 _tokenIn, IERC20 _tokenOut, uint _reserveIn, uint _reserveOut) = istoken0 
        ? (token0,token1,reserve0,reserve1) : (token1, token0,reserve1,reserve0); 

        // transferring tokens in 
        _tokenIn.transferFrom(msg.sender, address(this), _amountIn);
        
        // calculating the amount of token to be given out (including fee)
        // y*dx / (x + dx) = dy 
        uint _amountOutWithFee = (_amountIn * 997)/1000;
        _amountOut = (_reserveOut * _amountIn)/(_reserveIn + _amountIn);

        
        // transferring token out 
        _tokenOut.transfer(msg.sender,_amountOut);
        
        // updating the reserve 
        _update(token0.balanceOf(address(this)),token1.balanceOf(address(this)));

    }

    // when someone add liquidity , shares mint
    function addLiquidity(uint _amount0, uint _amount1) external returns(uint shares){ 
        // pull in token 1 and token 2 
        // mint the shares 
        // update the reserves 
        
        // pull in tokens 
        token0.transferFrom(msg.sender,address(this),_amount0);
        token1.transferFrom(msg.sender,address(this),_amount1);

        // dy/dx = y/x the ratio of tokens coming in == ration of the reserves of the tokens
        if (reserve0 >0 || reserve1 > 0) {
            require(reserve0 * _amount1 == reserve1 * _amount0, "dy/dx != y/x");
        }

        // mint Shares 
        // f(x,y) = value of liquidity = sqrt(x*y)
        // shares (s) = (dx/x)T = (dy/y)T
        if (totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
        }
        else {
            shares  = _min((_amount0 * totalSupply)/reserve0, (_amount1 * totalSupply)/reserve1);
        }

        require(shares > 0, "error shares < 0");
        // mint the shares
        _mint(msg.sender,shares); 

        // update the reserves
        _update(token0.balanceOf(address(this)),token1.balanceOf(address(this)));
    }
    
    // when someone removes liquidity , shares burn and collect the fees
    function removerLiquidity(uint _shares) external returns(uint amount0,uint amount1){ 
        // first calculate amount0 and amount1 to withdraw 
        // dx = s / T * x
        // dy = s / T * y
        uint bal0 = token0.balanceOf(address(this));
        uint bal1 = token1.balanceOf(address(this));

        amount0 = (_shares * bal0) / totalSupply;
        amount1 = (_shares * bal1) / totalSupply;
        require(amount0 > 0 && amount1 > 0, "amount0 or amount1 is < 0");

        // burn the shares 
        _burn(msg.sender, _shares);

        // update the reserves 
        _update(bal0 - amount0, bal1 - amount1);

        // transfer the tokens to msg.sender 
        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);


    }

    // to get the liquidity
    function _sqrt(uint y) private pure returns(uint z) {  
        if (y > 3) {
            z = y;
            uint x = y/2 + 1;
            while(x < z){
                z = x;
                x = (y / x + x) / 2;
            }
        }
        else if (y != 0) {
            z = 1;
        }
    }

    // to get the minimum of 2 numbers
    function _min(uint x, uint y) private pure returns(uint) { 
        return (x <= y) ? x : y;
    }

}
