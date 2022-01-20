// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// End Of Support
library RFIFeeCalculator {
    uint256 private constant HOUR = 60 * 60;

    struct feeData {
        uint256 burnFee;
        uint256 holderFee;
        uint256 marketingFee;
    }

    struct feeDataSell {
        uint256 burnFee;
        uint256 holderFee;
        uint256 marketingFee;
    }

    struct transactionFee {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 rMarketing;
        uint256 rBurn;

        uint256 tAmount;
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tMarketing;
        uint256 tBurn;

        uint256 currentRate;
    }

    struct taxTiers {
        uint256[] time;
        mapping(uint256 => feeData) tax;
    }
}