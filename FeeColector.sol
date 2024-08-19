pragma solidity >=0.8.2 <0.9.0;
import "@openzeppelin/contracts/access/AccessControl.sol" ;
import "@openzeppelin/contracts/access/Ownable.sol";
contract FeeColector is Ownable(msg.sender) , AccessControl{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public platformFee ;
    uint256 public registrationFee ;
    event updatedPlatformFee(uint256 platformFee) ;
    event updatedRegistrationFee(uint256 registrationFee) ;
    constructor(){
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "AccessControl: account is missing ADMINER");
        _;
    }
    function setPlatformFee(uint256 _platformFee) public onlyAdmin{
        require(_platformFee > 0 , "_platformFee must greater than 0");
        platformFee = _platformFee ;
        emit updatedPlatformFee(_platformFee);
    }
    function setRegistrationFee(uint256 _registrationFee) public onlyAdmin {
        require(_registrationFee > 0 , "__registrationFee must greater than 0");
        registrationFee = _registrationFee ;
        emit updatedRegistrationFee(_registrationFee);
    }
    function addAdmin(address account ) public onlyOwner {
        grantRole(ADMIN_ROLE, account) ;
    }
} 