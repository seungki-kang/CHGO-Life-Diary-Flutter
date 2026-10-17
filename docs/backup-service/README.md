# Life Diary backup and coach sharing — design requirements

Status: **REQUIREMENTS** — no implementation exists  
Decisions: LD-D1 (b) and LD-D5 in ADR-LD01, 2026-10-17

## Owner requirement

> Users must be certain that no one can see their diary unless they personally allow it.

This is a technical requirement, not a policy statement. It is met only if nobody other than the user can decrypt diary content without the user's action. That includes the backup server, Life Diary operators, church staff, coaches without a grant, and CHGO Platform.

## 1. Backup (LD-D1 = b)

1. **End-to-end encryption.**
   - Entries are encrypted on the device before upload.
   - The keys are generated and held only on the user's devices.
   - The server stores ciphertext and the minimum metadata needed to sync.
2. **No server-side readable copy.** No key escrow, no operator recovery key, and no "admin view". A design that lets operators decrypt does not meet the requirement.
3. **Recovery is user-held.**
   - Restoring on a new device uses a recovery key or passphrase that only the user keeps.
   - If it is lost, the backup cannot be recovered. The app must explain this before backup is enabled.
4. **Opt-in.** The app works fully offline without backup, as it does today.
5. **Minimal metadata.** Sync metadata must not reveal content. That includes question answers, old-person categories, and fruits. Timestamps are coarsened where sync allows.
6. **Deletion.**
   - Deleting an entry deletes its ciphertext from the server.
   - Deleting the account deletes everything.
   - Retention follows PDV-006, which must be revised for this design.

## 2. Coach sharing (LD-D5)

1. **Explicit grant per share.** The user chooses each of the following:
   - which coach
   - what to share: a whole entry, specific questions, or a summary
   - for what purpose
   - until when
2. **Encrypted to the coach.** Shared content is re-encrypted on the user's device for that coach's key. The server still cannot read it.
3. **Revocable at any time.**
   - Revocation stops future access immediately.
   - The app must say plainly that revocation cannot erase what a coach has already read.
4. **Visible to the user.** The user can see every active grant and an access log of when shared items were opened.
5. **Separate from analytics.** Shared content never reaches CHGO Platform or its engine. Coaching notes written by the coach are a separate, coach-owned record.
6. **Legal.**
   - Showing diary content to a coach is a provision of likely-sensitive information to a third party (PIPA Art. 17, Art. 23).
   - Each grant needs separate, informed consent.
   - Counsel must review before release.

## 3. Dependencies

- **Coach identity.** Coaches need a verified identity and a public key. This depends on the user and community identity design (LD-D4).
- **Earlier designs as inputs.** `platform-era/` holds the earlier CHGO Personal Data Vault design (PDV-002 to PDV-005, PDV-007). It was written for a Platform-hosted vault and is built on server-side decryption:
  - **Server-held keys.** Envelope encryption protects the data, with the key-encryption keys held in a server KMS/HSM (PDV-005, Storage Architecture).
  - **Server-side decryption.** Content is decrypted on the server after an authorization decision (PDV-004, PDV-007).
  - **Operator access.** A governed break-glass procedure allows exceptional operator access (PDV-002, Storage Architecture).
  
  All three conflict with Section 1. Reuse the threat analysis, lifecycle, deletion, and export material, and replace the key model with device-held keys.
- **Earlier API design.** The Vault and coach-sharing endpoints in the consolidated OpenAPI v2 of `JesusLife-Church-OS` (formerly CHGO-Platform) belong to this service. They are removed from Church OS in its next API baseline (ADR-LD01, Section 4.4). The PDV-008 Vault test pack was removed from Church OS on 2026-10-17 and is available at commit `b64dd9a` there.
