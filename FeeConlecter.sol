pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract FeeConlecter is Ownable , AccessControl{
    bytes32 public constant ADMINER = keccak256("ADMINER") ;
    uint256 public platformFee ;
    uint256 public registrationFee ;
    event updatedPlatformFee(uint256) ;
    event updatedRegistrationFee(uint256) ;
    constructor() Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMINER, msg.sender);
    }
    modifier onlyAdmin (){
        require(hasRole(ADMINER , msg.sender) , "Caller not an admin") ;
        _;
    }
    function setPlatformFee(uint256 _platformFee) public onlyAdmin{
        require(_platformFee >0 , "_platformFee must greater than 0") ;
        platformFee = _platformFee ;
        emit updatedPlatformFee(_platformFee);
    }
    function setRegistrationFee(uint256 _registrationFee) public onlyAdmin{
        require(_registrationFee >0 , "_registrationFee must greater than 0") ;
        registrationFee=_registrationFee ;
        emit updatedRegistrationFee(_registrationFee);
    }
     function addAdmin(address account ) public onlyOwner {
        grantRole(ADMINER, account) ;
    }
    function removeAdmin(address account ) public onlyOwner {
        revokeRole(ADMINER, account)  ; 
    }
}