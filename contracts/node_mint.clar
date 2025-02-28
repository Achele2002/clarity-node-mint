;; NodeMint - IoT NFT Platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-device-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-nft (err u103))

;; Define NFT token
(define-non-fungible-token iot-nft uint)

;; Data structures
(define-map devices 
  {device-id: (string-ascii 32)}
  {
    owner: principal,
    device-type: (string-ascii 32),
    authorized: bool
  }
)

(define-map nft-data
  {token-id: uint}
  {
    device-id: (string-ascii 32),
    data: (list 200 uint),
    timestamp: uint,
    owner: principal
  }
)

(define-data-var nft-id-counter uint u0)

;; Device registration
(define-public (register-device (device-id (string-ascii 32)) (device-owner principal) (device-type (string-ascii 32)))
  (if (is-eq tx-sender contract-owner)
    (begin
      (map-set devices 
        {device-id: device-id}
        {
          owner: device-owner,
          device-type: device-type,
          authorized: true
        }
      )
      (ok true)
    )
    err-owner-only
  )
)

;; Mint NFT
(define-public (mint-nft (device-id (string-ascii 32)) (sensor-data (list 200 uint)) (recipient principal))
  (let
    (
      (device (unwrap! (map-get? devices {device-id: device-id}) err-device-not-found))
      (new-id (+ (var-get nft-id-counter) u1))
    )
    (if (and 
      (get authorized device)
      (is-eq (get owner device) tx-sender)
    )
      (begin
        (try! (nft-mint? iot-nft new-id recipient))
        (map-set nft-data
          {token-id: new-id}
          {
            device-id: device-id,
            data: sensor-data,
            timestamp: block-height,
            owner: recipient
          }
        )
        (var-set nft-id-counter new-id)
        (ok new-id)
      )
      err-unauthorized
    )
  )
)

;; Transfer NFT
(define-public (transfer-nft (token-id uint) (recipient principal))
  (let
    (
      (nft-info (unwrap! (map-get? nft-data {token-id: token-id}) err-invalid-nft))
    )
    (if (is-eq tx-sender (get owner nft-info))
      (begin
        (try! (nft-transfer? iot-nft token-id tx-sender recipient))
        (map-set nft-data
          {token-id: token-id}
          (merge nft-info {owner: recipient})
        )
        (ok true)
      )
      err-unauthorized
    )
  )
)

;; Read-only functions
(define-read-only (get-nft-data (token-id uint))
  (ok (map-get? nft-data {token-id: token-id}))
)

(define-read-only (get-device-info (device-id (string-ascii 32)))
  (ok (map-get? devices {device-id: device-id}))
)
