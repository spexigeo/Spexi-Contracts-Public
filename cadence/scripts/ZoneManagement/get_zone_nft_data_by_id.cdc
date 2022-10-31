import MetadataViews from "../../contracts/MetadataViews.cdc"
import SpexiDataStandards from "../../contracts/SpexiDataStandards.cdc"
import ZoneManagement from "../../contracts/ZoneManagement.cdc"

//TODO: Shoudln't need to input address I think.
pub fun main(address: Address, zoneID: UInt64): SpexiDataStandards.NFTData? {
    let account = getAccount(address)
    let collection = account.getCapability(ZoneManagement.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow Zone Collection reference.")
    
    let zoneResolver = collection.borrowViewResolver(id: zoneID)
    let zoneView = zoneResolver.resolveView(Type<SpexiDataStandards.NFTData>())
    return zoneView as! SpexiDataStandards.NFTData?
}