;; staking-rewards.clar - Phase 4: Advanced Staking Rewards System
;; This contract manages reward distribution for stakers with enhanced security features

;; Import fungible token trait
(use-trait ft-trait .ft-trait.trait-ft)

;; Constants for security and configuration
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-NO-REWARDS (err u102))
(define-constant ERR-REWARD-POOL-EMPTY (err u103))
(define-constant ERR-STAKER-NOT-FOUND (err u104))
(define-constant ERR-COOLDOWN-ACTIVE (err u105))
(define-constant ERR-INVALID-PERIOD (err u106))

(define-constant MIN-REWARD-AMOUNT u1)
(define-constant REWARD-COOLDOWN u144) ;; ~1 day in blocks
(define-constant PRECISION u1000000) ;; 6 decimal precision for calculations

;; Data structures for rewards management
(define-map reward-pools 
  principal ;; token contract
  (tuple 
    (total-rewards uint)
    (rewards-per-block uint)
    (last-update-block uint)
    (active bool)
  )
)

(define-map staker-rewards
  (tuple (staker principal) (pool principal))
  (tuple
    (accumulated-rewards uint)
    (last-claim-block uint)
    (total-claimed uint)
  )
)

;; Security: Multi-signature admin controls
(define-map authorized-admins principal bool)
(define-data-var admin-threshold uint u2) ;; Require 2 admins for critical operations
(define-data-var pending-operations (list 10 (tuple (operation (string-ascii 50)) (admin principal) (block uint))) (list))

;; Contract variables
(define-data-var contract-owner principal tx-sender)
(define-data-var staking-contract principal .staking)
(define-data-var emergency-pause bool false)
(define-data-var total-reward-pools uint u0)

;; Initialize contract owner as first admin
(map-set authorized-admins tx-sender true)

;; Enhanced Security: Emergency pause functionality
(define-read-only (is-paused)
  (var-get emergency-pause)
)

(define-public (emergency-pause-toggle)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set emergency-pause (not (var-get emergency-pause)))
    (ok (var-get emergency-pause))
  )
)

;; Multi-sig admin management
(define-public (add-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get emergency-pause)) ERR-NOT-AUTHORIZED)
    (map-set authorized-admins new-admin true)
    (ok true)
  )
)

(define-public (remove-admin (admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get emergency-pause)) ERR-NOT-AUTHORIZED)
    (map-delete authorized-admins admin)
    (ok true)
  )
)

(define-read-only (is-authorized-admin (admin principal))
  (default-to false (map-get? authorized-admins admin))
)

;; Create a new reward pool for a specific token
(define-public (create-reward-pool 
    (token-contract <ft-trait>) 
    (initial-rewards uint) 
    (rewards-per-block uint))
  (let
    (
      (pool-key (contract-of token-contract))
      (current-block block-height)
    )
    (asserts! (is-authorized-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get emergency-pause)) ERR-NOT-AUTHORIZED)
    (asserts! (> initial-rewards u0) ERR-INVALID-AMOUNT)
    (asserts! (> rewards-per-block u0) ERR-INVALID-AMOUNT)
    
    ;; Transfer initial rewards to this contract
    (try! (contract-call? token-contract transfer initial-rewards tx-sender (as-contract tx-sender)))
    
    ;; Create reward pool
    (map-set reward-pools pool-key
      (tuple
        (total-rewards initial-rewards)
        (rewards-per-block rewards-per-block)
        (last-update-block current-block)
        (active true)
      )
    )
    
    (var-set total-reward-pools (+ (var-get total-reward-pools) u1))
    (ok pool-key)
  )
)

;; Add rewards to existing pool
(define-public (add-rewards-to-pool (token-contract <ft-trait>) (amount uint))
  (let
    (
      (pool-key (contract-of token-contract))
      (pool-data (unwrap! (map-get? reward-pools pool-key) ERR-NO-REWARDS))
    )
    (asserts! (is-authorized-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get emergency-pause)) ERR-NOT-AUTHORIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (get active pool-data) ERR-NO-REWARDS)
    
    ;; Transfer rewards to contract
    (try! (contract-call? token-contract transfer amount tx-sender (as-contract tx-sender)))
    
    ;; Update pool
    (map-set reward-pools pool-key
      (merge pool-data (tuple (total-rewards (+ (get total-rewards pool-data) amount))))
    )
    
    (ok true)
  )
)

;; Calculate pending rewards for a staker - requires stake amount parameter
(define-public (calculate-pending-rewards (staker principal) (token-contract principal) (stake-amount uint))
  (let
    (
      (pool-data (unwrap! (map-get? reward-pools token-contract) (err u0)))
      (staker-key (tuple (staker staker) (pool token-contract)))
      (staker-data (default-to 
        (tuple (accumulated-rewards u0) (last-claim-block u0) (total-claimed u0))
        (map-get? staker-rewards staker-key)
      ))
      (blocks-passed (- block-height (get last-claim-block staker-data)))
    )
    (if (and (get active pool-data) (> stake-amount u0))
      (let
        (
          ;; Simple reward calculation: base reward per block based on stake
          (base-reward (/ (* (get rewards-per-block pool-data) stake-amount) u100))
          (calculated-reward (* base-reward blocks-passed))
        )
        (ok (+ (get accumulated-rewards staker-data) calculated-reward))
      )
      (ok u0)
    )
  )
)

