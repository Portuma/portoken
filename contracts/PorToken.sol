// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/UniswapInterface.sol";
import "./libraries/RFIFeeCalculator.sol";
import "./utils/Errors.sol";

/*
 * Por Token
 * Web: https://portoken.com 
 * Telegram: https://t.me/portumacommunity
 * Twitter: https://twitter.com/portumatoken
 * Instagram: https://www.instagram.com/portumatoken/
 * Linkedin: https://www.linkedin.com/company/portumatoken/
 * 
 * Total Supply: 10,000,000,000
 * Max Transaction Amount: 50,000,000 (0.5% of Total Supply)
 *
 *
 * first month sale conditions
 * Sell within 1 days  : %30 (%15 marketing, %5 Burn, %10 RFI) = Slippage Min: 43
 * Sell within 21 days : %20 (%10 marketing, %5 burn, %5 RFI) = Slippage Min: 25
 * Sell within 30 days : %10 (%7 marketing, %1 burn, %2 RFI) = Slippage Min: 11
 * sell after 30 days  : %5  (%4 marketing, %0.5 burn, %0.5 RFI) = Slippage Min: 6
 *
 * Ownership will be transfered to a Gnosis Multi Sig Wallet
 *
 *
 * Smart Contract Development by WeCare Labs: https://wecarelabs.org
 */

