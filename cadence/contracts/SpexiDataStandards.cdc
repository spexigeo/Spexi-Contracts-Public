pub contract SpexiDataStandards {

    //A standardized way of handling generic NFT Data
    pub struct NFTData {
        pub let id: UInt64
        pub let name: String
        pub let metadata: AnyStruct

        init(id: UInt64, name: String, metadata: AnyStruct) {
            self.id = id
            self.name = name
            self.metadata = metadata //TODO: Investigate Opensea Standard for Flow
        }
    }


    //Metadata type for ZoneV1.NFT with explicit types.
    pub struct ZoneData {
        pub let blockMinted: UInt64
        pub let timeMinted: UFix64
        pub var coordinates: [UInt8]
        pub var pilotQueue:  [Address]
        pub var freshAtTime: UFix64

        init(
            blockMinted: UInt64,
            timeMinted: UFix64,
            coordinates: [UInt8],
        ) {
            self.blockMinted = blockMinted
            self.timeMinted = timeMinted
            self.coordinates = coordinates
            self.pilotQueue = []            //Initialize with nothing.
            self.freshAtTime = timeMinted   //Fresh at mint.
        }

        pub fun removePilotFromQueueByIndex(index: Int){ self.pilotQueue.remove(at: index); }
        pub fun clearPilotQueue() { self.pilotQueue = [] }
        pub fun setFreshAtTime(freshAtTime: UFix64) {  self.freshAtTime = freshAtTime }
        pub fun updateCoordinates(coordinates: [UInt8]) { self.coordinates = coordinates }
        
        pub fun addPilotToQueue(address: Address) {
            pre{ self.pilotQueue.contains(address) : "Pilot has already been queued. Can not queue a pilot more than once." }
            self.pilotQueue.append(address) 
        }

        pub fun removePilotFromQueue(address: Address) {
            pre{ !self.pilotQueue.contains(address) : "Pilot not removed because pilot was not in the queue." }

            var index = 0;
            for pilot in self.pilotQueue {
                if(pilot == address) {
                    self.removePilotFromQueueByIndex(index: index)
                    return
                }
                index = index+1
            }
        }
    }


    //A data type that converts ZoneData into a representation of the Zone's status.
    pub struct ZoneStatus {
        pub let reservedPilotCount: Int
        pub let reservedPilots: [Address]
        pub let isFresh: Bool
        pub let isFullyReserved: Bool
        pub let isLocked: Bool

        init(zoneData: ZoneData, currentTime: UFix64, maxPilotQueue: Int) {
            self.reservedPilotCount = zoneData.pilotQueue.length
            self.reservedPilots = zoneData.pilotQueue
            self.isFresh = currentTime >= zoneData.freshAtTime
            self.isFullyReserved = zoneData.pilotQueue.length >= maxPilotQueue
            self.isLocked = !self.isFresh || self.isFullyReserved
        }
    }

    pub struct ZoneErrors {
        //Zone Base Errors
        pub let pilotIsQueued: String
        pub let emptyPilotQueue: String
        pub let freshnessImmutable: String
        pub let coordinatesImmutable: String
        pub let indestructible: String
        pub let cantBorrow: String
        pub let zoneLocked: String
        pub let idDoesntExist: String
        pub let invalidResourceReference: String

        //Troubleshoot suggestions.
        pub let checkZoneLock: String
        pub let removePilots: String

        //Zone compound errors.
        pub let changeFreshnessWithPilot: String
        pub let changeCoordinatesWithPilot: String
        pub let destroyZoneWithPilot: String
        pub let cantBorrowInvalidReference: String

        //Errors with troubleshoots.
        pub let zoneLockTrouble: String
        pub let changeFreshnessWithPilotTrouble: String
        pub let changeCoordinatesWithPilotTrouble: String
        pub let destroyZoneWithPilotTrouble: String


        init() {
            self.pilotIsQueued = "Pilots are currently surveying this zone. "
            self.emptyPilotQueue = "There are no pilots in the queue. "
            self.freshnessImmutable = "Can not change freshness. "
            self.coordinatesImmutable = "Can not change coordinates. "
            self.indestructible = "Can not destroy resource. "
            self.cantBorrow = "Cannot borrow the zone reference. "
            self.zoneLocked = "Zone is locked. Meaning either fully reserved or not fresh. "
            self.idDoesntExist = "Zone ID does not exist. "
            self.invalidResourceReference = "There was an invalid resource referenced. "

            self.checkZoneLock = "Please check zone lock before reserving. "
            self.removePilots = "Please remove pilots firsts. "

            self.changeFreshnessWithPilot = self.pilotIsQueued.concat(self.freshnessImmutable)
            self.changeCoordinatesWithPilot = self.pilotIsQueued.concat(self.coordinatesImmutable)
            self.destroyZoneWithPilot = self.pilotIsQueued.concat(self.indestructible)
            self.cantBorrowInvalidReference = self.cantBorrow.concat(self.invalidResourceReference)

            self.changeFreshnessWithPilotTrouble = self.changeFreshnessWithPilot.concat(self.removePilots)
            self.changeCoordinatesWithPilotTrouble = self.changeCoordinatesWithPilot.concat(self.removePilots)
            self.destroyZoneWithPilotTrouble = self.destroyZoneWithPilot.concat(self.removePilots)
            self.zoneLockTrouble = self.zoneLocked.concat(self.checkZoneLock)
        }
    }
}