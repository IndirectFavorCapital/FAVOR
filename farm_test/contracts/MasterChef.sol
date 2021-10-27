pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "@nomiclabs/buidler/console.sol";

//Interfeace for interact with pancakeswap farm smart contract
interface IFarm {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
}

// MasterChef is the master of Favor. He can make Favor and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Favor is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant MAX_UINT = 2**256 - 1;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Favors
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accFavorPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accFavorPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        address favorCampaignOwner;       // Address of campaign owner
        uint256 pancakeswapPid;   // Pancakeswap farm pool id
        uint256 allocPoint;       // How many allocation points assigned to this pool. Favors to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Favors distribution occurs.
        uint256 accFavorPerShare; // Accumulated Favors per share, times 1e12. See below.
    }

    // The Favor TOKEN!
    IERC20 public favor;
    // The SYRUP TOKEN!
    //SyrupBar public syrup;
    // Dev address.
    address public devaddr;
    // Favor tokens created per block.
    uint256 public favorPerBlock;
    // Bonus muliplier for early favor makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Favor mining starts.
    uint256 public startBlock;
    // Pancakeswap farm smart contract
    IFarm public pancakeswapFarm;
    // Cake Token address 
    IERC20 public cake;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _favor,
    //    SyrupBar _syrup,
    //    address _devaddr,
        IFarm _pancakeswapFarm,
        IERC20 _cake,
        uint256 _favorPerBlock,
        uint256 _startBlock
    ) public {
        favor = _favor;
    //    syrup = _syrup;
        devaddr = msg.sender;// _devaddr;
        pancakeswapFarm = _pancakeswapFarm;
        cake = _cake;
        favorPerBlock = _favorPerBlock;
        startBlock = _startBlock;

        /*
        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _favor,
            favorCampaignOwner: devaddr,
            pancakeswapPid: 0,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accFavorPerShare: 0
        }));
        */

        totalAllocPoint = 1000;

    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, address _favorCampaignOwner, uint256 _pancakeswapPid, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            favorCampaignOwner: _favorCampaignOwner,
            pancakeswapPid: _pancakeswapPid,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accFavorPerShare: 0
        }));
        //updateStakingPool();

        _lpToken.approve(address(pancakeswapFarm), MAX_UINT);
    }

    // Update the given pool's Favor allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            //updateStakingPool();
        }
    }


    /*
    function updateStakingPool() internal {
        uint256 length = poolInfo.length;
        uint256 points = 0;
        for (uint256 pid = 1; pid < length; ++pid) {
            points = points.add(poolInfo[pid].allocPoint);
        }
        if (points != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(poolInfo[0].allocPoint).add(points);
            poolInfo[0].allocPoint = points;
        }
    }
    */


    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending Favors on frontend.
    function pendingFavor(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accFavorPerShare = pool.accFavorPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 favorReward = multiplier.mul(favorPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accFavorPerShare = accFavorPerShare.add(favorReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accFavorPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 favorReward = multiplier.mul(favorPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        //favor.mint(favorReward.div(10));
        //favor.mint(address(syrup), favorReward);
        pool.accFavorPerShare = pool.accFavorPerShare.add(favorReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for Favor allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'deposit Favor by staking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accFavorPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                uint256 half = pending.div(2);
                favorTransfer(msg.sender, half);
                favorTransfer(pool.favorCampaignOwner, pending - half);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accFavorPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);

        pancakeswapFarm.deposit(pool.pancakeswapPid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'withdraw Favor by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accFavorPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            uint256 half = pending.div(2);
            favorTransfer(msg.sender, half);
            favorTransfer(pool.favorCampaignOwner, pending - half);
            
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pancakeswapFarm.withdraw(pool.pancakeswapPid, _amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accFavorPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);

    }


    /*
    // Stake Favor tokens to MasterChef
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accFavorPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                favorTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accFavorPerShare).div(1e12);

    //    syrup.mint(msg.sender, _amount);
        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw Favor tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accFavorPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            favorTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accFavorPerShare).div(1e12);

    //    syrup.burn(msg.sender, _amount);
        emit Withdraw(msg.sender, 0, _amount);
    }
    */

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pancakeswapFarm.withdraw(pool.pancakeswapPid, _amount);
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Favor transfer function
    function favorTransfer(address _to, uint256 _amount) internal {
        uint256 favorBal = favor.balanceOf(address(this));
        require(favorBal >= _amount, "not enough favor in smart contract");
        favor.transfer(_to, _amount);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    // Withdraw cake reward from samrt contract to dev
    function cakeWithdraw() public onlyOwner {
        uint256 cakeBal = cake.balanceOf(address(this));
        cake.transfer(devaddr, cakeBal);
    }

    // Withdraw favor reward from samrt contract to dev
    function favorWithdraw() public onlyOwner {
        uint256 favorBal = favor.balanceOf(address(this));
        favor.transfer(devaddr, favorBal);
    }
}
