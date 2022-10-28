import NonFungibleToken from "./NonFungibleToken.cdc"

pub contract FlightManagement: NonFungibleToken {
 
  pub var totalSupply: UInt64
  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event ReceiptMinted(id: UInt64, to: Address?)

  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let MinterStoragePath: StoragePath


  //Some metadata for flight receipt:
  pub struct Submission {
    pub var numberOfFiles:UInt16
    pub var metadataURI:String 
    pub var filesURI:String

    init(_numberOfFiles:UInt16, _metadataURI:String, _filesURI:String){
      self.numberOfFiles = _numberOfFiles;
      self.metadataURI = _metadataURI;
      self.filesURI = _filesURI;
    }
  }
  
  //Status of each flight receipt:
  //All flight start as AwaitingSubmission -> inReview -> Failed/Verified
  pub enum Status:UInt8{
    pub case AwaitingSubmission
    pub case InReview
    pub case Failed
    pub case Verified
  }

  // The NFT Receipt Resource
  //@param id: unique uuid to this receipt
  //@param submissionStatus: of type status -> initialized as AwaitingSubmission
  //@param zone: The H3 hash for the zone this flight is for
  //@param flightType[]: array of all types of flights submitted (Orbit, Map, Pano) -- This is work in progres
  //@param date: date of flight
  //@param imageURI: URI of the thubmnail image of NFT
  //@param submissionDetails: type submission (numberOfFiles,metadataURI,filesURI)
  pub resource NFT: NonFungibleToken.INFT {
    pub let id: UInt64 
    pub(set) var submissionStatus: Status
    pub let zone:String 
    //an array[] of different flights which were executed on this flight (Pano/orbit/map)
    pub let flightType:[String]
    pub let date:UFix64
    pub var imageURI: String
    pub var submissionDetails: Submission


    init(_zone:String,_totalFlights:UInt64, _flightType:[String], _imageURI:String,_submissionDetails:Submission){

      self.submissionStatus = FlightManagement.Status.AwaitingSubmission; 
      self.zone = _zone;
      self.id = _totalFlights + 1; 
      self.flightType = _flightType;
      self.date = getCurrentBlock().timestamp;
      self.imageURI = _imageURI;
      self.submissionDetails = _submissionDetails
      FlightManagement.totalSupply = FlightManagement.totalSupply + 1
    }
  }

  // DAPPER: How should this interface be handled? Should borrowAuthNFT be public or borrowNFT?
  //custom Interface for collection resource
  // we want to provide access to this function, so we can get a reference of an NFT. 
  pub resource interface ICollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowAuthNFT(id: UInt64): &NFT
  }

  // DAPPER: SHOULD THESE FUNCTIONS REMAIN AS 'pub fun' or should these be access(account)?
  //Functionality of Collection Resource
  pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, ICollectionPublic{
  
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let nft <- self.ownedNFTs.remove(key: withdrawID) 
              ?? panic("This Receipt does not exist in this Collection.")
      emit Withdraw(id: nft.id, from: self.owner?.address)
      return <- nft
    }

    pub fun deposit(token: @NonFungibleToken.NFT) {
      let nft <- token as! @NFT
      emit Deposit(id: nft.id, to: self.owner?.address)
      self.ownedNFTs[nft.id] <-! nft
    }

    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }


    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
    }

    pub fun borrowAuthNFT(id: UInt64): &NFT {
      let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
      return ref as! &NFT  
    }   


    init() {
      self.ownedNFTs <- {}
    }

    //DAPPER: is there a way to limit the users ability to destroy their collection? we do not want them to destroy.
    destroy() {
      destroy self.ownedNFTs
    }
  }

  //Functionality of a ReceiptMinter resource
  pub resource ReceiptMinter {

    //Generates a Flight Receipt using a set of Perameters
    //@returns an NFT flight resource
    pub fun generateFlightReceipt(_zone:String, _flightType:[String], _imageURI:String,_numberOfFiles:UInt16, _metadataURI:String,_filesURI:String): @NFT {
      let _submissionDetails = FlightManagement.Submission(_numberOfFiles,_metadataURI,_filesURI);
      let _totalFlights = FlightManagement.totalSupply
      emit ReceiptMinted(id: _totalFlights + 1,to:self.owner?.address)
      return <- create NFT(_zone:_zone,_totalFlights: _totalFlights, _flightType:_flightType, _imageURI:_imageURI,_submissionDetails:_submissionDetails) 
    }

    //Modifies a receipt status
    //@param _receipt: a reference to the specific flight
    //@param _submissionStatus: Pending,Failed or Verified status
    pub fun modifyReceipt(_receipt: &NFT, _submissionStatus: FlightManagement.Status) {
      _receipt.submissionStatus = _submissionStatus
    }

    //DAPPER: should we make this access(contract) ??
    pub fun createMinter(): @ReceiptMinter {
      return <- create ReceiptMinter()
    }

  }

  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }


  init(){
    self.totalSupply = 0
    
    self.CollectionStoragePath = /storage/FlightManagementCollection
    self.CollectionPublicPath = /public/FlightManagementCollection
    self.MinterStoragePath = /storage/ReceiptMinterMinter

    self.account.save(<- create ReceiptMinter(), to: self.MinterStoragePath)
    
    self.account.save(<- self.createEmptyCollection(), to: self.CollectionStoragePath)
    
    //DAPPER: any security issues here since we make ICollectionPublic available??
    //create a Link for public access between the CollectionStoragePath and CollectionPublicPath
    // but Limited to CollectionPublic and ICollection interfaces
    self.account.link<&FlightManagement.Collection{NonFungibleToken.CollectionPublic, FlightManagement.ICollectionPublic}>(
      self.CollectionPublicPath,
      target: self.CollectionStoragePath
    )
    
    emit ContractInitialized()
  } 

}
 