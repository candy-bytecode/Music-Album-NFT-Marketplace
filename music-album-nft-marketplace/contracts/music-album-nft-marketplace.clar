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

(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
    (ok (some (concat (var-get base-uri) (uint-to-ascii token-id))))
)

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? music-album token-id))
)

(define-read-only (get-album-details (token-id uint))
    (map-get? album-details token-id)
)

(define-read-only (get-album-tracks (token-id uint))
    (map-get? album-tracks token-id)
)

;; New function 1: Get album statistics including sales data
(define-read-only (get-album-stats (token-id uint))
    (let
        (
            (details (map-get? album-details token-id))
            (sales (default-to {total-sales: u0, total-royalties-paid: u0, last-sale-price: u0} 
                              (map-get? album-sales token-id)))
        )
        (match details
            album-data (ok {
                artist: (get artist album-data),
                album-title: (get album-title album-data),
                track-count: (get track-count album-data),
                genre: (get genre album-data),
                release-year: (get release-year album-data),
                artist-royalty: (get artist-royalty album-data),
                total-sales: (get total-sales sales),
                total-royalties-paid: (get total-royalties-paid sales),
                last-sale-price: (get last-sale-price sales)
            })
            ERR-NOT-FOUND
        )
    )
)