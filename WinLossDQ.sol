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
    uint256 public roundCounter;
    mapping(uint256 => GameResult) public gameResults;

    event SubmitGameResult(
       address _winner, 
       bool _win
    );

    event ApproveGameResult(
       uint256 _roundId
    );

    constructor(address _bookie) {
        bookie = Bookie(_bookie);
    }

    function submitGameResult(address _winner, bool _win) public onlyArbiter {
        require(_winner != address(0),"Address does not exist");
        gameResults[roundCounter].winner = _winner;
        gameResults[roundCounter].win = _win;
        
        roundCounter++;
        emit SubmitGameResult(_winner,_win);
    }

    function approveGameResult(uint256 _roundId) public onlyArbiter{
        uint128 countArbiter = bookie.countArbiter();
        bool checkApproved = true;

        for (uint128 i = 0; i<countArbiter; i++){
           (address arbiter,bool status) = bookie.listArbiter(i); 
            if(status){
                if(!gameResults[_roundId].approvals[arbiter]){
                    checkApproved = false;
                    break ;
                }
            }
        }

        if(checkApproved){
            gameResults[_roundId].approved = true;
            emit ApproveGameResult(_roundId);
        }
    }
    
    function isResultApproved(uint256 _roundId,bool _approve) public onlyArbiter{
        require(gameResults[_roundId].winner != address(0),"Id does not exist");
        
        gameResults[_roundId].approvals[msg.sender] = _approve;
    }

    function getWinner(uint256 _roundId) public view returns (address, bool){
        require(gameResults[_roundId].approved,"The results have not been approved");
        
        return (gameResults[_roundId].winner, gameResults[_roundId].win);
    }


    modifier onlyArbiter() {
        require(bookie.hasRole(bookie.ARBITER_ROLE(), msg.sender), "Caller is not an arbiter");
        require(bookie.adreesArbiterExists(msg.sender), "Arbiter is not active");
        _;
    }
}