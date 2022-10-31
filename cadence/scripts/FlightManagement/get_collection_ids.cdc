import FlightManagement from "../../contracts/FlightManagement.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"


pub fun main(address: Address): [UInt64]{
    let account = getAccount(address)

    let collection = account.getCapability(FlightManagement.CollectionPublicPath)
        .borrow<&FlightManagement.Collection{NonFungibleToken.CollectionPublic}>() ?? panic ("We could not get the public Link!")

    return collection.getIDs()
}
