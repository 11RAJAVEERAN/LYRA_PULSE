# Stage 3F — Product Decision Register

## Purpose and authority

This register records approved recovery-protocol policy and separates it from
technical values that still require review. Product-policy approval is not
technical-contract approval and is not authorization to implement.

The A–E defaults and D-14 execution sequence below are approved by the product
owner at policy/project-plan level. Exact technical values explicitly marked
**PROPOSED / PENDING REVIEW** are not approved.

## Status summary

- **A–E policy defaults:** APPROVED
- **D-01 through D-11, D-13:** Approved policy; listed technical details remain
  open where stated below.
- **D-12:** BLOCKED pending separately approved disposable-hardware validation.
- **D-14 execution sequence:** APPROVED; each implementation stage still needs
  its own explicit implementation authorization.
- **Implementation:** NOT AUTHORIZED
- **Terminal rejection:** DISABLED
- **Phase 5:** IN PROGRESS — NOT COMPLETE
- **Phase 6:** MUST NOT START until Phase 5 is complete and explicitly approved.

## D-01 — Canonical Event Identity and Digest

**Status: APPROVED — product policy and technical serialization FINALIZED**

1. Normalize valid event timestamps to UTC and serialize with fixed
   microsecond precision.
2. Use canonical lowercase, hyphenated UUID representation.
3. Compute a versioned SHA-256 digest using the authenticated device ID,
   canonical event UUID, integer fingerprint slot, and canonical UTC timestamp.
4. Equivalent timezone representations of the same instant produce the same
   canonical timestamp and digest.
5. Once digest version 1 is implemented, its canonicalization rules are
   immutable. Any future change requires a new digest version.
6. Digest version is separate from the HTTP contract version.

### Finalized digest v1 serialization

**Status: FINALIZED / APPROVED — technical serialization**

Encode the fields as tagged, length-prefixed binary, in this order:

1. Device ID — tag `0x01`
2. Event UUID — tag `0x02`
3. Fingerprint slot — tag `0x03`
4. Timestamp — tag `0x04`

Each field is encoded as its one-byte tag, a two-byte unsigned big-endian
length counting bytes, then the field value. The bytes hashed by SHA-256 begin
with ASCII `LYRA-FP-EVENT` followed by NUL, then the one-byte digest version
`0x01`, then the four tagged fields in the order above. Both the domain prefix
and version byte are included in the hash input.

- **Device ID:** Exact authenticated device identity, case-sensitive, encoded
  as 1–100 ASCII bytes. Reject non-ASCII values.
- **Event UUID:** Accept parseable UUID input, canonicalize to lowercase
  hyphenated form, then encode as the standard 16-byte network-order UUID.
- **Fingerprint slot:** Valid range 0–999; encode as an unsigned 32-bit
  big-endian integer. Its field length is four bytes.
- **Timestamp:** Require timezone-aware input. Accept valid timezone offsets,
  including `+00:00`; normalize the instant to UTC and encode as
  `YYYY-MM-DDTHH:MM:SS.ffffffZ`. Reject naive timestamps and precision beyond
  six fractional digits; never silently truncate.
- **Versioning:** Digest v1 serialization is immutable. Any future
  serialization change requires a new digest version. Digest version is not
  the HTTP contract version.

## D-02 — Payload Allowlist and Request Size

**Status: APPROVED — product policy, including A default**

1. Accept exactly `device_id`, `event_id`, `fingerprint_slot`, and `occurred_at`.
2. Enforce a maximum request body size of **4 KiB** before normal payload
   processing.
3. Reject unknown/additional fields and oversized requests.
4. Never silently ignore fields or truncate a payload.
5. Do not retain raw rejected request bodies by default; store only minimum
   approved receipt metadata.

Field-level limits, rejected-payload retention exceptions, and receipt schema
details remain **PROPOSED / PENDING REVIEW**.

## D-03 — Durable Deterministic Rejection Receipts

**Status: APPROVED — product policy, including A default**

1. Only explicitly allowlisted deterministic rejections from authenticated
   devices with parseable event UUIDs may receive durable rejection receipts.
