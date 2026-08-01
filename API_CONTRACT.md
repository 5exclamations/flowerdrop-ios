# FlowerDrop API contract

Version 1. Base path `/api/`. Everything is JSON, request and response, UTF-8.
Timestamps are ISO-8601 in **UTC** (`2026-07-30T17:00:00Z`) — the server stores
and serialises UTC, and the client renders them in the device's timezone.
`Shop.closes_at` is the exception: a bare local wall-clock time in Baku
(`"21:00:00"`), because that is what a shop puts on its door.
Money is a decimal **string** with two places (`"22.00"`) so that no client
turns it into a float. Distances are kilometres, one decimal place of meaning,
two of precision.

The iOS client is the only consumer today.

---

## Authentication

Sign-in is a two-step one-time password on a phone number. There are no
passwords and no e-mail anywhere.

Every authenticated request carries a static token:

```
Authorization: Token 9f4c1e0b7ac2d1e35f6a8b0c2d4e6f8a1b3c5d7e
```

The token does not expire and is not refreshed. The server invalidates it in
two cases: the account is blocked, or the customer deletes the account.

| Endpoint | Auth |
|---|---|
| `POST /api/auth/otp/request` | none |
| `POST /api/auth/otp/verify` | none |
| `GET /api/bouquets/` | none |
| `GET /api/bouquets/{id}/` | none |
| `POST /api/reservations/` | token |
| `GET /api/reservations/` | token |
| `POST /api/reservations/{id}/pickup` | token |
| `DELETE /api/account` | token |

The feed is open on purpose: the app shows the shop window before asking
anyone to sign in, and asks for the phone number only at the moment of
reserving.

### Phone format

Any of `+994501112233`, `994 50 111 22 33`, `0501112233`, `501112233` is
accepted; the server normalises to `+994501112233` and returns that form.
Only Azerbaijani mobile prefixes (`10 50 51 55 60 70 77 99`) pass validation.

---

## Errors

Every non-2xx response has the same shape:

```json
{
  "error": {
    "code": "otp_invalid",
    "message": "Wrong code.",
    "fields": {"phone": ["Enter an Azerbaijani mobile number."]}
  }
}
```

- `code` — stable, machine-readable, safe to branch on.
- `message` — one sentence, currently English, safe to log; the client shows
  its own localised text.
- `fields` — present only for field-level validation errors.

| HTTP | `code` | When |
|---|---|---|
| 400 | `validation_error` | Malformed body or query, per-field details in `fields` |
| 400 | `otp_invalid` | Wrong, expired, already used, or over-attempted code |
| 401 | `not_authenticated` | No token was sent |
| 401 | `authentication_failed` | A token was sent but the server does not know it — including a token whose account was deleted |
| 403 | `permission_denied` | Token is valid but the action is not allowed |
| 403 | `account_disabled` | The account is blocked |
| 404 | `not_found` | No such object, or not this user's object |
| 405 | `method_not_allowed` | Wrong HTTP verb |
| 409 | `bouquet_unavailable` | The bouquet exists but sold out, is hidden, its window closed, or another customer won the race |
| 409 | `already_reserved` | This user already holds this bouquet |
| 409 | `already_picked_up` | The reservation was already collected |
| 409 | `reservation_expired` | The hold ran out before pickup |
| 429 | `otp_cooldown` | A new code was requested too soon for this number |
| 429 | `throttled` | Too many requests from this IP |

`404` and `409` on a reservation say different things and the client should
treat them differently: `404 not_found` means the id is wrong (drop the card),
`409 bouquet_unavailable` means the id is fine but the feed is stale (refresh
it and tell the customer somebody was faster).

A reservation that belongs to another customer is a `404`, never a `403` — the
API does not confirm that someone else's reservation exists.

---

## `POST /api/auth/otp/request`

Sends a four-digit code by SMS. Three independent limits apply:

