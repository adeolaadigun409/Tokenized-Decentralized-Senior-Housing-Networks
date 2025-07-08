;; Medical Coordination Contract
;; Manages healthcare provider integration

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_NOT_FOUND (err u501))
(define-constant ERR_INVALID_INPUT (err u502))
(define-constant ERR_APPOINTMENT_CONFLICT (err u503))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u504))

;; Data Variables
(define-data-var next-provider-id uint u1)
(define-data-var next-appointment-id uint u1)
(define-data-var next-record-id uint u1)

;; Data Maps
(define-map healthcare-providers
  { provider-id: uint }
  {
    name: (string-ascii 200),
    specialty: (string-ascii 100),
    license-number: (string-ascii 50),
    contact-info: (string-ascii 300),
    hourly-rate: uint,
    availability-hours: (string-ascii 200),
    rating: uint,
    total-appointments: uint,
    verified: bool,
    status: (string-ascii 20)
  }
)

(define-map appointments
  { appointment-id: uint }
  {
    provider-id: uint,
    patient-principal: principal,
    patient-name: (string-ascii 100),
    appointment-date: uint,
    appointment-time: uint,
    duration: uint,
    appointment-type: (string-ascii 50),
    cost: uint,
    payment-status: (string-ascii 20),
    completion-status: (string-ascii 20),
    notes: (string-ascii 1000)
  }
)

(define-map medical-records
  { record-id: uint }
  {
    patient-principal: principal,
    provider-id: uint,
    appointment-id: uint,
    record-type: (string-ascii 50),
    diagnosis: (string-ascii 500),
    treatment: (string-ascii 500),
    medications: (string-ascii 500),
    follow-up-required: bool,
    record-date: uint,
    access-level: (string-ascii 20)
  }
)

(define-map patient-providers
  { patient-principal: principal, provider-id: uint }
  {
    relationship-start: uint,
    last-appointment: uint,
    total-visits: uint,
    status: (string-ascii 20)
  }
)

(define-map authorized-access
  { record-id: uint, accessor: principal }
  {
    access-granted: bool,
    granted-by: principal,
    granted-date: uint,
    access-level: (string-ascii 20)
  }
)

;; Provider Management Functions
(define-public (register-provider
  (name (string-ascii 200))
  (specialty (string-ascii 100))
  (license-number (string-ascii 50))
  (contact-info (string-ascii 300))
  (hourly-rate uint)
  (availability-hours (string-ascii 200))
)
  (let
    (
      (provider-id (var-get next-provider-id))
    )
    (asserts! (and (> (len name) u0) (> (len license-number) u0)) ERR_INVALID_INPUT)
    (asserts! (> hourly-rate u0) ERR_INVALID_INPUT)

    (map-set healthcare-providers
      { provider-id: provider-id }
      {
        name: name,
        specialty: specialty,
        license-number: license-number,
        contact-info: contact-info,
        hourly-rate: hourly-rate,
        availability-hours: availability-hours,
        rating: u0,
        total-appointments: u0,
        verified: false,
        status: "pending"
      }
    )

    (var-set next-provider-id (+ provider-id u1))
    (ok provider-id)
  )
)

