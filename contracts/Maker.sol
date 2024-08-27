// SPDX-License-Identifier: none
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./VRFRandomNumber.sol";
import "./WinLossDQ.sol";

contract Maker is AccessControl{

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    WinLossDQ winLossDQ;
    Bookie bookie;
    uint public currentRound;
    mapping(uint roundId => address []) public rounds;
    uint currentGame;
    address public tournamentWinner;

    event updateRound(uint roundId);
    event foundWiner(address winner);

    constructor(address _winLossDQ, address _bookie ){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        bookie = Bookie(_bookie);
        require(bookie.tournamentStarted(),"Tournament is not started yet");
        winLossDQ = WinLossDQ(_winLossDQ);
    }

    function setPosition(uint randomNumber) public onlyRole(ADMIN_ROLE){
        currentRound++;
        require(rounds[1].length == 0 && currentRound == 1, "Position is already set");
        require(randomNumber != 0, "Random number did not set");
        // store hash player address
        uint maxPlayer = bookie.maxPlayers();
        uint [] memory addressHash = new uint[](maxPlayer);
        for(uint128 i; i < maxPlayer; i++){
            (,address player,) = bookie.listPlayer(i);
            // hash player address with random number and add player id to the last 4 numbers
            addressHash[i] = uint(keccak256(abi.encodePacked(player, randomNumber))) / 10000 * 10000 + i; 
        }
        quickSort(addressHash, 0, int(maxPlayer-1));
        for(uint i; i < maxPlayer; i++){
            // convert hash address to address by the last 4 numbers and push to round array
            (,address player,) = bookie.listPlayer(uint128(addressHash[i] % 10000));
            rounds[1].push(player);
        }
        emit updateRound(1);
    } 

    function setNextRound() public onlyRole(ADMIN_ROLE){
        uint previousRound = currentRound;
        currentRound++;
        require(currentRound > 1, "Position did not set yet");
        uint numberPlayers = rounds[previousRound].length / 2;
        if(numberPlayers == 1){
            (tournamentWinner, ,) = winLossDQ.gameResults(currentGame); 
            emit foundWiner(tournamentWinner);
        }
        else{
            for(uint i = 1; i <= numberPlayers; i++){
                (address gameWinner, ,) = winLossDQ.gameResults(currentGame);
                require(gameWinner != address(0),"Game winner did not set yet");
                rounds[currentRound].push(gameWinner);
                currentGame++;
            }
            emit updateRound(currentRound);
        }
    }

    function getRound(uint roundID) public view returns(address [] memory){
        return rounds[roundID];
    }

    function quickSort(uint [] memory arr, int left, int right) internal {
    int i = left;
    int j = right;
    if (i == j) return;
    uint pivot = arr[uint(left + (right - left) / 2)];
    while (i <= j) {
        while (arr[uint(i)] < pivot) i++;
        while (pivot < arr[uint(j)]) j--;
        if (i <= j) {
            (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
            i++;
            j--;
        }
    }
    if (left < j)
        quickSort(arr, left, j);
    if (i < right)
        quickSort(arr, i, right);
    }
}