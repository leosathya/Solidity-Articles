//SPDX-License-Identifier:UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ETHHandler{
    address payable immutable owner;

    event BalanceReceived(address, uint);
    event BalanceWithdrawn(address, uint);

    modifier onlyOwner{
        require(msg.sender == owner, "onlyOwner can.");
        _;
    }

    constructor(address _mainContract){
        owner = payable(_mainContract);
    }
    function showETHBalance() external view returns(uint bal){
        bal = address(this).balance;
    } 

    /**
     1. If a function marked as payable then, we can simply transfer ETH to that contract
        by calling that function and passing ETH as msg.value

     2. To Transfer ETH from a Contract to other Contract or EOA we have 3 methods
        And the receiver contract only will able to receive ETH, only and only when it defines 
        receive()/fallback() in its code base, otherwise ETH transfer will failed.

                a. send()
                b. transfer()
                c. call() 
        
        send() -> . on transaction fail, its return a bool(true for success, false for failure)
                  . So in that case it get mandatory to check return value of send() to know the 
                    status of transaction
                  . This Function use a hardcoded gas amount(2300)

        transfer() -> . on transaction fail, it reverts(means return true on success, on failure whole
                        transaction get reverted)
                      . This function also use hardcoded gas amount(2300)

        In above two(send and transfer) both use 2300 gas only, this gas amount is sufficient for
        transfering ETH(native coin) and log a event in Past. This act like a Reentrancy gaurd.
        
        But the problem here is The Istanbul hardfork increases the gas cost of the SLOAD operation and
        therefore breaks some existing smart contracts. any smart contract that uses transfer() or send() 
        is taking a hard dependency on gas costs by forwarding a fixed amount of gas (2300). 
        This forwards 2300 gas, which may not be enough if the recipient is a contract and the cost of gas changes.

        So to solve above problem its recommended to use call()

        call() -> . on transaction fail, its return bool(true for success, false for failure)
                  . This is a low level function, not only it used to send ETH(native coin) it also used to
                    call other functions as well.
                  . No hardcoded gas limits here

        This also open up a another problem, as there is no hardcoded gas limits so this is vulnerable to
        reentrancy attack.
        This problem can easily erradicated by proper use of Check-Effect-Interaction Pattern or by using
        Reentrancy gaurd.


        END OF STORY
        . Avoid to use transfer() and call()
        . Switch to call() for transfering ETH(native token) with proper Reentrancy guard

    */

    function receiveEth() external payable{
        emit BalanceReceived(msg.sender, msg.value);
    }


    function withdrawETH() external{
        uint amount = address(this).balance;

        // send
        require(owner.send(amount), "Sending ETH via send Failed.");

        // // transfer
        // owner.transfer(amount);

        // // call
        // (bool success, ) = owner.call{value: amount}("");
        // require(success, "Sending ETH via call Failed");
    }
}



contract MyToken is ERC20, Ownable {
    mapping(address => uint256) private _balances;
    constructor() ERC20("MyToken", "MTK") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
      Here for transfering ERC20 contract use transfer()/transferFrom()

      The ERC20.transfer() and ERC20.transferFrom() functions return a 
      boolean value indicating success. This parameter needs to be checked for success.
      Some tokens(like USDT) do not revert if the transfer failed but return false instead. 
      Tokens that don’t actually perform the transfer and return false are still counted as a correct transfer.

      To get rid of this type of problem always use SafeERC20 instaed of ERC20 and 
      safeTransfer()/safeTransferFrom instaed of transfer()/transferFrom()
    */

}



contract MainContract{
    address payable immutable public owner;

    event BalanceReceived(address, uint);
    event BalanceWithdrawn(address, uint);

    constructor(){
        owner = payable(msg.sender);
    }

    fallback() external payable{
        emit BalanceReceived(msg.sender, msg.value);
    }
} 