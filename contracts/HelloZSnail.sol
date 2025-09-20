// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title HelloZSnail
 * @dev A simple contract to test deployment on ZSnail L2
 * @author ZSnail L2 Team
 */
contract HelloZSnail {
    string public message;
    address public owner;
    uint256 public deploymentBlock;
    uint256 public callCount;
    
    event MessageUpdated(string newMessage, address updatedBy);
    event GreetingCalled(address caller, uint256 totalCalls);
    
    constructor(string memory _initialMessage) {
        message = _initialMessage;
        owner = msg.sender;
        deploymentBlock = block.number;
        callCount = 0;
    }
    
    function updateMessage(string memory _newMessage) public {
        require(msg.sender == owner, "Only owner can update message");
        message = _newMessage;
        emit MessageUpdated(_newMessage, msg.sender);
    }
    
    function greet() public returns (string memory) {
        callCount++;
        emit GreetingCalled(msg.sender, callCount);
        return string(abi.encodePacked("Hello from ZSnail L2! ", message));
    }
    
    function getContractInfo() public view returns (
        string memory currentMessage,
        address contractOwner,
        uint256 deployedAtBlock,
        uint256 totalCalls,
        uint256 currentBlock
    ) {
        return (message, owner, deploymentBlock, callCount, block.number);
    }
    
    function getChainInfo() public view returns (uint256 chainId, uint256 blockNumber) {
        return (block.chainid, block.number);
    }
}