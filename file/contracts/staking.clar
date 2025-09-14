;; -----------------------------------------------------
;; Staking Contract (Clarity)
;; Author: Hammed Yakub
;; Description: Simple staking contract where users can
;; lock tokens for a period and earn rewards.
;; -----------------------------------------------------

;; ------------------------------
;; DATA VARIABLES & CONSTANTS
;; ------------------------------

(define-data-var total-staked uint u0)

(define-map stakes
  { user: principal }
  { amount: uint, unlock-height: uint })

(define-data-var reward-rate uint u10) ;; Default 10%

;; Contract owner (replace with deployer address from Clarinet.toml if different)
(define-constant contract-owner 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; ------------------------------
;; STAKE FUNCTION
;; ------------------------------
(define-public (stake (amount uint) (lock-period uint))
  (begin
    (asserts! (> amount u0) (err u100))          ;; must stake > 0
    (asserts! (> lock-period u0) (err u101))     ;; lock period must be > 0
    (let
      (
        (caller tx-sender)
        (unlock (+ block-height lock-period))
      )
      ;; record the stake
      (map-set stakes { user: caller }
        { amount: amount, unlock-height: unlock })
      (var-set total-staked (+ (var-get total-staked) amount))
      (ok { staker: caller, staked: amount, unlocks-at: unlock })
    )
  )
)

;; ------------------------------
;; UNSTAKE FUNCTION
;; ------------------------------
(define-public (unstake)
  (let
    (
      (caller tx-sender)
      (stake-opt (map-get? stakes { user: caller }))
    )
    (match stake-opt stake-data
      (begin
        (asserts! (>= block-height (get unlock-height stake-data)) (err u102))
        (let
          (
            (amount (get amount stake-data))
            (reward (/ (* amount (var-get reward-rate)) u100)) ;; simple percentage
            (total (+ amount reward))
          )
          ;; remove the stake
          (map-delete stakes { user: caller })
          (var-set total-staked (- (var-get total-staked) amount))
          ;; return staked + reward (in a real version: transfer tokens)
          (ok { staker: caller, withdrawn: total })
        )
      )
      (err u103) ;; no stake found
    )
  )
)

;; ------------------------------
;; ADMIN FUNCTION
;; ------------------------------
(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err u104)) ;; only owner
    (var-set reward-rate new-rate)
    (ok { updated-rate: new-rate })
  )
)