2. Authentication failures, unkeyable UUIDs, transient failures, and
   unexpected server errors must never receive such receipts.
3. A receipt must not create, modify, or settle an attendance record.
4. Receipt persistence must be idempotent.
5. Missing or unparseable event UUIDs cannot receive keyed receipts and remain
   blocked on the device.

The eligible rejection-code list, exact receipt schema/retention, and
transaction/savepoint and concurrency mechanics remain **PROPOSED / PENDING
REVIEW**.

## D-04 — Stable Error Contract

**Status: APPROVED — additive policy**

Preserve the existing response envelope fields `success`, `message`, and
`errors`. Add stable machine-readable metadata additively, with proposed fields
`code`, `scope`, `retryable`, `event_id`, `payload_digest`, and
`receipt_recorded`. Existing clients must remain compatible. Firmware must be
able to distinguish deterministic rejection, authentication failure,
transient server failure, and unknown disposition.

The complete error-code catalog, HTTP status mapping, allowed `scope` and
`retryable` semantics, `receipt_recorded` conditions, malformed/missing UUID
behavior, and contract-versioning policy remain **PROPOSED / PENDING REVIEW**.

## D-05 — Legacy Receipt Handling

**Status: APPROVED — product policy, including B default**

1. Never guess or reconstruct historical payload digests.
2. Legacy records without trustworthy original digests remain ambiguous and
   blocked; use `LEGACY_RECEIPT_AMBIGUOUS` for this ambiguity concept.
3. Never automatically retry, accept, or resolve ambiguous legacy events.
4. Require explicit reconciliation before further action and preserve
   historical attendance and event records.

Legacy detection criteria, reconciliation evidence and roles, API/status
semantics, and retry eligibility after reconciliation remain **PROPOSED /
PENDING REVIEW**.

## D-06 — Employee Mapping Changes

**Status: APPROVED — product policy, including B default**

1. Never automatically retry against a changed slot-to-employee mapping using
   only the current mapping.
2. Require explicit reconciliation using authoritative identity evidence.
3. Preserve the original event ID and payload throughout reconciliation and
   retry.
4. If the original employee identity cannot be established, keep the event
   blocked. Do not create attendance for an unverified employee.
5. Where eligible, terminal rejection may only follow D-08 and its hardware
   restrictions.

Accepted evidence sources, mapping-snapshot design, reconciliation roles/API
semantics, and interaction with D-07/D-08 remain **PROPOSED / PENDING REVIEW**.

## D-07 — Retry Authorization

**Status: APPROVED — Option B**

1. Super Admin may authorize retry within permitted organization/branch scope.
2. Explicitly authorized Branch Admin or Device Recovery Admin may authorize
   retry only within assigned and permitted branch scope.
3. Backend APIs enforce permissions and scope; React controls are not a
   security boundary.
4. Retry does not require dual approval.
5. Bind retry to the exact device ID, event ID, digest version, digest, and
   unique operation ID.
6. Preserve the original event ID and payload unchanged. Polling and
   acknowledgment are idempotent.
7. If fingerprint mapping or employee identity changed, require reconciliation;
   never automatically retry against a new employee.
8. Deny unauthorized users and users outside permitted scope.

Exact permission names/grants and role-to-scope implementation remain
**PROPOSED / PENDING REVIEW**.

## D-08 — Terminal Rejection

**Status: APPROVED — policy; capability DISABLED**

1. An authorized operator may request terminal rejection for a specific
   blocked event; a different, independently authorized operator must approve.
2. No self-approval. Audit both decisions with actor, timestamp, event ID,
   device ID, digest, operation ID, and reason.
3. Terminal rejection must not create or modify attendance.
4. Backend authorization alone must never remove a device queue event.
5. The device must persist a durable tombstone for the exact event ID, digest,
   and operation ID, then receive successful backend acknowledgment for that
   exact disposition. Only then may it advance FIFO.
6. Terminal rejection remains disabled until disposable ESP32 storage
   validation passes and separate approval is obtained.

## D-09 — Recovery Operation Expiry

