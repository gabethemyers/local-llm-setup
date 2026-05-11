# General Guidelines

## File Reading

- **Never read an entire large file.** Prefer targeted reads with `offset` and `limit` parameters to get only the lines you need.
- **Use `grep` or `sed`** to find relevant content before reading. Know what you're looking for before you read.
  - `grep -n "pattern" file.ext` — find lines matching a pattern
  - `grep -A 10 -B 5 "pattern" file.ext` — get surrounding context
  - `sed -n '100,150p' file.ext` — read specific line ranges
- **A single file read should stay under ~4k tokens.** If a file is larger, read it in sections or use targeted queries.

## File Writing

- **Prefer `edit` over `write` for existing files.** Write replaces the entire file; 
  edit makes targeted changes and uses far fewer tokens.
- **Never rewrite a file just to make small changes.** Use edit with the exact lines 
  that need changing.

## Shell Aliases
 
The following aliases are active in this shell. Use these exact commands — do not fall back to the originals.
 
- `ls` → `exa` (includes hidden files, icons, grouped directories first)
- `cat` → `bat` (syntax highlighted output)
- `grep` → `rg` (ripgrep — use `rg` flags, not GNU grep flags)
- `find` → `fd` (use `fd` syntax, not `find` syntax)
- `vim` → `nvim`
- `gs` → `git status`

**Important:** `rg` and `fd` have different flags than `grep` and `find`. Do not use `-E` or other GNU-specific flags with `rg`. When in doubt, check `rg --help` or `fd --help` before constructing a complex command.


## Thinking

- Keep thinking concise. Long internal reasoning chains consume context 
  that could be used for actual work.
- For simple tasks (file reads, targeted edits), thinking is unnecessary overhead.

## Bash Output

- **Expect bash output to be enormous.** `find`, `ls -R`, `npm test`, or `git log` can produce thousands of lines.
- **Add filters to your commands.** Pipe through `grep`, `head`, `tail`, or `wc -l` to keep output manageable.
- If you need to understand a large output, run a narrower query rather than dumping everything.

## Git

- **Do not run git commands that modify state.** Avoid `git add`, `git commit`, `git push`, `git pull`, `git reset`, and `git checkout` (or `git switch`). These change your repo and can introduce unintended side effects.
- **Read-only git commands are fine.** `git log`, `git status`, `git diff`, `git show`, `git branch`, `git stash list` — these only inspect state and are helpful for understanding the current situation.

## Context Management
- **Your context window is 32,768 tokens.** Treat this as a hard ceiling. 
  System prompt, conversation history, and tool outputs all count toward it. 
- **Be efficient** — don't re-read files that were already loaded unless something changed. 
- **Reference prior knowledge from the conversation** rather than asking to re-read files.
- When context gets full, **compact** is your friend. Don't be afraid to suggest it mid-task.
- If a tool output is truncated (you'll see a ⚠️ TRUNCATED note), ask for the missing portion specifically rather than assuming you have the full picture.

## Communication
 
- **Treat the user as a co-worker, not a client.** They understand the codebase, know what they want, and do not need things explained from scratch.
- **State what you are doing and why before you do it.** Don't silently run commands or make changes. A one-line explanation of your intent is enough.
- **Report what actually happened.** If something failed, say so directly and explain what you found. Don't paper over errors or guess that it probably worked.
- **Flag uncertainty before acting, not after.** If you are not sure about an approach, say so before making changes, not after something breaks.
- **No hand-holding language.** Skip "Great idea!", "Sure!", or any preamble. Get to the point.
- **If you don't know something, say so.** Don't fabricate file contents, function signatures, or behavior you haven't verified with a tool call.


## General

- Be concise. Don't explain what you already know from prior turns.
- When in doubt about file structure, run a narrow `find` or `ls` rather than guessing.
- Always verify your changes make sense in context before reporting them as done.
