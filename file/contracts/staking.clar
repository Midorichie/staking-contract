;; staking.clar - Phase 2

;; Store stakers mapping: principal to tuple { amount, unlock, withdrawn }
(define-map stakers principal (tuple (amount uint) (unlock uint) (withdrawn bool)))

;; Constants
(define-constant MIN-STAKE u1)

;; Stake tokens with a lock period
(define-public (stake (amount uint) (lock-period uint))
  (begin
    (asserts! (> amount MIN-STAKE) (err "Amount must be greater than 0"))
    (let ((unlock (+ block-height lock-period)))
      (map-insert stakers tx-sender { amount: amount, unlock: unlock, withdrawn: false })
      (ok { staker: tx-sender, amount: amount, unlock: unlock })
    )
  )
)

;; Withdraw staked tokens + reward or penalty
(define-public (withdraw)
  (let ((stake-data (map-get? stakers tx-sender)))
    (match stake-data st
      (begin
        (asserts! (not (get withdrawn st)) (err "Already withdrawn"))
        (let ((unlock (get unlock st))
              (amount (get amount st)))
          (if (>= block-height unlock)
              ;; Reward path
              (let ((reward (/ amount u10)))
                (map-set stakers tx-sender { amount: amount, unlock: unlock, withdrawn: true })
                (ok { amount: (+ amount reward), staker: tx-sender, withdrawn: u1 })
              )
              ;; Penalty path
              (let ((penalty (/ amount u20)))
                (map-set stakers tx-sender { amount: amount, unlock: unlock, withdrawn: true })
                (ok { amount: (- amount penalty), staker: tx-sender, withdrawn: u1 })
              )
          )
        )
      )
      (err "No stake found")
    )
  )
)

;; Read-only function to check staker info
(define-read-only (get-staker (who principal))
  (map-get? stakers who)
)
