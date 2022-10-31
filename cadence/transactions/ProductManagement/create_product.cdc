import ProductManagement from "../../contracts/ProductManagement.cdc"
import FlightManagement from "../../contracts/FlightManagement.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

transaction(address: Address, flightID: UInt64){

    prepare(signer: AuthAccount){
        let minter = signer.borrow<&ProductManagement.ProductMinter>
            (from: ProductManagement.ProductMinterStoragePath)
            ?? panic("Admin Resource not found")

        let account = getAccount(address)

        let receipentFlightcollection = account.getCapability(FlightManagement.CollectionPublicPath)
        .borrow<&FlightManagement.Collection{NonFungibleToken.CollectionPublic, FlightManagement.ICollectionPublic}>() ?? panic ("We could not get the public Link!")
    
         let flight = receipentFlightcollection.borrowAuthNFT(id: flightID)


        let receipientsProductCollection = account.getCapability(ProductManagement.ProductCollectionPublicPath)
        .borrow<&ProductManagement.Collection{NonFungibleToken.CollectionPublic, ProductManagement.ICollection}>() ?? panic ("We could not get the public Link!")
    
        
        let nfts <- minter.generateProductReceipts(_flightReceipt:flight)

        receipientsProductCollection.batchDeposit(tokens: <- nfts)
    }

    execute{
    
    }
}
