# Database Schema

Postgres schema hosted on Supabase. All user-authored rows are subject to Row-Level Security (RLS).

## Tables Overview

| Table | Purpose |
|-------|---------|
| `profiles` | Extended user metadata (Supabase `auth.users` holds authentication; this table holds app-specific fields like name, role, created_at) |
| `businesses` | Business entities (bakeries, cafes). One profile may own one business (`owner_id` FK). |
| `products` | Surplus products listed by businesses. Central table of the marketplace. |
| `orders` | User reservations against products. Includes status machine transitions. |
| `impact_logs` | Per-order impact metrics (kg saved, CO2 saved, money saved) written at pickup. |

## Why a `profiles` Table?

Supabase `auth.users` is managed by Supabase and cannot be freely modified. All app-level user fields go into `profiles`, linked 1:1 via `profiles.id = auth.users.id`. A trigger auto-creates a profile row when a user signs up.

## Table Definitions

### `profiles`

```sql
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text,
  phone text,
  role text not null default 'user' check (role in ('user', 'business', 'admin')),
  kvkk_accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index profiles_role_idx on public.profiles(role);
```

**Notes:**
- `role`: 'user' for regular end users; 'business' for business owners. A business owner is still a regular user who can also list products — the role just unlocks business screens.
- `kvkk_accepted_at`: null until the user explicitly accepts KVKK consent. App should block usage if null.

### `businesses`

```sql
create table public.businesses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  description text,
  phone text,
  address text not null,
  latitude numeric(9,6) not null,
  longitude numeric(9,6) not null,
  logo_url text,
  category text not null check (category in ('bakery', 'cafe', 'patisserie', 'other')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index businesses_owner_id_idx on public.businesses(owner_id);
create index businesses_location_idx on public.businesses(latitude, longitude);
create index businesses_active_idx on public.businesses(is_active) where is_active = true;
```

**Notes:**
- One owner, one business (unique constraint on `owner_id`). Multi-location businesses are out of MVP scope.
- `latitude`/`longitude`: stored as `numeric(9,6)` (enough precision for ~10cm). PostGIS is overkill for MVP; client-side distance calculation using Haversine is sufficient for ≤5km radius queries.
- `is_active`: businesses can temporarily deactivate (e.g. on vacation) without deleting their account.

### `products`

```sql
create table public.products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  description text,
  image_url text,
  category text not null check (category in ('bread', 'pastry', 'sandwich', 'dessert', 'drink', 'mixed_box', 'other')),
  listing_type text not null check (listing_type in ('menu_item', 'surprise_box')),
  original_price numeric(8,2) not null check (original_price > 0),
  current_price numeric(8,2) not null check (current_price > 0),
  stock int not null default 1 check (stock >= 0),
  pickup_start timestamptz not null,
  pickup_end timestamptz not null,
  status text not null default 'active' check (status in ('active', 'sold_out', 'expired', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint pickup_window_valid check (pickup_end > pickup_start)
);

create index products_business_id_idx on public.products(business_id);
create index products_status_active_idx on public.products(status, pickup_end) where status = 'active';
create index products_category_idx on public.products(category);
```

**Notes:**
- `listing_type`:
  - `menu_item` → user sees exactly what they get (name, description, photo)
  - `surprise_box` → user sees category + approximate value, contents are mystery
- `current_price`: updated by dynamic pricing logic. Original price stays fixed for impact calculation.
- `stock`: how many units available. Decremented on order creation.
- `pickup_start` / `pickup_end`: the window during which the user must pick up. Dynamic pricing tiers use time-until-`pickup_end`.
- `status`:
  - `active` → visible and orderable
  - `sold_out` → stock hit 0
  - `expired` → `pickup_end` passed without selling
  - `cancelled` → business cancelled listing

### `orders`

```sql
create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  business_id uuid not null references public.businesses(id) on delete restrict,
  price_paid numeric(8,2) not null check (price_paid > 0),
  original_price numeric(8,2) not null check (original_price > 0),
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'picked_up', 'cancelled', 'expired')),
  cancelled_reason text,
  created_at timestamptz not null default now(),
  confirmed_at timestamptz,
  picked_up_at timestamptz,
  cancelled_at timestamptz,

  constraint order_status_timestamps check (
    (status = 'pending' and confirmed_at is null and picked_up_at is null) or
    (status = 'confirmed' and confirmed_at is not null and picked_up_at is null) or
    (status = 'picked_up' and confirmed_at is not null and picked_up_at is not null) or
    (status in ('cancelled', 'expired') and cancelled_at is not null)
  )
);

create index orders_user_id_idx on public.orders(user_id);
create index orders_business_id_idx on public.orders(business_id);
create index orders_product_id_idx on public.orders(product_id);
create index orders_status_idx on public.orders(status);
```

**Notes:**
- `product_id` and `business_id` use `on delete restrict` — we want to preserve order history even if the product listing is removed.
- `business_id` is denormalized (derivable from `product_id`) for faster queries on business-side order lists.
- `price_paid` is frozen at order time — even if product price changes later, the order preserves what the user committed to.
- `original_price` is also frozen — used for impact calculation (savings = original - paid).
- Status transitions enforced at application layer via state machine (see FEATURE_SPECS.md), not database triggers.

### `impact_logs`

