// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IPreSale.sol";
import "./interfaces/IBionLock.sol";

contract PreSale is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    enum SaleStatus {
        STARTED,
        FINALIZED,
        CANCELED
    }

    struct PurchaseDetail {
        address purchaser;
        uint256 amount;
        uint256 tokenAmountClaimed;
        bool isRefunded;
    }

    uint256 public constant RATE_PRECISION_FACTOR = 10000;

    address public feeTo;
    IRouter public router;
    IERC20 public token;
    IERC20 public quoteToken;
    bool public isQuoteETH;
    bool public isWhitelistEnabled;
    bool public isBurnUnsold;
    uint256 public price;
    uint256 public listingPrice;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public lpPercent;
    uint256 public softCap;
    uint256 public hardCap;
    bool public isAutoListing;
    uint256 public baseFee;
    uint256 public tokenFee;
    uint256 public tgeDate;
    uint256 public tgeReleasePercent;
    uint256 public cycleDuration;
    uint256 public cycleReleasePercent;
    uint256 public lockLPDuration; // in days

    SaleStatus public status;
    mapping(address => PurchaseDetail) public purchaseDetails;
    address[] public purchasers;
    uint256 public currentCap;

    mapping(address => bool) public whitelisteds;
    address[] public whitelistedList;

    uint256 public tokenDecimals;
    uint256 public quoteTokenDecimals;
    IBionLock public bionLock;
    uint256 public lockId;

    event Purchased(address indexed sale, address indexed purchaser, uint256 amount);
    event Claimed(address indexed sale, address indexed purchaser, uint256 amount);
    event Refunded(address indexed sale, address indexed purchaser, uint256 amount);
    event SaleFinalized(address indexed sale);
    event SaleCanceled(address indexed sale);

    function initialize(SaleDetail memory _saleDetail, address _bionLock) external initializer {
        // init upgradeable
        _transferOwnership(_saleDetail.owner); // owner
        __ReentrancyGuard_init();
        if (_saleDetail.lpPercent == 0) {
            require(!_saleDetail.isAutoListing, "INVALID_LP_PERCENT");
        }

        require(
            (_saleDetail.tgeReleasePercent + _saleDetail.cycleReleasePercent) <= RATE_PRECISION_FACTOR,
            "INVALID_RELEASE_PERCENT"
        );
        require(
            _saleDetail.startTime < _saleDetail.endTime && _saleDetail.endTime < _saleDetail.tgeDate,
            "INVALID_TIME"
        );

        // initialize
        feeTo = _saleDetail.feeTo;
        router = IRouter(_saleDetail.router);
        token = IERC20(_saleDetail.token);
        quoteToken = IERC20(_saleDetail.quoteToken);
        isQuoteETH = _saleDetail.quoteToken == address(0) ? true : false;
        isWhitelistEnabled = _saleDetail.isWhitelistEnabled;
        isBurnUnsold = _saleDetail.isBurnUnsold;
        price = _saleDetail.price;
        listingPrice = _saleDetail.listingPrice;
        minPurchase = _saleDetail.minPurchase;
        maxPurchase = _saleDetail.maxPurchase;
        softCap = _saleDetail.softCap;
        hardCap = _saleDetail.hardCap;
        startTime = _saleDetail.startTime;
        endTime = _saleDetail.endTime;
        lpPercent = _saleDetail.lpPercent;
        isAutoListing = _saleDetail.isAutoListing;
        baseFee = _saleDetail.baseFee;
        tokenFee = _saleDetail.tokenFee;
        tgeDate = _saleDetail.tgeDate;
        tgeReleasePercent = _saleDetail.tgeReleasePercent;
        cycleDuration = _saleDetail.cycleDuration;
        cycleReleasePercent = _saleDetail.cycleReleasePercent;
        lockLPDuration = _saleDetail.lockLPDuration;

        bionLock = IBionLock(_bionLock);
        tokenDecimals = IERC20Metadata(address(token)).decimals();
        quoteTokenDecimals = isQuoteETH ? 18 : IERC20Metadata(address(quoteToken)).decimals();
    }

    modifier occurring() {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime && status == SaleStatus.STARTED,
            "NOT_OCCURRING"
        );
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount >= minPurchase && amount <= maxPurchase && currentCap + amount <= hardCap, "INVALID_AMOUNT");
        _;
    }

    modifier whenFinalized() {
        require(status == SaleStatus.FINALIZED, "NOT_FINALIZED_YET");
        _;
    }

    modifier whenCanceled() {
        require(status == SaleStatus.CANCELED, "NOT_CANCELED");
        _;
    }

    modifier inQuoteETH() {
        require(isQuoteETH, "NOT_BUY_IN_ETH");
        _;
    }

    modifier inQuoteToken() {
        require(!isQuoteETH, "NOT_BUY_IN_TOKEN");
        _;
    }

    function setWhitelistEnabled(bool _isWhitelistEnabled) external onlyOwner {
        isWhitelistEnabled = _isWhitelistEnabled;
    }

    function addWhitelist(address account) public onlyOwner {
        require(!whitelisteds[account], "ALREADY_WHITELISTED");
        whitelisteds[account] = true;
        whitelistedList.push(account);
    }

    function removeWhitelist(address account) public onlyOwner {
        require(whitelisteds[account], "NOT_WHITELISTED");
        whitelisteds[account] = false;
        for (uint256 i = 0; i < whitelistedList.length; i++) {
            if (whitelistedList[i] == account) {
                whitelistedList[i] = whitelistedList[whitelistedList.length - 1];
                whitelistedList.pop();
                break;
            }
        }
    }

    function addWhitelistMany(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            addWhitelist(accounts[i]);
        }
    }

    function getWhitelistedList() public view returns (address[] memory) {
        return whitelistedList;
    }

    function getAllPurchasers() public view returns (PurchaseDetail[] memory) {
        uint256 length = purchasers.length;
        PurchaseDetail[] memory allPurchasers = new PurchaseDetail[](length);

        for (uint8 i = 0; i < length; i++) {
            allPurchasers[i] = purchaseDetails[purchasers[i]];
        }

        return allPurchasers;
    }

    function purchaseInETH() external payable occurring validAmount(msg.value) inQuoteETH {
        if (isWhitelistEnabled) {
            require(whitelisteds[msg.sender], "NOT_WHITELISTED");
        }

        PurchaseDetail memory purchaseDetail = purchaseDetails[msg.sender];
        require(purchaseDetail.amount == 0, "ALREADY_PURCHASED");

        uint256 amount = msg.value;
        currentCap = currentCap + amount;
        if (purchaseDetail.amount == 0) {
            purchaseDetails[msg.sender].purchaser = msg.sender;
            purchasers.push(msg.sender);
        }
        purchaseDetails[msg.sender].amount = purchaseDetail.amount + amount;

        emit Purchased(address(this), msg.sender, amount);
    }

    function purchase(uint256 amount) external occurring validAmount(amount) inQuoteToken {
        if (isWhitelistEnabled) {
            require(whitelisteds[msg.sender], "NOT_WHITELISTED");
        }

        PurchaseDetail memory purchaseDetail = purchaseDetails[msg.sender];
        require(purchaseDetail.amount == 0, "ALREADY_PURCHASED");

        quoteToken.transferFrom(msg.sender, address(this), amount);
        currentCap = currentCap + amount;
        if (purchaseDetail.amount == 0) {
            purchaseDetails[msg.sender].purchaser = msg.sender;
            purchasers.push(msg.sender);
        }
        purchaseDetails[msg.sender].amount = purchaseDetail.amount + amount;

        emit Purchased(address(this), msg.sender, amount);
    }

    function calcTotalTokensRequired() public view returns (uint256) {
        return
            (((hardCap * (RATE_PRECISION_FACTOR + baseFee)) / RATE_PRECISION_FACTOR) * 10**tokenDecimals) /
            price +
            (((hardCap * lpPercent) / RATE_PRECISION_FACTOR) * 10**tokenDecimals) /
            listingPrice;
    }

    function calcCurrentTokensRequired() public view returns (uint256) {
        return
            (((currentCap * (RATE_PRECISION_FACTOR + baseFee)) / RATE_PRECISION_FACTOR) * 10**tokenDecimals) /
            price +
            (((currentCap * lpPercent) / RATE_PRECISION_FACTOR) * 10**tokenDecimals) /
            listingPrice;
    }

    function calcPurchasedTokenAmount(address purchaser) public view returns (uint256) {
        return (purchaseDetails[purchaser].amount * 10**tokenDecimals) / price;
    }

    function calcClaimableTokenAmount(address purchaser) public view returns (uint256) {
        if (status != SaleStatus.FINALIZED || block.timestamp < tgeDate) {
            return 0;
        }
        uint256 precision = RATE_PRECISION_FACTOR; // gas saving

        uint256 totalTokens = calcPurchasedTokenAmount(purchaser);
        uint256 tgeReleaseAmount = (totalTokens * tgeReleasePercent) / precision;
        uint256 cycleReleaseAmount = (totalTokens * cycleReleasePercent) / precision;
        uint256 totalCycles = (RATE_PRECISION_FACTOR - tgeReleasePercent) /
            cycleReleasePercent +
            ((RATE_PRECISION_FACTOR - tgeReleasePercent) % cycleReleasePercent == 0 ? 0 : 1);
        uint256 currentCycle = (block.timestamp - tgeDate) / cycleDuration;

        uint256 vestingAmount = 0;
        if (currentCycle == 0) {
            vestingAmount = tgeReleaseAmount;
        } else if (currentCycle >= totalCycles) {
            vestingAmount = totalTokens;
        } else {
            vestingAmount = tgeReleaseAmount + (cycleReleaseAmount * currentCycle);
        }

        return vestingAmount - purchaseDetails[purchaser].tokenAmountClaimed;
    }

    function finalizeInETH() external onlyOwner nonReentrant inQuoteETH {
        require(status == SaleStatus.STARTED, "ALREADY_FINALIZED_OR_CANCELED");
        status = SaleStatus.FINALIZED;

        uint256 baseFeeAmount = 0;
        if (baseFee > 0) {
            baseFeeAmount = (currentCap * baseFee) / RATE_PRECISION_FACTOR;
            payable(feeTo).transfer(baseFeeAmount);
        }

        uint256 tokenFeeAmount = 0;
        if (tokenFee > 0) {
            tokenFeeAmount = (((currentCap * 10**tokenDecimals) / price) * tokenFee) / RATE_PRECISION_FACTOR;
            token.transfer(feeTo, tokenFeeAmount);
        }

        address owner = owner();
        if (isAutoListing) {
            // for liquidity
            uint256 ethLiqAmount = (currentCap * lpPercent) / RATE_PRECISION_FACTOR;
            uint256 tokenLiqAmount = (ethLiqAmount * 10**tokenDecimals) / listingPrice;

            token.approve(address(router), tokenLiqAmount);
            if (lockLPDuration > 0) {
                router.addLiquidityETH{value: ethLiqAmount}(
                    address(token),
                    tokenLiqAmount,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );

                address pair = IFactory(router.factory()).getPair(address(token), router.WETH());
                IERC20(pair).approve(address(bionLock), IERC20(pair).balanceOf(address(this)));

                lockId = bionLock.lock(
                    owner,
                    pair,
                    true,
                    IERC20(pair).balanceOf(address(this)),
                    block.timestamp + lockLPDuration,
                    ""
                );
            } else {
                router.addLiquidityETH{value: ethLiqAmount}(
                    address(token),
                    tokenLiqAmount,
                    0,
                    0,
                    owner,
                    block.timestamp
                );
            }

            // for project
            payable(owner).transfer(currentCap - ethLiqAmount - baseFeeAmount);
        } else {
            // for project
            payable(owner).transfer(currentCap - baseFeeAmount);
        }

        uint256 unsoldTokens = calcTotalTokensRequired() - calcCurrentTokensRequired();
        if (isBurnUnsold) {
            token.transfer(0x000000000000000000000000000000000000dEaD, unsoldTokens);
        } else {
            token.transfer(owner, unsoldTokens);
        }

        emit SaleFinalized(address(this));
    }

    function finalize() external onlyOwner inQuoteToken {
        require(status == SaleStatus.STARTED, "ALREADY_FINALIZED_OR_CANCELED");
        status = SaleStatus.FINALIZED;

        uint256 baseFeeAmount = 0;
        if (baseFee > 0) {
            baseFeeAmount = (currentCap * baseFee) / RATE_PRECISION_FACTOR;
            quoteToken.transfer(feeTo, baseFeeAmount);
        }

        uint256 tokenFeeAmount = 0;
        if (tokenFee > 0) {
            tokenFeeAmount = (((currentCap * 10**tokenDecimals) / price) * tokenFee) / RATE_PRECISION_FACTOR;
            token.transfer(feeTo, tokenFeeAmount);
        }

        address owner = owner();
        if (isAutoListing) {
            // for liquidity
            uint256 currencyLiqAmount = (currentCap * lpPercent) / RATE_PRECISION_FACTOR;
            uint256 tokenLiqAmount = (currencyLiqAmount * 10**tokenDecimals) / listingPrice;

            token.approve(address(router), tokenLiqAmount);
            quoteToken.approve(address(router), currencyLiqAmount);

            if (lockLPDuration > 0) {
                router.addLiquidity(
                    address(token),
                    address(quoteToken),
                    tokenLiqAmount,
                    currencyLiqAmount,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );

                address pair = IFactory(router.factory()).getPair(address(token), address(quoteToken));
                IERC20(pair).approve(address(bionLock), IERC20(pair).balanceOf(address(this)));
                lockId = bionLock.lock(
                    owner,
                    pair,
                    true,
                    IERC20(pair).balanceOf(address(this)),
                    block.timestamp + lockLPDuration,
                    ""
                );
            } else {
                router.addLiquidity(
                    address(token),
                    address(quoteToken),
                    tokenLiqAmount,
                    currencyLiqAmount,
                    0,
                    0,
                    owner,
                    block.timestamp
                );
            }

            // for project
            quoteToken.transfer(owner, currentCap - currencyLiqAmount - baseFeeAmount);
        } else {
            quoteToken.transfer(owner, currentCap - baseFeeAmount);
        }

        uint256 unsoldTokens = calcTotalTokensRequired() - calcCurrentTokensRequired();
        if (isBurnUnsold) {
            token.transfer(0x000000000000000000000000000000000000dEaD, unsoldTokens);
        } else {
            token.transfer(owner, unsoldTokens);
        }

        emit SaleFinalized(address(this));
    }

    function cancelSale() external onlyOwner {
        require(status == SaleStatus.STARTED, "ALREADY_CANCELED_OR_FINALIZED");
        status = SaleStatus.CANCELED;
    }

    function refundInETH() external whenCanceled nonReentrant inQuoteETH {
        PurchaseDetail memory purchaseDetail = purchaseDetails[msg.sender];
        require(purchaseDetail.amount > 0 && !purchaseDetail.isRefunded, "INVALID_ACTION");

        purchaseDetails[msg.sender].isRefunded = true;
        payable(msg.sender).transfer(purchaseDetail.amount);

        emit Refunded(address(this), msg.sender, purchaseDetail.amount);
    }

    function refund() external whenCanceled inQuoteToken {
        PurchaseDetail memory purchaseDetail = purchaseDetails[msg.sender];
        require(purchaseDetail.amount > 0 && !purchaseDetail.isRefunded, "INVALID_ACTION");

        purchaseDetails[msg.sender].isRefunded = true;
        quoteToken.transfer(msg.sender, purchaseDetail.amount);

        emit Refunded(address(this), msg.sender, purchaseDetail.amount);
    }

    function claim() external whenFinalized {
        PurchaseDetail memory purchaseDetail = purchaseDetails[msg.sender];
        require(purchaseDetail.amount > 0, "INVALID_ACTION");

        uint256 claimableAmount = calcClaimableTokenAmount(msg.sender);
        require(claimableAmount > 0, "NO_CLAIMABLE_TOKEN");

        purchaseDetails[msg.sender].tokenAmountClaimed = purchaseDetail.tokenAmountClaimed + claimableAmount;
        token.transfer(msg.sender, claimableAmount);

        emit Claimed(address(this), msg.sender, claimableAmount);
    }
}
