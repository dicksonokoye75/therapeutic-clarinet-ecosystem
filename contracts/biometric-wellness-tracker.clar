
;; title: biometric-wellness-tracker
;; version: 1.0.0
;; summary: Advanced biometric monitoring and wellness tracking for clarinet therapy sessions
;; description: Tracks patient vitals, stress hormones, brain activity, and generates therapeutic efficacy reports

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u200))
(define-constant ERR_PATIENT_NOT_FOUND (err u201))
(define-constant ERR_INVALID_BIOMETRIC_DATA (err u202))
(define-constant ERR_SESSION_NOT_FOUND (err u203))
(define-constant ERR_DUPLICATE_READING (err u204))
(define-constant ERR_INVALID_VITAL_RANGE (err u205))
(define-constant ERR_DEVICE_NOT_AUTHORIZED (err u206))

;; vital sign normal ranges
(define-constant MIN_HEART_RATE u40)
(define-constant MAX_HEART_RATE u200)
(define-constant MIN_BLOOD_PRESSURE u70)
(define-constant MAX_BLOOD_PRESSURE u180)
(define-constant MIN_OXYGEN_SATURATION u80)
(define-constant MAX_OXYGEN_SATURATION u100)
(define-constant MIN_STRESS_LEVEL u0)
(define-constant MAX_STRESS_LEVEL u100)

;; brain wave frequency bands (Hz)
(define-constant DELTA_MIN u1)
(define-constant DELTA_MAX u4)
(define-constant THETA_MIN u4)
(define-constant THETA_MAX u8)
(define-constant ALPHA_MIN u8)
(define-constant ALPHA_MAX u13)
(define-constant BETA_MIN u13)
(define-constant BETA_MAX u30)

;; data vars
(define-data-var next-reading-id uint u1)
(define-data-var next-report-id uint u1)
(define-data-var total-biometric-readings uint u0)
(define-data-var contract-active bool true)
(define-data-var monitoring-enabled bool true)

;; data maps
;; Real-time vital signs monitoring
(define-map biometric-readings
  { reading-id: uint }
  {
    patient-id: uint,
    session-id: uint,
    timestamp: uint,
    heart-rate: uint,
    blood-pressure-systolic: uint,
    blood-pressure-diastolic: uint,
    oxygen-saturation: uint,
    respiratory-rate: uint,
    body-temperature: uint, ;; in celsius * 10 (e.g., 370 = 37.0C)
    stress-level: uint,
    device-id: (string-ascii 50),
    healthcare-provider: principal
  }
)

;; Advanced brain activity monitoring
(define-map brain-activity-data
  { reading-id: uint }
  {
    patient-id: uint,
    session-id: uint,
    timestamp: uint,
    delta-waves: uint, ;; 1-4 Hz - deep sleep, healing
    theta-waves: uint, ;; 4-8 Hz - meditation, creativity
    alpha-waves: uint, ;; 8-13 Hz - relaxation, calmness
    beta-waves: uint,  ;; 13-30 Hz - alertness, concentration
    gamma-waves: uint, ;; 30-100 Hz - cognitive processing
    attention-level: uint,
    meditation-depth: uint,
    cognitive-load: uint,
    emotional-state: (string-ascii 20)
  }
)

;; Hormone level tracking
(define-map hormone-levels
  { reading-id: uint }
  {
    patient-id: uint,
    session-id: uint,
    timestamp: uint,
    cortisol-level: uint,    ;; stress hormone
    dopamine-level: uint,    ;; reward, motivation
    serotonin-level: uint,   ;; mood, happiness
    endorphin-level: uint,   ;; natural pain relief
    adrenaline-level: uint,  ;; fight or flight response
    oxytocin-level: uint,    ;; bonding, trust
    measurement-method: (string-ascii 30)
  }
)

;; Session wellness reports
(define-map wellness-reports
  { report-id: uint }
  {
    patient-id: uint,
    session-id: uint,
    report-date: uint,
    overall-wellness-score: uint,
    stress-reduction: uint,
    cognitive-improvement: uint,
    respiratory-efficiency: uint,
    emotional-state-improvement: uint,
    therapeutic-benefit-score: uint,
    recommendations: (string-ascii 200),
    next-session-adjustments: (string-ascii 150),
    healthcare-provider: principal
  }
)

;; Authorized monitoring devices
(define-map authorized-devices
  { device-id: (string-ascii 50) }
  {
    device-name: (string-ascii 100),
    manufacturer: (string-ascii 50),
    model: (string-ascii 50),
    calibration-date: uint,
    authorized-date: uint,
    active: bool,
    accuracy-rating: uint
  }
)

