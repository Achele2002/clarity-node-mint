;; NodeMint - IoT NFT Platform

;; Constants
(define-constant contract-owner tx-sender)

;; Error codes
;; Authorization errors
(define-constant err-owner-only (err u100))
(define-constant err-unauthorized (err u102))

;; Data validation errors
(define-constant err-device-not-found (err u101))
(define-constant err-invalid-nft (err u103))
(define-constant err-empty-data (err u104))
(define-constant err-device-exists (err u105))

;; Define NFT token
(define-non-fungible-token iot-nft uint)

;; Data structures
(define-map devices 
  {device-id: (string-ascii 32)}
  {
    owner: principal,
    device-type: (string-ascii 32),
    authorized: bool,
    registration-time: uint
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

;; Events
(define-public (print-device-registered (device-id (string-ascii 32)))
  (ok (print {event: "device-registered", device-id: device-id}))
)

(define-public (print-nft-minted (token-id uint))
  (ok (print {event: "nft-minted", token-id: token-id}))
)

;; Utility functions
(define-private (is-device-registered (device-id (string-ascii 32)))
  (is-some (map-get? devices {device-id: device-id}))
)

;; Device registration
(define-public (register-device (device-id (string-ascii 32)) (device-owner principal) (device-type (string-ascii 32)))
  (if (is-eq tx-sender contract-owner)
    (if (not (is-device-registered device-id))
      (begin
        (map-set devices 
          {device-id: device-id}
          {
            owner: device-owner,
            device-type: device-type,
            authorized: true,
            registration-time: block-height
          }
        )
        (try! (print-device-registered device-id))
        (ok true)
      )
      err-device-exists
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
      (> (len sensor-data) u0)
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
        (try! (print-nft-minted new-id))
        (ok new-id)
      )
      (if (<= (len sensor-data) u0)
        err-empty-data
        err-unauthorized
      )
    )
  )
)

[Rest of the contract remains unchanged...]