/// @title PorToken Token
/// @author WeCare Labs - https://wecarelabs.org
/// @notice Contract Has first month sell conditions by tiers defining the taken fee
contract PorToken is Initializable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using RFIFeeCalculator for uint256;

    uint256 private constant MAX = type(uint256).max;

    uint256 private _tTotal;
    uint256 private _rTotal;

    uint256 private _tFeeTotal;
    uint256 private _maxTxAmount;

    uint256 private _start_timestamp;
    address private _marketingWallet;
    address private _teamWallet;
    uint256 private _marketingFeeCollected;
    uint256 private _swapMarketingAtAmount; // = 1 * 10**6 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private inSwap;
    bool private tradingIsEnabled;

    // Reflection Owned
    mapping(address => uint256) private _rOwned; //
    // Token Owned
    mapping(address => uint256) private _tOwned; //
    // is address allowed to spend on behalf
    mapping(address => mapping(address => uint256)) private _allowances; //
    // is address excluded from fee taken
    mapping(address => bool) private _isExcludedFromFee; //
    // is address exluded from Maximum transaction amount
    mapping(address => bool) private _isExcludedFromMaxTx; //
    // is address exlcuded from reward list?
    mapping(address => bool) private _isExcluded; //
    // is address Blacklisted?
    mapping(address => bool) private _isBlacklisted; //
    // store automatic market maker pairs.
    mapping (address => bool) private automatedMarketMakerPairs;

    address[] private _excluded; //

    // modifiers
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    // structs
    RFIFeeCalculator.taxTiers private taxTiers;
    RFIFeeCalculator.feeData private feeData;
    RFIFeeCalculator.transactionFee private fees;

    // Events
    event SetAutomatedMarketMakerPair(address indexed pair, bool value);
    event ResetStartTimestamp(uint256 newStartTimestamp);
    event SetBurnFee(uint256 newStartTimestamp);
    event SetHolderFee(uint256 newHolderFee);
    event SetMarketingFee(uint256 newMarketingFee);
    event SetMarketingWallet(address marketingWallet);
    event SetTeamWallet(address teamWalletAddress);
    event SetSwapMarketingAtAmount(uint256 amount);
    event ExcludeFromReward(address account);
    event IncludeInReward(address account);
    event CreateETHSwapPair(address routerAddress);
    event SetMaxTxAmount(uint256 amount);
    event ExcludeFromFee(address account);
    event IncludeInFee(address account);
    event SetTradingStatus(bool status);
    event MarketingFeeSent(uint256 amount);
    event BlacklistStatusChanged(address indexed account, bool value);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC20_init("Portuma", "POR");
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 1e10 * 10 ** decimals());

        __initializeParams();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {
    }

    receive() external payable {}

    // initialize the additional parameter on contract deploy
    function __initializeParams() initializer internal {
        _tTotal = super.totalSupply();
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[owner()] = _rTotal;

        _maxTxAmount = _tTotal * 50 / 1e4; //Max Transaction: 50 Milion (0.5%)
        _swapMarketingAtAmount = 1 * 1e6 * 10**decimals();

        feeData = RFIFeeCalculator.feeData(0.5 * 1e2, 0.5 * 1e2, 4 * 1e2);

        taxTiers.time = [24, 504, 720];
        // 24 = 1 day, 168 = 7 days, 504 = 21 days, 720 = 30 days
        taxTiers.tax[0] = RFIFeeCalculator.feeData(5 * 1e2, 10 * 1e2, 15 * 1e2);
        taxTiers.tax[1] = RFIFeeCalculator.feeData(5 * 1e2, 5 * 1e2, 10 * 1e2);
        taxTiers.tax[2] = RFIFeeCalculator.feeData(1 * 1e2, 2 * 1e2, 7 * 1e2);

        _start_timestamp = block.timestamp;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromMaxTx[owner()] = true;

        tradingIsEnabled = false;
        
        _excludeFromReward(address(0xdead));
        _excludeFromReward(address(0));
        _excludeFromReward(address(this));
    }

    /***********************************|
    |              Overrides            |
    |__________________________________*/
    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function _burn(address account, uint256 amount) internal virtual override {
        if(account == address(0)) revert AddressIsZero(account);

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balanceOf(account);
        if(accountBalance < amount) revert AmountExceedsAccountBalance();

        bool feeDeducted = _isExcluded[account];
        uint256 rAmount = reflectionFromToken(amount, feeDeducted);
        _rTotal -= rAmount;
        _tTotal -= amount;
        
        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /***********************************|
    |           Write Functions         |
    |__________________________________*/
    function setMaxTxAmount(uint256 _maxAmount) external onlyOwner {
        if (_maxAmount > totalSupply()) revert MaxTransactionAmountExeeds(_maxAmount, totalSupply());

        _maxTxAmount = _maxAmount;
        emit SetMaxTxAmount(_maxAmount);
    }

    function excludeFromReward(address account) external onlyOwner {
        if (_isExcluded[account]) revert AccountAlreadyExcludedFromReward(account);

        _excludeFromReward(account);
    }

    function includeInReward(address account) external onlyOwner {
        if (!_isExcluded[account]) revert AccountAlreadyIncludedInReward(account);

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }

        emit IncludeInReward(account);
    }

    function excludeFromFee(address account) external onlyOwner {
        if (_isExcludedFromFee[account]) revert AccountAlreadyExcludedFromFee(account);

        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }

    function includeInFee(address account) external onlyOwner {
        if (!_isExcludedFromFee[account]) revert AccountAlreadyIncludedInFee(account);

        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }

    /*
     * newStartTimestamp: in seconds
     */
    function resetStartTimestamp(uint256 newStartTimestamp) external onlyOwner {
        _start_timestamp = newStartTimestamp;

        emit ResetStartTimestamp(newStartTimestamp);
    }

    /*
     * newBurnFee: 100 = 1.00%
     */
    function setBurnFee(uint256 newBurnFee) external onlyOwner {
        feeData.burnFee = newBurnFee;

        emit SetBurnFee(newBurnFee);
    }

    /*
     * newHolderFee: 100 = 1.00%
     */
    function setHolderFee(uint256 newHolderFee) external onlyOwner {
        feeData.holderFee = newHolderFee;

        emit SetHolderFee(newHolderFee);
    }

    /*
     * newMarketingFee: 100 = 1.00%
     */
    function setMarketingFee(uint256 newMarketingFee) external onlyOwner {
        feeData.marketingFee = newMarketingFee;

        emit SetMarketingFee(newMarketingFee);
    }

    function setMarketingWallet(address marketingWalletAddress) external onlyOwner {
        if (marketingWalletAddress == address(0)) revert AddressIsZero(marketingWalletAddress);
        
        _marketingWallet = marketingWalletAddress;
        emit SetMarketingWallet(marketingWalletAddress);
    }
    
    function setSwapMarketingAtAmount(uint256 amount) external onlyOwner {
        if (amount <= 0) revert AmountIsZero();

        _swapMarketingAtAmount = amount;
        emit SetSwapMarketingAtAmount(amount);
    }

    function setTeamWallet(address teamWalletAddress) external onlyOwner {
        if (teamWalletAddress == address(0)) revert AddressIsZero(teamWalletAddress);
        
        _teamWallet = teamWalletAddress;
        emit SetTeamWallet(teamWalletAddress);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        if (automatedMarketMakerPairs[pair] == value) revert MarketMakerAlreadySet(pair, value);

        _setAutomatedMarketMakerPair(pair, value);
    }

    function createETHSwapPair(address _routerAddress) external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_routerAddress);        
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

        emit CreateETHSwapPair(_routerAddress);
    }

    function setUniswapRouter(address _addr) external onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_addr);
        uniswapV2Router = _uniswapV2Router;
    }

    function setUniswapPair(address _addr) external onlyOwner {
        if(_addr == address(0)) revert AddressIsZero(_addr);
        if (uniswapV2Pair == _addr) revert PairAlreadySet(_addr); 
        
        uniswapV2Pair = _addr;
        _excludeFromReward(uniswapV2Pair);
    }

    function setTradingIsEnabled(bool value) external onlyOwner {
        if(tradingIsEnabled == value) revert TradingStatusAlreadySet(value);

        tradingIsEnabled = value;
        emit SetTradingStatus(value);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        if(_isBlacklisted[account] == value) revert BlaclistStatusAlreadySet(account, value);

        _isBlacklisted[account] = value;

        emit BlacklistStatusChanged(account, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) internal {
        if (automatedMarketMakerPairs[pair] != value) {
            automatedMarketMakerPairs[pair] = value;

            _excludeFromReward(pair);
            emit SetAutomatedMarketMakerPair(pair, value);
        }
    }

    function _excludeFromReward(address account) internal {
        if (!_isExcluded[account]) {
            if (_rOwned[account] > 0) _tOwned[account] = tokenFromReflection(_rOwned[account]);

            _isExcluded[account] = true;
            _excluded.push(account);
            
            emit ExcludeFromReward(account);
        }
    }

    /***********************************|
    |            Read Functions         |
    |__________________________________*/
    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        if(rAmount > _rTotal) revert AmountExceedsTotalReflection(rAmount);

        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        if(tAmount > _tTotal) revert AmountExceedsTotalSupply(tAmount);
        uint256 tss = block.timestamp - _start_timestamp;
        
        RFIFeeCalculator.transactionFee memory f = tAmount.calculateFees(_getRate(), feeData, false, taxTiers, tss);
        if (!deductTransferFee) return f.rAmount;
        
        return f.rTransferAmount;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function getBurnFee() external view returns (uint256) {
        return feeData.burnFee;
    }

    function getHolderFee() external view returns (uint256) {
        return feeData.holderFee;
    }

    function getMarketingFee() external view returns (uint256) {
        return feeData.marketingFee;
    }

    function getTaxTiers() external view returns (uint256[] memory) {
        return taxTiers.time;
    }

    function getTradingStatus() external view returns (bool) {
        return tradingIsEnabled;
    }

    function _getRate() internal view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        
        return rSupply / tSupply;
    }

    // Get current supply for Reflection
    function _getCurrentSupply() internal view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            
            rSupply -= _rOwned[_excluded[i]];
            tSupply -= _tOwned[_excluded[i]];
        }

        if (rSupply < _rTotal /_tTotal) return (_rTotal, _tTotal);

        return (rSupply, tSupply);
    }

    /***********************************|
   |          General Functions         |
   |__________________________________*/
    function getCurrentBurnFeeOnSale() external view returns (uint256 fee) {
        uint256 time_since_start = block.timestamp - _start_timestamp;
        return RFIFeeCalculator.getCurrentBurnFeeOnSale(time_since_start, taxTiers, feeData);
    }

    function getCurrentHolderFeeOnSale() external view returns (uint256 fee) {
        uint256 time_since_start = block.timestamp - _start_timestamp;
        return RFIFeeCalculator.getCurrentHolderFeeOnSale(time_since_start, taxTiers, feeData);
    }

    function getCurrentMarketingFeeOnSale() external view returns (uint256 fee) {
        uint256 time_since_start = block.timestamp - _start_timestamp;
        return RFIFeeCalculator.getCurrentMarketingFeeOnSale(time_since_start, taxTiers, feeData);
    }

    function calculateFee(uint256 amount, uint256 fee) internal pure returns (uint256) {
        return (amount * fee) / 10**4;
    }
    
    /***********************************|
    |        Transfer Functions         |
    |__________________________________*/
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
        if (sender == address(0) || recipient == address(0)) revert SenderOrRecipientAddressIsZero(sender, recipient);
        if (_isBlacklisted[sender] || _isBlacklisted[recipient]) revert SenderOrRecipientBlacklisted(sender, recipient);
        if (amount <= 0) revert AmountIsZero();
        if (!tradingIsEnabled && (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient])) revert TradingNotStarted();

        if (!_isExcludedFromMaxTx[sender] && !_isExcludedFromMaxTx[recipient]) {
            if(amount > _maxTxAmount) revert MaxTransactionAmountExeeds(_maxTxAmount, amount);
        }

        uint256 curentSenderBalance = balanceOf(sender);
        if (amount > curentSenderBalance) {
            revert InsufficientBalance({
                available: curentSenderBalance,
                required: amount
            });
        }

        _beforeTokenTransfer(sender, recipient, amount);

        //if any account belongs to _isExcludedFromFee account then remove the fee
        bool takeFee = true;
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) takeFee = false;
        bool isSell = false;
        if (sender != address(uniswapV2Router) && automatedMarketMakerPairs[recipient] && takeFee) isSell = true;

        _tokenTransfer(sender, recipient, amount, takeFee, isSell);

        uint256 _swapMarketingFeeCollected = _marketingFeeCollected;
        if (_swapMarketingFeeCollected >= _swapMarketingAtAmount && !inSwap && !automatedMarketMakerPairs[sender]) {
            swapAndSendTokensForMarketing(_swapMarketingAtAmount);
        }

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) internal {
        uint256 transferAmount = amount;
        uint256 currentRate = _getRate();

        if (takeFee) {
            uint256 tss = block.timestamp - _start_timestamp;
            RFIFeeCalculator.transactionFee memory f = amount.calculateFees(currentRate, feeData, isSell, taxTiers, tss);
            // Take Reflect Fee
            _takeReflectFee(sender, recipient, f);
            _reflectFee(f.rFee, f.tFee);

            if (f.tMarketing > 0) {
                _marketingFeeCollected += f.tMarketing;
                _takeTransactionFee(address(this), f.tMarketing, f.currentRate);
            }

            if (f.tBurn > 0) {
                _takeTransactionFee(address(0), f.tBurn, f.currentRate);
                _burn(sender, f.tBurn);
            }

            transferAmount = f.tTransferAmount;
        } else {
            uint256 reflectionAmount = transferAmount * currentRate;
            RFIFeeCalculator.transactionFee memory nofee = RFIFeeCalculator.transactionFee(
                reflectionAmount, reflectionAmount, 0, 0, 0, transferAmount, transferAmount, 0, 0, 0, currentRate
            );
            _takeReflectFee(sender, recipient, nofee);
        }

        emit Transfer(sender, recipient, transferAmount);
    }

    function _takeReflectFee(address sender, address recipient, RFIFeeCalculator.transactionFee memory f) internal {
        _rOwned[sender] -= f.rAmount;
        _rOwned[recipient] += f.rTransferAmount;

        if (_isExcluded[sender]) _tOwned[sender] -= f.tAmount;
        if (_isExcluded[recipient]) _tOwned[recipient] += f.tTransferAmount;
    }

    function _takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) internal {
        uint256 rAmount = tAmount * currentRate;
        _rOwned[to] += rAmount;

        if (_isExcluded[to]) _tOwned[to] += tAmount;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) internal {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    /***********************************|
    |            External Calls         |
    |__________________________________*/
    function swapAndSendTokensForMarketing(uint256 tokenAmount) internal lockTheSwap {
        if (tokenAmount > _marketingFeeCollected) {
            tokenAmount = _marketingFeeCollected;
        }

        _marketingFeeCollected -= tokenAmount;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        emit MarketingFeeSent(tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _marketingWallet,
            block.timestamp + 360
        );
    }

    function withdrawAnyToken(address _recipient, address _ERC20address, uint256 _amount) external onlyOwner returns (bool) {
        if(_ERC20address == address(this)) revert CannotTransferContractTokens();
        return IERC20Upgradeable(_ERC20address).transfer(_recipient, _amount);
    }

    function transferXS() external onlyOwner returns (bool) {
        (bool success,) = owner().call{value: address(this).balance}("");
        
        return success;
    }

    // Current Version of the implementation
    function version() external pure returns (string memory) {
        return '1.0.0';
    }
}