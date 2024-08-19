// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./FeeConlecter.sol";

contract Bookie is AccessControl,Ownable(msg.sender){
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ARBITER_ROLE = keccak256("ARBITER_ROLE");

   address payable withdrawWallet;

    uint128 countPlayer;
    uint128 countArbiter;
    FeeColector public feeConlecter;

    struct Player{
        string username;
        address wallet;
        uint256 registrationFee;
        uint8 typePlayer; 
    }

    struct Arbiter{
        address wallet;
        bool status;
    }

    mapping(string => bool) private usernameExists;
    mapping (uint128 => Player) public listPlayer;
    mapping (uint128 => Arbiter) public listArbiter;

    event CreatePlayer(
       string _username, 
       address _wallet, 
       uint256 _registrationFee, 
       uint8 _typePlayer
    );

    event CreateArbiter(
       address _wallet
    );

    event UpdatePlayer(
       uint _countPlayer, 
       string _username, 
       address _wallet, 
       uint8 _typePlayer
    );

    event UpdateArbiter(
      uint _countArbiter, 
      address _wallet, 
      bool _status
    );

    constructor(
        address _feeConlecter
    ){
        feeConlecter = FeeColector(_feeConlecter);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        withdrawWallet = payable(msg.sender);
    }

    function createPlayer(string memory _username, uint8 _typePlayer) public payable {
        uint256 _registrationFee = feeConlecter.registrationFee();
        require(msg.sender != address(0),"Wallet does not exist");
        require(bytes(_username).length != 0,"Empty username");
        require(_typePlayer>=0 && _typePlayer < 2 ,"Empty type");
        require(_registrationFee==msg.value,"Fee is not enough");
        require(!usernameExists[_username], "Username already exists");

        usernameExists[_username] = true;

        listPlayer[countPlayer] = Player(_username,msg.sender, _registrationFee, _typePlayer);
        countPlayer++;

        emit CreatePlayer(_username, msg.sender, _registrationFee, _typePlayer);
        
    }

    function withdrawWalletAdmin() public onlyOwner {
        require(withdrawWallet != address(0), "Withdraw wallet not set");

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No balance to withdraw");

        withdrawWallet.transfer(contractBalance);
    }

    function createArbiter(address _wallet) public onlyRole(ADMIN_ROLE){
        require(_wallet != address(0),"Address does not exist");
        _grantRole(ARBITER_ROLE, _wallet);
        listArbiter[countArbiter] = Arbiter(_wallet,true);
        countArbiter++;

        emit CreateArbiter(_wallet);
    }

    function updatePlayer(uint128 _countPlayer, address _wallet, string memory _username, uint8 _typePlayer) public onlyRole(ADMIN_ROLE){
        require(_wallet != address(0),"Wallet does not exist");
        require(bytes(_username).length != 0,"Empty username");
        require(_typePlayer>=0 && _typePlayer < 2 ,"Empty type");
        require(listPlayer[_countPlayer].wallet != address(0),"Player does not exist");

        listPlayer[_countPlayer].wallet = _wallet;
        listPlayer[_countPlayer].username = _username;
        listPlayer[_countPlayer].typePlayer = _typePlayer;

        emit UpdatePlayer(_countPlayer, _username, _wallet, _typePlayer);
    }

    function updateArbiter(uint128 _countArbiter, address _wallet, bool _status) public onlyRole(ADMIN_ROLE){
        require(listArbiter[_countArbiter].wallet != address(0),"Player does not exist");
        require(_wallet != address(0),"Address does not exist");

        if(_status==true){
            listArbiter[_countArbiter].wallet = _wallet;
            listArbiter[_countArbiter].status = _status;
        }else{
            _revokeRole(ARBITER_ROLE, _wallet);
        }
        emit UpdateArbiter(_countArbiter, _wallet, _status);
    }

    function deposit() public payable {}
}