;; Patient baseline measurements
(define-map patient-baselines
  { patient-id: uint }
  {
    baseline-heart-rate: uint,
    baseline-blood-pressure: uint,
    baseline-stress-level: uint,
    baseline-oxygen-saturation: uint,
    baseline-brain-alpha: uint,
    baseline-cortisol: uint,
    established-date: uint,
    last-updated: uint
  }
)

;; public functions

;; Record comprehensive biometric readings during therapy
(define-public (record-biometric-reading
    (patient-id uint)
    (session-id uint)
    (heart-rate uint)
    (bp-systolic uint)
    (bp-diastolic uint)
    (oxygen-sat uint)
    (resp-rate uint)
    (body-temp uint)
    (stress-level uint)
    (device-id (string-ascii 50))
  )
  (let
    (
      (reading-id (var-get next-reading-id))
      (current-time u1)
    )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (var-get monitoring-enabled) ERR_NOT_AUTHORIZED)
    (asserts! (is-authorized-device device-id) ERR_DEVICE_NOT_AUTHORIZED)
    (asserts! (and (>= heart-rate MIN_HEART_RATE) (<= heart-rate MAX_HEART_RATE)) ERR_INVALID_VITAL_RANGE)
    (asserts! (and (>= bp-systolic MIN_BLOOD_PRESSURE) (<= bp-systolic MAX_BLOOD_PRESSURE)) ERR_INVALID_VITAL_RANGE)
    (asserts! (and (>= oxygen-sat MIN_OXYGEN_SATURATION) (<= oxygen-sat MAX_OXYGEN_SATURATION)) ERR_INVALID_VITAL_RANGE)
    (asserts! (and (>= stress-level MIN_STRESS_LEVEL) (<= stress-level MAX_STRESS_LEVEL)) ERR_INVALID_VITAL_RANGE)
    
    (map-set biometric-readings
      { reading-id: reading-id }
      {
        patient-id: patient-id,
        session-id: session-id,
        timestamp: current-time,
        heart-rate: heart-rate,
        blood-pressure-systolic: bp-systolic,
        blood-pressure-diastolic: bp-diastolic,
        oxygen-saturation: oxygen-sat,
        respiratory-rate: resp-rate,
        body-temperature: body-temp,
        stress-level: stress-level,
        device-id: device-id,
        healthcare-provider: tx-sender
      }
    )
    
    (var-set next-reading-id (+ reading-id u1))
    (var-set total-biometric-readings (+ (var-get total-biometric-readings) u1))
    
    (ok reading-id)
  )
)

;; Record advanced brain activity measurements
(define-public (record-brain-activity
    (patient-id uint)
    (session-id uint)
    (delta uint)
    (theta uint)
    (alpha uint)
    (beta uint)
    (gamma uint)
    (attention uint)
    (meditation uint)
    (cognitive-load uint)
    (emotional-state (string-ascii 20))
  )
  (let
    (
      (reading-id (var-get next-reading-id))
      (current-time u1)
    )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (var-get monitoring-enabled) ERR_NOT_AUTHORIZED)
    (asserts! (and (<= attention u100) (<= meditation u100) (<= cognitive-load u100)) ERR_INVALID_VITAL_RANGE)
    
    (map-set brain-activity-data
      { reading-id: reading-id }
      {
        patient-id: patient-id,
        session-id: session-id,
        timestamp: current-time,
        delta-waves: delta,
        theta-waves: theta,
        alpha-waves: alpha,
        beta-waves: beta,
        gamma-waves: gamma,
        attention-level: attention,
        meditation-depth: meditation,
        cognitive-load: cognitive-load,
        emotional-state: emotional-state
      }
    )
    
    (var-set next-reading-id (+ reading-id u1))
    
    (ok reading-id)
  )
)

;; Record hormone level measurements
(define-public (record-hormone-levels
    (patient-id uint)
    (session-id uint)
    (cortisol uint)
    (dopamine uint)
    (serotonin uint)
    (endorphin uint)
    (adrenaline uint)
    (oxytocin uint)
    (method (string-ascii 30))
  )
  (let
    (
      (reading-id (var-get next-reading-id))
      (current-time u1)
    )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (var-get monitoring-enabled) ERR_NOT_AUTHORIZED)
    
    (map-set hormone-levels
      { reading-id: reading-id }
      {
        patient-id: patient-id,
        session-id: session-id,
        timestamp: current-time,
        cortisol-level: cortisol,
        dopamine-level: dopamine,
        serotonin-level: serotonin,
        endorphin-level: endorphin,
        adrenaline-level: adrenaline,
        oxytocin-level: oxytocin,
        measurement-method: method
      }
    )
    
    (var-set next-reading-id (+ reading-id u1))
    
    (ok reading-id)
  )
)