**Status: APPROVED — product policy, including C default**

1. Recovery authorizations expire and must never be executed or reused after
   expiry; a new authorization is required.
2. Preserve exact device ID, event ID, digest version/digest, and operation ID
   binding. Polling and acknowledgment remain idempotent.
3. Expiry must not remove or skip the blocked queue event.

Operation lifetime, trusted clock and skew handling, in-flight expiry,
polling cadence/backoff, cleanup, and expired-operation API semantics remain
**PROPOSED / PENDING REVIEW**.

## D-10 — Recovery Roles and Tenant/Branch Scope

**Status: APPROVED — product policy, including C default**

1. Super Admin acts only within permitted organization and branch scope.
2. Branch Admin acts only within assigned branch scope.
3. Device Recovery Admin acts only within explicitly granted branch scope.
4. All other roles are denied.
5. Every relevant backend request validates role, permission, organization,
   branch, and device ownership. React UI visibility is not security
   enforcement.
6. Retry remains subject to D-07 exact event/digest/operation binding;
   terminal rejection always requires D-08 independent dual approval.
7. Permission revocation takes effect at the next backend authorization check.

Exact permission grants/codenames, scope-resolution mapping, role
representation, and active-session behavior remain **PROPOSED / PENDING REVIEW**.

## D-11 — Audit Trail and Retention

**Status: APPROVED — product policy, including D default**

1. Recovery actions produce an append-only audit trail recording actor,
   timestamp, role, organization/branch, device ID, event ID, digest
   version/digest, operation ID, and reason where applicable.
2. Audit authorization, approval, rejection, expiry, reconciliation, and
   acknowledgment.
3. Normal application workflows cannot edit or delete audit entries.
4. Never store tokens, passwords, or other secrets in audit records.
5. Preserve audit records until an approved retention policy permits archival
   or deletion.

Retention duration, archival/deletion procedure, exact schema, and
database-level immutability/tamper-evidence mechanism remain **PROPOSED /
PENDING REVIEW**.

## D-12 — ESP32 Storage Validation

**Status: BLOCKED**

Validation requires a separately identified disposable ESP32 and explicit
approval. `LYRA-DEVICE-001` is the live attendance device and must never be
used for destructive storage validation. Host-side tests using temporary
storage are not proof of physical flash durability, power-loss safety, or
tombstone persistence.

Terminal rejection remains **DISABLED** until D-12 validation passes and
separate approval is obtained.

## D-13 — Database Migration and Rollback Safety

**Status: APPROVED — product policy, including D default**

1. Use forward-only, data-safe migrations; prefer additive and nullable schema
   changes.
2. Preserve historical attendance, enrollment, payroll, fingerprint mapping,
   and device-event records.
3. Never guess or backfill legacy payload digests.
4. Require a verified backup and tested restore to a separate disposable
   database before deployment migration.
5. Never perform destructive reverse migrations that could discard recovery
   data. Plan roll-forward recovery for partially applied migrations.

Backup verification procedure, migration sequence, compatibility window,
rollback-versus-roll-forward operations, and partial-failure recovery remain
**PROPOSED / PENDING REVIEW**.

## A–E — Approved Safe Defaults

**Status: APPROVED — policy-level defaults; not implementation authorization**

### A. Ingestion and rejection contract

The D-02/D-03 rules above are approved: 4 KiB maximum, exact four-field
allowlist, reject unknown/oversized payloads, no silent ignore or truncation,
no raw rejected-body retention by default, minimal approved receipt metadata,
explicit deterministic-rejection allowlist, no receipts for authentication,
unkeyable, transient, or unexpected failures, no attendance effect from
rejections, and idempotent receipt persistence.

Exact rejection codes, field-level limits, receipt schema details, and
transaction/savepoint mechanics remain technical proposals requiring review.

### B. Legacy and identity reconciliation

The D-05/D-06 rules above are approved: no guessed historical digest; ambiguous
legacy events remain blocked under `LEGACY_RECEIPT_AMBIGUOUS`; no automatic
retry against legacy ambiguity or a changed mapping; require authoritative
identity evidence and explicit reconciliation; preserve original ID/payload;
keep unresolved identity blocked.

