# Spexi-Contracts-Public Documentation:

## What is Spexi?

Spexi is the world’s first standardized, ‘Fly-to-Earn’ drone imagery platform, powered by crypto; with the vision of collecting earths most important data with drones.

With our new Fly-to-Earn model, people who own consumer drones will be able to earn $SPEXI tokens and dollars while building a high resolution base layer of the earth. This new base layer will enable governments and organizations of all sizes to make better decisions about real world assets like buildings, utilities, infrastructure, risk and natural resources, without requiring people on the ground.

By using Spexigon, organizations that require high-resolution aerial imagery will no longer need to own their own drones or hire their own pilots. Instead, they’ll use our web and mobile app to search for and purchase imagery. Data buyers will then be able to use a variety of internal and external tools to put the imagery to use.

Our goal is to remove friction from the process by collecting high resolution aerial imagery in advance of demand, and then making it easily available online.

## What are the goals of these contracts?

We would like to create an economy for our Pilots to incetivize them to collect high quality data and provide it to us to provide on our platform. These contracts will operate on chain to ensure transparency and ownership is and rights of pilots are maintained.

## What is the structure of the contracts/How far along are these contracts built?

We have

## What is the user flow of these contracts along with a front end?

## Where are the security concerns in these contracts mostly?

---

# Contracts:

## FlightManagement:

This contract will be used to manage all flight submissions. The general overview of how this contract will be utilized is as follows:

- Pilots will start a project on the app
- On the mobile app they will start their fly route on the mobile app, once they're on site
- As soon as they hit start, an NFT receipt will be generated for them using `FlightManagement` contract, with a status of `AwaitingSubmission`
- Once they've completed their flight and they've submitted files on the app, we will automatically use `modifyReceipt()` and change their status to `inReview`
- once verification is complete on our backend, we will modify this receipt to be `Verified` or `Failed`

#### Things to keep in mind:

- Only hodler of `ReceiptMinter` is able to create receipts/modify them
- In order to mint a receipt for someone, they must have a collection initialized in their storage.

## FlightManagement - Scripts/Transactions:

### Scripts:

#### 1. `get_collection_ids`:

This script takes an input of an `account address` and returns the entire Flight Receipt Collection in that account. The return type is an array of `UInt64`. Output Examples:
`[]`, `[1,5,7]`

#### 2. `get_flight_by_id`:

This script takes an input of `account address`, a `flightID` which is the ID of the flight you'd like to retreive information about. The return type is a `FlightManagement NFT`. Output Example:

`A.f8d6e0586b0a20c7.FlightManagement.NFT(uuid: 26, id: 2, submissionStatus: A.f8d6e0586b0a20c7.FlightManagement.Status(rawValue: 2), zone: "Zone", flightType: "FlightType", date: 1665529702.00000000, imageURI: "imageURL", submissionDetails: A.f8d6e0586b0a20c7.FlightManagement.Submission(numberOfFiles: 15, metadataURI: "Metadata", filesURI: "Files"))`

### Transactions:

#### 1. `create_collection`:

This transaction has to be run by the signer that is trying to make a collection for themselves. If you sign it, then it means you want to create a collection for yourself, in your own storage. This transaction will not return anything.

You must create a collection in an account before you can mint to it.

#### 2. `create_receipt`:

This transaction will mint a brand new receipt with the specified inputs to the inputted address. Currently the arguments are hardcoded in the `minter.generateFlightReceipt()` call, but we can extract those and input them into the function along with the address.

In order to mint to an address, the address MUST have a collection in their account.

#### 3. `modify_receipt_status`:

This is the main important transaction that we will be using for managing the states of a flight receipt. This transaction takes `account address`, `flightID`, `new state you want to modify TO`. The function will check if the specified flight exists in the user account and then modify it to the exact state you'd like it to switch to. The current available states of the contract are:

1. `0` = `AwaitingSubmission`
2. `1` = `inReview`
3. `2` = `Failed`
4. `3` = `Verified`

---

## ProductManagement:

This contract will be used to manage all live Products. The general overview of how this contract will be utilized is as follows:

- After a Pilot had submitted their files and we attach everything to the Flight Receipt, we will being to do a verification process on the data on our end.
- Once the verification has been completed and we've verified it, we can run the `create_product` transaction
- The contract will then iterate over the flightType of the FlightReceipt submitted and will generate a Product for each flightType included in this FlightReceipt

#### Things to keep in mind:

- Only hodler of `ReceiptMinter` is able to create or delete a product
- In order to mint a product for someone, they must have a collection initialized in their storage.

## ProductManagement - Scripts/Transactions:

### Scripts:

#### 1. `get_collection_ids`:

This script takes an input of an `account address` and returns the entire Product Collection in that account. The return type is an array of `UInt64`. Output Examples:
`[]`, `[1,5,7]`

#### 2. `get_product_by_id`:

This script takes an input of `account address`, a `productID` which is the ID of the product you'd like to retreive information about. The return type is a `ProductManagement NFT`. Output Example:

`A.f8d6e0586b0a20c7.ProductManagement.NFT(uuid: 32, id: 2, name: "Zone 1666384898.00000000 FlightType2", description: "Zone", productType: "FlightType2", zone: "Zone", date: 1666384898.00000000, thumbnail: "imageURL", metadataURI: "Metadata")`

### Transactions:

#### 1. `create_collection`:

This transaction has to be run by the signer that is trying to make a collection for themselves. If you sign it, then it means you want to create a collection for yourself, in your own storage. This transaction will not return anything.

You must create a collection in an account before you can mint to it.

#### 2. `create_product`:

This transaction will mint a brand new product with the specified inputs of the `FlightManagement.NFT` we provided.

In order to mint to an address, the address MUST have a collection in their account.

#### 3. `destroy_product`:

This function allows us to delete a certain NFT out of a collection. It takes the inputs of an `address` and `id` for which nft you would like to destroy.

This function works but currently has some concerns around it. Its currently accessible by anyone (anyone can delete an NFT). But also we need to be aware of the fact that when we delete an NFT, we remove its ID from circulation but the totalSupply and the IDs of everything else dont change. Meaning, if we delete NFT with `id = 1`, then NFT with `id = 2` will maintain that ID but we will no longer have an NFT with `id = 1`. So we would need to keep track of which NFTs were deleted in our back end.
