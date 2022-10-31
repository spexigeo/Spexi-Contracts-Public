import FlightManagement from "../../contracts/FlightManagement.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

pub fun main(address: Address, flightID: UInt64): &FlightManagement.NFT? {
    let account = getAccount(address)

  let collection = account.getCapability(FlightManagement.CollectionPublicPath)
        .borrow<&FlightManagement.Collection{NonFungibleToken.CollectionPublic, FlightManagement.ICollectionPublic}>() ?? panic ("We could not get the public Link!")
    
    let flight = collection.borrowAuthNFT(id: flightID)
    return flight
}