(define-public (verify-provider (provider-id uint))
  (let
    (
      (provider (unwrap! (map-get? healthcare-providers { provider-id: provider-id }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (ok (map-set healthcare-providers
      { provider-id: provider-id }
      (merge provider {
        verified: true,
        status: "active"
      })
    ))
  )
)

;; Appointment Functions
(define-public (schedule-appointment
  (provider-id uint)
  (patient-name (string-ascii 100))
  (appointment-date uint)
  (appointment-time uint)
  (duration uint)
  (appointment-type (string-ascii 50))
)
  (let
    (
      (provider (unwrap! (map-get? healthcare-providers { provider-id: provider-id }) ERR_NOT_FOUND))
      (appointment-id (var-get next-appointment-id))
      (cost (* (get hourly-rate provider) duration))
    )
    (asserts! (get verified provider) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status provider) "active") ERR_INVALID_INPUT)
    (asserts! (and (> duration u0) (> (len patient-name) u0)) ERR_INVALID_INPUT)

    ;; Create appointment
    (map-set appointments
      { appointment-id: appointment-id }
      {
        provider-id: provider-id,
        patient-principal: tx-sender,
        patient-name: patient-name,
        appointment-date: appointment-date,
        appointment-time: appointment-time,
        duration: duration,
        appointment-type: appointment-type,
        cost: cost,
        payment-status: "pending",
        completion-status: "scheduled",
        notes: ""
      }
    )

    ;; Update provider stats
    (map-set healthcare-providers
      { provider-id: provider-id }
      (merge provider {
        total-appointments: (+ (get total-appointments provider) u1)
      })
    )

    ;; Update patient-provider relationship
    (let
      (
        (existing-relationship (map-get? patient-providers { patient-principal: tx-sender, provider-id: provider-id }))
      )
      (if (is-some existing-relationship)
        (map-set patient-providers
          { patient-principal: tx-sender, provider-id: provider-id }
          (merge (unwrap-panic existing-relationship) {
            last-appointment: appointment-date,
            total-visits: (+ (get total-visits (unwrap-panic existing-relationship)) u1)
          })
        )
        (map-set patient-providers
          { patient-principal: tx-sender, provider-id: provider-id }
          {
            relationship-start: block-height,
            last-appointment: appointment-date,
            total-visits: u1,
            status: "active"
          }
        )
      )
    )

    (var-set next-appointment-id (+ appointment-id u1))
    (ok appointment-id)
  )
)

(define-public (pay-appointment (appointment-id uint))
  (let
    (
      (appointment (unwrap! (map-get? appointments { appointment-id: appointment-id }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get patient-principal appointment)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get payment-status appointment) "pending") ERR_INVALID_INPUT)

    ;; Transfer payment
    (try! (stx-transfer? (get cost appointment) tx-sender (as-contract tx-sender)))

    (ok (map-set appointments
      { appointment-id: appointment-id }
      (merge appointment { payment-status: "paid" })
    ))
  )
)

(define-public (complete-appointment (appointment-id uint) (notes (string-ascii 1000)))
  (let
    (
      (appointment (unwrap! (map-get? appointments { appointment-id: appointment-id }) ERR_NOT_FOUND))
      (provider (unwrap! (map-get? healthcare-providers { provider-id: (get provider-id appointment) }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED) ;; In real implementation, this would be the provider
    (asserts! (is-eq (get payment-status appointment) "paid") ERR_INVALID_INPUT)

    (ok (map-set appointments
      { appointment-id: appointment-id }
      (merge appointment {
        completion-status: "completed",
        notes: notes
      })
    ))
  )
)

;; Medical Records Functions
(define-public (create-medical-record
  (provider-id uint)
  (appointment-id uint)
  (record-type (string-ascii 50))
  (diagnosis (string-ascii 500))
  (treatment (string-ascii 500))
  (medications (string-ascii 500))
  (follow-up-required bool)
)
  (let
    (
      (record-id (var-get next-record-id))
      (appointment (unwrap! (map-get? appointments { appointment-id: appointment-id }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED) ;; In real implementation, this would be the provider
    (asserts! (is-eq (get completion-status appointment) "completed") ERR_INVALID_INPUT)

    (map-set medical-records
      { record-id: record-id }
      {
        patient-principal: (get patient-principal appointment),
        provider-id: provider-id,
        appointment-id: appointment-id,
        record-type: record-type,
        diagnosis: diagnosis,
        treatment: treatment,
        medications: medications,
        follow-up-required: follow-up-required,
        record-date: block-height,
        access-level: "private"
      }
    )

    (var-set next-record-id (+ record-id u1))
    (ok record-id)
  )
)

(define-public (grant-record-access (record-id uint) (accessor principal) (access-level (string-ascii 20)))
  (let
    (
      (record (unwrap! (map-get? medical-records { record-id: record-id }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get patient-principal record)) ERR_UNAUTHORIZED)

    (ok (map-set authorized-access
      { record-id: record-id, accessor: accessor }
      {
        access-granted: true,
        granted-by: tx-sender,
        granted-date: block-height,
        access-level: access-level
      }
    ))
  )
)

;; Read-only Functions
(define-read-only (get-provider (provider-id uint))
  (map-get? healthcare-providers { provider-id: provider-id })
)

(define-read-only (get-appointment (appointment-id uint))
  (map-get? appointments { appointment-id: appointment-id })
)

(define-read-only (get-medical-record (record-id uint))
  (map-get? medical-records { record-id: record-id })
)

(define-read-only (get-patient-provider-relationship (patient-principal principal) (provider-id uint))
  (map-get? patient-providers { patient-principal: patient-principal, provider-id: provider-id })
)

(define-read-only (check-record-access (record-id uint) (accessor principal))
  (map-get? authorized-access { record-id: record-id, accessor: accessor })
)

(define-read-only (get-provider-availability (provider-id uint))
  (match (map-get? healthcare-providers { provider-id: provider-id })
    provider (some (get availability-hours provider))
    none
  )
)
