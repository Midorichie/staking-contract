;; staking.clar - Phase 3 (fixed owner handling)

;; Store stakers mapping: principal -> { amount, unlock, withdrawn }
(define-map stakers principal (tuple (amount uint) (unlock uint) (withdrawn bool)))

;; Constants
(define-constant MIN-STAKE u1)

;; Contract variables
(define-data-var token-contract principal 'ST000000000000000000002AMW42H.my-token)
(define-data-var contract-owner principal tx-sender) ;; set deployer as owner

;; ... stake, withdraw, get-staker functions remain the same ...

;; Admin function: set token contract
(define-public (set-token (token principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err "Only contract owner can set token"))
    (var-set token-contract token)
    (ok token)
  )
)
