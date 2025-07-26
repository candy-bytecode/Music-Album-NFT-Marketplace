# Music Album NFT Contract

A Clarity smart contract for minting and managing music album NFTs on the Stacks blockchain.

## Features

- Mint albums with complete track listings (up to 20 tracks)
- Store album metadata including artist, genre, and release year
- Artist royalty system (up to 30%)
- Track listing storage and retrieval
- Standard NFT trait compliance

## Contract Functions

### Public Functions
- `mint-album`: Create a new album NFT with track listing
- `transfer`: Transfer album ownership
- `update-base-uri`: Update metadata base URI (owner only)

### Read-Only Functions
- `get-last-token-id`: Get the latest minted token ID
- `get-token-uri`: Get metadata URI for an album
- `get-owner`: Get current owner of an album
- `get-album-details`: Get album metadata
- `get-album-tracks`: Get complete track listing

## Usage

Call `mint-album` with recipient address, album title, track list, genre, release year, and royalty percentage to mint a new album NFT.