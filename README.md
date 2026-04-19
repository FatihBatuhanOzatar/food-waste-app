# Food Waste App

A mobile marketplace that connects university-area bakeries and cafes with nearby users to sell end-of-day surplus food at a discount. Pickup only, no delivery.

## Tech Stack

Flutter · Dart · Supabase (Postgres + Auth + RLS + Storage) · Riverpod · GoRouter · Google Maps

## Architecture

Feature-first folder structure with repository pattern. UI ↔ Provider ↔ Repository ↔ Supabase. Full details in `docs/ARCHITECTURE.md`.

## Current Status

**MVP in progress** — 6-week sprint (April–May 2026), Istanbul University Software Engineering course.

Implemented so far:
- Authentication (email signup/login, role-based: user & business)
- KVKK consent flow (Turkish data protection compliance)
- Home screen with product listing, category filtering, live countdown
- Product detail page with reservation flow
- Order management (create, cancel, status tracking)
- Business dashboard, product CRUD, order approval/rejection
- Impact tracking (kg saved, CO₂ prevented, money saved)

Not yet implemented: map view, push notifications, in-app payment, search, reviews.

## Team

Built as a 4-person team project for Istanbul University Software Engineering course. This is my personal development branch.
