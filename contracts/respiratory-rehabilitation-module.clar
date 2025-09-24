
;; title: respiratory-rehabilitation-module
;; version: 1.0.0
;; summary: Medical-grade respiratory rehabilitation smart contract for clarinet therapy
;; description: Manages patient treatment protocols, breathing patterns, and therapeutic progress tracking

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_PATIENT_NOT_FOUND (err u101))
(define-constant ERR_INVALID_SESSION (err u102))
(define-constant ERR_TREATMENT_COMPLETED (err u103))
(define-constant ERR_INVALID_PARAMETERS (err u104))
(define-constant ERR_SESSION_IN_PROGRESS (err u105))

;; therapy levels and intensity ranges
(define-constant MIN_THERAPY_LEVEL u1)
(define-constant MAX_THERAPY_LEVEL u10)
(define-constant MIN_PRESSURE_RESISTANCE u10)
(define-constant MAX_PRESSURE_RESISTANCE u100)
(define-constant MIN_FREQUENCY u20)
(define-constant MAX_FREQUENCY u2000)

;; data vars
(define-data-var next-patient-id uint u1)
(define-data-var next-session-id uint u1)
(define-data-var contract-active bool true)
(define-data-var total-patients uint u0)
(define-data-var total-sessions uint u0)

;; data maps
;; Patient registration and profile management
(define-map patients
  { patient-id: uint }
  {
    wallet-address: principal,
    healthcare-provider: principal,
    condition-type: (string-ascii 50),
    severity-level: uint,
    registration-date: uint,
    treatment-active: bool,
    total-sessions: uint,
    last-session-date: uint
  }
)

;; Treatment protocols for different conditions
(define-map treatment-protocols
  { patient-id: uint }
  {
    breathing-pattern: (string-ascii 30),
    pressure-resistance: uint,
    frequency-range: { min: uint, max: uint },
    session-duration: uint,
    sessions-per-week: uint,
    protocol-start-date: uint,
    protocol-end-date: uint,
    adjustments-allowed: bool
  }
)

;; Individual therapy sessions
(define-map therapy-sessions
  { session-id: uint }
  {
    patient-id: uint,
    session-date: uint,
    duration-minutes: uint,
    breathing-efficiency: uint,
    pressure-achieved: uint,
    frequency-used: uint,
    session-rating: uint,
    notes: (string-ascii 200),
    completed: bool,
    healthcare-provider: principal
  }
)

;; Progress tracking for each patient
(define-map patient-progress
  { patient-id: uint }
  {
    initial-capacity: uint,
    current-capacity: uint,
    improvement-percentage: uint,
    last-updated: uint,
    milestones-achieved: uint,
    next-assessment-date: uint
  }
)

;; Healthcare provider authorizations
(define-map authorized-providers
  { provider-address: principal }
  {
    provider-name: (string-ascii 100),
    license-number: (string-ascii 50),
    specialization: (string-ascii 50),
    authorized-date: uint,
    active: bool
  }
)

;; public functions

;; Register a new patient in the system
(define-public (register-patient (patient-wallet principal) (condition (string-ascii 50)) (severity uint))
  (let
    (
      (patient-id (var-get next-patient-id))
      (current-time u1)
    )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (is-authorized-provider tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (and (>= severity u1) (<= severity u10)) ERR_INVALID_PARAMETERS)
    
    ;; Create patient record
    (map-set patients
      { patient-id: patient-id }
      {
        wallet-address: patient-wallet,
        healthcare-provider: tx-sender,
        condition-type: condition,
        severity-level: severity,
        registration-date: current-time,
        treatment-active: true,
        total-sessions: u0,
        last-session-date: u0
      }
    )
    
    ;; Initialize patient progress tracking
    (map-set patient-progress
      { patient-id: patient-id }
      {
        initial-capacity: u0,
        current-capacity: u0,
        improvement-percentage: u0,
        last-updated: current-time,
        milestones-achieved: u0,
        next-assessment-date: (+ current-time u604800) ;; 7 days
      }
    )
    
    (var-set next-patient-id (+ patient-id u1))
    (var-set total-patients (+ (var-get total-patients) u1))
    
    (ok patient-id)
  )
)

;; Create personalized treatment protocol
(define-public (create-treatment-protocol
    (patient-id uint)
    (breathing-pattern (string-ascii 30))
    (pressure-resistance uint)
    (freq-min uint)
    (freq-max uint)
    (duration uint)
    (sessions-weekly uint)
    (protocol-duration uint)
  )
  (let
    (
      (current-time u1)
      (patient-data (unwrap! (map-get? patients { patient-id: patient-id }) ERR_PATIENT_NOT_FOUND))
    )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get healthcare-provider patient-data) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (and (>= pressure-resistance MIN_PRESSURE_RESISTANCE) (<= pressure-resistance MAX_PRESSURE_RESISTANCE)) ERR_INVALID_PARAMETERS)
    (asserts! (and (>= freq-min MIN_FREQUENCY) (<= freq-max MAX_FREQUENCY) (< freq-min freq-max)) ERR_INVALID_PARAMETERS)
    (asserts! (and (> duration u0) (<= duration u120)) ERR_INVALID_PARAMETERS) ;; max 120 minutes
    (asserts! (and (> sessions-weekly u0) (<= sessions-weekly u14)) ERR_INVALID_PARAMETERS)
    
    (map-set treatment-protocols
      { patient-id: patient-id }
      {
        breathing-pattern: breathing-pattern,
        pressure-resistance: pressure-resistance,
        frequency-range: { min: freq-min, max: freq-max },
        session-duration: duration,
        sessions-per-week: sessions-weekly,
        protocol-start-date: current-time,
        protocol-end-date: (+ current-time (* protocol-duration u86400)), ;; duration in days
        adjustments-allowed: true
      }
    )
    
    (ok true)
  )
)

