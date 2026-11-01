# ADR 0006: Versioned Firestore schema and ownership boundaries

Date: 2026-09-06. Status: accepted for Phase 4.

## Decision

Use four top-level, versioned collections: `users`, `restaurants`,
`menu_items`, and `meal_logs`. Models use explicit serialization and reject
unknown `schemaVersion` values. Queries are defined before indexes and collection
access patterns.

Restaurant/menu catalog records are publicly readable only when `isActive` is
true and are never writable by mobile clients. User documents and meal logs are
private to their authenticated owner. Trusted catalog population is deferred to
Phase 5 administrative seed tooling.

Profile and food-preference values retain their existing version 1 nested
contracts so dietary filtering semantics do not fork between local and remote
representations. No automatic migration or merge is performed in Phase 4.

## Consequences

- The optional-account product flow can read public catalog data without forcing
  sign-in, while private data remains owner-scoped.
- Queries must carry the rule-visible constraints (`isActive` or exact `userId`)
  or Firestore rejects the whole query.
- Client-owned timestamps use server timestamps and immutable ownership fields.
- Strict version checks make incompatible changes visible and require an
  intentional future migration.
- Location/geohash fields may be added only with a documented schema version or
  backwards-compatible optional-field decision during the Location phase.

See `docs/phase-4-firestore-schema.md` for the complete field and query contract.
