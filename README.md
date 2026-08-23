# Nexus Shine

A Ruby on Rails online shop for **Nexus Shine** — official Bulgarian importer of
professional cleaning chemistry (ERA 111 Professional, TURBOPAX, Power 1) for
self-service car washes, carpet-washing factories, home and industry.

Built on the same stack as `nexus-cleaning`: **Rails 8.1**, PostgreSQL, Propshaft,
importmap, Hotwire (Turbo + Stimulus), Solid Queue/Cache/Cable, Kamal.

## What's included

- **Catalogue** — `Brand`, `Category`, `Product` (price stored in EUR cents; BGN
  derived at the fixed 1.95583 peg via the `Money` value object). Products can
  belong to several categories.
- **Shop** — `/shop` grid with category filter (`?category=`) and sorting
  (`?sort=`), product detail pages at `/product/:slug`.
- **Cart** — session-backed `Cart` (no DB row until checkout), add / update /
  remove, live header badge via Turbo Stream.
- **Checkout** — `/orders/new` captures shipping details and snapshots the cart
  into an `Order` + `OrderItem`s, then shows a confirmation.
- **Pages** — Home, About (brands + testimonials), Contact (form), FAQ, Privacy.
- **Design** — single Propshaft `application.css` design system (cyan/gold
  "shine" palette), Bulgarian UI, topbar + sticky header + footer + cookie
  consent, matching the Nexus house style.

## Getting started

```bash
bin/rails db:create db:migrate db:seed   # 3 brands, 3 categories, 12 products
bin/rails server                          # http://localhost:3000
```

## myPOS card payments

Checkout offers **card (myPOS)** or **cash-on-delivery / bank transfer**. The card
flow uses myPOS Checkout (`IPCPurchase`): the customer is redirected to myPOS's
hosted page, so no card data touches this app. A signed server-to-server
notification (`URL_Notify`) marks the order paid. Code lives in
`app/services/mypos/` (`Config`, `Purchase`, `Notification`) and
`PaymentsController`.

### Configuration

Card payment is offered only when myPOS is configured. Add credentials with
`bin/rails credentials:edit` (never commit keys):

```yaml
mypos:
  sid: "your-store-id"
  wallet_number: "your-wallet-number"
  key_index: 1
  private_key: |
    -----BEGIN RSA PRIVATE KEY-----
    ... your merchant private key ...
    -----END RSA PRIVATE KEY-----
  public_cert: |
    -----BEGIN CERTIFICATE-----
    ... the myPOS API public certificate ...
    -----END CERTIFICATE-----
  ipc_url: "https://mypos.com/vmp/checkout-test"   # TEST; use .../checkout for live
```

Or via env vars: `MYPOS_SID`, `MYPOS_WALLET_NUMBER`, `MYPOS_KEY_INDEX`,
`MYPOS_PRIVATE_KEY`, `MYPOS_PUBLIC_CERT`, `MYPOS_IPC_URL`. Generate the key pair
and download the myPOS certificate from your myPOS account (Online payments →
your store). Defaults to the **test** endpoint so nothing charges real cards.

### Local sandbox (no credentials needed)

For development there's a **built-in myPOS simulator** so the whole card flow
works on `localhost` without real credentials or a public tunnel. It's enabled
by default in development (`config/environments/development.rb` sets
`MYPOS_LOCAL_SANDBOX=1`) and generates a throwaway RSA keypair under
`tmp/mypos_sandbox/`.

Flow: choose **Плащане с карта** at checkout → a mock myPOS page (`/dev/mypos/…`,
dev-only) → **Плати (успех)** signs a real notification, posts it to
`URL_Notify`, and the order is marked paid. This exercises the actual signing
and verification code.

To test against the **real myPOS sandbox** instead, set `MYPOS_LOCAL_SANDBOX=0`
and add real test credentials (below), pointing `ipc_url` at `…/checkout-test`.

### Testing notes

- Keep `ipc_url` on `…/checkout-test` and use myPOS test cards until verified.
- **`URL_Notify` must be publicly reachable by myPOS**, so on `localhost` the
  paid-confirmation callback won't arrive — expose the app with a tunnel
  (e.g. ngrok) for a full sandbox test, or mark the order paid manually in the
  admin (Поръчки → order → Статус на плащането). The signature algorithm and
  full flow are covered by an in-process round-trip test.
- Signature = `base64( join(values, "-") )` → RSA-SHA256 sign → base64, matching
  the official myPOS PHP SDK; notifications are verified against `public_cert`.

## Speedy shipping

Checkout offers **Speedy** delivery to an office or to an address, with the price
calculated live via the Speedy API (`app/services/speedy/`) and added to the order
total. Products carry a **weight (kg)** (admin) used for the calculation; the price
is always recomputed server-side at checkout (never trusted from the browser).

### Configuration

Copy `config/speedy.example.yml` to `config/speedy.yml` (git-ignored) and fill in
your Speedy API username/password:

```yaml
username: "your-speedy-username"
password: "your-speedy-password"
language: "BG"
sender_site_id: ""        # optional dispatch city id
# service_ids: "505"      # optional; empty = ask Speedy for all and pick cheapest
```

Or via env: `SPEEDY_USERNAME`, `SPEEDY_PASSWORD`, `SPEEDY_SENDER_SITE_ID`,
`SPEEDY_SERVICE_IDS`. Validate with:

```
bin/rails speedy:check
```

The shipping section appears at checkout only when Speedy is configured; otherwise
checkout proceeds without a live shipping charge.

## Notable follow-ups (not built in v1)

- **Product images** — `Product has_one_attached :image`; cards/detail show a
  brand-initial placeholder until images are uploaded. Add an admin or attach in
  the seed.
- **Contact form / order emails** — `PagesController#send_message` and orders
  only log; wire up ActionMailer to actually deliver.
- **Admin panel, user accounts, wishlist, payments** — deliberately out of scope
  for the first cut; the original site's storefront is fully reproduced.
