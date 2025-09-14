;; ft-trait.clar
;; Minimal SIP-010 Fungible Token Trait for dependency linking

(define-trait trait-ft
  (
    ;; Transfer tokens: amount, sender, recipient
    (transfer (uint principal principal) (response bool uint))

    ;; Get balance of a principal
    (balance-of (principal) (response uint uint))

    ;; Get total supply
    (total-supply () (response uint uint))

    ;; Optional: token decimals
    (get-decimals () (response uint uint))

    ;; Optional: token symbol
    (get-symbol () (response (string-ascii 32) uint))

    ;; Optional: token name
    (get-name () (response (string-ascii 32) uint))
  )
)
