# Consent Language Templates

Adapt these consent snippets for your participant information sheet and informed consent form. All edits must be approved by your ethics supervisor before use.

These templates are written for UK-based psychotherapy research. Adjust legal references for other jurisdictions.

---

## Variant A — Personal non-sensitive data

Use this variant when `sensitivity: personal_non_sensitive` and the study does not process special category therapy or health data.

### A1. Participant information sheet — AI analysis section

*(Insert this section into your participant information sheet where you describe how data will be used.)*

> **Use of AI in data analysis**
>
> This research uses an artificial intelligence (AI) system to assist with the analysis of your [interview/session recording]. The AI system runs locally on the researcher's computer — your data is never sent to external servers or third-party AI services such as OpenAI or Google.
>
> The AI assists the researcher by identifying themes, patterns, and linguistic features in the data. All AI-generated findings are reviewed by the researcher before any conclusions are drawn. No finding goes into the research without a human researcher verifying it against the original data.
>
> Your data will be de-identified before any AI processing. Your name, identifying details, and any information that could identify you will be replaced with a code before the AI processes your data. The link between your identity and your participant code is stored separately from your data and is not accessible to the AI.

---

## A2. Informed consent form — AI analysis item

*(Add this item to your consent form checklist.)*

> [ ] I understand that an AI system will assist with the analysis of my data. I understand that:
> - My data will be de-identified before AI processing
> - The AI processes data locally on the researcher's computer only — my data will not be sent to external AI services
> - All AI-generated outputs will be reviewed by the human researcher before use in the research
> - This does not change my right to withdraw my data at any time

---

## A3. Withdrawal from research — language

*(Use or adapt this section when explaining the right to withdraw.)*

> You have the right to withdraw your participation from this research at any time without giving a reason. If you withdraw after your data has been included in AI analysis, we will delete your data from the analysis files. However, if the findings have already been written into the research report, it may not be possible to remove your individual contribution at that stage. Please contact [researcher contact details] if you wish to withdraw.

---

## A4. Audio/video recording consent

*(If you are recording therapy sessions, use this additional item.)*

> [ ] I consent to [my sessions / my interviews] being recorded for research purposes. I understand that recordings will be transcribed and the transcripts will be analysed. Recordings will be stored securely and deleted after transcription, unless I indicate below that I consent to the recordings being retained for the study duration.
>
> [ ] I consent to my recordings being retained until [end date] for verification purposes
> [ ] I consent to my recordings being deleted after transcription

---

## Variant B — Special category data (GDPR Art. 9 / BPS)

Use this variant when the study processes therapy, health, or other `special_category` data. Keep wording aligned with your approved DPIA and institutional ethics documents.

### B1. Data category + sensitivity statement

> **Special category data notice**
>
> This study involves psychotherapy or related health information. Your interview, session, or transcript data is treated as special category personal data under GDPR Article 9 and is handled under enhanced governance safeguards.

### B2. Purpose and local-only processing statement

> **Purpose and local-only processing**
>
> The purpose of this study is to examine psychotherapy experience, process, or meaning-making in a structured research setting. AI-assisted analysis is limited to local-only processing on the researcher's approved computer. Your data will not be sent to external APIs, cloud AI services, or other forms of data egress outside the approved governance pathway.

### B3. Explicit consent language for Article 9 data

> [ ] I explicitly consent to the use of my therapy-related or health-related data for this research study.
> 
> [ ] I understand that this research involves special category personal data under GDPR Article 9.
> 
> [ ] I understand that de-identified data may be analysed by a local-only AI system under researcher supervision, with no external API processing.

### B4. DPIA / governance notice

> A Data Protection Impact Assessment (DPIA) has been completed for this study before analysis began. The study follows local-only processing, de-identification, access control, audit trail recording, and supervisor or DPO sign-off requirements.

### B5. Withdrawal / retention / contact wording

> You may withdraw your participation without giving a reason. If you withdraw before analysis outputs are finalised, we will remove your data from the active research set where feasible. Retention and secure deletion will follow the approved ethics and DPIA schedule for this higher-sensitivity study. Contact [researcher contact details] or [supervisor/DPO contact details] with any withdrawal, retention, or data protection questions.

---

## Notes for researchers

1. **Ethics approval required** — these are templates only. Your version must be approved by your university ethics committee before use.
2. **Special category data** — if you are processing health or therapy data, GDPR Article 9 requires explicit consent for AI-assisted processing. The templates above address this, but verify with your institutional DPO.
3. **Keep signed consent forms** — store separately from research data; do not include in this repository.
4. **DPIA reference** — reference the DPIA (`artifacts/dpia_checklist.md`) in your ethics application to demonstrate pre-registration of data processing activities.
