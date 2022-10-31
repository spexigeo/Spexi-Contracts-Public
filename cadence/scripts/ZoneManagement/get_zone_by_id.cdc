import ZoneManagement from "../../contracts/ZoneManagement.cdc"

pub fun main(address: Address, zoneID: UInt64): &ZoneManagement.NFT? {
    let account = getAccount(address)
    let collection = account.getCapability(ZoneManagement.CollectionPublicPath)
        .borrow<&{ZoneManagement.ZoneCollection}>()
        ?? panic("Could not borrow Zone Collection reference.")
    
    let zone = collection.borrowZone(id: zoneID)
    return zone
}