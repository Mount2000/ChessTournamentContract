// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

 contract VRFRandomNumber is VRFConsumerBaseV2Plus{
   bytes32 keyHash;
   address Coordinator;
   uint subscriptionId;
   uint [] public randomNumber;
   uint requestId;
   
   constructor( bytes32 _keyHash, address _Coordinator, uint _SubscriptionId ) VRFConsumerBaseV2Plus(_Coordinator){
      keyHash = _keyHash;
      Coordinator = _Coordinator;
      subscriptionId = _SubscriptionId;
   }

   function requestRandomNumber() internal {
        // Will revert if subscription is not set and funded.
         requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: subscriptionId,
                requestConfirmations: 3,
                callbackGasLimit: 100000,
                numWords: 1,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
    }

    // get value and assign first element of random array to randomNumber
   function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] calldata randomNumbers
    ) internal override {
        randomNumber.push(randomNumbers[0]);
   }   

   function getRandomNumber() external returns(uint){
      requestRandomNumber();
      return randomNumber[randomNumber.length];
   }

   function getRandomNumberHistory() public view returns(uint [] memory){
    return randomNumber;
   }
 }