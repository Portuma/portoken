// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library FeeCalculator {
    struct feeData {
        uint256 burnFee;
        uint256 holderFee;
        uint256 marketingFee;
        uint256 lPFee;
        uint256 stakeFee;
    }

    struct feeDataSell {
        uint256 burnFee;
        uint256 holderFee;
        uint256 marketingFee;
        uint256 lPFee;
        uint256 stakeFee;
    }

    struct transactionFee {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 rMarketing;
        uint256 rBurn;
        uint256 rLP;
        uint256 rStake;

        uint256 tAmount;
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tMarketing;
        uint256 tBurn;
        uint256 tLP;
        uint256 tStake;

        uint256 currentRate;
    }

    function calculateFees(
        uint256 amount,
        uint256 rate,
        feeData memory fd,
        feeDataSell memory fdSell,
        bool isSell
    ) internal pure returns (transactionFee memory) {
        transactionFee memory tf;
        tf.currentRate = rate;

        tf.tAmount    = amount;
        tf.tBurn      = calculateFee(amount, isSell ? fdSell.burnFee : fd.burnFee);
        tf.tFee       = calculateFee(amount, isSell ? fdSell.holderFee : fd.holderFee);
        tf.tMarketing = calculateFee(amount, isSell ? fdSell.marketingFee : fd.marketingFee);
        tf.tLP        = calculateFee(amount, isSell ? fdSell.lPFee : fd.lPFee);
        tf.tStake     = calculateFee(amount, isSell ? fdSell.stakeFee : fd.stakeFee);
        
        tf.tTransferAmount = amount - tf.tFee - tf.tMarketing - tf.tBurn - tf.tLP - tf.tStake;
        
        tf.rAmount    = tf.tAmount * tf.currentRate;
        tf.rBurn      = tf.tBurn * tf.currentRate;
        tf.rFee       = tf.tFee * tf.currentRate;
        tf.rMarketing = tf.tMarketing * tf.currentRate;
        tf.rLP        = tf.tLP * tf.currentRate;
        tf.rStake     = tf.tStake * tf.currentRate;

        tf.rTransferAmount = tf.rAmount - tf.rFee - tf.rMarketing - tf.rBurn - tf.rLP - tf.rStake;

        return tf;
    }

    function calculateFee(uint256 amount, uint256 fee) internal pure returns (uint256) {
        return (amount * fee) / 10**4;
    }
}