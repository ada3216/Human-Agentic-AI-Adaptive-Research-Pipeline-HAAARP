# DPIA Checklist — Data Protection Impact Assessment

**Complete this document before running the pipeline with `sensitivity: special_category` data.**

This checklist must be completed, signed off by a Data Protection Officer (or ethical supervisor acting in that capacity), and saved as `artifacts/dpia_signed.json` before any data ingestion can proceed.

---

## About this requirement

Under GDPR Article 9, processing special category data (health data, therapy transcripts, data revealing mental health information) requires a completed DPIA. This pipeline enforces this requirement in code — the pipeline will not ingest data until `artifacts/dpia_signed.json` exists with `dpia_complete: true` and `decision: approved`.

For a master's dissertation: your university ethics committee sign-off typically satisfies this requirement. Check with your supervisor and/or institutional DPO.

## Lawful basis for processing

- **GDPR Article 6 basis:** [Select and justify the primary lawful basis for the study]
- **GDPR Article 9 basis:** [Select and justify the special category condition, including explicit consent where used]
- **Why this basis applies:** [Short explanation tied to the study design and institution]
- **Recorded in study config:** [Confirm the lawful basis is reflected consistently in ethics paperwork and local study documentation]

---

## Checklist

### 1. Description of processing

- **Purpose of data collection:** [Describe your research question and why data collection is necessary]
- **Type of data:** [e.g., audio recordings of psychotherapy sessions, interview transcripts]
- **Sensitivity classification:** `special_category` — health/therapy data (GDPR Art. 9)
- **Number of participants:** [n]
- **Data subjects:** [e.g., psychotherapy clients, research participants]

### 2. Necessity and proportionality

- [ ] The research question cannot be adequately answered without this data
- [ ] The minimum necessary amount of data is collected
- [ ] Data will be pseudonymised before AI processing (via `ingest_and_deid.py`)

### 3. Local processing confirmation

- [ ] All AI processing uses a local model only (no data sent to external APIs)
- [ ] No participant data will be stored in cloud services
- [ ] Transcription uses WhisperX locally — no cloud transcription services

### 4. Participant safeguards

- [ ] Written informed consent obtained from all participants
- [ ] Participants informed of AI use in data analysis
- [ ] Right to withdraw explained and documented
- [ ] Consent documentation stored separately from analysis data
- [ ] See `artifacts/consent_snippets.md` for approved consent language

### 5. Security measures

- [ ] Data stored on encrypted device/volume
- [ ] Access limited to named researchers only
- [ ] Data destruction plan documented

### 5a. Risk matrix

| Risk | Likelihood | Impact | Mitigation | Residual risk |
|---|---|---|---|---|
| Re-identification from transcripts | [Low/Med/High] | [Low/Med/High] | [Describe de-identification and quote review controls] | [Low/Med/High] |
| Unauthorised device or file access | [Low/Med/High] | [Low/Med/High] | [Describe encryption, passwords, and role-based access] | [Low/Med/High] |
| Accidental data egress to external services | [Low/Med/High] | [Low/Med/High] | [Describe local-only processing and no external API use] | [Low/Med/High] |
| Retention beyond approved schedule | [Low/Med/High] | [Low/Med/High] | [Describe deletion schedule and ownership] | [Low/Med/High] |

### 5b. Mitigations

1. **Local processing only** — all AI and transcription processing remains on the researcher's approved local machine.
2. **De-identification before analysis** — direct identifiers are removed or replaced before any analytic processing.
3. **Access control** — only named researchers or approved supervisors may access governed files.
4. **Destruction plan** — raw and derived data are retained only for the approved period, then securely deleted.
5. **Audit trail** — the pipeline records governed artifacts and review checkpoints to support later verification.

### 5c. Config linkage

- `config/*.yaml` study settings should mark whether DPIA completion is required for the dataset sensitivity classification.
- `dpia_complete` in `artifacts/dpia_signed.json` is the machine-readable gate status used by the pipeline.
- `dpia_document_path` in study configuration should point to this checklist or the signed DPIA record so supervisors can verify the source document.
- Keep this checklist and `artifacts/dpia_signed.json` aligned; inconsistencies should be treated as a governance failure and resolved before ingestion.

### 6. Researcher sign-off

- **Researcher name and role:** [Name, role/student number]
- **Date checklist completed:** [YYYY-MM-DD]
- **ORCID (if available):** [https://orcid.org/...]

### 7. DPO / Supervisor sign-off

To be completed by Data Protection Officer or ethics supervisor:

- **Name:** [Name]
- **Role:** [DPO / Ethics committee / Supervisor acting as ethics lead]
- **Institution:** [Institution name]
- **Decision:** [ ] Approved  [ ] Requires revision  [ ] Rejected
- **Conditions (if any):** [Any conditions attached to approval]
- **Date:** [YYYY-MM-DD]
- **Signature:** *(wet or digital signature; reference number may substitute)*

---

## After completion

Once this checklist is signed off:

1. Create `artifacts/dpia_signed.json` using `examples/dpia_signed.json` as your template
2. Fill in all required fields: `dpo_sign_off.dpo_name`, `signature_date`, `decision: "approved"`, `dpia_complete: true`
3. Keep this checklist stored alongside your ethics documentation
4. The pipeline will automatically detect `dpia_signed.json` and allow processing to proceed

**Do not create a fake `dpia_signed.json` to bypass this gate. Doing so may constitute a GDPR lawful processing violation for special category health data.**
