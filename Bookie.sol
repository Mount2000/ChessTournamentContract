// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./FeeConlecter.sol";

contract Bookie is AccessControl,Ownable(msg.sender){
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ARBITER_ROLE = keccak256("ARBITER_ROLE");

    address payable withdrawWallet;

    uint public startTime;
    bool public tournamentStarted; 
    bool public isCancelled; 
    uint public tournamentType;
    uint128 public minPlayers; 
    uint128 public maxPlayers;

    uint128 countPlayer;
    uint128 countArbiter;
    
    uint256 public prizePool;

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
    mapping(address => bool) private adreesArbiterExists;

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

    event WithdrawWalletAdmin(
        address wallet
    );

    event CancelTournament(
        address wallet
    );

    event PlayerWithdraw(
        address wallet,
        uint128 _idPlayer
    );

    constructor(
        address _feeConlecter,
        uint _startTime
    ){
        startTime = _startTime;
        isCancelled = false;
        tournamentStarted = false;
        feeConlecter = FeeColector(_feeConlecter);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        withdrawWallet = payable(msg.sender);
    }

    function setStartTime(uint _startTime) public onlyAdminOrArbiter{
        startTime = _startTime;
    }

    function setMinPlayers(uint128 _minPlayers) public onlyRole(ADMIN_ROLE){
        minPlayers = _minPlayers;
    }

    function setMaxPlayers(uint128 _maxPlayers) public onlyRole(ADMIN_ROLE){
        maxPlayers = _maxPlayers;
    }

    function addPrizePool(uint256 _prizePool) public onlyRole(ADMIN_ROLE){
        prizePool += _prizePool;
    }

    function setPrizePool(uint256 _prizePool) public onlyRole(ADMIN_ROLE){
        prizePool = _prizePool;
    }

    function setTournamentType(uint _tournamentType) public onlyRole(ADMIN_ROLE){
        tournamentType = _tournamentType;
    }

    function createPlayer(string memory _username, uint8 _typePlayer) 
    public payable checkMinPlayers checkMaxPlayers checkIsCancelled checkStartTime checkTournamentStarted checkUsernameIsExist(_username){
        uint256 _registrationFee = feeConlecter.registrationFee();
        require(msg.sender != address(0),"Wallet does not exist");
        require(bytes(_username).length != 0,"Empty username");
        require(_typePlayer>=0 && _typePlayer < 2 ,"Empty type");
        require(_registrationFee==msg.value,"Fee is not enough");

        usernameExists[_username] = true;

        listPlayer[countPlayer] = Player(_username,msg.sender, _registrationFee, _typePlayer);
        
        countPlayer++;
        emit CreatePlayer(_username, msg.sender, _registrationFee, _typePlayer);   
    }

    function createArbiter(address _wallet) public checkMinPlayers checkMaxPlayers onlyRole(ADMIN_ROLE){
        require(_wallet != address(0),"Address does not exist");
        _grantRole(ARBITER_ROLE, _wallet);
        listArbiter[countArbiter] = Arbiter(_wallet,true);
        adreesArbiterExists[_wallet] = true;
        countArbiter++;

        emit CreateArbiter(_wallet);
    }

    function updatePlayer(uint128 _countPlayer, address _wallet, string memory _username, uint8 _typePlayer) checkMinPlayers checkMaxPlayers public onlyRole(ADMIN_ROLE){
        require(_wallet != address(0),"Wallet does not exist");
        require(bytes(_username).length != 0,"Empty username");
        require(_typePlayer>=0 && _typePlayer < 2 ,"Empty type");
        require(listPlayer[_countPlayer].wallet != address(0),"Player does not exist");

        listPlayer[_countPlayer].wallet = _wallet;
        listPlayer[_countPlayer].username = _username;
        listPlayer[_countPlayer].typePlayer = _typePlayer;

        if(_typePlayer==0 && adreesArbiterExists[_wallet]){
             _revokeRole(ARBITER_ROLE, _wallet);
            adreesArbiterExists[_wallet] = false;
        }

        if(_typePlayer==1 && !adreesArbiterExists[_wallet]){
            createArbiter(_wallet);
        }

        emit UpdatePlayer(_countPlayer, _username, _wallet, _typePlayer);
    }

    function updateArbiter(uint128 _countArbiter, address _wallet, bool _status) public checkMinPlayers checkMaxPlayers onlyRole(ADMIN_ROLE){
        require(listArbiter[_countArbiter].wallet != address(0),"Player does not exist");
        require(_wallet != address(0),"Address does not exist");
        
        listArbiter[_countArbiter].wallet = _wallet;
        listArbiter[_countArbiter].status = _status;
        
        if(_status==true){
            if(hasRole(ARBITER_ROLE, _wallet)){    
                _grantRole(ARBITER_ROLE, _wallet);
            }
            adreesArbiterExists[_wallet] = true;
        }else{
            _revokeRole(ARBITER_ROLE, _wallet);
            adreesArbiterExists[_wallet] = false;
        }
        emit UpdateArbiter(_countArbiter, _wallet, _status);
    }

    function startTournament() public checkStartTime onlyAdminOrArbiter{
        require(countPlayer==maxPlayers,"Player is not enough");
        tournamentStarted = true;
    }

    function withdrawWalletAdmin() public onlyOwner {
        require(withdrawWallet != address(0), "Withdraw wallet not set");

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No balance to withdraw");
        
        (bool sent, ) = withdrawWallet.call{value: contractBalance}("");
        require(sent, "Failed to send Ether");

        emit WithdrawWalletAdmin(address(this));
    }

    function cancelTournament() public checkTournamentStarted checkIsCancelled onlyAdminOrArbiter{
        tournamentStarted = false;
        isCancelled = true;

        emit CancelTournament(address(this));
    }

    function playerWithdraw(uint128 _idPlayer) public {
        require(
            isCancelled,
            "Tournament has not cancelled"
        );
        require(
           listPlayer[_idPlayer].registrationFee>0,
            "Tournament has not cancelled"
        );

        require(
            address(this).balance >= listPlayer[_idPlayer].registrationFee,
            "Insufficient contract balance"
        );

        (bool sent, ) = msg.sender.call{value: listPlayer[_idPlayer].registrationFee}("");
        require(sent, "Failed to send Ether");

        emit PlayerWithdraw(address(this),_idPlayer);
    }

    modifier checkMaxPlayers(){
        require(maxPlayers>0,"maxPlayers is not set yet");
    _;
    }

    modifier checkMinPlayers(){
        require(minPlayers>0,"minPlayers is not set yet");
    _;
    }

    modifier checkUsernameIsExist(string memory _username) {
        require(!usernameExists[_username], "Username already exists");
        _;
    }

    modifier onlyAdminOrArbiter() {
        require(
            hasRole(ADMIN_ROLE, msg.sender) || hasRole(ARBITER_ROLE, msg.sender),
            "Caller is not an admin or an arbiter"
        );
    _;
    }

    modifier checkIsCancelled() {
         require(
            !isCancelled, 
            "The tournament was cancelled"
         );
    _;
    }

    modifier checkStartTime() {
        require(
            startTime <= block.timestamp,
            "The startTime was expired"
        );
    _;
    }

    modifier checkTournamentStarted() {
        require(
            tournamentStarted, 
            "Tournament has not started"
        );
    _;
    }

    function deposit() public payable {}

}