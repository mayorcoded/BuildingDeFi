pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// What an exchange contract needs:
/// addLiquidity function, getReserve, removeLiquidity, swap, getPrice
contract Exchange is ERC20 {
    address public tokenAddress;

    constructor(address _tokenAddress) ERC20("Defiswap-V1", "DEFI-V1"){
        require(_tokenAddress != address (0), "invalid token address");
        tokenAddress = _tokenAddress;
    }

    function addLiquidity(uint256 _tokenAmount) public payable {
        if(getReserve() == 0){
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
        }else {
            //this was done for slippage tolerance
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            require(_tokenAmount >= tokenAmount, "insufficient token amount");

            IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);
            uint256 liquidity = (totalSupply() * msg.value) / ethReserve; //why is the liquidity calculation tied to eth reserve?
            _mint(msg.sender, liquidity);
        }
    }

    function getReserve() public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address (this));
    }

    function getTokenAmount(uint256 _ethSold) public view returns(uint256) {
        require(_ethSold > 0, "ethSold is too small");

        uint256 tokenReserve = getReserve();
        return _getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    function getEthAmount(uint256 _tokenSold) public view returns(uint256) {
        require(_tokenSold > 0, "tokenSold is too small");

        uint256 tokenReserve = getReserve();
        return _getAmount(_tokenSold,tokenReserve, address(this).balance);
    }

    function ethToTokenSwap(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = _getAmount(msg.value, address(this).balance, tokenReserve);

        require(tokensBought >= _minTokens, "insufficient input amount");
        IERC20(tokenAddress).transfer(msg.sender, tokensBought);
    }

    function tokenToEthSwap(uint256 _tokenSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = _getAmount(_tokenSold, tokenReserve, address(this).balance);

        require(ethBought >= _minEth, "insufficient input amount");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
        payable(msg.sender).transfer(ethBought);
    }

    function removeLiquidity(uint256 _amount) public returns(uint256, uint256) {
        require(_amount > 0, "invalid amount");

        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        return (ethAmount, tokenAmount);
    }

    function _getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns(uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }
}
