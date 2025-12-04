# MongoDB Prod → Staging Sync Runbook



## 1. Pre-Sync Check (Production Document Counts)

Run this before starting a restore to confirm the reference document counts captured from the latest production snapshot (via the temporary sync job pod):

```
make -f Makefile.sync pre-sync-check
```

Expected outcome:
- The command prints the contents of `.sync_doc_counts`, for example:
  - `DOC_COUNT_users=10`
  - `DOC_COUNT_posts=100`
- These values are used later to verify staging correctness.

---

## 2. Post-Restore Verification (Staging vs Prod Counts)

After a restore, validate that staging has the same document counts as the production snapshot used during sync:

```
make -f Makefile.restore verify-restore
```

This verification step:
- Reads expected counts from `.sync_doc_counts`.
- Connects to the staging Mongo pod and runs `countDocuments()` for `users` and `posts`.
- Compares staging counts against the expected values.

Outcomes:
- If counts match, you see a success message similar to:
  - `✅ ✅ PERFECT MATCH! users=10/10, posts=100/100`
- If counts differ, verification fails with:
  - A clear error showing expected vs actual counts.
  - A pointer to the latest backup file.
  - An instruction to run the rollback command.


## 3. Rollback Staging to Previous Backup

If verification fails or staging data is otherwise invalid, rollback restores the staging MongoDB from the most recent backup taken just before the latest restore:

```
make -f Makefile.restore rollback-restore
```


What this does:
- Locates the newest `current-staging-*.archive.gz` in `../backups`.
- Copies this archive into the staging Mongo pod as `/tmp/rollback.archive.gz`.
- Runs `mongorestore --drop --gzip --archive=/tmp/rollback.archive.gz` against staging.
- Prints the backup file used for rollback.