Detection criteria, evidence sources, mapping snapshots, roles, and API
semantics remain technical proposals requiring review.

### C. Recovery authorization and expiry

The D-07/D-09/D-10 rules above are approved: appropriately authorized, scoped
operators only; backend-enforced checks on each relevant request; exact
device/event/digest/version/operation binding; idempotent polling and
acknowledgment; expiring, non-reusable operations; expiry never skips/removes
the FIFO event; new authorization after expiry; revocation at the next backend
check.

Permission names/grants, lifetime, clock/skew, in-flight behavior, cadence,
backoff, and cleanup remain technical proposals requiring review.

### D. Audit and migration safety

The D-11/D-13 rules above are approved: append-only audit; required actor and
recovery context; no secrets; retain until approved retention permits archival
or deletion; forward-only, data-safe migrations; additive/nullable changes
where possible; preserve history; verified backup and separate-database
restore; roll-forward plan; no destructive reverse migration that loses
recovery data.

Retention, tamper evidence, backup procedure, migration order, compatibility,
and partial-failure details remain technical proposals requiring review.

### E. Execution sequence and approval gates

The D-14 sequence below is approved. Every implementation stage still requires
its own explicit implementation authorization. Approval of this sequence does
not authorize step 2 or any later implementation.

## Exact Technical Values — PROPOSED / PENDING REVIEW

No values in this section are approved by this register unless already
explicitly specified in D-01, D-02, or the approved policies above.

- Complete stable error-code catalog and HTTP status mapping.
- Definitions and allowed values for `scope`, `retryable`, `receipt_recorded`,
  malformed/unparseable event IDs, and contract versioning.
- Receipt-eligible rejection-code allowlist.
- Receipt schema, field-level limits, retention, and transaction/savepoint and
  concurrency strategy.
- Exact legacy-detection criteria; reconciliation evidence, roles, and API
  semantics.
- Mapping snapshot design and validation strategy.
- Permission codenames, role grants, Device Recovery Admin representation,
  tenant/branch resolution, and session behavior.
- Recovery operation lifetime, trusted clock source, skew tolerance,
  in-flight-expiry behavior, polling cadence, backoff, and cleanup.
- Audit schema details, retention duration, archival/deletion, and
  tamper-protection mechanism.
- Backup/restore procedure, migration sequencing, compatibility window, and
  partial-failure/roll-forward procedure.

Technical proposals require review before implementation. They must not be
silently treated as approved product decisions.

## D-14 — Approved Execution Sequence

**Status: APPROVED — project execution plan; implementation NOT AUTHORIZED**

1. Finalize the technical contract and document evidence-based proposed values.
2. Backend canonicalization, validation, error contract, durable receipts, and
   legacy/mapping protections.
3. Backend recovery authorization, polling, expiry, acknowledgment, and audit.
4. Isolated database migration and backup/restore verification.
5. Backend security, concurrency, replay, rejection, and regression tests.
6. Firmware host-side queue recovery tests using disposable temporary storage.
7. Keep terminal rejection disabled until D-12 hardware validation passes and
   separate approval is obtained.
8. Implement React and firmware against the frozen backend contract, with
   separately approved validation targets.
9. Complete disposable integration verification and final Phase 5 audit.
10. Obtain explicit Phase 5 completion approval and separate live deployment
    approval.

Every implementation stage requires its own explicit authorization.
**Phase 6 cannot begin until Phase 5 is completed and explicitly approved.**

## Implementation and hardware boundary

- **Implementation authorization:** NOT GRANTED.
- **Terminal rejection:** DISABLED.
- **D-12:** BLOCKED.
- **Live device:** `LYRA-DEVICE-001`; do not use it for destructive storage
  validation.
- **Host-side tests:** useful for queue logic, but not physical durability
  proof.
- **Phase 5:** IN PROGRESS — NOT COMPLETE.
- **Phase 6:** MUST NOT START before explicit Phase 5 approval.
