## v0.2.0 (2023-04-14)

This release includes changes to policies created by `create_policy`. Migrations that have already been performed will not be affected, so it is safe to upgrade as-is, but for performance reasons it is recommended to update existing policies to the new format. See https://github.com/kufu/activerecord-tenant-level-security/pull/16 for details.

### Breaking Changes

- [#16](https://github.com/kufu/activerecord-tenant-level-security/pull/16): Cast `current_setting` instead of `tenant_id`
- [#17](https://github.com/kufu/activerecord-tenant-level-security/pull/17): CI against Ruby 3.2 and PostgreSQL 15, drop Ruby 2.7

### Chores

- [#13](https://github.com/kufu/activerecord-tenant-level-security/pull/13): Mention multiple databases support status
- [#15](https://github.com/kufu/activerecord-tenant-level-security/pull/15): Update License and CoC files

## v0.1.0 (2023-01-23)

### BugFixes

- [#12](https://github.com/kufu/activerecord-tenant-level-security/pull/12): Clear query cache after switching

### Chores

- [#8](https://github.com/kufu/activerecord-tenant-level-security/pull/8): Project tweaks
- [#9](https://github.com/kufu/activerecord-tenant-level-security/pull/9): fix email
- [#10](https://github.com/kufu/activerecord-tenant-level-security/pull/10): CI against Rails 7.0/Ruby 3.1/PostgreSQL 14
- [#11](https://github.com/kufu/activerecord-tenant-level-security/pull/11): Fix typos in README.md

## v0.0.1 (2021-11-10)

Initial release 🥳
