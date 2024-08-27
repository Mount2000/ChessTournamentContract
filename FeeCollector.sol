// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/AccessControl.sol" ;
import "@openzeppelin/contracts/access/Ownable.sol";
contract FeeCollector is Ownable(msg.sender) , AccessControl{
    bytes32 public constant ADMINER = keccak256("ADMINER");
    uint256 public platformFee ;
    uint256 public registrationFee ;
    event updatedPlatformFee(uint256 platformFee) ;
    event updatedRegistrationFee(uint256 registrationFee) ;
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMINER, msg.sender);
    }
    modifier onlyAdmin() {
        require(hasRole(ADMINER, msg.sender), "AccessControl: account is missing ADMINER");
        _;
    }
    function setPlatformFee(uint256 _PlatformFee) public onlyAdmin{
        require(_PlatformFee > 0 , "_PlatformFee must greater than 0");
        platformFee = _PlatformFee ;
        emit updatedPlatformFee(_PlatformFee);
    }
    function setRegistrationFee(uint256 _RegistrationFee) public onlyAdmin {
        require(_RegistrationFee > 0 , "__RegistrationFee must greater than 0");
        registrationFee = _RegistrationFee ;
        emit updatedRegistrationFee(_RegistrationFee);
    }
    function addAdmin(address account ) public onlyOwner {
        grantRole(ADMINER, account) ;
    }
} 