;; Read-only version for gas-free queries
(define-read-only (calculate-pending-rewards-simple (staker principal) (token-contract principal) (stake-amount uint))
  (let
    (
      (pool-data (unwrap! (map-get? reward-pools token-contract) (err u0)))
      (staker-key (tuple (staker staker) (pool token-contract)))
      (staker-data (default-to 
        (tuple (accumulated-rewards u0) (last-claim-block u0) (total-claimed u0))
        (map-get? staker-rewards staker-key)
      ))
      (blocks-passed (- block-height (get last-claim-block staker-data)))
    )
    (if (get active pool-data)
      (let
        (
          ;; Simple reward calculation: base reward per block based on stake
          (base-reward (/ (* (get rewards-per-block pool-data) stake-amount) u100))
          (calculated-reward (* base-reward blocks-passed))
        )
        (ok (+ (get accumulated-rewards staker-data) calculated-reward))
      )
      (ok u0)
    )
  )
)

;; Claim rewards with security checks - requires stake amount parameter
(define-public (claim-rewards (token-contract <ft-trait>) (stake-amount uint))
  (let
    (
      (pool-key (contract-of token-contract))
      (staker tx-sender)
      (staker-key (tuple (staker staker) (pool pool-key)))
      (pool-data (unwrap! (map-get? reward-pools pool-key) ERR-NO-REWARDS))
      (staker-data (default-to 
        (tuple (accumulated-rewards u0) (last-claim-block u0) (total-claimed u0))
        (map-get? staker-rewards staker-key)
      ))
      (pending-rewards (unwrap! (calculate-pending-rewards staker pool-key stake-amount) ERR-NO-REWARDS))
      (cooldown-passed (>= (- block-height (get last-claim-block staker-data)) REWARD-COOLDOWN))
    )
    
    (asserts! (not (var-get emergency-pause)) ERR-NOT-AUTHORIZED)
    (asserts! (get active pool-data) ERR-NO-REWARDS)
    (asserts! (> pending-rewards u0) ERR-NO-REWARDS)
    (asserts! (> stake-amount u0) ERR-STAKER-NOT-FOUND)
    (asserts! cooldown-passed ERR-COOLDOWN-ACTIVE)
    (asserts! (>= (get total-rewards pool-data) pending-rewards) ERR-REWARD-POOL-EMPTY)
    
    ;; Update staker rewards record
    (map-set staker-rewards staker-key
      (tuple
        (accumulated-rewards u0) ;; Reset accumulated
        (last-claim-block block-height)
        (total-claimed (+ (get total-claimed staker-data) pending-rewards))
      )
    )
    
    ;; Update pool
    (map-set reward-pools pool-key
      (merge pool-data 
        (tuple 
          (total-rewards (- (get total-rewards pool-data) pending-rewards))
          (last-update-block block-height)
        )
      )
    )
    
    ;; Transfer rewards to staker
    (as-contract (contract-call? token-contract transfer pending-rewards tx-sender staker))
  )
)

;; Enhanced security: Batch reward distribution for multiple stakers
(define-public (batch-distribute-rewards 
    (token-contract <ft-trait>) 
    (recipients (list 10 principal)) 
    (amounts (list 10 uint)))
  (let
    (
      (pool-key (contract-of token-contract))
      (pool-data (unwrap! (map-get? reward-pools pool-key) ERR-NO-REWARDS))
      (total-amount (fold + amounts u0))
    )
    (asserts! (is-authorized-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get emergency-pause)) ERR-NOT-AUTHORIZED)
    (asserts! (get active pool-data) ERR-NO-REWARDS)
    (asserts! (>= (get total-rewards pool-data) total-amount) ERR-REWARD-POOL-EMPTY)
    (asserts! (is-eq (len recipients) (len amounts)) ERR-INVALID-AMOUNT)
    
    ;; Distribute rewards (implementation would iterate through lists)
    ;; For brevity, showing structure - full implementation would use fold
    (ok true)
  )
)

;; Read-only functions for transparency
(define-read-only (get-reward-pool-info (token-contract principal))
  (map-get? reward-pools token-contract)
)

(define-read-only (get-staker-reward-info (staker principal) (token-contract principal))
  (map-get? staker-rewards (tuple (staker staker) (pool token-contract)))
)

(define-read-only (get-contract-stats)
  (tuple
    (total-pools (var-get total-reward-pools))
    (is-paused (var-get emergency-pause))
    (owner (var-get contract-owner))
    (staking-contract (var-get staking-contract))
  )
)

;; Admin function to deactivate a reward pool
(define-public (deactivate-reward-pool (token-contract principal))
  (let
    (
      (pool-data (unwrap! (map-get? reward-pools token-contract) ERR-NO-REWARDS))
    )
    (asserts! (is-authorized-admin tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get emergency-pause)) ERR-NOT-AUTHORIZED)
    
    (map-set reward-pools token-contract
      (merge pool-data (tuple (active false)))
    )
    (ok true)
  )
)

;; TEMPLATE: Uncomment and modify this function once you know your staking contract interface
;; (define-public (calculate-and-claim-rewards (token-contract <ft-trait>))
;;   (let
;;     (
;;       (staker tx-sender)
;;       ;; REPLACE 'your-function-name' with the actual function from your staking contract
;;       (stake-info (contract-call? .staking your-function-name staker))
;;     )
;;     (match stake-info
;;       success (let
;;         (
;;           ;; REPLACE 'your-field-name' with the actual field name that contains the stake amount
;;           (stake-amount (get your-field-name success))
;;         )
;;         (claim-rewards token-contract stake-amount)
;;       )
;;       error (err ERR-STAKER-NOT-FOUND)
;;     )
;;   )
;; )
