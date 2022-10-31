import ProductManagement from "../../contracts/ProductManagement.cdc"
import FlightManagement from "../../contracts/FlightManagement.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"

transaction(address: Address, flightID: UInt64){

    prepare(signer: AuthAccount){
        let minter = signer.borrow<&ProductManagement.ProductMinter>
            (from: ProductManagement.ProductMinterStoragePath)
            ?? panic("Admin Resource not found")

        let account = getAccount(address)

        let receipentProductcollection = account.getCapability(ProductManagement.ProductCollectionPublicPath)
        .borrow<&ProductManagement.Collection{NonFungibleToken.CollectionPublic, ProductManagement.ICollection}>() ?? panic ("We could not get the public Link!")
    
        receipentProductcollection.switchProductState(id: flightID)
    }
}