;; Generate comprehensive wellness report
(define-public (generate-wellness-report
    (patient-id uint)
    (session-id uint)
    (wellness-score uint)
    (stress-reduction uint)
    (cognitive-improvement uint)
    (respiratory-efficiency uint)
    (emotional-improvement uint)
    (therapeutic-benefit uint)
    (recommendations (string-ascii 200))
    (adjustments (string-ascii 150))
  )
  (let
    (
      (report-id (var-get next-report-id))
      (current-time u1)
    )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (and (<= wellness-score u100) (<= stress-reduction u100) (<= cognitive-improvement u100)) ERR_INVALID_VITAL_RANGE)
    (asserts! (and (<= respiratory-efficiency u100) (<= emotional-improvement u100) (<= therapeutic-benefit u100)) ERR_INVALID_VITAL_RANGE)
    
    (map-set wellness-reports
      { report-id: report-id }
      {
        patient-id: patient-id,
        session-id: session-id,
        report-date: current-time,
        overall-wellness-score: wellness-score,
        stress-reduction: stress-reduction,
        cognitive-improvement: cognitive-improvement,
        respiratory-efficiency: respiratory-efficiency,
        emotional-state-improvement: emotional-improvement,
        therapeutic-benefit-score: therapeutic-benefit,
        recommendations: recommendations,
        next-session-adjustments: adjustments,
        healthcare-provider: tx-sender
      }
    )
    
    (var-set next-report-id (+ report-id u1))
    
    (ok report-id)
  )
)

;; Establish patient baseline measurements
(define-public (establish-patient-baseline
    (patient-id uint)
    (baseline-hr uint)
    (baseline-bp uint)
    (baseline-stress uint)
    (baseline-oxygen uint)
    (baseline-alpha uint)
    (baseline-cortisol uint)
  )
  (let
    (
      (current-time u1)
    )
    (asserts! (var-get contract-active) ERR_NOT_AUTHORIZED)
    (asserts! (and (>= baseline-hr MIN_HEART_RATE) (<= baseline-hr MAX_HEART_RATE)) ERR_INVALID_VITAL_RANGE)
    (asserts! (and (>= baseline-oxygen MIN_OXYGEN_SATURATION) (<= baseline-oxygen MAX_OXYGEN_SATURATION)) ERR_INVALID_VITAL_RANGE)
    
    (map-set patient-baselines
      { patient-id: patient-id }
      {
        baseline-heart-rate: baseline-hr,
        baseline-blood-pressure: baseline-bp,
        baseline-stress-level: baseline-stress,
        baseline-oxygen-saturation: baseline-oxygen,
        baseline-brain-alpha: baseline-alpha,
        baseline-cortisol: baseline-cortisol,
        established-date: current-time,
        last-updated: current-time
      }
    )
    
    (ok true)
  )
)

;; Authorize monitoring device
(define-public (authorize-device (device-id (string-ascii 50)) (device-name (string-ascii 100)) (manufacturer (string-ascii 50)) (model (string-ascii 50)) (accuracy uint))
  (let
    (
      (current-time u1)
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (and (>= accuracy u70) (<= accuracy u100)) ERR_INVALID_VITAL_RANGE)
    
    (map-set authorized-devices
      { device-id: device-id }
      {
        device-name: device-name,
        manufacturer: manufacturer,
        model: model,
        calibration-date: current-time,
        authorized-date: current-time,
        active: true,
        accuracy-rating: accuracy
      }
    )
    
    (ok true)
  )
)

;; read only functions

;; Check if device is authorized
(define-read-only (is-authorized-device (device-id (string-ascii 50)))
  (default-to false (get active (map-get? authorized-devices { device-id: device-id })))
)

;; Get biometric reading
(define-read-only (get-biometric-reading (reading-id uint))
  (map-get? biometric-readings { reading-id: reading-id })
)

;; Get brain activity data
(define-read-only (get-brain-activity (reading-id uint))
  (map-get? brain-activity-data { reading-id: reading-id })
)

;; Get hormone levels
(define-read-only (get-hormone-levels (reading-id uint))
  (map-get? hormone-levels { reading-id: reading-id })
)

;; Get wellness report
(define-read-only (get-wellness-report (report-id uint))
  (map-get? wellness-reports { report-id: report-id })
)

;; Get patient baseline
(define-read-only (get-patient-baseline (patient-id uint))
  (map-get? patient-baselines { patient-id: patient-id })
)

;; Get monitoring statistics
(define-read-only (get-monitoring-stats)
  {
    total-readings: (var-get total-biometric-readings),
    next-reading-id: (var-get next-reading-id),
    next-report-id: (var-get next-report-id),
    monitoring-active: (var-get monitoring-enabled),
    contract-active: (var-get contract-active)
  }
)

