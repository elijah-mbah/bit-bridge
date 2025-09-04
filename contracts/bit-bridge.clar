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

;; Check if counterparty is authorized for this transaction
(define-private (is-authorized-counterparty (counterparty principal))
  (match (map-get? authorized-counterparties {
    user: tx-sender,
    counterparty: counterparty,
  })
    entry
    (get authorized entry)
    true ;; If no explicit authorization map exists, allow (backward compatibility)
  )
)

;; SECURITY UTILITIES

;; Authorize a counterparty for future transactions
(define-public (authorize-counterparty (counterparty principal))
  (begin
    (asserts! (validate-counterparty counterparty) ERR-INVALID-COUNTERPARTY)

    (map-set authorized-counterparties {
      user: tx-sender,
      counterparty: counterparty,
    } {
      authorized: true,
      authorized-at: stacks-block-height,
    })

    (ok true)
  )
)

;; Revoke counterparty authorization
(define-public (revoke-counterparty (counterparty principal))
  (begin
    (map-delete authorized-counterparties {
      user: tx-sender,
      counterparty: counterparty,
    })
    (ok true)
  )
)

;; CRYPTOGRAPHIC UTILITIES

(define-private (serialize-uint (value uint))
  (unwrap-panic (to-consensus-buff? value))
)

(define-private (create-channel-message
    (channel-id (buff 32))
    (balance-a uint)
    (balance-b uint)
  )
  (concat (concat channel-id (serialize-uint balance-a))
    (serialize-uint balance-b)
  )
)

;; Enhanced signature verification with additional checks
(define-private (verify-channel-signature
    (message (buff 256))
    (signature (buff 65))
    (expected-signer principal)
  )
  (and
    (validate-signature signature)
    (validate-counterparty expected-signer)
    ;; TODO: Implement proper ECDSA verification
    ;; This is a placeholder - in production, use proper cryptographic verification
    (is-eq tx-sender expected-signer)
  )
)

;; CHANNEL MANAGEMENT FUNCTIONS

;; Creates a bidirectional payment channel between two parties
(define-public (establish-channel
    (channel-id (buff 32))
    (counterparty principal)
    (initial-deposit uint)
  )
  (begin
    ;; Enhanced input validation
    (asserts! (validate-channel-id channel-id) ERR-INVALID-PARAMETERS)
    (asserts! (validate-amount initial-deposit) ERR-INVALID-PARAMETERS)
    (asserts! (validate-counterparty counterparty) ERR-INVALID-COUNTERPARTY)
    (asserts! (is-authorized-counterparty counterparty) ERR-UNAUTHORIZED)

    ;; Ensure channel doesn't already exist (check both directions)
    (asserts!
      (and
        (is-none (map-get? payment-channels {
          channel-id: channel-id,
          participant-a: tx-sender,
          participant-b: counterparty,
        }))
        (is-none (map-get? payment-channels {
          channel-id: channel-id,
          participant-a: counterparty,
          participant-b: tx-sender,
        }))
      )
      ERR-CHANNEL-EXISTS
    )

    ;; Verify sender has sufficient balance
    (asserts! (>= (stx-get-balance tx-sender) initial-deposit)
      ERR-INSUFFICIENT-FUNDS
    )

    ;; Lock initial funds in contract
    (try! (stx-transfer? initial-deposit tx-sender (as-contract tx-sender)))

    ;; Initialize channel state
    (map-set payment-channels {
      channel-id: channel-id,
      participant-a: tx-sender,
      participant-b: counterparty,
    } {
      total-deposited: initial-deposit,
      balance-a: initial-deposit,
      balance-b: u0,
      is-active: true,
      dispute-deadline: u0,
      sequence-number: u0,
      created-at: stacks-block-height,
    })

    (ok channel-id)
  )
)

;; Adds liquidity to an existing channel
(define-public (deposit-funds
    (channel-id (buff 32))
    (counterparty principal)
    (deposit-amount uint)
  )
  (let (
      (channel-key {
        channel-id: channel-id,
        participant-a: tx-sender,
        participant-b: counterparty,
      })
      (channel (unwrap! (map-get? payment-channels channel-key) ERR-CHANNEL-NOT-FOUND))
    )
    ;; Enhanced validation checks
    (asserts! (validate-channel-id channel-id) ERR-INVALID-PARAMETERS)
    (asserts! (validate-amount deposit-amount) ERR-INVALID-PARAMETERS)
    (asserts! (validate-counterparty counterparty) ERR-INVALID-COUNTERPARTY)
    (asserts! (is-authorized-counterparty counterparty) ERR-UNAUTHORIZED)
    (asserts! (get is-active channel) ERR-CHANNEL-CLOSED)
    (asserts! (>= (stx-get-balance tx-sender) deposit-amount)
      ERR-INSUFFICIENT-FUNDS
    )

    ;; Check for overflow protection
    (asserts!
      (<= (+ (get total-deposited channel) deposit-amount) MAX-CHANNEL-VALUE)
      ERR-VALUE-TOO-HIGH
    )

    ;; Transfer additional funds to contract
    (try! (stx-transfer? deposit-amount tx-sender (as-contract tx-sender)))

    ;; Update channel state with new funds
    (map-set payment-channels channel-key
      (merge channel {
        total-deposited: (+ (get total-deposited channel) deposit-amount),
        balance-a: (+ (get balance-a channel) deposit-amount),
      })
    )

    (ok deposit-amount)
  )
)

;; CHANNEL CLOSURE MECHANISMS

;; Cooperative channel closure with dual signatures
(define-public (close-channel-cooperatively
    (channel-id (buff 32))
    (counterparty principal)
    (final-balance-a uint)
    (final-balance-b uint)
    (signature-a (buff 65))
    (signature-b (buff 65))
  )
  (let (
      (channel-key {
        channel-id: channel-id,
        participant-a: tx-sender,
        participant-b: counterparty,
      })
      (channel (unwrap! (map-get? payment-channels channel-key) ERR-CHANNEL-NOT-FOUND))
      (total-funds (get total-deposited channel))
      (settlement-message (create-channel-message channel-id final-balance-a final-balance-b))
    )
    ;; Comprehensive validation with enhanced security
    (asserts! (validate-channel-id channel-id) ERR-INVALID-PARAMETERS)
    (asserts! (validate-signature signature-a) ERR-INVALID-PARAMETERS)
    (asserts! (validate-signature signature-b) ERR-INVALID-PARAMETERS)
    (asserts! (validate-counterparty counterparty) ERR-INVALID-COUNTERPARTY)
    (asserts! (is-authorized-counterparty counterparty) ERR-UNAUTHORIZED)
    (asserts! (get is-active channel) ERR-CHANNEL-CLOSED)
    (asserts!
      (validate-balance-distribution final-balance-a final-balance-b total-funds)
      ERR-BALANCE-MISMATCH
    )