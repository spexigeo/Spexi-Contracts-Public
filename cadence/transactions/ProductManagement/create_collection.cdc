import ProductManagement from "../../contracts/ProductManagement.cdc"

transaction(){
    
    prepare(signer: AuthAccount) {
       let minter = signer.borrow<&ProductManagement.ProductMinter>
            (from: ProductManagement.ProductMinterStoragePath) 
         ?? panic("Admin Resource not found")

        if signer.borrow<&ProductManagement.Collection>(from: ProductManagement.ProductCollectionStoragePath) != nil {
            log("This account already has a collection")
            return
        }

       
        
        signer.save(<- ProductManagement.createEmptyCollection(), to:ProductManagement.ProductCollectionStoragePath)
        //create capability to signer.link(public capability)
    }

    execute{
    }

}
 