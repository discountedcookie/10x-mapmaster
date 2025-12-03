# Tool Usage Rules

These rules apply to every agent and subagent.

## File Operations

You have dedicated tools for file operations. Use them:

| Task | Tool | NOT bash |
|------|------|----------|
| Read file contents | `Read` | ~~cat, head, tail~~ |
| List directory | `List` | ~~ls, find -type d~~ |
| Find files by pattern | `Glob` | ~~find, ls~~ |
| Search file contents | `Grep` | ~~grep, rg~~ |

These bash commands are DENIED and will fail: `cat`, `ls`, `find`, `grep`

## Allowed Bash Commands

Bash is permitted ONLY for:

- **Scripts**: `bun run *`
- **Database**: `supabase *`, `psql *`
- **Git**: `git *`
- **OpenSpec**: `openspec *`
- **Output filtering**: `head`, `tail`, `wc` (when piping from allowed commands)

Check your agent's `permission.bash` configuration for the specific allowlist.

## Why This Matters

Using denied commands wastes tokens and time. The dedicated tools are:
- Faster (no shell overhead)
- Safer (no injection risks)
- Integrated (results formatted for context)
