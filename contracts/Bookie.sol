// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./FeeCollector.sol";
 
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
    address public playerWinner;

    uint128 public countPlayer;
    uint128 public countArbiter;
    
    uint256 public prizePool;

    FeeCollector public feeCollector;

    struct Player{
        string username;
        address wallet;
        uint256 registrationFee;
    }

    struct Arbiter{
        address wallet;
        bool status;
    }

    mapping(string => bool) private usernameExists;
    mapping (uint128 => Player) public listPlayer;
    mapping (uint128 => Arbiter) public listArbiter;
    mapping(address => bool) public adreesArbiterExists;

    event CreatePlayer(
       uint128 _countPlayer,
       string _username, 
       address _wallet, 
       uint256 _registrationFee
    );

    event CreateArbiter(
       uint128 _countArbiter,
       address _wallet
    );

    event UpdatePlayer(
       uint _countPlayer, 
       string _username, 
       address _wallet
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
        address _feeCollector,
        uint _startTime
    ){
        require(
            _startTime >= block.timestamp,
            "The startTime was fail"
        );
        startTime = _startTime;
        isCancelled = false;
        tournamentStarted = false;
        feeCollector = FeeCollector(_feeCollector);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        withdrawWallet = payable(msg.sender);
    }

    function setTimeAndMinMax(uint _startTime, uint128 _minPlayers, uint128 _maxPlayers) public onlyRole(ADMIN_ROLE){
        require(
            _minPlayers>0,
            "MinPlayer must be greater than 0");
        require(
            _maxPlayers>_minPlayers,
            "MaxPlayer must be greater than minPlayer");
        require(
            _startTime >= block.timestamp,
            "The startTime was fail"
        );
        
        startTime = _startTime;
        minPlayers = _minPlayers;
        maxPlayers = _maxPlayers;
    }

    function addPrizePool(uint256 _prize) public payable onlyOwner{
        require(address(this).balance > _prize, "Insufficient contract balance");
        require(_prize == msg.value, "Price is not enough");
        prizePool += _prize;
    }

    function setPlayerWinner(address _playerWinner) public onlyRole(ADMIN_ROLE){
        require(_playerWinner != address(0),"Address does not exist");
        playerWinner = _playerWinner;
    }

    function setTournamentType(uint _tournamentType) public onlyRole(ADMIN_ROLE){
        tournamentType = _tournamentType;
    }

    function createPlayer(string memory _username) 
    public payable checkMinPlayers checkMaxPlayers checkIsCancelled checkStartTime checkUsernameIsExist(_username){
        uint256 _registrationFee = feeCollector.registrationFee();
        require(msg.sender != address(0),"Wallet does not exist");
        require(bytes(_username).length != 0,"Empty username");
        require(_registrationFee==msg.value,"Fee is not enough");

        usernameExists[_username] = true;

        listPlayer[countPlayer] = Player(_username,msg.sender, _registrationFee);
        
        prizePool += msg.value;

        emit CreatePlayer(countPlayer,_username, msg.sender, _registrationFee);   
        countPlayer++;
    }

    function createArbiter(address _wallet) public checkMinPlayers checkMaxPlayers onlyRole(ADMIN_ROLE){
        require(_wallet != address(0),"Address does not exist");
        _grantRole(ARBITER_ROLE, _wallet);
        listArbiter[countArbiter] = Arbiter(_wallet,true);
        adreesArbiterExists[_wallet] = true;

        emit CreateArbiter(countArbiter,_wallet);
        countArbiter++;
    }

    function updatePlayer(uint128 _countPlayer, address _wallet, string memory _username) checkMinPlayers checkMaxPlayers public onlyRole(ADMIN_ROLE){
        require(_wallet != address(0),"Wallet does not exist");
        require(bytes(_username).length != 0,"Empty username");
        require(listPlayer[_countPlayer].wallet != address(0),"Player does not exist");

        listPlayer[_countPlayer].wallet = _wallet;
        listPlayer[_countPlayer].username = _username;

        emit UpdatePlayer(_countPlayer, _username, _wallet);
    }

    function updateArbiter(uint128 _countArbiter, address _wallet, bool _status) public onlyRole(ADMIN_ROLE){
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

    function startTournament() public checkStartTime onlyRole(ADMIN_ROLE){
        require(countPlayer==maxPlayers,"Players is not enough");
        tournamentStarted = true;
    }

    function withdrawWalletAdmin() public payable onlyOwner {
        require(withdrawWallet != address(0), "WithdrawWallet does not set");

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No balance to withdraw");
        
        (bool sent, ) = withdrawWallet.call{value: contractBalance}("");
        require(sent, "Failed to send Ether");

        prizePool = 0;

        emit WithdrawWalletAdmin(address(this));
    }

    function cancelTournament() public checkTournamentStarted checkIsCancelled onlyAdminOrArbiter{
        tournamentStarted = false;
        isCancelled = true;

        emit CancelTournament(address(this));
    }

    function playerWithdraw(uint128 _idPlayer) public payable onlyOwner{
        require(
            isCancelled,
            "Tournament has not cancelled"
        );
        require(
           listPlayer[_idPlayer].registrationFee>0,
            "Fee is not enough"
        );

        require(
            address(this).balance >= listPlayer[_idPlayer].registrationFee,
            "Insufficient contract balance"
        );

        (bool sent, ) = msg.sender.call{value: listPlayer[_idPlayer].registrationFee}("");
        require(sent, "Failed to send Ether");

        prizePool -= listPlayer[_idPlayer].registrationFee;

        emit PlayerWithdraw(address(this),_idPlayer);
    }

    function playerWinnerWithdraw(address _playerWinner) public payable onlyOwner{
        require(_playerWinner != address(0),"Address player winner does not exist");
        require(playerWinner==_playerWinner,"The address is not the winning player");

        // (bool sent, ) = withdrawWallet.call{value: contractBalance}("");
        // require(sent, "Failed to send Ether");

    }

    modifier checkMaxPlayers(){
        require(maxPlayers>minPlayers,"MaxPlayer must be greater than minPlayer");
    _;
    }

    modifier checkMinPlayers(){
        require(minPlayers>0,"MinPlayer must be greater than 0");
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