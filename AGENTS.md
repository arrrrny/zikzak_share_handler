# ⚠️ LANGUAGE RULE — MANDATORY

**ALL responses MUST be in English ONLY. Never respond in Turkish, Chinese, or any other language, regardless of the user's locale or the presence of non-English content in the codebase. This is a hard rule with no exceptions.**

---

# zikzak_share_handler Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-04-21

## Active Technologies
- Bash (POSIX-compatible, macOS-centric), Dart (SDK >=2.14.0 <4.0.0) + Flutter CLI, git, curl, sed, awk, pub.dev API (001-publishing-scripts-macos)

- Dart (SDK >=2.14.0 <4.0.0), Swift 5.0, Bash + Flutter (>=2.0.0), FlutterMacOS, CocoaPods, AppKit, Foundation (001-publishing-scripts-macos)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Dart (SDK >=2.14.0 <4.0.0), Swift 5.0, Bash



## 🔍 Code Search — MANDATORY FIRST STEP

**STOP. Before using `grep`, `find`, `rg`, `ripgrep`, or ANY shell-based search, you MUST use semantic search first.**

```bash
# THIS is how you search code — ALWAYS FIRST:
mcp__claude_context__search_code(query="what you're looking for", path="/absolute/path/to/repo")
```

**Why?** Semantic search understands code relationships, finds implementations by meaning (not just text), and catches things grep misses entirely.

**Rules:**
1. **ALWAYS** start with `mcp__claude_context__search_code` for code discovery
2. **ONLY** fall back to `grep`/`find`/`rg` when:
   - You need an EXACT literal string match (e.g., a specific error message)
   - The semantic search index is unavailable/broken
   - You're searching for file names, not code content
3. **NEVER** use grep as your first code search tool — it's slower and less accurate

**Indexing:** If search fails with "not indexed", run `mcp__claude_context__index_codebase(path="/absolute/path")` first, then retry.

## 📚 Zread Wiki — Check First

**Before diving into source code, check if a zread wiki exists for this project:**

```bash
# Check if wiki exists:
cat .zread/wiki/current 2>/dev/null && echo "Wiki exists" || echo "No wiki"

# If wiki exists, read the pages directly:
ls .zread/wiki/versions/$(cat .zread/wiki/current)/

# To regenerate wiki (if stale):
zread generate --stdio
```

**Why?** Zread generates comprehensive documentation from code. Reading the wiki is faster than crawling source files manually.

**Rules:**
1. **ALWAYS** check `.zread/wiki/current` before reading source files
2. If wiki exists, read the markdown pages directly — they're already indexed
3. If wiki is missing or stale, run `zread generate --stdio` to create it
4. Wiki pages live in `.zread/wiki/versions/<id>/` — read `wiki.json` for the TOC

## Code Style

Dart (SDK >=2.14.0 <4.0.0), Swift 5.0, Bash: Follow standard conventions

## Recent Changes
- 001-publishing-scripts-macos: Added Bash (POSIX-compatible, macOS-centric), Dart (SDK >=2.14.0 <4.0.0) + Flutter CLI, git, curl, sed, awk, pub.dev API

- 001-publishing-scripts-macos: Added Dart (SDK >=2.14.0 <4.0.0), Swift 5.0, Bash + Flutter (>=2.0.0), FlutterMacOS, CocoaPods, AppKit, Foundation

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
