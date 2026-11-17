# Cloud Functions Module Architecture

This document defines how Firebase Cloud Functions are organized in this
project. The structure is feature-first and layered. Each module owns one
business capability, while shared infrastructure remains outside feature
modules.

## Goals

- Keep callable entry points small and easy to find.
- Validate all untrusted input at the boundary with Zod.
- Keep business rules in services, not in controllers or repositories.
- Keep Firestore reads and writes in repositories.
- Keep modules independently testable.
- Use object factories instead of service or repository classes.
- Preserve a one-way dependency flow.

## Directory Structure

```text
functions/
├── src/
│   ├── index.ts
│   ├── expenses.ts                 # Public expense exports
│   ├── rooms.ts                    # Public room exports
│   │
│   ├── common/                     # Shared backend infrastructure
│   │   ├── errors/
│   │   │   ├── app-error.ts
│   │   │   └── to-https-error.ts
│   │   ├── firebase/
│   │   │   ├── admin.ts
│   │   │   └── firestore.ts
│   │   ├── auth/
│   │   │   └── require-uid.ts
│   │   ├── validation/
│   │   │   └── parse-input.ts
│   │   └── utils/
│   │
│   ├── notifications/              # Shared notification infrastructure
│   │   ├── notification.service.ts
│   │   └── notification.types.ts
│   │
│   └── modules/
│       ├── expenses/
│       │   ├── expense.functions.ts
│       │   ├── expense.controller.ts
│       │   ├── expense.schema.ts
│       │   ├── expense.service.ts
│       │   ├── expense.repository.ts
│       │   ├── expense-summary.ts
│       │   └── expense.types.ts
│       │
│       ├── rooms/
│       │   ├── room.functions.ts
│       │   ├── room.controller.ts
│       │   ├── room.schema.ts
│       │   ├── room.service.ts
│       │   ├── room.repository.ts
│       │   └── room.types.ts
│       │
│       └── users/
│           ├── user.functions.ts
│           ├── user.controller.ts
│           ├── user.schema.ts
│           ├── user.service.ts
│           ├── user.repository.ts
│           └── user.types.ts
│
└── test/
		├── expenses/
		├── rooms/
		└── users/
```

The current project uses `src/expenses` and `src/rooms` directly. Those folders
are valid module folders. Moving them under `src/modules` is optional and
should be done as a separate mechanical change so imports remain easy to
review.

## Dependency Direction

Dependencies point inward toward the business module:

```text
Firebase export
		-> functions adapter
				-> controller
						-> schema and auth boundary
								-> service
										-> repository
												-> Firebase Admin SDK
```

The preferred dependency rules are:

| Layer | May depend on | Must not depend on |
| --- | --- | --- |
| Functions adapter | Controller | Firestore, business rules |
| Controller | Schema, auth helper, service | Direct Firestore queries |
| Schema | Zod, module types | Firebase Admin, service |
| Service | Repository, shared services, module types | Callable request objects |
| Repository | Firebase Admin SDK, module types | Controllers, Zod request parsing |
| Types | TypeScript types | Firebase runtime services |

A service may receive a repository or shared service as a dependency. This
makes unit tests independent from Firestore.

## Layer Responsibilities

### 1. Functions Adapter

The functions file connects Firebase Functions v2 to the controller. It should
only register the callable and forward the request.

```ts
import { onCall } from 'firebase-functions/v2/https';
import { createExpenseController } from './expense.controller';

const controller = createExpenseController();

export const createExpense = onCall((request) =>
	controller.create(request),
);
```

Do not validate input, access Firestore, or implement business rules here.

### 2. Controller

The controller is the HTTP/callable boundary. It should:

1. Require an authenticated user when the operation needs one.
2. Parse `request.data` with the module schema.
3. Call exactly one service operation.
4. Return the service result.

```ts
export function createExpenseController(
	service: ExpenseService = createExpenseService(),
): ExpenseController {
	return {
		async create(request) {
			const uid = requireUid(request);
			const input = parseCreateExpenseInput(request.data);
			return service.create(input, uid);
		},
	};
}
```

Controllers should not contain Firestore queries, transactions, summary
calculation, or notification decisions.

### 3. Schema

Schemas define and validate external input. Every callable input must be
validated before it reaches a service.

```ts
import { z } from 'zod';
import { HttpsError } from 'firebase-functions/v2/https';

const createRoomSchema = z.object({
	name: z.string().trim().min(1).max(80),
	currency: z.string().trim().length(3).toUpperCase(),
});

export function parseCreateRoomInput(value: unknown) {
	const result = createRoomSchema.safeParse(value);
	if (!result.success) {
		throw new HttpsError('invalid-argument', result.error.issues[0]?.message ?? 'Invalid input.');
	}
	return result.data;
}
```

Schemas should reject unknown or malformed input, normalize values where
appropriate, and return a typed result. They should not read Firestore or
check room membership.

### 4. Service

The service owns use cases and business rules. It coordinates repositories,
transactions, derived data, and notifications.

Services are object factories. Closures hold dependencies; `this` is not used.

