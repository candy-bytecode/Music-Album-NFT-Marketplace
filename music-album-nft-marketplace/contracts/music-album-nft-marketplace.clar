;; Music Album NFT Contract
;; NFT contract for music albums with track listing and artist royalties

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

;; New function 2: Transfer with royalty payment to original artist
(define-public (transfer-with-royalty (token-id uint) (sender principal) (recipient principal) (sale-price uint))
    (let
        (
            (album-data (unwrap! (map-get? album-details token-id) ERR-NOT-FOUND))
            (artist (get artist album-data))
            (royalty-rate (get artist-royalty album-data))
            (royalty-amount (/ (* sale-price royalty-rate) u100))
            (seller-amount (- sale-price royalty-amount))
            (current-sales (default-to {total-sales: u0, total-royalties-paid: u0, last-sale-price: u0} 
                                     (map-get? album-sales token-id)))
        )
        (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
        (asserts! (is-some (nft-get-owner? music-album token-id)) ERR-NOT-FOUND)
        (asserts! (> sale-price u0) ERR-INVALID-PARAMS)
        
        ;; Transfer the NFT
        (try! (nft-transfer? music-album token-id sender recipient))
        
        ;; Pay royalty to artist (if artist is different from seller)
        (if (not (is-eq artist sender))
            (begin
                (try! (stx-transfer? royalty-amount sender artist))
                ;; Update sales statistics
                (map-set album-sales token-id {
                    total-sales: (+ (get total-sales current-sales) u1),
                    total-royalties-paid: (+ (get total-royalties-paid current-sales) royalty-amount),
                    last-sale-price: sale-price
                })
            )
            ;; If artist is selling, just update sales count
            (map-set album-sales token-id {
                total-sales: (+ (get total-sales current-sales) u1),
                total-royalties-paid: (get total-royalties-paid current-sales),
                last-sale-price: sale-price
            })
        )
        
        (ok {
            royalty-paid: royalty-amount,
            seller-received: seller-amount,
            new-owner: recipient
        })
    )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
        (asserts! (is-some (nft-get-owner? music-album token-id)) ERR-NOT-FOUND)
        (nft-transfer? music-album token-id sender recipient)
    )
)

(define-public (mint-album 
    (recipient principal)
    (album-title (string-ascii 100))
    (track-list (list 20 (string-ascii 100)))
    (genre (string-ascii 50))
    (release-year uint)
    (artist-royalty uint)
)
    (let
        (
            (next-id (+ (var-get last-token-id) u1))
            (track-count (len track-list))
        )
        (asserts! (> track-count u0) ERR-INVALID-PARAMS)
        (asserts! (<= track-count u20) ERR-TOO-MANY-TRACKS)
        (asserts! (<= artist-royalty u30) ERR-INVALID-PARAMS)
        (asserts! (> release-year u1900) ERR-INVALID-PARAMS)
        
        (try! (nft-mint? music-album next-id recipient))
        
        (map-set album-details next-id {
            artist: tx-sender,
            album-title: album-title,
            track-count: track-count,
            genre: genre,
            release-year: release-year,
            artist-royalty: artist-royalty
        })
        
        (map-set album-tracks next-id track-list)
        
        ;; Initialize sales data
        (map-set album-sales next-id {
            total-sales: u0,
            total-royalties-paid: u0,
            last-sale-price: u0
        })
        
        (var-set last-token-id next-id)
        (ok next-id)
    )
)

(define-public (update-base-uri (new-uri (string-ascii 256)))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (var-set base-uri new-uri)
        (ok true)
    )
)

;; Fixed uint-to-ascii function
(define-read-only (uint-to-ascii (value uint))
    (if (is-eq value u0)
        "0"
        (get result (fold uint-to-ascii-fold 
            (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
            {value: value, result: ""}
        ))
    )
)

(define-private (uint-to-ascii-fold (i uint) (data {value: uint, result: (string-ascii 39)}))
    (let
        (
            (current-value (get value data))
            (current-result (get result data))
        )
        (if (> current-value u0)
            {
                value: (/ current-value u10),
                result: (unwrap-panic (as-max-len? 
                    (concat 
                        (unwrap-panic (element-at "0123456789" (mod current-value u10))) 
                        current-result
                    ) 
                    u39
                ))
            }
            data
        )
    )
)