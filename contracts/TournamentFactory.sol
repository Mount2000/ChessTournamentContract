// SPDX-License-Identifier: none
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Maker.sol";

contract TournamentFactory is AccessControl{

    struct Tournament{
        address bookie;
        address maker;
        address winLossDQ;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    mapping (uint => Tournament) public tournaments;
    uint public tournamentCount;

    event CreateTournamentBookie(uint tournamentID, address bookie);
    event CreateTournamentMaker(uint tournamentID, address maker);
    event CreateTournamentWinLossDQ(uint tournamentID, address winLossDQ);

    constructor(){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createTournamentBookie(address feeConlecter, uint startTime) public onlyRole(ADMIN_ROLE){
        tournamentCount++;
        Bookie tournamentBookie = new Bookie(feeConlecter, startTime);
        tournaments[tournamentCount].bookie = address(tournamentBookie);

        emit CreateTournamentBookie(tournamentCount, tournaments[tournamentCount].bookie);
    }

    function createTournamentMaker(uint tournamentID, address vrfRandomNumber, address winLossDQ, address _bookie) public onlyRole(ADMIN_ROLE){
        require(tournaments[tournamentID].maker == address(0),"Tournament maker is already created");
        require( _bookie == tournaments[tournamentID].bookie);
        Maker tournamentMaker = new Maker(vrfRandomNumber, winLossDQ, _bookie);
        tournaments[tournamentID].maker = address(tournamentMaker);

        emit CreateTournamentMaker(tournamentID, tournaments[tournamentID].maker);
    }

    function createTournamentWinLossDQ(uint tournamentID, address _bookie) public onlyRole(ADMIN_ROLE){
        require(tournaments[tournamentID].winLossDQ == address(0),"Tournament winLossDQ is already created");
        require( _bookie == tournaments[tournamentID].bookie);
        WinLossDQ tournamentWinLossDQ = new WinLossDQ(_bookie);
        tournaments[tournamentID].winLossDQ = address(tournamentWinLossDQ);

        emit CreateTournamentWinLossDQ(tournamentID, tournaments[tournamentID].winLossDQ);
    }
}