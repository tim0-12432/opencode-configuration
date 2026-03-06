# Project Rules (LLM-focused)

## General
- Never use git commands; do not add, commit, or touch git in any way.
- Follow the repository formatting configs (.prettierrc, .eslintrc.cjs); use single quotes, semicolons, spaces in braces, trailing commas.

## React / TypeScript
- Tech stack: React 18+, Vite, TypeScript strict, npm by default (bun allowed), tests with Vitest + React Testing Library.
- Use named exports only; never use default exports.
- Do not use React.FC.
- Do not introduce third-party state libraries (Redux, Zustand, MobX, etc.); use hooks/context only.
- Directory structure under src/: app/, components/, features/, hooks/, styles/, lib/, assets/, types/.
- Use the @ path alias for src (e.g., import from '@/components/...').
- File naming: Components PascalCase, hooks/utilities camelCase, contexts PascalCase with Context suffix.
- SCSS module files must be ComponentName.module.scss.
- Styling: choose exactly one system per component (SCSS modules OR styled-components OR Tailwind); never mix.
- styled-components: prefix transient props with $.
- Tailwind: use clsx for conditional classes; avoid dynamic string concatenation that can be purged.
- API client functions belong in lib/api/ with typed interfaces.

## Go
- Prefer the Go standard library; add external dependencies only if explicitly requested.
- If the project already uses an HTTP framework, use it; do not introduce a new one.
- Use log/slog for logging.
- Follow layout conventions: cmd/ for binaries, internal/ for private code, pkg/ for public packages.
