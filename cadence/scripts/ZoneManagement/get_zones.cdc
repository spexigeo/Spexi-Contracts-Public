import ZoneManagement from "../../contracts/ZoneManagement.cdc"

pub fun main(address: Address): [&ZoneManagement.NFT?] {
    let account = getAccount(address)
    let collection = account.getCapability(ZoneManagement.CollectionPublicPath)
        .borrow<&{ZoneManagement.ZoneCollection}>()
        ?? panic("Could not borrow Zone Collection reference.")

    let zones: [&ZoneManagement.NFT?] = []
    for id in collection.getIDs() {
        let zone = collection.borrowZone(id: id)
        zones.append(zone)
    }

    return zones
}