// SPDX-License-Identifier: MIT
// Pragma
pragma solidity ^0.8.8;

//Get funds from users
//Withdraw funds
//Set a minimun funding value in USD

//Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// 794731
// 775165

//Error Codes
error FundMe__NotOwner();

// Interfaces, Libraries, Contracts

/**
 * @title A contract for crowd funding
 * @author Renato Souza
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    uint256 public constant MINIMUN_USD = 50 * 1e18; // 1 * 10 ** 18
    // 417 - CONSTANT
    // 2407 - NON-CONSTANT
    // 417 * 150000000000 = 62,550,000,000,000 = USD 0.1251
    // 2407 * 150000000000 = 361,050,000,000,000 = USD 0.7221
    address private immutable i_owner;
    // 2558 gas - non-immutable
    // 444 gas - immutable

    AggregatorV3Interface private s_priceFeed;

    // Modifier
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not onwer!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    // Functions order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /**
     * @notice This function funds this contract
     * @dev This implements price feeds as our library
     */
    function fund() public payable {
        // Want to be able to set a minimun funding value in USD
        // 1. How do we send ETH to this contract
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUN_USD,
            "You need to spend more ETH!"
        ); // 1e18 == 1 * 10 ** 18 = 1000000000000000000 Wei = 1 ETH
        // 18 decimals
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
        // What is reverting?
        // undo any action before, and send the remaining gas back.
    }

    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);

        // actually withdraw the funds
        /* 
        // Three ways: Transfer, Send and Call.
        
        // Transfer: (Transfer automactically reverts if transaction fails)
        // msg.sender = address
        // payable(msg.sender) = payable address
        payable(msg.sender).transfer(address(this).balance);

        // Send: (Send will only revert the transaction if we add the require statement)
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");
 */
        // Call:
        (bool success /* bytes memory dataReturned */, ) = payable(msg.sender)
            .call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
