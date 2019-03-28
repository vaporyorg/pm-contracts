pragma solidity ^0.5.0;
import "../Markets/Campaign.sol";


/// @title Campaign factory contract - Allows to create campaign contracts
/// @author Stefan George - <stefan@gnosis.pm>
contract CampaignFactory {

    /*
     *  Events
     */
    event CampaignCreation(address indexed creator, Campaign campaign, Event eventContract, StandardMarketFactory marketFactory, MarketMaker marketMaker, uint24 fee, uint funding, uint deadline);

    /*
     *  Storage
     */
    Campaign public campaignMasterCopy;

    /*
     *  Public functions
     */
    constructor(Campaign _campaignMasterCopy)
        public
    {
        campaignMasterCopy = _campaignMasterCopy;
    }

    /// @dev Creates a new campaign contract
    /// @param eventContract Event contract
    /// @param marketFactory Market factory contract
    /// @param marketMaker Market maker contract
    /// @param fee Market fee
    /// @param funding Initial funding for market
    /// @param deadline Campaign deadline
    /// @return Market contract
    function createCampaign(
        Event eventContract,
        StandardMarketFactory marketFactory,
        MarketMaker marketMaker,
        uint24 fee,
        uint funding,
        uint deadline
    )
        public
        returns (Campaign campaign)
    {
        campaign = Campaign(address(new CampaignProxy(
            address(campaignMasterCopy), eventContract, marketFactory, marketMaker, fee, funding, deadline)));
        emit CampaignCreation(msg.sender, campaign, eventContract, marketFactory, marketMaker, fee, funding, deadline);
    }
}
