import NonFungibleToken from "./NonFungibleToken.cdc"
import FlightManagement from "./FlightManagement.cdc"
import MetadataViews from "./MetadataViews.cdc"


pub contract ProductManagement: NonFungibleToken {

  pub var totalSupply: UInt64
  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event ProductsMinted(id: [UInt64], to: Address?)
  pub event ProductStateSwitched(id: UInt64, to: Address?)
  
  pub let ProductCollectionStoragePath: StoragePath
  pub let ProductCollectionPublicPath: PublicPath
  pub let ProductMinterStoragePath: StoragePath

    // The NFT Receipt Resource
    //@param id: unique uuid to this flight
    //@param name: Zone ID + FlightDate + FlightType
    //@param description: coordinates of Zone
    //@param productType: Type of product (orbit,map,pano,raw)
    //@param date: date of flight
    //@param thumbail: URI of the thubmnail image of NFT
    //@param metadataURI: URI where all the metadata will be stored
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        pub let id: UInt64 
        pub let name: String
        pub let description: String
        pub let productType: String
        pub let zone:String 
        pub let date:UFix64
        pub(set) var live:Bool
        pub var thumbnail: String
        pub var metadataURI: String

        init(_productType:String, _zone:String, _thumbnail:String, _metadataURI:String, _coordinates:String){
            self.id = ProductManagement.totalSupply + 1
            ProductManagement.totalSupply = ProductManagement.totalSupply + 1
            self.productType = _productType
            self.zone = _zone
            self.date = getCurrentBlock().timestamp;
            self.live = true;
            self.thumbnail = _thumbnail;
            self.metadataURI = _metadataURI
            self.name = _zone.concat(" ").concat((self.date).toString()).concat(" ").concat(_productType)
            self.description = _coordinates
        }

        pub fun getViews(): [Type] {
            return [
            
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Royalties>(),
                Type<MetadataViews.ExternalURL>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Traits>()
            
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
        /*
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(
                            url: self.thumbnail
                        )
                    )
                case Type<MetadataViews.Royalties>():
                    return MetadataViews.Royalties(
                        self.royalties
                    )
                case Type<MetadataViews.ExternalURL>():
                    //need to change this to URL we want later
                    //return MetadataViews.ExternalURL("https://example-nft.onflow.org/".concat(self.id.toString()))
                    return nil
                case Type<MetadataViews.NFTCollectionData>():
                    return MetadataViews.NFTCollectionData(
                        storagePath: ProductManagement.ProductCollectionStoragePath,
                        publicPath: ProductManagement.ProductCollectionPublicPath,
                        providerPath: /private/exampleNFTCollection,
                        publicCollection: Type<&ProductManagement.Collection{ProductManagement.ICollection}>(),
                        publicLinkedType: Type<&ProductManagement.Collection{ProductManagement.ICollection,NonFungibleToken.CollectionPublic,NonFungibleToken.Receiver,MetadataViews.ResolverCollection}>(),
                        providerLinkedType: Type<&ProductManagement.Collection{ProductManagement.ICollection,NonFungibleToken.CollectionPublic,NonFungibleToken.Provider,MetadataViews.ResolverCollection}>(),
                        createEmptyCollectionFunction: (fun (): @NonFungibleToken.Collection {
                            return <-ProductManagement.createEmptyCollection()
                        })
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    let media = MetadataViews.Media(
                        //insert proper storage path
                        file: MetadataViews.HTTPFile(
                            //url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
                            url: ""
                        ),
                        mediaType: "image/svg+xml"
                    )
                    return MetadataViews.NFTCollectionDisplay(
                        name: "Spexi Flight Collection",
                        description: "This collection is to display current availabel and approved flight data for spexi",
                        externalURL: MetadataViews.ExternalURL(""),
                        squareImage: media,
                        bannerImage: media,
                        socials: {
                            "twitter": MetadataViews.ExternalURL("https://twitter.com/spexigon")
                        }
                    )
                case Type<MetadataViews.Traits>():
                    let excludedTraits: [String] = []
                    let traitDictionary: {String:AnyStruct} = {
                        "flightType": "FlightType",
                        "dataURL": "Data URL",
                        "numOfFiles": "Num OF Files"
                    }
                    return MetadataViews.dictToTraits(dict: traitDictionary, excludedNames:excludedTraits)
            }
            */
            return nil
        }
    }

    // DAPPER: Same Issue here. How should this interface be handled? Should borrowAuthNFT be public or borrowNFT or neither?
    //custom Interface for collection resource
    // we want to provide access to this function, so we can get a reference of an NFT. 
    pub resource interface ICollection {
        pub fun borrowAuthNFT(id: UInt64): &NFT
        pub fun batchDeposit(tokens: @[ProductManagement.NFT])
        pub fun switchProductState(id: UInt64)
    }


    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, ICollection {
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

        //ability to deposit multiple products into an account
        //@param tokens: array of Products to deposit into an account
        pub fun batchDeposit(tokens: @[ProductManagement.NFT]) {
            var i = 0
            let numOfNFTs = tokens.length
            while i < numOfNFTs {
                let nft <- tokens.removeFirst()
                let currID = nft.id
                self.ownedNFTs[nft.id] <-! nft
                emit Deposit(id: currID, to: self.owner?.address)
                i=i+1
            }
            destroy tokens
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

        //DAPPER: How can we make this function ONLY accessible by us (ProductMinter resource)??
        //ability to invalidate a product if needed. we just switch a boolean off in the NFT so it doesnt show up in our marketplace
        //@param id: the ID of the product
        pub fun switchProductState(id: UInt64){     
            let nft = self.borrowAuthNFT(id: id)
            nft.live = !nft.live;
            let holder = self.owner?.address 
            emit ProductStateSwitched(id: id, to: holder)
        
        }

        /*
        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let productNFT = nft as! &ProductManagement.NFT
            return productNFT as &AnyResource{MetadataViews.Resolver}
        }
        */

        init() {
            self.ownedNFTs <- {}
        }

        //DAPPER: Are we able to override this and not allow them to destroy their NFTs?
        destroy() {
            destroy self.ownedNFTs
        }
    
}

    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }
    

    //DAPPER: Should this stay pub? or priv?
    pub resource ProductMinter {

        //Generates a Flight Receipt using a set of Perameters
        //@returns an NFT flight resource
        pub fun generateSingleProductReceipt(_productType:String, _zone:String, _thumbnail:String, _metadataURI:String, _coordinates:String): @NFT {
            post {
                result.id == ProductManagement.totalSupply: "There was an issue with generating your Receipt"
            }
            return <- create NFT(_productType:_productType, _zone:_zone, _thumbnail:_thumbnail, _metadataURI:_metadataURI,_coordinates:_coordinates) 
        }

        pub fun createMinter(): @ProductMinter {
            return <- create ProductMinter()
        }
        
        //The actual minting function the transactions will be utilizing. 
        //@param _flightReceipt: a reference to a Flight Receipt
        //The function will check the flight types recorded in this Flight Receipt and create _flightReciept.flightType.length amount of Products
        //and deposit them into the users collection (using BatchDeposit)
        pub fun generateProductReceipts(_flightReceipt: &FlightManagement.NFT): @[ProductManagement.NFT]{
            let myNFTs: @[ProductManagement.NFT] <- []
            let nftIDs: [UInt64] = []
            let _coordinates = _flightReceipt.zone
            for element in _flightReceipt.flightType {
                let newNFT <- self.generateSingleProductReceipt(_productType:element, _zone:_flightReceipt.zone, _thumbnail:_flightReceipt.imageURI, _metadataURI:_flightReceipt.submissionDetails.metadataURI,_coordinates:_coordinates)
                let id = newNFT.id
                myNFTs.append(<- newNFT)
                nftIDs.append(id)
                
            }
            emit ProductsMinted(id:nftIDs, to:self.owner?.address)

            return <- myNFTs
        }

    }


    init(){
        self.totalSupply = 0
    
        self.ProductCollectionStoragePath = /storage/ProductManagementCollection
        self.ProductCollectionPublicPath = /public/ProductManagementCollection
        self.ProductMinterStoragePath = /storage/ProductProductMinter

        self.account.save(<- create ProductMinter(), to: self.ProductMinterStoragePath)
        
        self.account.save(<- self.createEmptyCollection(), to: self.ProductCollectionStoragePath)

        //DAPPER: any security issues here since we make ICollectionPublic available??
        //create a Link for public access between the CollectionStoragePath and CollectionPublicPath
        // but Limited to CollectionPublic and ICollection interfaces
        self.account.link<&ProductManagement.Collection{NonFungibleToken.CollectionPublic, ProductManagement.ICollection}>(
        self.ProductCollectionPublicPath,
        target: self.ProductCollectionStoragePath
        )
    
        emit ContractInitialized()
    }

}
 