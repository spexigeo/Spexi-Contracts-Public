import FlightManagement from "../../contracts/FlightManagement.cdc"

transaction(){
    
    prepare(signer: AuthAccount) {
       let minter = signer.borrow<&FlightManagement.ReceiptMinter>
            (from: FlightManagement.MinterStoragePath) 
         ?? panic("Admin Resource not found")

        if signer.borrow<&FlightManagement.Collection>(from: FlightManagement.CollectionStoragePath) != nil {
            log("This account already has a collection")
            return
        }
        signer.save(<- FlightManagement.createEmptyCollection(), to:FlightManagement.CollectionStoragePath)
    }

    execute{
    }

}
 