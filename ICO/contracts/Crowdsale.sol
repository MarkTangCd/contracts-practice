pragma solidity ^0.4.16;

interface token {
    function transfer(address receiver, uint256 amount) external;
}

contract Crowdsale {
    address public beneficiary; // 募资成功后的收款方
    uint256 public fundingGoal; // 募资额度
    uint256 public amountRaised; // 参与数量
    uint256 public deadline; // 募资截止期

    uint256 public price; // token与以太坊的汇率，token 卖多少钱
    token public tokenReward; // 要卖的token

    mapping(address => uint256) public balanceOf;

    bool fundingGoalReached = false; // 众筹是否达到目标
    bool crowdsaleClosed = false; // 众筹是否结束

    event GoalReached(address recipient, uint256 totalAmountRaised);
    event FundTransfer(address backer, uint256 amount, bool isContribution);

    constructor(
        address ifSuccessfulSendTo,
        uint256 fundingGoalInEthers,
        uint256 durationInMinutes,
        uint256 finneyCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = finneyCostOfEachToken * 1 finney;
        tokenReward = token(addressOfTokenUsedAsReward); // 传入已发布的token合约的地址来创建实例
    }

    /**
     * 无函数名的Fallback函数
     * 在向合约转账时，这个函数会被调用
     **/
    function() payable public {
        require(!crowdsaleClosed);
        uint256 amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        emit FundTransfer(msg.sender, amount, true);
    }

    /**
     * 定义函数修改器modifier (作用和Python的装饰器很相似)
     * 用于在函数执行前检查某种前置条件 (判断通过之后才会继续执行该方法)
     * _ 表示继续执行之后的代码
     **/
    modifier afterDeadline() {
        if (now >= deadline) _;
    }

    // 判断众筹是否完成融资目标，这个方法使用了afterDeadline 函数修改器
    function checkGoalReached() afterDeadline public {
        if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    /**
     * 完成融资目标时，融资款发送到收款方
     * 未完成融资目标时，执行退款
     **/
    function safeWithdrawal() afterDeadline public {
        if (!fundingGoalReached) {
            uint256 amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
                emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                // If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
}
