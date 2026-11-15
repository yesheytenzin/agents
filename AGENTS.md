<!-- SINGLE SOURCE OF TRUTH: ~/.agents/AGENTS.md — edit only here. -->
<!-- ~/AGENTS.md, ~/.codex/AGENTS.md, ~/.claude/CLAUDE.md, -->
<!-- ~/.config/opencode/AGENTS.md are all symlinks to this file. -->
<!-- Installed by ~/.agents/install.sh (re-run to re-link). -->

# Global — Agent Guidelines

## Git identity — every repo, every commit

Every commit you create, in any repo you have access to, MUST be authored and
committed as `yesheytenzin <yesheytenzin09@gmail.com>`.

- Before the first commit in a repo, check `git config user.name` and
  `git config user.email`. If either is missing or different from the values
  above, fix it repo-locally:

  ```bash
  git config user.name yesheytenzin
  git config user.email yesheytenzin09@gmail.com
  ```

- **Never** author with `tenzin@users.noreply.github.com`. That address is linked
  to a different GitHub account (github.com/tenzin), so every commit using it is
  attributed to that stranger instead of you. If an email must not be public, use
  the correctly linked noreply form: `133156653+yesheytenzin@users.noreply.github.com`.
- Never override identity per commit: no `git -c user.email=…`, and no
  `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_EMAIL`, `GIT_AUTHOR_NAME`, or
  `GIT_COMMITTER_NAME` environment variables.
- Before pushing, verify with `git log -1 --format='%an <%ae>'` — it must print
  `yesheytenzin <yesheytenzin09@gmail.com>`. If it does not, fix the config and
  amend the commit before it is pushed.

## Rails Projects — Always generate migrations with the generator

Never hand-write a migration file. Always run the generator so the timestamp,
class name, and versioned migration are correct:

```bash
rails g migration AddStatusToOrders status:string
rails g migration CreateOrderItems order:references name:string
rails g migration RemoveLegacyFlagFromUsers legacy_flag:boolean
```

- Use `rails g migration <Name> <column>:<type>` and Rails names/timestamps the file.
- `rails g model ...` / `rails g scaffold ...` are fine too — they already emit a migration.
- Only edit a generated migration afterward to add details (indexes, `null: false`,
  defaults, data backfills) that the generator arguments cannot express.
- Never invent a filename like `db/migrate/20250101000000_add_x.rb` by hand.

## Rails Projects — No inline Rubocop disables

Never add inline `# rubocop:disable ...` / `# rubocop:enable ...` comments. Fix
the underlying code, or adjust `.rubocop.yml`, instead of silencing a cop inline.

## Rails Projects — Use shoulda-matchers for tests

Use the `shoulda-matchers` gem for model/controller test assertions (validations,
associations, etc.) instead of hand-writing equivalent matchers.
