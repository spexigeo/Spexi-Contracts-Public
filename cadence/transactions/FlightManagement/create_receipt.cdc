import FlightManagement from "../../contracts/FlightManagement.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

transaction(address: Address) {

    prepare(signer: AuthAccount){
        let minter = signer.borrow<&FlightManagement.ReceiptMinter>
            (from: FlightManagement.MinterStoragePath)
            ?? panic("Admin Resource not found")

        let account = getAccount(address)
        let receipientsCollection = account.getCapability(FlightManagement.CollectionPublicPath)
        .borrow<&FlightManagement.Collection{NonFungibleToken.CollectionPublic, FlightManagement.ICollectionPublic}>() ?? panic ("We could not get the public Link!")
    
        //hardcoded values for the time being
        let nft <- minter.generateFlightReceipt(_zone: "Zone",_flightType: ["FlightType1","FlightType2","FlightType3"],_imageURI: "imageURL",_numberOfFiles:15,_metadataURI:"Metadata",_filesURI:"Files")

        receipientsCollection.deposit(token: <- nft)   
    }

    execute{
    
    }
}
