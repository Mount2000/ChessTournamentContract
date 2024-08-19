pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/AccessControl.sol" ;
import "@openzeppelin/contracts/access/Ownable.sol";
contract FeeColector is Ownable(msg.sender) , AccessControl{
    bytes32 public constant ADMINER = keccak256("ADMINER");
    uint256 public PlatformFee ;
    uint256 public RegistrationFee ;
    event updatedPlatformFee(uint256 PlatformFee) ;
    event updatedRegistrationFee(uint256 RegistrationFee) ;
    constructor() Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMINER, msg.sender);
    }
    modifier onlyAdmin() {
        require(hasRole(ADMINER, msg.sender), "AccessControl: account is missing ADMINER");
        _;
    }
    function setPlatformFee(uint256 _PlatformFee) public onlyAdmin{
        require(_PlatformFee > 0 , "_PlatformFee must greater than 0");
        PlatformFee = _PlatformFee ;
        emit updatedPlatformFee(_PlatformFee);
    }
    function setRegistrationFee(uint256 _RegistrationFee) public onlyAdmin {
        require(_RegistrationFee > 0 , "__RegistrationFee must greater than 0");
        RegistrationFee = _RegistrationFee ;
        emit updatedRegistrationFee(_RegistrationFee);
    }
    function addAdmin(address account ) public onlyOwner {
        grantRole(ADMINER, account) ;
    }
} 