//SPDX-License-Identifier:UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MyToken is ERC20 {
    address public owner;

    constructor() ERC20("MyToken", "MTK") {
        owner = msg.sender;
        mint(msg.sender, 100*10**18);
    }

    function mint(address to, uint256 amount) private {
        _mint(to, amount);
    }

    /**
     * Allowing max amount of token(for now) to Contract EncodingDataInSolidity,
     * So that it will transfer token on behalf of Owner.

     * @param _contract  =>  Address of EncodingDataInSolidity-Contract
     * 
     */
    function approveContract(address _contract) external{
        require(msg.sender == owner, "onlyOwner Function");
        approve(_contract, 100*10**18); // allowing max amount of token
    }
}

contract EncodingDataInSolidity{
    IERC20 public tokenContract;

    constructor(address _tokenContract){
        tokenContract = IERC20(_tokenContract);
    }

    function tokenTransferWithEncodeData(address _contract, bytes calldata data) external {
        (bool success, ) = _contract.call(data);
        require(success, "Contract call failed.");
    }
    /** 
    . An encoded function is a function that has been transformed into (EVM’s) bytecode.

    . This encoded data is used to create payload data that can be sent to
      function calls for the external contract calls. These are also used to
      generate unique hashes of different values.

    . For example let say, you have a secondary contract which has a function "Fun-A" and from your primary contract
      you need to call that function multiple times depending on situation, instead of everytime writing
      whole code again and again, we can simply encode that function signature and store it on a constant
      state variable, and use it in external contract call further.

    . There is no perticular rule, that we have follow this way. But when project big, and there are so many external
      contract calls, at that time this type of technique makes whole code base looks more cleaner and professional

     3 ways of encoding data
                 a. encodeWithSignature()
                 b. encodeWithSelector()
                 c. encodeCall()
    

     /**
     * encodeWithSignature()
     * @param _to  =>  The receiver address
     * @param _amount => Amount of token to be sent

     * Here Problem is that
     * Even if we pass wrong function signature like 
       "transferFrom(address,address, uint256)" or
       "transferFrom(address,address,uint)" the contract will still successfully compile, which is wrong btw
     */
    function encodingTypeOne(address _to, uint256 _amount) external view returns(bytes memory){
        return abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, _to, _amount);
        //return abi.encodeWithSignature("transferFrom(address,address, uint256)", msg.sender, _to, _amount);
    }

    /**
     * encodeWithSelector()
     * @param _to  =>  The receiver address
     * @param _amount => Amount of token to be sent

     * The fisrt Problem is tackled here but it comes with its own
     * Here we can't pass wrong signature like 
       IERC20.transferFroms.selector , compiler produce a error

     * However this still compile successfully if we wrong inputs
       // data = abi.encodeWithSelector(IERC20.transferFrom.selector, msg.sender, _to, true);
       like here instead of address, address, uint  I pass address, address, bool

       or even it compile without error, when we forgot to pass any argument
       // data = abi.encodeWithSelector(IERC20.transferFrom.selector, msg.sender, _to);
       like here i only pass address, address i.e i pass only 2 when it requires 3

    * PLEASE COPY PASTE ABOVE BUGY CODE IN FUNCTION, TO TEST ON YOUR OWN
    */
    
    function encodingTypeTwo(address _to, uint _amount) external view returns(bytes memory data){
        data = abi.encodeWithSelector(IERC20.transferFrom.selector, msg.sender, _to, _amount);   
    }

    /**
     * encodeCall()
     * @param _to  =>  The receiver address
     * @param _amount => Amount of token to be sent
     *
     * Here we can't pass wrong function name or wrong input data(both datatype and amount of data)
     * So encodeCall checks that both function and input to pass are matches or not, if not it through errors
     */
    function encodingTypeThree(address _to, uint _amount) external view returns(bytes memory data){
        data = abi.encodeCall(IERC20.transferFrom, (msg.sender, _to, _amount));
    }


    /**
    * END LESSON
    a. encodeWithSignature() => We can mistakely send wrong function signature
    b. encodeWithSelector() => Here we can't mess with function signature, 
                               but cann pass wrong input datatype and amount of inputs 
    c. encodeCall()  => Both issues resolved by using this, if function name or input datatypes
                        not match, though compilation error
    */
}