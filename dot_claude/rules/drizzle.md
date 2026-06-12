---
paths:
  - "**/schema.ts"
  - "**/schema.tsx"
  - "**/drizzle.config.*"
  - "**/drizzle/**"
---

# Drizzle ORM

## Timestamps

Every table must include `createdAt` and `updatedAt` columns. Use the
dialect-appropriate pattern.

### Postgres / MySQL

Native `timestamp` with explicit timezone behavior.

```ts
createdAt: timestamp({ withTimezone: true }).notNull().defaultNow(),
updatedAt: timestamp({ withTimezone: true }).notNull().defaultNow().$onUpdate(() => new Date()),
```

### SQLite / Cloudflare D1

SQLite has no native datetime type. Store ISO 8601 strings in a `text`
column; `new Date().toISOString()` always emits UTC, so this provides
UTC storage without an explicit flag.

```ts
const timestampDefault = () => new Date().toISOString();

createdAt: text("created_at").notNull().$defaultFn(timestampDefault),
updatedAt: text("updated_at").notNull().$defaultFn(timestampDefault).$onUpdate(timestampDefault),
```

If the project uses Better Auth's `drizzleAdapter`, the auth-managed
tables (`users` / `sessions` / `accounts` / `verifications`) need a
custom type that round-trips `Date` objects, because Better Auth's
adapter writes `Date` directly:

```ts
const textDate = customType<{ data: Date; driverData: string }>({
  dataType: () => "text",
  toDriver: (v) => (v instanceof Date ? v.toISOString() : String(v)),
  fromDriver: (v) => new Date(v),
});

createdAt: textDate("created_at").notNull().$defaultFn(() => new Date()),
updatedAt: textDate("updated_at").notNull().$defaultFn(() => new Date()).$onUpdate(() => new Date()),
```

### Exception: immutable single-event tables

A table whose row creation IS the only domain event, and which is never
updated in place (recomputation goes through cascade delete + insert),
may use a single domain-named timestamp instead of the standard pair.
Document the exception inline in the schema. Example: an `embeddings`
row that records "this embedding was computed at time X" can use
`computed_at` alone.

The exception is justified by domain semantics, not laziness — the
single timestamp's name carries meaning that the standard pair would
obscure.

## Migrations

- See `development-principles.md` for migration rules.
- For un-shipped iteration on the initial migration in a PR (the
  `0000_*.sql` file is not yet on `main`), prefer regenerating in
  place — `rm` the file + `meta/`, then `db:generate` — over
  appending an `ALTER TABLE` migration on top of un-merged work.
