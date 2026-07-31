# Schema Design

Applies when deciding any durable shape that is expensive to change later — persisted-data formats (JSON documents, DB schemas), API shapes (request/response bodies), config/file formats, and infrastructure configuration (IaC resources, network layout).

## Agreement gate

Before implementing, always present a concise before/after sample of the shape (current vs proposed; "none" if new) and get the user's agreement. A prose description does not count — show the actual sample (for infrastructure, the config diff or topology sketch).

## Shape principles (data shapes)

- Don't persist what can be derived from other stored data
- Keys repeated inside arrays stay short — their cost is paid per element
- A fixed-arity, immutable structure becomes a tuple, not a keyed object
- Design enums for orthogonality: one axis per enum; don't fold independent axes into combined values
