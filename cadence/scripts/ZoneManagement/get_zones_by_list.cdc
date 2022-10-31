import ZoneManagement from "../../contracts/ZoneManagement.cdc"

pub fun main(address: Address, zoneIDsToGet: [UInt64]): [&ZoneManagement.NFT?] {
    let account = getAccount(address)
    let collection = account.getCapability(ZoneManagement.CollectionPublicPath)
        .borrow<&{ZoneManagement.ZoneCollection}>()
        ?? panic("Could not borrow Zone Collection reference.")

    let zones: [&ZoneManagement.NFT?] = []
    for id in zoneIDsToGet{
        let zone = collection.borrowZone(id: id)
        zones.append(zone)
    }

    return zones
}