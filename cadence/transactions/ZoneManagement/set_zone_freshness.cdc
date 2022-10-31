import ZoneManagement from "../../contracts/ZoneManagement.cdc"

transaction(id: UInt64, freshAtTime: UFix64) {
    let admin: &ZoneManagement.ZoneAdmin
    let collection: &ZoneManagement.Collection
    prepare(account: AuthAccount) {
        //Get our admin from our private storage.
        self.admin = account.borrow<&ZoneManagement.ZoneAdmin>
        (from: ZoneManagement.AdminStoragePath) ?? panic("Zone Admin not found")
        
        //Get our collection from our private storage.
        self.collection = account.borrow<&ZoneManagement.Collection>
        (from: ZoneManagement.CollectionPublicPath) ?? panic("Could not find zone collection.")
    }

    execute {
        self.admin.setZoneFreshDate(collection: self.collection, id: id, freshAtTime: freshAtTime)
    }
}