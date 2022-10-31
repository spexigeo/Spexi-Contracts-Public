//Note: Cadence extension can't properly read some lines if 
//      you add new line seperators for readability. So, if
//      you see a line running off the editor, just keep it 
//      that way. Otherwise the extension will mark it.
import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import SpexiDataStandards from "./SpexiDataStandards.cdc"

pub contract ZoneManagement: NonFungibleToken {

    pub let maxPilotQueue: Int
    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event ZoneCreated(id: UInt64, name: String)
    pub event ZoneDestroyed(id: UInt64, name: String)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath

    access(contract) let errorList: SpexiDataStandards.ZoneErrors

    init() {
        self.totalSupply = 0
        self.maxPilotQueue = 4

        //Set the named paths.
        self.CollectionStoragePath = /storage/zoneCollection
        self.CollectionPublicPath = /public/zoneCollection
        self.AdminStoragePath = /storage/zoneAdmin

        //Initialize collection resource storage.
        let collection: @ZoneManagement.Collection <- create Collection()
        self.account.save(<-collection, to: self.CollectionStoragePath)

        //Create a way for the public to access the storage.
        self.account.link<&ZoneManagement.Collection{NonFungibleToken.CollectionPublic, ZoneManagement.ZoneCollection, MetadataViews.ResolverCollection}>(
            self.CollectionPublicPath,
            target: self.CollectionStoragePath
        )

        //Create the only admin resource that will ever exist and store it.
        let admin: @ZoneManagement.ZoneAdmin <- create ZoneAdmin()
        self.account.save(<-admin, to: self.AdminStoragePath)

        self.errorList = SpexiDataStandards.ZoneErrors()
        emit ContractInitialized()
    }


    //Represents Zone as an NFT. NFT interface requirement.
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

        pub let id: UInt64
        pub var name: String
        access(self) var metadata: SpexiDataStandards.ZoneData
        
        init(
            id: UInt64,
            name: String,
            blockMinted: UInt64,
            timeMinted: UFix64,
            coordinates: [UInt8]
        ) {
            self.id = id
            self.name = name
            self.metadata = SpexiDataStandards.ZoneData(
                blockMinted: blockMinted, 
                timeMinted: timeMinted, 
                coordinates: coordinates
            )
        }

        access(account) fun getStatus(): SpexiDataStandards.ZoneStatus { 
            return SpexiDataStandards.ZoneStatus(
                zoneData: self.metadata, 
                currentTime: getCurrentBlock().timestamp,
                maxPilotQueue: ZoneManagement.maxPilotQueue
            )
        }
        
        //Functionality
        access(account) fun setFreshAtTime(time: UFix64) {
            pre{ self.getStatus().reservedPilotCount != 0 : ZoneManagement.errorList.changeFreshnessWithPilotTrouble }
            self.metadata.setFreshAtTime(freshAtTime: time) 
        }

        access(account) fun reserve(address: Address) {
            pre{ self.getStatus().isLocked : ZoneManagement.errorList.zoneLockTrouble }
            self.metadata.addPilotToQueue(address: address);
        }

        access(account) fun removeReservation(address: Address) {
            pre{ self.getStatus().reservedPilotCount == 0 : ZoneManagement.errorList.emptyPilotQueue }
            self.metadata.removePilotFromQueue(address: address)
        }

        access(account) fun removeAllReservations() {
            pre{ self.getStatus().reservedPilotCount == 0 : ZoneManagement.errorList.emptyPilotQueue }
            self.metadata.clearPilotQueue()
        }

        access(account) fun updateCoordinates(coordinates: [UInt8]) {
            pre{ self.getStatus().reservedPilotCount != 0 : ZoneManagement.errorList.changeCoordinatesWithPilotTrouble }
            self.metadata.updateCoordinates(coordinates: coordinates)
        }

        pub fun getViews(): [Type] { 
            return [
                Type<SpexiDataStandards.NFTData>(),
                Type<SpexiDataStandards.ZoneData>(),
                Type<SpexiDataStandards.ZoneStatus>()
            ] 
        }

        pub fun resolveView(_ view: Type): AnyStruct? { 
            switch view {
                case Type<SpexiDataStandards.NFTData>():
                    return SpexiDataStandards.NFTData(id: self.id, name: self.name, metadata: self.metadata)

                case Type<SpexiDataStandards.ZoneData>():
                    return self.metadata
                
                case Type<SpexiDataStandards.ZoneStatus>():
                    return self.getStatus()

                default:
                    return nil
            }
        }
    }


    pub resource interface ZoneCollection {
        pub fun getIDs(): [UInt64]
        access(account) fun borrowZone(id: UInt64): &ZoneManagement.NFT? {
            post { (result == nil) || (result?.id == id): ZoneManagement.errorList.cantBorrowInvalidReference }
        }

        access(account) fun destroyZone(id: UInt64)
        access(account) fun reserveZone(id: UInt64, address: Address)
        access(account) fun removeReservation(id: UInt64, address: Address)
        access(account) fun removeAllReservations(id: UInt64)
        access(account) fun removeAllReservationsFromAllZones()
        access(account) fun removeAllReservationsFromList(ids: [UInt64])
        access(account) fun setZoneFreshDate(id: UInt64, freshAtTime: UFix64)
        access(account) fun setZoneFreshDateForAllZones(freshAtTime: UFix64)
        access(account) fun setZoneFreshDateForZoneList(ids: [UInt64], freshAtTime: UFix64)
        access(account) fun updateCoordinates(id: UInt64, coordinates: [UInt8])
    }


    //Resource to store zones.
    pub resource Collection: ZoneCollection, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
        init () { self.ownedNFTs <- {} }
        
        pub fun getIDs(): [UInt64] { return self.ownedNFTs.keys }

        //Tell the user withdrawing is not an option for zones.
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            panic("Zones can not be withdrawn from the collection.")
        }

        //Add a zone to the collection.
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @ZoneManagement.NFT
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }

        //DAPPER: What is the best security measure for borrowing resources?
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT { return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)! }

        access(account) fun borrowZone(id: UInt64): &ZoneManagement.NFT? {
            if self.ownedNFTs[id] != nil {
                //Get Standard NFT type object from dictionary then cast to ZoneManagement.NFT type.
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &ZoneManagement.NFT //DAPPER: Does this allow modification?
            }

            return nil
        }

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let zoneNFT = nft as! &ZoneManagement.NFT
            return zoneNFT as &AnyResource{MetadataViews.Resolver}
        }
        
        //Remove zone from collection and destroy it.
        access(account) fun destroyZone(id: UInt64) {
            let zone = self.borrowZone(id: id) ?? panic(ZoneManagement.errorList.idDoesntExist)
            if(zone.getStatus().reservedPilotCount != 0) { panic(ZoneManagement.errorList.destroyZoneWithPilotTrouble) }
    
            let token <- self.ownedNFTs.remove(key: id) ?? panic(ZoneManagement.errorList.idDoesntExist)
            emit ZoneDestroyed(id: zone.id, name: zone.name)
            destroy token
        }
        
        //Add a pilot address to the pilot queue.
        access(account) fun reserveZone(id: UInt64, address: Address) {
            let zone = self.borrowZone(id: id) ?? panic(ZoneManagement.errorList.idDoesntExist)
            //DAPPER: Is there a proper way to use 'pre' or 'post' in this context instead of panic.
            if(zone.getStatus().isLocked) { panic(ZoneManagement.errorList.zoneLockTrouble) }
            zone.reserve(address: address)
        }

        //Remove a pilot by address from the pilot queue.
        access(account) fun removeReservation(id: UInt64, address: Address) {
            let zone = self.borrowZone(id: id) ?? panic(ZoneManagement.errorList.idDoesntExist)
            if(zone.getStatus().reservedPilotCount == 0) { panic(ZoneManagement.errorList.emptyPilotQueue) }
            zone.removeReservation(address: address)
        }

        //Remove all pilot addresses from the pilot queue.
        access(account) fun removeAllReservations(id: UInt64) {
            let zone = self.borrowZone(id: id) ?? panic(ZoneManagement.errorList.idDoesntExist)
            if(zone.getStatus().reservedPilotCount == 0) { panic(ZoneManagement.errorList.emptyPilotQueue) }
            zone.removeAllReservations()
        }

        access(account) fun removeAllReservationsFromAllZones() {
            for id in self.getIDs() { self.removeAllReservations(id:id) }
        }

        access(account) fun removeAllReservationsFromList(ids: [UInt64]) {
            for id in ids { self.removeAllReservations(id:id) }
        }

        //Set the block time at which a zone is considered fresh.
        access(account) fun setZoneFreshDate(id: UInt64, freshAtTime: UFix64) {
            let zone = self.borrowZone(id: id) ?? panic(ZoneManagement.errorList.idDoesntExist)
            if(zone.getStatus().reservedPilotCount != 0) { panic(ZoneManagement.errorList.changeFreshnessWithPilotTrouble) }
            zone.setFreshAtTime(time: freshAtTime)
        }

        access(account) fun setZoneFreshDateForAllZones(freshAtTime: UFix64) {
            for id in self.getIDs() { self.setZoneFreshDate(id:id, freshAtTime:freshAtTime) } 
        }

        access(account) fun setZoneFreshDateForZoneList(ids: [UInt64], freshAtTime: UFix64) {
            for id in ids { self.setZoneFreshDate(id:id, freshAtTime:freshAtTime) } 
        }

        pub fun updateCoordinates(id: UInt64, coordinates: [UInt8]) {
            let zone = self.borrowZone(id: id) ?? panic(ZoneManagement.errorList.idDoesntExist)
            if(zone.getStatus().reservedPilotCount != 0) { panic(ZoneManagement.errorList.changeCoordinatesWithPilotTrouble) }
            zone.updateCoordinates(coordinates: coordinates)
        }

        destroy() { destroy self.ownedNFTs }
    }
    

    //Resource to control zones.
    pub resource ZoneAdmin {
        
        //Create a zone.
        pub fun mintZone(
            recipient: &{NonFungibleToken.CollectionPublic}, 
            name: String,
            coordinates: [UInt8]
        ) { 
            let currentBlock: Block = getCurrentBlock()

            var zone: @ZoneManagement.NFT <- create NFT(
                id: ZoneManagement.totalSupply,
                name: name,
                blockMinted: currentBlock.height,
                timeMinted: currentBlock.timestamp,
                coordinates: coordinates
            )

            
            emit ZoneCreated(id: zone.id, name: zone.name);
            recipient.deposit(token: <-zone)
            ZoneManagement.totalSupply = ZoneManagement.totalSupply + 1
        }

        //Destroy a zone and its data.
        pub fun destroyZone(collection: &ZoneManagement.Collection, id: UInt64) {
            collection.destroyZone(id: id)
            ZoneManagement.totalSupply = ZoneManagement.totalSupply - 1
        }

        //Reserve a zone by id with a pilots address.
       pub fun reserveZone(collection: &ZoneManagement.Collection, id: UInt64, address: Address) {
            collection.reserveZone(id: id, address: address)
        }

        //Remove a pilots reservation by providing their reserved zone and their address.
        pub fun removeReservation(collection: &ZoneManagement.Collection, id: UInt64, address: Address) {
            collection.removeReservation(id: id, address: address)
        }

        //Remove all reservations on a zone.
        pub fun removeAllReservations(collection: &ZoneManagement.Collection, id: UInt64) {
            collection.removeAllReservations(id: id)
        }

        //Remove all reservations from all existing zones.
        pub fun removeAllReservationsFromAllZones(collection: &ZoneManagement.Collection) {
            collection.removeAllReservationsFromAllZones()
        }

        //Remove all reservations from all zones in a list.
        pub fun removeAllReservationsFromList(collection: &ZoneManagement.Collection, ids: [UInt64]) {
            collection.removeAllReservationsFromList(ids: ids)
        }

        //Set the time that a zone is considered fresh for surveying.
       pub fun setZoneFreshDate(collection: &ZoneManagement.Collection, id: UInt64, freshAtTime: UFix64) {
            collection.setZoneFreshDate(id: id, freshAtTime: freshAtTime)
        }

        //Set the time that a zone is considered fresh for all zones.
        pub fun setZoneFreshDateForAllZones(collection: &ZoneManagement.Collection, freshAtTime: UFix64) {
            collection.setZoneFreshDateForAllZones(freshAtTime: freshAtTime)
        }

        //Set the time that a zone is considered fresh for a list of zones.
        pub fun setZoneFreshDateForZoneList(collection: &ZoneManagement.Collection, ids: [UInt64], freshAtTime: UFix64) {
            collection.setZoneFreshDateForZoneList(ids: ids, freshAtTime: freshAtTime)
        }

        //Update the coordinates for a zone.
        pub fun updateCoordinates(collection: &ZoneManagement.Collection, id: UInt64, coordinates: [UInt8]) {
            collection.updateCoordinates(id: id, coordinates: coordinates)
        }
    }


    //Collection initializer. NFT interface requirement
    pub fun createEmptyCollection(): @NonFungibleToken.Collection { return <- create Collection() }
}
 