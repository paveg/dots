# Drizzle ORM

## Timestamps

- Every table must include `createdAt` and `updatedAt` columns
- Use `withTimezone: true` to store timestamps in UTC

```ts
createdAt: timestamp({ withTimezone: true }).notNull().defaultNow(),
updatedAt: timestamp({ withTimezone: true }).notNull().defaultNow().$onUpdate(() => new Date()),
```

## Migrations

- See `development-principles.md` for migration rules
