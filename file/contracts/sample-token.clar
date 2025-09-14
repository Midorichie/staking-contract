;; sample-token.clar - Sample SIP-010 Token for Testing
;; This contract implements a basic fungible token for testing the staking ecosystem

(impl-trait .ft-trait.trait-ft)

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant TOKEN-NAME "Sample Reward Token")
(define-constant TOKEN-SYMBOL "SRT")
(define-constant TOKEN-DECIMALS u6)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))

;; Token data
(define-fungible-token sample-token)
(define-data-var token-uri (optional (string-utf8 256)) none)

;; SIP-010 Implementation

(define-public (transfer (amount uint) (sender principal) (recipient principal))
  (begin
    (asserts! (or (is-eq tx-sender sender) (is-eq contract-caller sender)) ERR-NOT-AUTHORIZED)
    (ft-transfer? sample-token amount sender recipient)
  )
)

(define-read-only (balance-of (who principal))
  (ok (ft-get-balance sample-token who))
)

(define-read-only (total-supply)
  (ok (ft-get-supply sample-token))
)

(define-read-only (get-name)
  (ok TOKEN-NAME)
)

(define-read-only (get-symbol)
  (ok TOKEN-SYMBOL)
)

(define-read-only (get-decimals)
  (ok TOKEN-DECIMALS)
)

(define-read-only (get-token-uri)
  (ok (var-get token-uri))
)

;; Admin functions for testing

(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (ft-mint? sample-token amount recipient)
  )
)

(define-public (set-token-uri (uri (string-utf8 256)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set token-uri (some uri))
    (ok true)
  )
)

;; Initialize with some tokens for the contract owner
(ft-mint? sample-token u1000000000000 CONTRACT-OWNER)