```sql
create table public.impact_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  order_id uuid not null unique references public.orders(id) on delete cascade,
  food_saved_kg numeric(6,2) not null,
  co2_saved_kg numeric(6,2) not null,
  money_saved_try numeric(8,2) not null,
  created_at timestamptz not null default now()
);

create index impact_logs_user_id_idx on public.impact_logs(user_id);
```

**Notes:**
- One row per completed pickup. Written by application code when order status transitions to `picked_up`.
- Coefficients (`food_saved_kg`, `co2_saved_kg`) use placeholder values (0.8 kg/order, 2.5 kg CO2/order) — these are TBD and should be extracted into a config constant, NOT hardcoded.
- Unique constraint on `order_id` prevents double-counting.

## Triggers

### Auto-create profile on signup

```sql
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
```

### Auto-update `updated_at`

```sql
create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_updated_at_profiles before update on public.profiles
  for each row execute function public.tg_set_updated_at();
create trigger set_updated_at_businesses before update on public.businesses
  for each row execute function public.tg_set_updated_at();
create trigger set_updated_at_products before update on public.products
  for each row execute function public.tg_set_updated_at();
```

## Row-Level Security (RLS)

RLS is **enabled on every table**. Default is deny — policies explicitly grant access.

### `profiles`

```sql
alter table public.profiles enable row level security;

-- Users can read any profile (needed to show business owner name, etc.)
create policy "Profiles are viewable by authenticated users"
  on public.profiles for select
  using (auth.role() = 'authenticated');

-- Users can only update their own profile
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);
```

### `businesses`

```sql
alter table public.businesses enable row level security;

-- Anyone (even anon) can view active businesses — for public marketing pages later
create policy "Active businesses are viewable by all"
  on public.businesses for select
  using (is_active = true or owner_id = auth.uid());

-- Only the owner can insert their own business
create policy "Users can create own business"
  on public.businesses for insert
  with check (auth.uid() = owner_id);

-- Only the owner can update their business
create policy "Owners can update own business"
  on public.businesses for update
  using (auth.uid() = owner_id);
```

### `products`

```sql
alter table public.products enable row level security;

-- Anyone can view active products
create policy "Active products are viewable"
  on public.products for select
  using (
    status = 'active'
    or business_id in (select id from public.businesses where owner_id = auth.uid())
  );

-- Only business owners can create products for their own business
create policy "Business owners can create products"
  on public.products for insert
  with check (
    business_id in (select id from public.businesses where owner_id = auth.uid())
  );

-- Only business owners can update their products
create policy "Business owners can update products"
  on public.products for update
  using (
    business_id in (select id from public.businesses where owner_id = auth.uid())
  );

-- Only business owners can delete their products
create policy "Business owners can delete products"
  on public.products for delete
  using (
    business_id in (select id from public.businesses where owner_id = auth.uid())
  );
```

### `orders`

```sql
alter table public.orders enable row level security;

-- Users see their own orders; businesses see orders for their products
create policy "Orders viewable by participants"
  on public.orders for select
  using (
    user_id = auth.uid()
    or business_id in (select id from public.businesses where owner_id = auth.uid())
  );

-- Only the ordering user can create an order for themselves
create policy "Users can create own orders"
  on public.orders for insert
  with check (auth.uid() = user_id);

-- Both parties can update (with further logic enforced application-side)
create policy "Order participants can update"
  on public.orders for update
  using (
    user_id = auth.uid()
    or business_id in (select id from public.businesses where owner_id = auth.uid())
  );
```

### `impact_logs`

```sql
alter table public.impact_logs enable row level security;

-- Users can only see their own impact
create policy "Users can view own impact"
  on public.impact_logs for select
  using (user_id = auth.uid());

-- Application writes impact logs via service role, not client
-- No insert policy for client-side.
```

## Storage Buckets

| Bucket | Path pattern | Purpose |
|--------|-------------|---------|
| `product-images` | `{business_id}/{product_id}/{uuid}.jpg` | Product listing photos |
| `business-logos` | `{business_id}/logo.jpg` | Business logos |

Both buckets are public-read but restricted-write (only the business owner can upload to their own path). RLS policies on storage mirror the ownership logic.

## Migration Order

When creating the database from scratch, apply SQL in this order:

1. `001_profiles.sql` — create `profiles` table + trigger for auto-creation on signup
2. `002_businesses.sql` — create `businesses` table
3. `003_products.sql` — create `products` table
4. `004_orders.sql` — create `orders` table
5. `005_impact_logs.sql` — create `impact_logs` table
6. `006_triggers.sql` — `updated_at` triggers for all tables
7. `007_rls_policies.sql` — all RLS policies
8. `008_storage_buckets.sql` — storage bucket creation + policies

The agent should create these as separate files in `supabase/migrations/` for clarity and future incremental changes.

## Open Schema Decisions

The following are intentionally unresolved. Mark with `TODO` when encountered:

- **Dynamic pricing tiers storage**: Should tiers be hardcoded in app logic, or stored in a `pricing_rules` table per business? Pending team decision.
- **Reviews/ratings table**: Not in MVP. Skeleton added in Phase 2.
- **Notification preferences**: No `notification_settings` table in MVP (notifications deferred).
- **Chat / messaging between user and business**: Not in MVP.
