;; Music Album NFT Contract
;; NFT contract for music albums with track listing and artist royalties

(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

(define-non-fungible-token music-album uint)

(define-data-var last-token-id uint u0)
(define-data-var contract-owner principal tx-sender)
(define-data-var base-uri (string-ascii 256) "https://api.musicnft.stacks/albums/")

(define-map album-details uint {
    artist: principal,
    album-title: (string-ascii 100),
    track-count: uint,
    genre: (string-ascii 50),
    release-year: uint,
    artist-royalty: uint
})

(define-map album-tracks uint (list 20 (string-ascii 100)))

;; New map to track album sales and royalty distributions
(define-map album-sales uint {
    total-sales: uint,
    total-royalties-paid: uint,
    last-sale-price: uint
})

(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-INVALID-PARAMS (err u400))
(define-constant ERR-TOO-MANY-TRACKS (err u413))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u402))
