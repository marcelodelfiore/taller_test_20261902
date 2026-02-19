# Library API (Books + Reservations)

Small Rails API implementing:

- `POST /books/:id/reserve` — reserve a book by email, update book status
- Optimized GET endpoints:
  - `GET /books` — paginated list, filtering/search, optional current reservation
  - `GET /books/:id` — book details, optional reservations/current reservation

This project focuses on **correctness, query performance, clean API behavior, and test coverage**.

---

## Requirements

- Ruby 3.4.x
- Bundler
- SQLite (default for dev/test)

> If you use another DB (Postgres), the code will work as well, but search uses a DB-agnostic `LOWER(...) LIKE ...` approach.

---

## Setup

```bash
bundle install
bin/rails db:create db:migrate
```

(Optional) Seed some data:
```bash
bin/rails db:seed
```

---

## Run the server

```bash
bin/rails server
```

Default: http://localhost:3000

---

## Run tests

```bash
bundle exec rspec
```

---

## API Endpoints

### 1) List books

`GET /books`

**Query params**
- `page` (default: `1`)
- `per` (default: `25`, max: `100`)
- `status` (optional): `available|reserved|checked_out`
- `q` (optional): case-insensitive search in `title` and `author`
- `include` (optional): `current_reservation`

**Example**
```bash
curl "http://localhost:3000/books?page=1&per=10&status=available&q=asimov"
```

**Include current reservation**
```bash
curl "http://localhost:3000/books?include=current_reservation"
```

Response shape:
```json
{
  "data": [
    {
      "id": 1,
      "title": "Foundation",
      "author": "Isaac Asimov",
      "status": "reserved",
      "created_at": "...",
      "updated_at": "...",
      "current_reservation": {
        "id": 10,
        "book_id": 1,
        "email": "user@example.com",
        "status": "reserved",
        "created_at": "...",
        "updated_at": "..."
      }
    }
  ],
  "meta": { "page": 1, "per": 10, "total": 1234 }
}
```

---

### 2) Show book details

`GET /books/:id`

**Query params**
- `include` (optional, comma-separated):
  - `reservations` (returns paginated reservations list)
  - `current_reservation`
- `page`, `per` (only applies when `include=reservations`)

**Examples**
```bash
curl "http://localhost:3000/books/1"
curl "http://localhost:3000/books/1?include=current_reservation"
curl "http://localhost:3000/books/1?include=reservations&page=1&per=25"
curl "http://localhost:3000/books/1?include=reservations,current_reservation"
```

Response shape (when including reservations):
```json
{
  "data": { "id": 1, "title": "...", "author": "...", "status": "..." },
  "reservations": [
    { "id": 10, "book_id": 1, "email": "user@example.com", "status": "reserved" }
  ],
  "meta": { "page": 1, "per": 25, "total": 3 }
}
```

---

### 3) Reserve a book

`POST /books/:id/reserve`

Body:
```json
{ "reservation": { "email": "user@example.com" } }
```

**Example**
```bash
curl -X POST "http://localhost:3000/books/1/reserve" \
  -H "Content-Type: application/json" \
  -d '{"reservation":{"email":"user@example.com"}}'
```

**Behavior / edge cases**
- If the book is already `reserved` → `409 Conflict`
- If the book is `checked_out` → `409 Conflict`
- Invalid email → `422 Unprocessable Content`
- Book not found → `404 Not Found`

---

## Data model

### Book
- `title` (string)
- `author` (string)
- `status` (string, default: `available`)
  Allowed: `available|reserved|checked_out`

### Reservation
- `book_id` (FK)
- `email` (string, validated)
- `status` (string)
  Allowed: `reserved|canceled|fulfilled`

---

## Notes on performance and scalability

The GET endpoints are implemented to handle large datasets:

- Pagination (`page/per`) with a hard cap (`per <= 100`)
- Stable ordering (`created_at DESC, id DESC`)
- Filtering by indexed fields (`books.status`)
- DB-agnostic search (`LOWER(...) LIKE ...`) for SQLite and Postgres
- Avoids N+1 when including current reservation on `/books`:
  - books loaded in one query
  - current reservations loaded in one additional query, mapped by `book_id`

### Future improvements (if scaling further)
- Cursor pagination (better than offset for very large tables)
- Postgres trigram index (`pg_trgm`) or full-text search for faster `q`
- DB-level enforcement for “only one active reserved reservation per book” (partial unique index in Postgres)
- Row locking (`book.lock!`) inside the reservation transaction to prevent race conditions under concurrent requests
- ETags / conditional GET caching for `GET /books`

---

## Development notes

- Status code `:unprocessable_entity` is deprecated in newer Rack versions; this project uses `:unprocessable_content`.
- Specs include request tests for success + edge cases and model validations.

---

## Quick checklist (for reviewers)

```bash
bundle install
bin/rails db:create db:migrate
bundle exec rspec
bin/rails s
```

Then try:
- `GET /books`
- `GET /books?include=current_reservation`
- `GET /books/:id?include=reservations,current_reservation`
- `POST /books/:id/reserve`