;; Start a new therapy session
(define-public (start-therapy-session (patient-id uint) (notes (string-ascii 200)))
  (let
    (
      (session-id (var-get next-session-id))
      (current-time u1)
      (patient-data (unwrap! (map-get? patients { patient-id: patient-id }) ERR_PATIENT_NOT_FOUND))
      (protocol-data (unwrap! (map-get? treatment-protocols { patient-id: patient-id }) ERR_PATIENT_NOT_FOUND))
    )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get healthcare-provider patient-data) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (get treatment-active patient-data) ERR_TREATMENT_COMPLETED)
    
    (map-set therapy-sessions
      { session-id: session-id }
      {
        patient-id: patient-id,
        session-date: current-time,
        duration-minutes: u0,
        breathing-efficiency: u0,
        pressure-achieved: u0,
        frequency-used: u0,
        session-rating: u0,
        notes: notes,
        completed: false,
        healthcare-provider: tx-sender
      }
    )
    
    (var-set next-session-id (+ session-id u1))
    (var-set total-sessions (+ (var-get total-sessions) u1))
    
    (ok session-id)
  )
)

;; Complete therapy session with results
(define-public (complete-therapy-session
    (session-id uint)
    (duration uint)
    (breathing-efficiency uint)
    (pressure-achieved uint)
    (frequency uint)
    (rating uint)
  )
  (let
    (
      (session-data (unwrap! (map-get? therapy-sessions { session-id: session-id }) ERR_INVALID_SESSION))
      (patient-id (get patient-id session-data))
      (patient-data (unwrap! (map-get? patients { patient-id: patient-id }) ERR_PATIENT_NOT_FOUND))
      (current-time u1)
    )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get healthcare-provider session-data) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (not (get completed session-data)) ERR_TREATMENT_COMPLETED)
    (asserts! (and (> duration u0) (<= duration u120)) ERR_INVALID_PARAMETERS)
    (asserts! (and (>= breathing-efficiency u0) (<= breathing-efficiency u100)) ERR_INVALID_PARAMETERS)
    (asserts! (and (>= rating u1) (<= rating u10)) ERR_INVALID_PARAMETERS)
    
    ;; Update session with completion data
    (map-set therapy-sessions
      { session-id: session-id }
      {
        patient-id: patient-id,
        session-date: (get session-date session-data),
        duration-minutes: duration,
        breathing-efficiency: breathing-efficiency,
        pressure-achieved: pressure-achieved,
        frequency-used: frequency,
        session-rating: rating,
        notes: (get notes session-data),
        completed: true,
        healthcare-provider: tx-sender
      }
    )
    
    ;; Update patient's session count and last session date
    (map-set patients
      { patient-id: patient-id }
      (merge
        patient-data
        {
          total-sessions: (+ (get total-sessions patient-data) u1),
          last-session-date: current-time
        }
      )
    )
    
    ;; Update progress tracking
    (try! (update-patient-progress patient-id breathing-efficiency))
    
    (ok true)
  )
)

;; Update patient progress metrics
(define-private (update-patient-progress (patient-id uint) (current-efficiency uint))
  (let
    (
      (progress-data (unwrap! (map-get? patient-progress { patient-id: patient-id }) ERR_PATIENT_NOT_FOUND))
      (current-time u1)
      (initial-cap (get initial-capacity progress-data))
      (new-current-cap (if (is-eq initial-cap u0) current-efficiency (if (> current-efficiency (get current-capacity progress-data)) current-efficiency (get current-capacity progress-data))))
      (new-initial-cap (if (is-eq initial-cap u0) current-efficiency initial-cap))
    )
    
    (map-set patient-progress
      { patient-id: patient-id }
      {
        initial-capacity: new-initial-cap,
        current-capacity: new-current-cap,
        improvement-percentage: (if (> new-initial-cap u0) (/ (* (- new-current-cap new-initial-cap) u100) new-initial-cap) u0),
        last-updated: current-time,
        milestones-achieved: (+ (get milestones-achieved progress-data) (if (>= new-current-cap (+ new-initial-cap u20)) u1 u0)),
        next-assessment-date: (+ current-time u604800) ;; 7 days
      }
    )
    
    (ok true)
  )
)

;; Authorize healthcare provider
(define-public (authorize-provider (provider principal) (name (string-ascii 100)) (license (string-ascii 50)) (specialization (string-ascii 50)))
  (let
    (
      (current-time u1)
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    (map-set authorized-providers
      { provider-address: provider }
      {
        provider-name: name,
        license-number: license,
        specialization: specialization,
        authorized-date: current-time,
        active: true
      }
    )
    
    (ok true)
  )
)

;; read only functions

;; Check if address is authorized provider
(define-read-only (is-authorized-provider (provider principal))
  (default-to false (get active (map-get? authorized-providers { provider-address: provider })))
)

;; Get patient information
(define-read-only (get-patient-info (patient-id uint))
  (map-get? patients { patient-id: patient-id })
)

;; Get treatment protocol
(define-read-only (get-treatment-protocol (patient-id uint))
  (map-get? treatment-protocols { patient-id: patient-id })
)

;; Get therapy session details
(define-read-only (get-session-details (session-id uint))
  (map-get? therapy-sessions { session-id: session-id })
)

;; Get patient progress
(define-read-only (get-patient-progress (patient-id uint))
  (map-get? patient-progress { patient-id: patient-id })
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-patients: (var-get total-patients),
    total-sessions: (var-get total-sessions),
    contract-active: (var-get contract-active),
    next-patient-id: (var-get next-patient-id),
    next-session-id: (var-get next-session-id)
  }
)

