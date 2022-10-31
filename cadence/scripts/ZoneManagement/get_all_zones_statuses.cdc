import MetadataViews from "../../contracts/MetadataViews.cdc"
import SpexiDataStandards from "../../contracts/SpexiDataStandards.cdc"
import ZoneManagement from "../../contracts/ZoneManagement.cdc"

//TODO: Shoudln't need to input address I think.
pub fun main(address: Address): [SpexiDataStandards.ZoneStatus?] {
    let account = getAccount(address)
    let collection = account.getCapability(ZoneManagement.CollectionPublicPath)
        .borrow<&{MetadataViews.ResolverCollection}>()
        ?? panic("Could not borrow Zone Collection reference.")

    let statuses: [SpexiDataStandards.ZoneStatus?] = []
    let ids: [UInt64] = collection.getIDs()
    for id in ids {
        let zoneResolver = collection.borrowViewResolver(id: id)
        let zoneView = zoneResolver.resolveView(Type<SpexiDataStandards.ZoneStatus>())
        statuses.append(zoneView as! SpexiDataStandards.ZoneStatus?)
    }

    return statuses
}