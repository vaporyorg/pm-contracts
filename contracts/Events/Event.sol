pragma solidity 0.4.18;
import "../Tokens/Token.sol";
import "../Tokens/OutcomeToken.sol";
import "../Oracles/Oracle.sol";
import "../Oracles/PriceOracle.sol";

/// @title Event contract - Provide basic functionality required by different event types
/// @author Stefan George - <stefan@gnosis.pm>
contract Event {

    /*
     *  Events
     */
    event OutcomeTokenCreation(OutcomeToken outcomeToken, uint8 index);
    event OutcomeTokenSetIssuance(address indexed buyer, uint collateralTokenCount);
    event OutcomeTokenSetRevocation(address indexed seller, uint outcomeTokenCount);
    event OutcomeAssignment(int outcome);
    event WinningsRedemption(address indexed receiver, uint winnings);

    /*
     *  Storage
     */
    Token public collateralToken;
    Oracle public oracle;
    bool public isOutcomeSet;
    int public outcome;
    OutcomeToken[] public outcomeTokens;

    // New variables needed to pay fees
    uint public feeRecipal=200;
    address OWLToken;
    PriceOracle public priceOracle;
    
    /*
     *  Public functions
     */
    /// @dev Contract constructor validates and sets basic event properties
    /// @param _collateralToken Tokens used as collateral in exchange for outcome tokens
    /// @param _oracle Oracle contract used to resolve the event
    /// @param outcomeCount Number of event outcomes
    function Event(Token _collateralToken, Oracle _oracle, uint8 outcomeCount)
        public
    {
        // Validate input
        require(address(_collateralToken) != 0 && address(_oracle) != 0 && outcomeCount >= 2);
        collateralToken = _collateralToken;
        oracle = _oracle;
        // Create an outcome token for each outcome
        for (uint8 i = 0; i < outcomeCount; i++) {
            OutcomeToken outcomeToken = new OutcomeToken();
            outcomeTokens.push(outcomeToken);
            OutcomeTokenCreation(outcomeToken, i);
        }
    }

    /// @dev Buys equal number of tokens of all outcomes, exchanging collateral tokens and sets of outcome tokens 1:1
    /// @param collateralTokenCount Number of collateral tokens
    function buyAllOutcomes(uint collateralTokenCount)
        public
    {
        // Transfer collateral tokens to events contract
        require(collateralToken.transferFrom(msg.sender, this, collateralTokenCount));

        uint fee=collateralTokenCount/feeRecipal;
        uint feeInOWL=priceOracle.getTokensValueInUSD(fee, collateralToken.address);
        uint feeInOWLPayable=Math.min(allowances[msg.sender][this], feeInWIZ);
        Token(OWLToken).approve(OWLToken, feeInOWLPayable);
        feeInWIZPayable = OWL(OWLToken).burnOWL(feeInOWLPayable);
        uint feeLeft = priceOracle.getAmountOfTokensofUSD(feeInOWL-feeInOWLPayable, collateralToken.address);
        Token(collateralToken.address).approve(IntermediateOfFeeAndAuction, feeLeft);
        
        // Issue new outcome tokens to sender
        for (uint8 i = 0; i < outcomeTokens.length; i++)
            outcomeTokens[i].issue(msg.sender, collateralTokenCount-fee);
        OutcomeTokenSetIssuance(msg.sender, collateralTokenCount-fee);
    }

    /// @dev Sells equal number of tokens of all outcomes, exchanging collateral tokens and sets of outcome tokens 1:1
    /// @param outcomeTokenCount Number of outcome tokens
    function sellAllOutcomes(uint outcomeTokenCount)
        public
    {
        // Revoke sender's outcome tokens of all outcomes
        for (uint8 i = 0; i < outcomeTokens.length; i++)
            outcomeTokens[i].revoke(msg.sender, outcomeTokenCount);
        // Transfer collateral tokens to sender
        require(collateralToken.transfer(msg.sender, outcomeTokenCount));
        OutcomeTokenSetRevocation(msg.sender, outcomeTokenCount);
    }

    /// @dev Sets winning event outcome
    function setOutcome()
        public
    {
        // Winning outcome is not set yet in event contract but in oracle contract
        require(!isOutcomeSet && oracle.isOutcomeSet());
        // Set winning outcome
        outcome = oracle.getOutcome();
        isOutcomeSet = true;
        OutcomeAssignment(outcome);
    }

    /// @dev Returns outcome count
    /// @return Outcome count
    function getOutcomeCount()
        public
        constant
        returns (uint8)
    {
        return uint8(outcomeTokens.length);
    }

    /// @dev Returns outcome tokens array
    /// @return Outcome tokens
    function getOutcomeTokens()
        public
        constant
        returns (OutcomeToken[])
    {
        return outcomeTokens;
    }

    /// @dev Returns the amount of outcome tokens held by owner
    /// @return Outcome token distribution
    function getOutcomeTokenDistribution(address owner)
        public
        constant
        returns (uint[] outcomeTokenDistribution)
    {
        outcomeTokenDistribution = new uint[](outcomeTokens.length);
        for (uint8 i = 0; i < outcomeTokenDistribution.length; i++)
            outcomeTokenDistribution[i] = outcomeTokens[i].balanceOf(owner);
    }

    /// @dev Calculates and returns event hash
    /// @return Event hash
    function getEventHash() public constant returns (bytes32);

    /// @dev Exchanges sender's winning outcome tokens for collateral tokens
    /// @return Sender's winnings
    function redeemWinnings() public returns (uint);
}
