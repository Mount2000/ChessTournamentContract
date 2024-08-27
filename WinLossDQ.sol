// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./bookie.sol";

contract WinLossDQ is Ownable(msg.sender) , AccessControl{

    struct GameResult {
        address winner;
        bool win;
        bool approved;
        mapping(address => bool) approvals;
    }

    Bookie public bookie;
    uint256 public game;
    mapping(uint256 => GameResult) public gameResults;
    uint32[] public moves;

    event Moves(
        uint256 _gameId,
        uint32 _move
    );

    event SubmitGameResult(
       address _winner, 
       bool _win
    );

    event ApproveGameResult(
       uint256 _gameId
    );

    constructor(address _bookie) {
        bookie = Bookie(_bookie);
    }

    function submitGameResult(address _winner, bool _win) public onlyArbiter {
        require(_winner != address(0),"Address does not exist");
        gameResults[game].winner = _winner;
        gameResults[game].win = _win;
        
        game++;
        emit SubmitGameResult(_winner,_win);
    }
    
    function setMoves(uint256 _gameId, uint32 _move) external  {
        require(gameResults[_gameId].winner != address(0), "The game does not exist.");
        moves.push(_move);
        emit Moves(_gameId,_move);
    }

    function approveGameResult(uint256 _gameId) public onlyArbiter{
        uint128 countArbiter = bookie.countArbiter();
        bool checkApproved = true;

        for (uint128 i = 0; i<countArbiter; i++){
           (address arbiter,bool status) = bookie.listArbiter(i); 
            if(status){
                if(!gameResults[_gameId].approvals[arbiter]){
                    checkApproved = false;
                    break ;
                }
            }
        }

        if(checkApproved){
            gameResults[_gameId].approved = true;
            emit ApproveGameResult(_gameId);
        }
    }
    
    function setApprove(uint256 _gameId,bool _approve) public onlyArbiter{
        require(gameResults[_gameId].winner != address(0),"Id does not exist");
        
        gameResults[_gameId].approvals[msg.sender] = _approve;
    }

    function isResultApproved(uint256 _gameId) public view returns (bool){
        require(gameResults[_gameId].winner != address(0),"Id does not exist");
        return gameResults[_gameId].approved;
    }

    function getWinner(uint256 _gameId) public view returns (address, bool){
        require(gameResults[_gameId].approved,"The results have not been approved");
        
        return (gameResults[_gameId].winner, gameResults[_gameId].win);
    }


    modifier onlyArbiter() {
        require(bookie.hasRole(bookie.ARBITER_ROLE(), msg.sender), "Caller is not an arbiter");
        require(bookie.adreesArbiterExists(msg.sender), "Arbiter is not active");
        _;
    }
}