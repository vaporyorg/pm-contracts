pragma solidity ^0.4.25;
import "../Markets/GnosisSightMarket.sol";


/// @title Market factory contract - Allows to create market contracts
/// @author Stefan George - <stefan@gnosis.pm>
contract GnosisSightMarketFactory {

    /*
     *  Events
     */
    event GnosisSightMarketCreation(address indexed creator, Market market, Event eventContract, MarketMaker marketMaker, uint24 fee, Whitelist whitelist);

    /*
     *  Storage
     */
    GnosisSightMarket public gnosisSightMarketMasterCopy;

    /*
     *  Public functions
     */
    constructor(GnosisSightMarket _gnosisSightMarketMasterCopy) public {
        gnosisSightMarketMasterCopy = _gnosisSightMarketMasterCopy;
    }

    /// @dev Creates a new market contract
    /// @param eventContract Event contract
    /// @param marketMaker Market maker contract
    /// @param fee Market fee
    /// @return Market contract
    function createMarket(Event eventContract, MarketMaker marketMaker, uint24 fee, Whitelist whitelist)
        public
        returns (GnosisSightMarket market)
    {
        market = GnosisSightMarket(new GnosisSightMarketProxy(gnosisSightMarketMasterCopy, msg.sender, eventContract, marketMaker, fee, whitelist));
        emit GnosisSightMarketCreation(msg.sender, market, eventContract, marketMaker, fee, whitelist);
    }
}