```ts
export interface RoomService {
	createRoom(name: string, currency: string, uid: string): Promise<RoomResult>;
}

export function createRoomService(
	db: Firestore = getFirestore(),
	repository: RoomRepository = createRoomRepository(db),
): RoomService {
	return {
		async createRoom(name, currency, uid) {
			// Membership, ownership, invite generation, and transaction logic live here.
			return repository.createRoom(name, currency, uid);
		},
	};
}
```

A service should expose named use cases such as `create`, `update`, `delete`,
`joinRoom`, or `rebuild`. It should not receive `CallableRequest` and should
not know how Firebase callable handlers are registered.

### 5. Repository

The repository owns persistence. It contains Firestore collection paths,
queries, document reads, document writes, batches, and transaction helpers.

```ts
export interface RoomRepository {
	roomRef(roomId: string): DocumentReference;
	readRoom(transaction: Transaction, roomRef: DocumentReference): Promise<DocumentSnapshot>;
	createRoom(transaction: Transaction, roomRef: DocumentReference, data: RoomData): void;
}

export function createRoomRepository(db: Firestore): RoomRepository {
	return {
		roomRef: (roomId) => db.collection('rooms').doc(roomId),
		async readRoom(transaction, roomRef) {
			return transaction.get(roomRef);
		},
		createRoom(transaction, roomRef, data) {
			transaction.create(roomRef, data);
		},
	};
}
```

Repositories should not decide whether a user is allowed to perform an
operation. Authorization and business rules belong in the service.

### 6. Types

Types describe module data and service contracts:

- callable input and output types;
- persisted Firestore document types;
- repository interfaces;
- service interfaces;
- domain-specific error types.

Runtime validation belongs in schemas. TypeScript types alone do not validate
data received from a callable client or Firestore.

## Request Flow Example

Creating an expense follows this path:

```text
Flutter client
		-> createExpense callable
				-> expense.functions.ts
						-> expense.controller.ts
								-> expense.schema.ts
								-> requireUid()
								-> expense.service.ts
										-> expense.repository.ts
										-> expense-summary.ts
										-> notification.service.ts
												-> Firestore transaction / FCM
```

The service should update the expense and all derived summary data in the same
Firestore transaction. Notifications are sent after the transaction succeeds;
a notification failure must not undo a successful expense mutation.

## Errors

Use `HttpsError` at the callable boundary with stable error codes:

| Situation | Code |
| --- | --- |
| Missing authentication | `unauthenticated` |
| Invalid callable input | `invalid-argument` |
| User is not a room member | `permission-denied` |
| Document does not exist | `not-found` |
| Duplicate idempotency key | `already-exists` |
| Valid request cannot be completed safely | `failed-precondition` |
| Temporary retry exhaustion | `resource-exhausted` |

Services may throw `HttpsError` for expected callable failures. Unexpected
errors should be logged and allowed to become an internal error through the
callable runtime. Do not expose raw Firestore or database errors to clients.

## Object Factory Rules

- Export an interface for each repository or service contract.
- Export a `createX` factory that accepts dependencies.
- Keep dependencies in closure scope.
- Use module-level pure helpers for calculations and formatting.
- Use dependency defaults only at composition boundaries.
- Inject fakes in unit tests instead of mocking global Firebase state.

Example composition:

```ts
const repository = createExpenseRepository(db);
const summary = createExpenseSummary(db);
const service = createExpenseService(db, repository, summary);
const controller = createExpenseController(service);
```

## Testing Strategy

### Schema tests

Test valid input, missing fields, wrong types, boundary lengths, and
normalization.

### Service tests

Inject fake repositories and verify business behavior:

- unauthorized users are rejected;
- invalid members cannot participate;
- create, update, and delete keep summaries in sync;
- repeated create requests are idempotent;
- notification failures do not fail a completed mutation.

### Repository tests

Use the Firebase Emulator for Firestore behavior, transactions, queries,
batches, and document shapes.

### Callable tests

Test the exported callable functions with authenticated and unauthenticated
requests. These tests verify the wiring between Firebase, controller, schema,
and service.

## Naming Rules

| Purpose | Naming |
| --- | --- |
| Firebase export adapter | `expense.functions.ts` |
| Callable boundary | `expense.controller.ts` |
| Zod validators | `expense.schema.ts` |
| Use cases | `expense.service.ts` |
| Firestore access | `expense.repository.ts` |
| Contracts and data shapes | `expense.types.ts` |
| Factory | `createExpenseService()` |
| Parser | `parseCreateExpenseInput()` |
| Handler | `createExpenseHandler()` |

Use one module vocabulary consistently. For example, do not call the same
operation `addExpense` in one layer and `createExpense` in another without a
clear adapter reason.

## Rules of Thumb

- A controller should be readable in one screen.
- A schema should never call Firebase.
- A repository should not contain authorization decisions.
- A service should describe a business action, not a database operation.
- Shared code belongs in `common` only when at least two modules use it.
- Keep module-specific helpers inside the module until reuse is proven.
- Prefer a small explicit factory over a generic dependency-injection system.
- Keep transactions in the service/repository boundary and document their
	consistency guarantees.
