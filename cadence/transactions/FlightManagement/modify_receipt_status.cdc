import FlightManagement from "../../contracts/FlightManagement.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

transaction(address: Address, flightID: UInt64, status: UInt8){
    
    prepare(signer: AuthAccount) {
        let account = getAccount(address)

        let collection = account.getCapability(FlightManagement.CollectionPublicPath)
        .borrow<&FlightManagement.Collection{NonFungibleToken.CollectionPublic, FlightManagement.ICollectionPublic}>() ?? panic ("We could not get the public Link!")
    
        //store the flight you want to modify
        let flight = collection.borrowAuthNFT(id: flightID)
    
       let minter = signer.borrow<&FlightManagement.ReceiptMinter>
            (from: FlightManagement.MinterStoragePath) 
         ?? panic("Admin Resource not found")

        let _status = FlightManagement.Status.AwaitingSubmission

        if(status == 0){
            minter.modifyReceipt(_receipt: flight, _submissionStatus: FlightManagement.Status.AwaitingSubmission) 
        }
        else if(status == 1){
            minter.modifyReceipt(_receipt: flight, _submissionStatus: FlightManagement.Status.InReview) 
        }
        else if(status == 2){
            minter.modifyReceipt(_receipt: flight, _submissionStatus: FlightManagement.Status.Failed) 
        }
        else if(status == 3){
            minter.modifyReceipt(_receipt: flight, _submissionStatus: FlightManagement.Status.Verified) 
        }
    }

    execute{
    }

}
 