// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IRouter.sol";

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

    struct SaleDetail {
        address owner;
        address feeTo;
        IRouter router;
        IERC20 token;
        bool isQuoteETH;
        uint256 price;
        uint256 listingPrice;
        uint256 minPurchase;
        uint256 maxPurchase;
        uint256 startTime;
        uint256 endTime;
        uint256 lpPercent;
        uint256 softCap;
        uint256 hardCap;
        uint256[] vestingTimes;
        uint256[] vestingPercents;
        bool isAutoListing;
        uint256 baseFee;
        uint256 tokenFee;
    }

    uint256 public RATE_PRECISION_FACTOR = 10000;

    address public feeTo;
    IRouter public router;
    IERC20 public token;
    IERC20 public quoteToken;
    bool public isQuoteETH;
    uint256 public price;
    uint256 public listingPrice;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public lpPercent;
    uint256 public softCap;
    uint256 public hardCap;
    uint256[] public vestingTimes;
    uint256[] public vestingPercents;
    bool public isAutoListing;
    uint256 public baseFee;
    uint256 public tokenFee;

    SaleStatus public status;
    mapping(address => PurchaseDetail) public purchaseDetails;
    address[] public purchasers;
    uint256 public currentCap;

    bool public isWhitelistEnabled;
    mapping(address => bool) public whitelisteds;
    address[] public whitelistedList;

    event Purchased(address indexed sale, address indexed purchaser, uint256 amount);
    event Claimed(address indexed sale, address indexed purchaser, uint256 amount);
    event Refunded(address indexed sale, address indexed purchaser, uint256 amount);
    event SaleFinalized(address indexed sale);
    event SaleCanceled(address indexed sale);

    function initialize(SaleDetail memory _saleDetail) external initializer {
        // init upgradeable
        transferOwnership(_saleDetail.owner); // owner
        __ReentrancyGuard_init();

        // initialize
        feeTo = _saleDetail.feeTo;
        router = IRouter(_saleDetail.router);
        token = IERC20(_saleDetail.token);
        isQuoteETH = _saleDetail.isQuoteETH;
        price = _saleDetail.price;
        listingPrice = _saleDetail.listingPrice;
        minPurchase = _saleDetail.minPurchase;
        maxPurchase = _saleDetail.maxPurchase;
        softCap = _saleDetail.softCap;
        hardCap = _saleDetail.hardCap;
        startTime = _saleDetail.startTime;
        endTime = _saleDetail.endTime;
        lpPercent = _saleDetail.lpPercent;
        vestingTimes = _saleDetail.vestingTimes;
        vestingPercents = _saleDetail.vestingPercents;
        isAutoListing = _saleDetail.isAutoListing;
        baseFee = _saleDetail.baseFee;
        tokenFee = _saleDetail.tokenFee;
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

    function purchase(uint256 amount) external occurring validAmount(amount) {
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
            (hardCap * (1 ether)) /
            price +
            (((hardCap * lpPercent) / RATE_PRECISION_FACTOR) * (1 ether)) /
            listingPrice;
    }

    function calcCurrentTokensRequired() public view returns (uint256) {
        return
            (currentCap * (1 ether)) /
            price +
            (((currentCap * lpPercent) / RATE_PRECISION_FACTOR) * (1 ether)) /
            listingPrice;
    }

    function calcPurchasedTokenAmount(address purchaser) public view returns (uint256) {
        return (purchaseDetails[purchaser].amount * (1 ether)) / price;
    }

    function calcClaimableTokenAmount(address purchaser) public view returns (uint256) {
        if (status != SaleStatus.FINALIZED) {
            return 0;
        }
        uint256 totalTokens = calcPurchasedTokenAmount(purchaser);
        uint256 claimableTokens = 0;

        if (block.timestamp > vestingTimes[vestingTimes.length - 1]) {
            return totalTokens - purchaseDetails[purchaser].tokenAmountClaimed;
        }

        for (uint8 i = 0; i < vestingTimes.length - 1; i++) {
            if (block.timestamp > vestingTimes[i]) {
                claimableTokens = claimableTokens + (totalTokens * (vestingPercents[i])) / RATE_PRECISION_FACTOR;
            } else {
                break;
            }
        }
        return claimableTokens - purchaseDetails[purchaser].tokenAmountClaimed;
    }

    function finalizeInETH() external onlyOwner nonReentrant inQuoteETH {
        require(status == SaleStatus.STARTED, "ALREADY_FINALIZED_OR_CANCELED");
        status = SaleStatus.FINALIZED;

        if (baseFee > 0) {
            uint256 baseFeeAmount = (currentCap * baseFee) / RATE_PRECISION_FACTOR;
            payable(feeTo).transfer(baseFeeAmount);
        }

        if (tokenFee > 0) {
            uint256 tokenFeeAmount = (currentCap * tokenFee) / RATE_PRECISION_FACTOR;
            quoteToken.transfer(feeTo, tokenFeeAmount);
        }

        address owner = owner();
        if (isAutoListing) {
            // for liquidity
            uint256 ethLiqAmount = (currentCap * lpPercent) / RATE_PRECISION_FACTOR;
            uint256 tokenLiqAmount = (ethLiqAmount * (1 ether)) / listingPrice;

            token.approve(address(router), tokenLiqAmount);

            router.addLiquidityETH{value: ethLiqAmount}(address(token), tokenLiqAmount, 0, 0, owner, block.timestamp);

            // for project
            payable(owner).transfer(currentCap - ethLiqAmount);
        } else {
            // for project
            payable(owner).transfer(currentCap);
        }

        emit SaleFinalized(address(this));
    }

    function finalize() external onlyOwner inQuoteToken {
        require(status == SaleStatus.STARTED, "ALREADY_FINALIZED_OR_CANCELED");
        status = SaleStatus.FINALIZED;

        address owner = owner();
        if (isAutoListing) {
            // for liquidity
            uint256 currencyLiqAmount = (currentCap * lpPercent) / RATE_PRECISION_FACTOR;
            uint256 tokenLiqAmount = (currencyLiqAmount * (1 ether)) / listingPrice;

            token.approve(address(router), tokenLiqAmount);
            quoteToken.approve(address(router), currencyLiqAmount);

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

            // for project
            quoteToken.transfer(owner, currentCap - currencyLiqAmount);
        } else {
            quoteToken.transfer(owner, currentCap);
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
