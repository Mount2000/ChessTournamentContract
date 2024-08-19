// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./FeeConlecter.sol";

contract Bookie is AccessControl,Ownable(msg.sender){
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ARBITER_ROLE = keccak256("ARBITER_ROLE");

    uint128 countPlayer;
    uint countArbiter;
    FeeConlecter feeConlecter;

    struct player{
        string username;
        address wallet;
        uint256 registrationFee;
        uint8 typeplayer; 
    }

    struct arbiter{
        address wallet;
        bool status;
    }

    mapping (uint128 => player) public listPlayer;
    mapping (uint => arbiter) public listArbiter;

    event CreatePlayer(
       string _username, 
       address _wallet, 
       uint256 _registrationFee, 
       uint8 _typeplayer
    );

    event CreateArbiter(
       address _wallet
    );

    event UpdatePlayer(
       uint _countPlayer, 
       string _username, 
       address _wallet, 
       uint8 _typeplayer
    );

    event UpdateArbiter(
      uint _countArbiter, 
      address _wallet, 
      bool _status
    );

    constructor(){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        feeConlecter = new FeeConlecter();
    }

    function createPlayer(string memory _username, uint8 _typeplayer) public{
        uint256 _registrationFee = feeConlecter.registrationFee();
        require(msg.sender != address(0),"Wallet does not exist");
        require(bytes(_username).length != 0,"Empty username");
        require(_typeplayer>=0 && _typeplayer < 3 ,"Empty type");
        require(_registrationFee>0, "Fee must be greater than 0");

        listPlayer[countPlayer] = player(_username,msg.sender, _registrationFee, _typeplayer);
        countPlayer++;

        emit CreatePlayer(_username, msg.sender, _registrationFee, _typeplayer);
    }

    function createArbiter(address _wallet) public onlyRole(ADMIN_ROLE){
        require(_wallet != address(0),"Address does not exist");
        _grantRole(ARBITER_ROLE, _wallet);
        listArbiter[countArbiter] = arbiter(_wallet,true);
        countArbiter++;

        emit CreateArbiter(_wallet);
    }


     function updatePlayer(uint128 _countPlayer, string memory _username, uint8 _typeplayer) public{
        require(listPlayer[_countPlayer].wallet != address(0),"Player does not exist");
        require(msg.sender != address(0),"Wallet does not exist");
        require(bytes(_username).length != 0,"Empty username");
        require(_typeplayer>=0 && _typeplayer < 3 ,"Empty type");

        listPlayer[_countPlayer].wallet = msg.sender;
        listPlayer[_countPlayer].username = _username;
        listPlayer[_countPlayer].typeplayer = _typeplayer;

        emit UpdatePlayer(_countPlayer, _username, msg.sender, _typeplayer);
    }

     function updateArbiter(uint _countArbiter, address _wallet, bool _status) public onlyRole(ADMIN_ROLE){
        require(listArbiter[_countArbiter].wallet != address(0),"Player does not exist");
        require(_wallet != address(0),"Address does not exist");

        listArbiter[_countArbiter].wallet = _wallet;
        listArbiter[_countArbiter].status = _status;

        emit UpdateArbiter(_countArbiter, _wallet, _status);
    }
}