pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Bookie is AccessControl,Ownable(msg.sender){
    uint countPlayer;
    uint countArbiter;

    struct player{
        string username;
        address wallet;
        uint256 registerStationFee;
        uint8 typeplayer; 
    }

    struct arbiter{
        address wallet;
        bool status;
    }

    mapping (uint countPlayer => player) public listPlayer;
    mapping (uint countArbiter => arbiter) public listArbiter;

    event CreatePlayer(
       string _username, 
       address _wallet, 
       uint256 _registerStationFee, 
       uint8 _typeplayer
    );

    event CreateArbiter(
       address _wallet
    );

    event UpdatePlayer(
       uint _countPlayer, 
       string _username, 
       address _wallet, 
       uint256 _registerStationFee, 
       uint8 _typeplayer
    );

    event UpdateArbiter(
      uint _countArbiter, 
      address _wallet, 
      bool _status
    );

    function createPlayer(string memory _username, address _wallet, uint256 _registerStationFee, uint8 _typeplayer) public{
        require(_wallet != address(0),"wallet does not exist");
        require(bytes(_username).length != 0,"empty username");
        require(_typeplayer>=0 && _typeplayer < 3 ,"empty type");
        require(_registerStationFee>0, "fee must be greater than 0");

        listPlayer[countPlayer] = player(_username,_wallet, _registerStationFee,_typeplayer);
        countPlayer++;

        emit CreatePlayer(_username, _wallet, _registerStationFee, _typeplayer);
    }

    function createArbiter(address _wallet) public onlyOwner{
        require(_wallet != address(0),"address does not exist");

        listArbiter[countArbiter] = arbiter(_wallet,true);
        countArbiter++;

        emit CreateArbiter(_wallet);
    }


     function updatePlayer(uint _countPlayer, string memory _username, address _wallet, uint256 _registerStationFee, uint8 _typeplayer) public{
        require(listPlayer[_countPlayer].wallet != address(0),"Player does not exist");
        require(_wallet != address(0),"wallet does not exist");
        require(bytes(_username).length != 0,"empty username");
        require(_typeplayer>=0 && _typeplayer < 3 ,"empty type");
        require(_registerStationFee>0, "fee must be greater than 0");

        listPlayer[_countPlayer].wallet = _wallet;
        listPlayer[_countPlayer].username = _username;
        listPlayer[_countPlayer].registerStationFee = _registerStationFee;
        listPlayer[_countPlayer].typeplayer = _typeplayer;

        emit UpdatePlayer(_countPlayer, _username, _wallet, _registerStationFee, _typeplayer);
    }

     function updateArbiter(uint _countArbiter, address _wallet, bool _status) public onlyOwner{
        require(listArbiter[_countArbiter].wallet != address(0),"Player does not exist");
        require(_wallet != address(0),"address does not exist");

        listArbiter[_countArbiter].wallet = _wallet;
        listArbiter[_countArbiter].status = _status;

        emit UpdateArbiter(_countArbiter, _wallet, _status);
    }
}