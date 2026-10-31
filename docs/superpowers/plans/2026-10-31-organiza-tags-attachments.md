# Organiza tags and attachments implementation plan

> Execute natively in this session, with tests first and one independent review before opening a draft PR.

**Goal:** Implement V3 Phase 2.5 in schema 21: reusable transaction tags and private image/PDF attachments that round-trip through encrypted backups.

**Architecture:** SQLite owns normalized tags, transaction links, and attachment metadata. A dedicated file service owns validated bytes under private `attachments/`. Backup v2 gains the attachment directory/count while preserving old v2 archives. The UI offers tag assignment/management and an attachment action on transaction rows.

**Tech:** Flutter/Dart, sqlite3, existing file_picker, UUID, cryptography SHA-256, existing ZIP backup v2.

**Spec:** `docs/superpowers/specs/2026-10-31-organiza-tags-attachments-design.md`; V3 Phase 2.5 in `docs/product/ORGANIZA_MEGA_PROMPT_V3.md`.

## Review focus

1. Migration 20→21 and v1→21 preserve old rows and allowlist/integrity behavior.
2. Attachment traversal/symlink/type/extension/signature/size checks cannot write or read outside the app's private folder.
3. Backup accepts old v2 archives and validates new `attachments/` entries, hashes, counts and size caps; failed restore does not overwrite conflicting local bytes or replace the live database.
4. Soft-deleting/restoring a transaction preserves its tag links and attachments; tag deletion cascades only tag links.
5. UI never passes the original external file path into the database, and tag selection remains valid for transfer and historical transaction editing.

### Task 1: Schema 21 and relational repository

**Files:** `lib/database/app_database.dart`, `lib/data/local_repository.dart`, `lib/domain/models.dart`, migration/repository tests.

**Interfaces:** Add `Tag`, `Attachment`, schema-21 allowlist tables `tags`, `transaction_tags`, `attachments`. Repository methods load tags/links/attachments, persist tag CRUD, replace links transactionally, insert metadata, and remove metadata returning its safe relative path.

- [ ] Add failing tests for exact 20→21 columns/constraints/FKs, v1→21, old row/transaction/saldo preservation, case-insensitive tag uniqueness, cascades, and snapshot round trip.
- [ ] Add migration tables and include them in snapshot/restore/integrity validation in FK-safe insertion order.
- [ ] Implement account-independent tag and attachment metadata mapping and repository methods; do not implement file I/O in database layer.
- [ ] Run focused migration/repository tests; commit `Adicione schema 21 para tags e anexos`.

### Task 2: Tag operations and transaction rules

**Files:** `lib/application/organiza_store.dart`, `lib/domain/models.dart`, application/domain tests.

**Interfaces:** Tag CRUD plus `setTransactionTags(transactionId, Set<String> tagIds)` and `tagsForTransaction(transactionId)`. Assignment accepts active or historically soft-deleted transaction rows only when the requested transaction is loaded by explicit action; reject missing tag IDs and duplicate names cleanly.

- [ ] Add failing tests for create/rename/color/delete, normalized-name uniqueness, assignment replacement, unknown IDs and soft-delete/restore preservation.
- [ ] Implement store/repository operations with one SQL transaction for replacing link rows.
- [ ] Verify transaction update, card-payment system records and transfers preserve unrelated associations.
- [ ] Run focused unit tests; commit `Gerencie tags de lançamentos`.

### Task 3: Private attachment storage and backup v2

**Files:** add `lib/services/attachment_storage_service.dart`; modify `lib/services/app_storage_paths.dart`, `lib/services/backup_archive_service.dart`, `lib/services/backup_coordinator.dart`, `lib/application/organiza_store.dart`; add unit/service tests.

**Interfaces:** `AttachmentStorageService.pickAndStore`, `storeFile`, `fileFor`, `deleteFile`, `sha256For`; `AppStoragePaths.attachmentDirectory` and `resolveAttachment`; extend `PreparedBackup` and coordinator with optional attachment directory.

- [ ] Add failing byte/file tests for each permitted image and PDF signature, unsupported extension/signature mismatch, >10 MiB, traversal, symlink, copy/rename cleanup and stable SHA-256 metadata.
- [ ] Add failing backup tests for old manifest without attachments, new attachment count/hash/path validation, export and restore file round-trip, conflicting file preservation and rollback behavior.
- [ ] Implement private UUID file storage and strict relative path resolution; persist relative paths only.
- [ ] Extend encrypted ZIP validation/export/prepare/confirm for `attachments/`, per-file 10 MiB and existing aggregate cap; keep v2 legacy images behavior unchanged.
- [ ] Run attachment, archive, coordinator and restore tests; commit `Armazene anexos privados no backup cifrado`.

### Task 4: Tag and attachment UI

**Files:** `lib/presentation/basic_pages.dart`, `lib/presentation/dialogs.dart`, `lib/presentation/organiza_app.dart`; widget tests.

**Interfaces:** Transaction edit dialog receives available tags and selected IDs; shell saves tag changes. Add a tag-management modal. Transaction rows get an “Anexos” action; dialog accepts callbacks for list/pick/remove/open metadata and does not directly persist SQL.

- [ ] Add failing widget tests for assigning multiple tags, creating/renaming/deleting a tag, filtering history by tag, adding/removing image and PDF attachments, and no layout/semantics regression at mobile width and 200% font.
- [ ] Implement tag selection, management and transaction-list tag filter using local metadata only.
- [ ] Implement an attachment dialog with allowlisted file picker, image preview, PDF icon/name/size, and remove action; ensure failed add leaves no orphan metadata.
- [ ] Run focused widget tests, existing mobile navigation and accessibility tests; commit `Mostre tags e anexos nos lançamentos`.

### Task 5: Documentation, review, and CI

**Files:** dossier, progress, feature matrix, changelog, decisions, known-good, phase report, this plan.

- [ ] Document schema 21, extension/MIME/size behavior, backup v2 compatibility, local-only storage and open risks.
- [ ] Run `flutter analyze --no-pub`, `flutter test --no-pub --coverage`, Windows integration and `git diff --check`.
- [ ] Perform read-only independent review; fix every important finding and rerun affected/full checks.
- [ ] Push `codex/organiza-v3-fase-2-5`, open a draft PR targeting `codex/organiza-v3-fase-2-4`, and wait for Windows/Ubuntu/Android CI. Keep PR draft and do not merge.
