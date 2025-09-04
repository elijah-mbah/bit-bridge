;; BitBridge Protocol - Enhanced Security Version
;;
;; A sophisticated Bitcoin-anchored payment channel system that enables instant,
;; trustless micropayments with enterprise-grade security. Built on Stacks blockchain
;; to leverage Bitcoin's uncompromising security model while providing Layer 2
;; scalability for high-frequency transactions.
;;
;; Security Enhancements:
;; - Added counterparty validation to prevent unauthorized access
;; - Improved input sanitization and boundary checks
;; - Enhanced signature verification placeholders
;; - Added additional safety checks for fund transfers

;; CONSTANTS & ERROR CODES

(define-constant CONTRACT-OWNER tx-sender)
(define-constant DISPUTE-PERIOD u1008) ;; ~1 week in Stacks blocks
(define-constant MAX-CHANNEL-VALUE u1000000000000) ;; 1M STX maximum
(define-constant MIN-CHANNEL-VALUE u1000) ;; 0.001 STX minimum

;; Error constants with descriptive naming
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-CHANNEL-EXISTS (err u101))
(define-constant ERR-CHANNEL-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-INVALID-SIGNATURE (err u104))
(define-constant ERR-CHANNEL-CLOSED (err u105))
(define-constant ERR-DISPUTE-ACTIVE (err u106))
(define-constant ERR-INVALID-PARAMETERS (err u107))
(define-constant ERR-BALANCE-MISMATCH (err u108))
(define-constant ERR-INVALID-COUNTERPARTY (err u109))
(define-constant ERR-VALUE-TOO-HIGH (err u110))
(define-constant ERR-VALUE-TOO-LOW (err u111))

;; DATA STRUCTURES

;; Primary channel state mapping
(define-map payment-channels
  {
    channel-id: (buff 32),
    participant-a: principal,
    participant-b: principal,
  }
  {
    total-deposited: uint,
    balance-a: uint,
    balance-b: uint,
    is-active: bool,
    dispute-deadline: uint,
    sequence-number: uint,
    created-at: uint,
  }
)

;; Track authorized counterparties for each user
(define-map authorized-counterparties
  {
    user: principal,
    counterparty: principal,
  }
  {
    authorized: bool,
    authorized-at: uint,
  }
)

;; INPUT VALIDATION UTILITIES

(define-private (validate-channel-id (channel-id (buff 32)))
  (and
    (> (len channel-id) u0)
    (<= (len channel-id) u32)
  )
)

(define-private (validate-amount (amount uint))
  (and
    (>= amount MIN-CHANNEL-VALUE)
    (<= amount MAX-CHANNEL-VALUE)
  )
)

(define-private (validate-signature (signature (buff 65)))
  (is-eq (len signature) u65)
)

(define-private (validate-balance-distribution
    (balance-a uint)
    (balance-b uint)
    (total uint)
  )
  (is-eq total (+ balance-a balance-b))
)

;; Enhanced counterparty validation
(define-private (validate-counterparty (counterparty principal))
  (and
    (not (is-eq tx-sender counterparty))
    (is-standard counterparty)
  )
)