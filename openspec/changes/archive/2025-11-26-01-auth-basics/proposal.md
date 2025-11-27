# Change: Add Auth Basics

## Why

Establish auth assumptions (anonymous vs registered), roles, and security posture so all RLS and SECURITY DEFINER rules have a clear baseline.

## What Changes

- Define auth model and roles used by the database (anon, authenticated, service_role)
- Document SECURITY DEFINER guardrails and search_path requirements
- Specify RLS posture for user-owned vs public data

## Impact

- Affected specs: database
- Affected code: policy conventions, SECURITY DEFINER templates, documentation in schema/README
