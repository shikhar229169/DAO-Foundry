// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    uint256 private number;

    event NumberChanged(uint256 indexed newNumber);

    /**@notice Sets the number to newNumber
     * @notice Can only be called by the owner which will be a DAO
     * @param newNumber The new number to set
    */
    function setNumber(uint256 newNumber) external onlyOwner {
        number = newNumber;
        emit NumberChanged(number);
    }

    function getNumber() external view returns (uint256) {
        return number;
    }
}