| Limit | Scope | On breach |
|---|---|---|
| 1 code per 60s | per phone number | `429 otp_cooldown` |
| 10 codes per hour | per IP | `429 throttled` |
| 5 wrong guesses | per issued code | `400 otp_invalid` |

`/verify` carries its own per-IP limit of 20 per hour, also `429 throttled`.
The per-phone cooldown alone would not stop anyone cycling through numbers,
which is why the per-IP limits exist as well.

**In development the code is always `1111`** — no gateway, no log-reading, the
simulator can just sign in. That is pinned in `config/settings/dev.py` and
hard-disabled in `prod.py`; no environment variable can turn it on in
production.

**Request**

```json
{"phone": "0501112233"}
```

**200**

```json
{"phone": "+994501112233", "expires_in": 300}
```

`expires_in` is seconds. In development builds the response also carries
`"debug_code": "4821"`, because the SMS gateway is not wired up yet. It is
never present when `DEBUG` is off.

**429**

```json
{"error": {"code": "otp_cooldown", "message": "Wait 43s before requesting a new code."}}
```

---

## `POST /api/auth/otp/verify`

Exchanges a valid code for a token. The account is created on first successful
verification — there is no separate sign-up.

**Request**

```json
{"phone": "0501112233", "code": "4821"}
```

**200**

```json
{
  "token": "9f4c1e0b7ac2d1e35f6a8b0c2d4e6f8a1b3c5d7e",
  "user": {"id": 12, "phone": "+994501112233", "name": ""}
}
```

**400** — `otp_invalid`. The same code is returned for a wrong code, an expired
code, a code that was already used, and a code that ran out of attempts (5).
The client shows one message and offers to resend.

---

## `GET /api/bouquets/?lat=&lng=`

Today's live offers, across all shops: active, still in stock, and inside a
pickup window that ends before midnight in Baku. Not paginated — one city, one
evening.

`lat` and `lng` are optional but must be sent **together**; sending one alone
is a `validation_error`. Without them `distance_km` is `null` and the list is
ordered by `pickup_until` ascending. With them the list is ordered by distance
ascending.

**200**

```json
[
  {
    "id": 4,
    "title": "Тюльпаны в крафте",
    "description": "Двадцать пять тюльпанов в крафтовой бумаге.",
    "photo_url": "http://localhost:8000/media/bouquets/1/pexels-36945270.jpg",
    "price_old": "44.00",
    "price_new": "22.00",
    "discount_percent": 50,
    "qty_left": 2,
    "pickup_until": "2026-07-30T17:00:00Z",
    "distance_km": 0.34,
    "shop": {
      "id": 1,
      "name": "Bakı Buket",
      "address": "ул. Низами, 28",
      "lat": 40.373,
      "lng": 49.839,
      "phone": "+994125981204",
      "closes_at": "21:00:00"
    }
  }
]
```

`photo_url` is absolute. It points at this server's media storage when the
shop uploaded a photo, and at the shop's own CDN otherwise; it is an empty
string only if a shop published a bouquet without any image.

`discount_percent` is the rounded whole percent, so the client does not have
to compute it — but it is derived from `price_old` and `price_new` and can be
recomputed if needed.

`qty_left` is what is on the shelf *after* other customers' active holds, so
it can drop between the feed loading and a reservation attempt. A reservation
that loses that race gets `404 bouquet_unavailable`.

### `GET /api/bouquets/{id}/`

The same object, for the detail screen. It ignores the "today" and "in stock"
filters so that a deep link to a sold-out bouquet still renders; check
`qty_left` and `pickup_until` before offering the reserve button.
Also accepts `lat`/`lng`. `404 not_found` for an unknown or hidden bouquet.

---

## `POST /api/reservations/`

Holds one item. Decrements `qty_left` atomically; two clients racing for the
last bouquet cannot both win.

**Request**

```json
{"bouquet_id": 4}
```

**201**

```json
{
  "id": 31,
  "code": "7412",
  "status": "active",
  "created_at": "2026-07-30T14:12:04Z",
  "expires_at": "2026-07-30T16:12:04Z",
  "picked_up_at": null,
  "bouquet": { "...": "the same object as in the feed" }
}
```

`code` is the four digits the customer reads out at the counter.
`expires_at` is `now + 2h`, capped by the bouquet's `pickup_until` — the hold
never outlives the shop's window.

**404** `not_found` — no bouquet with that id.
**409** `bouquet_unavailable` — sold out, hidden, the window closed, or the
last item went to somebody else. Two clients posting for the same last bouquet
at the same instant are serialised by a row lock: exactly one gets `201`, the
other gets this.
**409** `already_reserved` — this customer already holds this bouquet.

---

## `GET /api/reservations/`

This customer's reservations, newest first, not paginated. Reading the list
also expires anything that timed out, so the statuses are always current and
stale holds return their stock to the feed.

**200**

```json
[
  {
    "id": 31,
    "code": "7412",
    "status": "active",
    "created_at": "2026-07-30T14:12:04Z",
    "expires_at": "2026-07-30T16:12:04Z",
    "picked_up_at": null,
    "bouquet": { "...": "the same object as in the feed" }
  }
]
```

`status` is one of:

| value | meaning |
|---|---|
| `active` | Held; `expires_at` is in the future |
| `expired` | The hold ran out; the bouquet went back on the shelf |
| `picked_up` | Collected at the shop; `picked_up_at` is set |

---

## `POST /api/reservations/{id}/pickup`

Closes a reservation as collected. Empty body. Returns the updated
reservation, same shape as the list item.

**200** — `status` becomes `picked_up`, `picked_up_at` is set.
**404** `not_found` — unknown id, or the reservation belongs to somebody else.
**409** `already_picked_up` / `reservation_expired`.

> **This endpoint will move.** Right now the *customer* closes their own
> reservation, which means anyone can mark a bouquet collected without
> visiting the shop. In production the confirmation belongs to the shop:
> staff already do it in the admin, and this becomes either a staff-only
> endpoint or `POST /api/shop/pickups {code}`. Treat pickup as a convenience
> in the app, never as proof of collection, and do not build anything on top
> of the customer calling it.

---

## `DELETE /api/account`

Erases the signed-in customer. No body, no query, nothing to confirm — the
app is expected to ask the question in its own UI before calling this.

Required by App Store guideline 5.1.1(v): an app that creates accounts has to
let a customer delete one from inside the app.

**204** — no content. From this moment the token is dead.
**401** — no token, or a token the server no longer knows. A second call with
the same token lands here.

What the server does, in one transaction:

| | |
|---|---|
| Account and phone number | deleted |
| Token | deleted — every device signed in with it is signed out |
| One-time codes for the number | deleted |
| Reservations still active | cancelled, and the bouquet goes back on sale |
| Past reservations | kept, with `user` cleared |

The last row is the one to be careful about. A reservation is also the shop's
record of a sale: bouquet, price, dates and outcome stay so the shop's
statistics for a past day do not change because a customer left. What goes is
the link to the person — the rows have no owner afterwards and no endpoint can
return them, because every reservation endpoint filters by the caller.

Cancelled holds get `status: "cancelled"`, a status that exists only in the
database. The client never receives it: the only rows carrying it belong to a
deleted account.

Signing up again with the same number produces a new, empty account.

---

## Notes for the client

- Trailing slashes matter. `/api/bouquets/` and `/api/reservations/` have one;
  `/api/auth/otp/request`, `/api/auth/otp/verify`, `/api/account` and
  `.../pickup` do not.
- Nothing is paginated in v1. When it becomes necessary the list endpoints
  will switch to `{"results": [...], "next": ...}` under a new version prefix,
  not silently.
- Expiry has no background worker behind it: a hold flips to `expired` the
  next time any reservation endpoint is called. Do not rely on the exact
  moment, rely on `expires_at`.
