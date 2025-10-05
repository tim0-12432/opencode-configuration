# Project Rules

## Coding Rules

### React

#### 1) Conventions

- Language: TypeScript (strict mode).
- Framework: React 18+ with Vite.
- Package manager: npm by default; bun optionally.
- Exports: Prefer named exports; avoid default exports unless there is exactly one clear primary entity in the file.
- File naming:
  - Components: PascalCase (e.g., Button.tsx).
  - Hooks/Utilities: camelCase (e.g., useLocalStorage.ts, formatDate.ts).
  - Contexts: PascalCase with "Context" suffix (e.g., ThemeContext.tsx).
- Styles (depending on the project):
  - SCSS modules: ComponentName.module.scss
  - styled-components: co-located in the component file or a ComponentName.styled.ts file.
  - TailwindCSS
- Directories (depending on the project):
  - src/
    - app/ (App.tsx, providers, routes)
    - components/ (reusable UI)
    - features/ (feature-specific components, contexts, hooks)
    - hooks/
    - styles/
    - lib/ (utilities/helpers)
    - assets/
    - types/ (global or shared types)

Keep modules cohesive; avoid "god" folders.

#### 2) TypeScript Code Style

- Quotes: single quotes.
- Object imports: spaces in curly braces → import { useState } from 'react';
- Semicolons: always end lines with semicolons.
- Avoid React.FC except when you explicitly need the implicit typing of children or displayName. - Prefer explicit props typing.
- Always type props and state; never rely on implicit any.
- Use React types where applicable:
- ReactNode for renderable children.
- ChangeEvent<HTMLInputElement>, MouseEvent<HTMLButtonElement>, etc. for event types.
- ComponentProps<'button'> to extend intrinsic element props.

- Prefer const over let. Avoid var.
- Use unions, generics, and discriminated unions for robust modeling (especially for reducers).
- Narrow types with type guards; avoid non-null assertions unless absolutely safe.

Example component props typing:

```typescript
import { ReactNode } from 'react';

type CardProps = {
  title: string;
  children?: ReactNode;
  onClose?: () => void;
};

export function Card({ title, children, onClose }: CardProps) {
  return (
    <section aria-label={title}>
      <header>
        <h2>{title}</h2>
        {onClose && (
          <button type="button" onClick={onClose} aria-label="Close">
            ×
          </button>
        )}
      </header>
      <div>{children}</div>
    </section>
  );
}
```

Forwarding refs with generics:

```typescript
import { forwardRef, ComponentPropsWithoutRef } from 'react';

type InputProps = ComponentPropsWithoutRef<'input'> & {
  label: string;
};

export const LabeledInput = forwardRef<HTMLInputElement, InputProps>(
  function LabeledInput({ label, id, ...props }, ref) {
    const inputId = id ?? `input-${Math.random().toString(36).slice(2)}`;
    return (
      <label htmlFor={inputId}>
        <span>{label}</span>
        <input id={inputId} ref={ref} {...props} />
      </label>
    );
  }
);
```

#### 3) Vite + Tooling

Initialize with Vite React + TS:
- npm: `npm create vite@latest my-app -- --template react-ts`
- bun: `bun create vite my-app --template react-ts`

Scripts (package.json):
- "dev": "vite"
- "build": "tsc -b && vite build"
- "preview": "vite preview"
- "typecheck": "tsc --noEmit"


Configure path alias @ → src:

tsconfig.json
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    }
  }
}
```

vite.config.ts
```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src')
    }
  }
});
```

Environment variables:
Use VITE_ prefix (e.g., VITE_API_URL).
Access via import.meta.env.VITE_API_URL (type-safe via vite/client types).

Declarations for assets and SCSS modules (if needed):

```typescript
// src/types/modules.d.ts
declare module '*.module.scss' {
  const classes: { [key: string]: string };
  export default classes;
}
declare module '*.svg' {
  import { FC, SVGProps } from 'react';
  const Component: FC<SVGProps<SVGSVGElement>>;
  export default Component;
}
```

#### 4) ESLint + Prettier

ESLint presets: eslint:recommended, @typescript-eslint, react, react-hooks, jsx-a11y, import.
Prettier for formatting with preferred style.
Example .prettierrc:

```json
{
  "singleQuote": true,
  "semi": true,
  "bracketSpacing": true,
  "trailingComma": "all",
  "printWidth": 100,
  "endOfLine": "lf",
  "arrowParens": "always"
}
```

Example .eslintrc.cjs (minimal):

```javascript
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  plugins: ['@typescript-eslint', 'react', 'react-hooks', 'jsx-a11y', 'import'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'plugin:jsx-a11y/recommended',
    'plugin:import/recommended',
    'plugin:import/typescript',
    'prettier'
  ],
  settings: {
    react: { version: 'detect' },
    'import/resolver': {
      typescript: true
    }
  },
  rules: {
    'react/react-in-jsx-scope': 'off',
    'import/order': [
      'warn',
      {
        groups: ['builtin', 'external', 'internal', ['parent', 'sibling', 'index']],
        'newlines-between': 'always',
        alphabetize: { order: 'asc', caseInsensitive: true }
      }
    ],
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }]
  }
};
```

#### 5) Components and Composition

- Small, focused components. Composition over inheritance.
- Avoid deeply nested prop drilling; use Context for cross-cutting concerns.
- Prefer controlled components for forms; use uncontrolled only for performance or simple cases.
- Keys: stable, unique keys for lists (use ids, not indexes, unless immutable/sorted).

Container + presentational example:

```typescript
// components/UserList.tsx (presentational)
type User = { id: string; name: string };

type UserListProps = {
  users: User[];
  onSelect: (id: string) => void;
};

export function UserList({ users, onSelect }: UserListProps) {
  return (
    <ul>
      {users.map((u) => (
        <li key={u.id}>
          <button type="button" onClick={() => onSelect(u.id)}>
            {u.name}
          </button>
        </li>
      ))}
    </ul>
  );
}

// features/users/UsersContainer.tsx (container)
import { useEffect, useState } from 'react';
import { UserList } from '@/components/UserList';

export function UsersContainer() {
  const [users, setUsers] = useState<{ id: string; name: string }[]>([]);

  useEffect(() => {
    const ctrl = new AbortController();
    (async () => {
      const res = await fetch('/api/users', { signal: ctrl.signal });
      const data = (await res.json()) as { id: string; name: string }[];
      setUsers(data);
    })().catch((e) => {
      if (e.name !== 'AbortError') console.error(e);
    });
    return () => ctrl.abort();
  }, []);

  return <UserList users={users} onSelect={(id) => console.log('select', id)} />;
}
```

#### 6) State Management via Hooks and Context

- Local state with useState/useReducer.
- Cross-cutting state with Context + custom hooks. Avoid third-party state libraries.
- Pattern: context with undefined default + safe hook.

Example: Auth context with reducer

```typescript
// features/auth/authTypes.ts
export type User = { id: string; email: string };

// features/auth/AuthContext.tsx
import { createContext, useContext, useReducer, ReactNode } from 'react';
import type { User } from './authTypes';

type AuthState = { user: User | null; loading: boolean; error?: string };
type AuthAction =
  | { type: 'LOGIN_START' }
  | { type: 'LOGIN_SUCCESS'; payload: User }
  | { type: 'LOGOUT' }
  | { type: 'ERROR'; payload: string };

function authReducer(state: AuthState, action: AuthAction): AuthState {
  switch (action.type) {
    case 'LOGIN_START':
      return { ...state, loading: true, error: undefined };
    case 'LOGIN_SUCCESS':
      return { user: action.payload, loading: false };
    case 'LOGOUT':
      return { user: null, loading: false };
    case 'ERROR':
      return { ...state, loading: false, error: action.payload };
    default:
      // exhaustive check
      const _exhaustive: never = action;
      return state;
  }
}

type AuthContextValue = {
  state: AuthState;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(authReducer, { user: null, loading: false });

  async function login(email: string, password: string) {
    dispatch({ type: 'LOGIN_START' });
    try {
      const res = await fetch('/api/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });
      if (!res.ok) throw new Error('Login failed');
      const user = (await res.json()) as User;
      dispatch({ type: 'LOGIN_SUCCESS', payload: user });
    } catch (e) {
      dispatch({ type: 'ERROR', payload: e instanceof Error ? e.message : 'Unknown error' });
    }
  }

  function logout() {
    dispatch({ type: 'LOGOUT' });
  }

  return (
    <AuthContext.Provider value={{ state, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return ctx;
}
```

Usage:

```typescript
import { useAuth } from '@/features/auth/AuthContext';

export function ProfileButton() {
  const { state, logout } = useAuth();
  if (state.loading) return <span>Loading...</span>;
  if (!state.user) return <a href="/login">Login</a>;
  return (
    <button type="button" onClick={logout}>
      Logout {state.user.email}
    </button>
  );
}
```

#### 7) Data Fetching and Effects

- Use fetch with async/await; handle errors and abort on unmount.
- Never update state after unmount; use AbortController or a mounted flag ref.
- Isolate fetching logic in custom hooks for reuse.
- Debounce expensive effects; memoize stable dependencies.

Custom hook example:

```typescript
import { useEffect, useRef, useState } from 'react';

export function useFetchJson<T>(url: string, deps: unknown[] = []) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const mounted = useRef(true);

  useEffect(() => {
    mounted.current = true;
    const ctrl = new AbortController();
    setLoading(true);
    (async () => {
      try {
        const res = await fetch(url, { signal: ctrl.signal });
        if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
        const json = (await res.json()) as T;
        if (mounted.current) setData(json);
      } catch (e) {
        if ((e as Error).name !== 'AbortError' && mounted.current) {
          setError(e instanceof Error ? e.message : 'Unknown error');
        }
      } finally {
        if (mounted.current) setLoading(false);
      }
    })();
    return () => {
      mounted.current = false;
      ctrl.abort();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);

  return { data, error, loading };
}
```

#### 8) Performance

- useMemo for expensive computed values (not for primitive props).
- useCallback for stable function identity when passed to children that memoize.
- React.memo for pure presentational components with stable props.
- Avoid anonymous components or styled components inside render loops; hoist them.

Example:

```typescript
import { memo, useMemo } from 'react';

type ListProps = { items: number[] };

const ListItem = memo(function ListItem({ value }: { value: number }) {
  return <li>{value}</li>;
});

export function SortedList({ items }: ListProps) {
  const sorted = useMemo(() => [...items].sort((a, b) => a - b), [items]);
  return (
    <ul>
      {sorted.map((n) => (
        <ListItem key={n} value={n} />
      ))}
    </ul>
  );
}
```

#### 9) Error Boundaries and Suspense

- Use error boundaries to catch render lifecycle errors in subtree.
- Lazy-load large feature modules with React.lazy and Suspense.

Error boundary:

```typescript
import { Component, ReactNode } from 'react';

type ErrorBoundaryProps = { children: ReactNode; fallback?: ReactNode };
type ErrorBoundaryState = { hasError: boolean };

export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  state: ErrorBoundaryState = { hasError: false };
  static getDerivedStateFromError() {
    return { hasError: true };
  }
  componentDidCatch(error: unknown) {
    console.error(error);
  }
  render() {
    if (this.state.hasError) return this.props.fallback ?? <p>Something went wrong.</p>;
    return this.props.children;
  }
}
```

Lazy loading:

```typescript
import { Suspense, lazy } from 'react';

const HeavyFeature = lazy(() => import('@/features/heavy/HeavyFeature'));

export function RouteHeavy() {
  return (
    <Suspense fallback={<p>Loading...</p>}>
      <HeavyFeature />
    </Suspense>
  );
}
```

#### 10) Forms

- Prefer controlled inputs for validation/instant feedback.
- Always prevent default on submit; type events precisely.
- Use HTML semantics and associate labels.

Example:

```typescript
import { FormEvent, useState } from 'react';

type LoginFormValues = { email: string; password: string };

export function LoginForm({ onSubmit }: { onSubmit: (v: LoginFormValues) => void }) {
  const [values, setValues] = useState<LoginFormValues>({ email: '', password: '' });

  function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    onSubmit(values);
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <label>
        Email
        <input
          type="email"
          value={values.email}
          onChange={(e) => setValues((v) => ({ ...v, email: e.target.value }))}
          required
        />
      </label>

      <label>
        Password
        <input
          type="password"
          value={values.password}
          onChange={(e) => setValues((v) => ({ ...v, password: e.target.value }))}
          required
          minLength={8}
        />
      </label>

      <button type="submit">Login</button>
    </form>
  );
}
```

#### 11) Routing (optional, if using react-router)

- Co-locate route components under app/routes/.
- Use lazy routes for larger sections.
- Keep loaders/actions minimal; prefer hooks and context for shared state.

#### 12) Styling Options

- You can use ANY of the following per component. Do not mix multiple systems in the same component unless necessary.

##### 12.1) SCSS Modules

- File: ComponentName.module.scss with local class names.
- Import as styles and use styles.className.

Example:

```scss
/* Button.module.scss */
.root {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  border-radius: 0.375rem;
  background: #111827;
  color: #fff;
  border: none;
  cursor: pointer;
}
.ghost {
  background: transparent;
  color: #111827;
  border: 1px solid #111827;
}
```
```typescript
// Button.tsx
import styles from './Button.module.scss';

type ButtonProps = {
  variant?: 'solid' | 'ghost';
} & React.ComponentProps<'button'>;

export function Button({ variant = 'solid', className, ...props }: ButtonProps) {
  const cls = [styles.root, variant === 'ghost' ? styles.ghost : null, className]
    .filter(Boolean)
    .join(' ');
  return <button className={cls} {...props} />;
}
```

##### 12.2) styled-components

- Keep styled definitions at module scope; do not create inside render.
- Prefer theme via ThemeProvider with typed DefaultTheme.

Example:

```typescript
// styles/theme.ts
export const theme = {
  colors: {
    primary: '#111827',
    textOnPrimary: '#ffffff'
  },
  radius: '6px'
};
export type AppTheme = typeof theme;
// styles/styled.d.ts
import 'styled-components';
import type { AppTheme } from './theme';

declare module 'styled-components' {
  export interface DefaultTheme extends AppTheme {}
}
// components/Button.tsx
import styled from 'styled-components';

const Root = styled.button<{ $variant: 'solid' | 'ghost' }>`
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.75rem;
  border-radius: ${({ theme }) => theme.radius};
  background: ${({ $variant, theme }) => ($variant === 'solid' ? theme.colors.primary : 'transparent')};
  color: ${({ $variant, theme }) => ($variant === 'solid' ? theme.colors.textOnPrimary : theme.colors.primary)};
  border: ${({ $variant, theme }) => ($variant === 'ghost' ? `1px solid ${theme.colors.primary}` : 'none')};
`;

type ButtonProps = React.ComponentProps<'button'> & { variant?: 'solid' | 'ghost' };

export function Button({ variant = 'solid', ...props }: ButtonProps) {
  return <Root $variant={variant} {...props} />;
}
```

Usage with provider:

```typescript
import { ThemeProvider } from 'styled-components';
import { theme } from '@/styles/theme';

export function AppProviders({ children }: { children: React.ReactNode }) {
  return <ThemeProvider theme={theme}>{children}</ThemeProvider>;
}
```

##### 12.3) TailwindCSS

- Use className strings; compose with clsx if needed (no dynamic string building that could be purged incorrectly).
- Keep class order logical; avoid inline style objects unless necessary.

Example:

```typescript
import clsx from 'clsx';

type ButtonProps = React.ComponentProps<'button'> & { variant?: 'solid' | 'ghost' };

export function Button({ className, variant = 'solid', ...props }: ButtonProps) {
  const base = 'inline-flex items-center gap-2 px-3 py-2 rounded-md';
  const solid = 'bg-gray-900 text-white';
  const ghost = 'border border-gray-900 text-gray-900';
  return (
    <button
      className={clsx(base, variant === 'solid' ? solid : ghost, className)}
      {...props}
    />
  );
}
```

#### 13) Accessibility (a11y)

- Every interactive element uses a native semantic element (button, a, input).
- Always label form elements; use aria-label only when no visible label.
- Manage focus on dialogs/menus; trap focus as needed.
- Color contrast AA minimum; don’t rely solely on color to convey meaning.
- Keyboard interactions: Enter/Space for buttons, Escape to close modals, Arrow keys for lists/menus.

#### 14) Testing (Vitest + React Testing Library)

- Test public behavior, not internals.
- Prefer queries by role and name; avoid testIDs unless necessary.
- Keep tests colocated: ComponentName.test.tsx.

Example:

```typescript
// Button.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from './Button';

test('calls onClick when clicked', async () => {
  const user = userEvent.setup();
  const onClick = vi.fn();
  render(<Button onClick={onClick}>Click</Button>);
  await user.click(screen.getByRole('button', { name: /click/i }));
  expect(onClick).toHaveBeenCalledTimes(1);
});
```

#### 15) API Layer and Types

- Centralize API clients in lib/api/ with typed functions.
- Create DTO types and map to domain types if API differs.
- Handle errors gracefully; return Result-like types or throw typed errors.

Example:

```typescript
// lib/api/users.ts
export type UserDTO = { id: string; name: string };

export async function fetchUsers(signal?: AbortSignal): Promise<UserDTO[]> {
  const res = await fetch('/api/users', { signal });
  if (!res.ok) throw new Error(`Failed: ${res.status}`);
  return (await res.json()) as UserDTO[];
}
```

#### 16) Internationalization (optional)

If needed, keep strings in a messages file; pass via context or use a small i18n helper. Avoid introducing heavy libraries unless justified.

#### 17) Logging and Error Handling

- Use console.error for unexpected errors; consider a lightweight log utility in production.
- Never swallow errors silently; surface via UI when actionable.
- For async handlers in components, surround with try/catch and reflect loading states.

#### 18) Output Rules and Checklist

When generating code, strictly follow:
- Imports/exports:
  - Use named exports.
  - Remove unused imports and variables.
- Formatting:
  - Use single quotes, spaces in curly braces, semicolons.
- Types:
  - No implicit any. Type all props, function returns when not obvious.
  - Use correct React event types and HTML attribute types.
- Hooks:
  - Respect the Rules of Hooks. Do not call hooks conditionally or in loops.
  - Include full dependency arrays; justify intentional omissions with a comment.
- Async:
  - Use try/catch for async actions that may fail.
  - Abort network requests on unmount.
- Accessibility:
  - Use semantic elements, proper labels, and roles.
- Styling:
  - Choose ONE system per component (SCSS module, styled-components, or Tailwind).
  - For Tailwind, do not generate dynamic arbitrary class names at runtime; use clsx for conditional classes.
  - For styled-components, hoist styled() calls to module scope and prefix transient props with $ (e.g., $variant).
- Structure:
  - Keep components small (< ~200 lines when possible).
  - Extract reusable logic to hooks/utilities.
- Tests:
  - For non-trivial components, add a minimal test demonstrating key behavior.

Pre-submit checklist:
- All code compiles (TypeScript) and runs under Vite.
- No ESLint errors for react, hooks, typescript.
- Props and events are correctly typed.
- No direct DOM manipulation unless using refs appropriately.
- No unnecessary re-renders from unstable callbacks.
- Keys are stable in lists.
- Side effects are cleaned up.

#### 19) npm and bun Commands

Install dependencies:
- npm: npm i
- bun: bun install

Dev server:
- npm: npm run dev
- bun: bun run dev

Build:
- npm: npm run build
- bun: bun run build

#### 20) Common Type Recipes

Merging intrinsic props:

```typescript
type PolymorphicButtonProps<E extends React.ElementType = 'button'> = {
  as?: E;
  variant?: 'solid' | 'ghost';
} & Omit<React.ComponentProps<E>, 'as'>;
```

Discriminated unions:

```typescript
type Shape =
  | { kind: 'circle'; radius: number }
  | { kind: 'square'; size: number };

function area(s: Shape): number {
  switch (s.kind) {
    case 'circle':
      return Math.PI * s.radius ** 2;
    case 'square':
      return s.size * s.size;
    default:
      const _x: never = s;
      return _x;
  }
}
```

Utility types:

```typescript
type WithId<T> = T & { id: string };
type Nullable<T> = T | null;
```

### Go

#### 0) How to use this guide (LLM operating instructions)

- Prefer the Go standard library. Do not add dependencies unless the user explicitly asks or a dependency is clearly justified.
- Always produce compilable code with package + imports + a main or exported API. Run mental "go build" and "go test" checks.
- Format with gofmt and organize imports. Avoid unused imports, variables, and functions.
- Include brief doc comments for exported identifiers. Add a short README or usage block when creating CLIs or services.
- Provide minimal, focused examples and table-driven tests for public functions.
- Default to Go 1.21–1.22+ idioms. If behavior differs by version (e.g., range loop variable capture changed in Go 1.22), write code that is safe across versions, or call it out.

#### 1) Project structure and modules

One module per repository unless you truly need multi-module.
Layout:
- CLI app: cmd/appname/main.go, internal logic in internal/ or pkg/.
- Library: code in package directories under . or pkg/; internal-only helpers in internal/.
- Tests colocated as *_test.go.

Initialize and manage modules:
- go mod init example.com/owner/repo
- Use semantic import versions for v2+: module example.com/owner/repo/v2.
- Avoid replace except for local development.
- Pin versions with go get and commit go.mod and go.sum.

Example tree:
- repo/
  - cmd/tool/main.go
  - internal/parse/parse.go
  - pkg/formatter/formatter.go
  - go.mod

#### 2) Naming, style, and formatting

Run gofmt and go vet. Prefer staticcheck if allowed.
MixedCaps for identifiers. Exported names are capitalized; keep package names lowercase, short, and no underscores.
Avoid stutter: if package is bytes, type is Buffer (not BytesBuffer).
Keep functions short; split after ~40–60 lines if doing multiple things.
Order in files: types, vars/consts, constructors, methods, helpers.
Comments:
- Package comment at top: `// Package foo ...`
- Exported names: `// Name ... full sentence.`
- Explain why, not what.

#### 3) Imports and dependencies

Standard library first, blank line, then external deps.
Don’t import what you don’t use.
Avoid heavy deps for small tasks; prefer stdlib (net/http, encoding/json, slices, maps, log/slog, context).
If an external lib is required, surface rationale and version pinning.

#### 4) Packages and API design

Keep packages focused. Limit exported surface area.
Small interfaces, defined by consumers:
Good: `type Reader interface { Read(p []byte) (int, error) }`
Avoid "god interfaces" with many methods.

Return concrete types; accept interfaces.
Constructor pattern:
- NewType(opts ...Option) (*Type, error) when validation is needed.
- Validate inputs; return errors early.

Example (functional options):
```go
type Server struct {
  addr string
  log  *slog.Logger
}

type Option func(*Server)

func WithAddr(addr string) Option     { return func(s *Server) { s.addr = addr } }
func WithLogger(l *slog.Logger) Option { return func(s *Server) { s.log = l } }

func NewServer(opts ...Option) (*Server, error) {
  s := &Server{addr: ":8080", log: slog.Default()}
  for _, opt := range opts { opt(s) }
  if s.addr == "" { return nil, fmt.Errorf("addr must not be empty") }
  return s, nil
}
```

#### 5) Functions, methods, and receivers

Method receiver choice:
- Pointer receiver if the method mutates the receiver, the type is large, or you need interface method-set compatibility.
- Value receiver for small, immutable types.

Parameter order:
- context.Context first.
- Inputs next.
- Options struct last.

Return values:
- Return (T, error) (not *T) unless nil is a meaningful state.
- Prefer zero values over nil maps/slices when returning from functions? Return zero value; caller can check len.

Avoid panics. Return errors.

Pitfall guard: loop variable capture in goroutines.
```go
for i, v := range values {
  i, v := i, v // explicitly shadow to avoid capture bugs (safe even pre-Go 1.22)
  go func() { _ = i; _ = v }()
}
```

#### 6) Types, slices, maps, and zero values

Zero values should be usable. Design types so zero value "does something sensible".
Slices:
- Preallocate with capacity when known: make([]T, 0, n).
- Use append idiom; avoid re-slicing beyond capacity.
- Beware converting []byte ↔ string (allocations).

Maps:
- nil maps cannot be assigned to; make(map[K]V) before writes.
- Check presence with the "comma ok": v, ok := m[k].

Time:
- Always use time.Time in UTC for storage and APIs. Convert at boundaries (I/O, presentation).
- Use time.Duration for timeouts and intervals.

#### 7) Error handling (central rules)

Return errors, don’t panic. Use wrapping to preserve context.
Create package-level sentinel errors only when consumers need to check them:

```go
var ErrNotFound = errors.New("not found")
```

Wrap with %w to keep the cause:

```go
if err != nil {
  return fmt.Errorf("open config %q: %w", path, err)
}
```

Check with errors.Is/As:

```go
if errors.Is(err, os.ErrNotExist) { /* ... */ }
```

Don’t log and return the same error from library code; let callers decide. In CLIs or main, log.
Prefer context-rich messages; avoid leaking secrets.

#### 8) Context: cancellation, timeouts, deadlines

First parameter: ctx context.Context.
Respect cancellation in loops and goroutines with select:

```go
select {
case <-ctx.Done():
  return ctx.Err()
default:
}
```

Create timeouts at the edge:

```go
ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
defer cancel()
```

Don’t store contexts in structs. Pass through calls.

#### 9) Concurrency and channels

Prefer goroutines + channels or goroutines + mutexes based on problem shape. Keep it simple.
Never leak goroutines. Ensure a way to stop them (context or channel close).
Channel rules:
- Close channels only by the sender.
- Use buffered channels to avoid trivial deadlocks when appropriate.
- Use for v := range ch {} to receive until closed.

Worker pool pattern:

```go
type Task func(context.Context) error

func RunPool(ctx context.Context, n int, tasks <-chan Task) error {
  g, ctx := errgroup.WithContext(ctx)
  for i := 0; i < n; i++ {
    g.Go(func() error {
      for {
        select {
        case <-ctx.Done():
          return ctx.Err()
        case t, ok := <-tasks:
          if !ok { return nil }
          if err := t(ctx); err != nil { return err }
        }
      }
    })
  }
  return g.Wait()
}
```

Data races: guard shared state with sync.Mutex or use message passing.

#### 10) I/O and resource management

Always close resources. Pattern:

```go
f, err := os.Open(path)
if err != nil { return err }
defer func() { _ = f.Close() }()
```

For writers, check Close errors (e.g., bufio.Writer and file sync).
Use io.Copy for streaming.
Use defer immediately after successful acquire.

#### 11) HTTP clients and servers

> AWARE: if the project makes already use of another technique for http server e.g. gin, please use that and ignore the following section!

Server:
- Use http.Server with timeouts and graceful shutdown.
- Validate and limit inputs; set sane read/write timeouts.
- Use slog or structured logging with request IDs.

Example server skeleton:
```go
type App struct {
  log *slog.Logger
  srv *http.Server
}

func NewApp(addr string, log *slog.Logger) *App {
  mux := http.NewServeMux()
  mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(http.StatusOK)
    _, _ = w.Write([]byte(`{"status":"ok"}`))
  })
  return &App{
    log: log,
    srv: &http.Server{
      Addr:              addr,
      Handler:           mux,
      ReadHeaderTimeout: 5 * time.Second,
      ReadTimeout:       10 * time.Second,
      WriteTimeout:      15 * time.Second,
      IdleTimeout:       60 * time.Second,
    },
  }
}

func (a *App) Run(ctx context.Context) error {
  go func() {
    <-ctx.Done()
    shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    _ = a.srv.Shutdown(shutdownCtx)
  }()
  a.log.Info("listening", "addr", a.srv.Addr)
  err := a.srv.ListenAndServe()
  if errors.Is(err, http.ErrServerClosed) { return nil }
  return err
}
```

Client:
Reuse http.Client with timeouts via context or Transport:

```go
client := &http.Client{ Timeout: 10 * time.Second }
req, _ := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
res, err := client.Do(req)
```

Close response bodies: `defer res.Body.Close()`.
Limit body size with io.LimitReader.

#### 12) JSON and encoding

Use encoding/json or jsoniter if allowed; set struct tags.
Omit empty with omitempty. Use pointer fields to distinguish zero vs missing when needed.

```go
type User struct {
  ID    int64   `json:"id"`
  Name  string  `json:"name"`
  Email *string `json:"email,omitempty"`
}
```

Decoder safety: `dec.DisallowUnknownFields()` when strictness is desired.

#### 13) CLI programs

Use flag for simple CLIs; print -help.
Exit codes: `os.Exit(0)` on success, 1 on failure.
Write errors to stderr. Keep stdout for machine-readable output when applicable.

Minimal CLI template:
```go
func main() {
  log := slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: slog.LevelInfo}))
  var path string
  flag.StringVar(&path, "file", "", "path to input file (required)")
  flag.Parse()
  if path == "" {
    fmt.Fprintln(os.Stderr, "error: -file is required")
    flag.Usage()
    os.Exit(2)
  }
  if err := run(path, log); err != nil {
    log.Error("failed", "err", err)
    os.Exit(1)
  }
}

func run(path string, log *slog.Logger) error {
  // ...
  return nil
}
```

#### 14) Testing and examples

Use table-driven tests. Keep tests deterministic and parallelizable.
Place fixtures in testdata/.
Use t.Helper() in helpers. Use t.Cleanup to free resources.
For concurrency, use -race and timeouts.

Table-driven test example:
```go
func TestSum(t *testing.T) {
  t.Parallel()
  tests := []struct{
    name string
    in   []int
    want int
  }{
    {"empty", nil, 0},
    {"single", []int{2}, 2},
    {"many", []int{1,2,3}, 6},
  }
  for _, tc := range tests {
    tc := tc
    t.Run(tc.name, func(t *testing.T) {
      t.Parallel()
      got := Sum(tc.in...)
      if got != tc.want {
        t.Fatalf("got %d, want %d", got, tc.want)
      }
    })
  }
}
```

Example test for errors:

```go
if err == nil || !errors.Is(err, ErrNotFound) {
  t.Fatalf("expected ErrNotFound, got %v", err)
}
```

Add Example functions for docs:

```go
func ExampleSum() {
  fmt.Println(Sum(1,2,3))
  // Output: 6
}
```

#### 15) Logging and observability

Prefer log/slog for structured logs.
Include request IDs, user IDs, and key fields. Avoid logging secrets.
Log at edges; libraries should return errors instead of logging.

```go
log.Info("user_created", "id", id, "email", email)
```

#### 16) Performance guidelines

Measure with go test -bench and pprof. Don’t guess.
Reduce allocations:
- Use strings.Builder for string concatenation in loops.
- Pre-size slices and maps when size known.
- Avoid converting []byte⇄string repeatedly; cache when possible.

- Avoid copying large structs; pass pointers where appropriate.
- Use sync.Pool for high-churn, short-lived objects if profiling shows benefit.
- Avoid reflection unless necessary.

#### 17) Security basics

- Validate all inputs; define length limits and types.
- Use crypto/rand for secrets; math/rand only for non-crypto.
- Compare secrets with subtle.ConstantTimeCompare.
- Prevent path traversal: join and clean paths, then ensure prefix stays inside root.

HTTP:
- Set timeouts. Limit body size. Encode outputs safely.
- Add security headers where relevant.

SQL:
- Always use prepared statements or parameterized queries.
- Handle context timeouts and cancellations.

Don’t embed secrets in code. Use environment variables or secret stores.

#### 18) Databases (brief)

Open one sql.DB per process; it’s a pool. Configure limits:

```go
db.SetMaxOpenConns(10)
db.SetMaxIdleConns(10)
db.SetConnMaxLifetime(time.Hour)
```

Transactions:

```go
tx, err := db.BeginTx(ctx, nil)
if err != nil { return err }
defer func() {
  if err != nil { _ = tx.Rollback() } // err from outer scope
}()
if _, err = tx.ExecContext(ctx, "..."); err != nil { return err }
return tx.Commit()
```

Scan into well-typed structs; handle NULL with sql.Null* or pointers.

#### 19) Generics (keep it simple)

Use generics when it removes duplication or increases type-safety without complexity.
Avoid over-generalization. Prefer concrete types for domain logic.
Example:

```go
func Map[T any, U any](in []T, f func(T) U) []U {
  out := make([]U, len(in))
  for i, v := range in { out[i] = f(v) }
  return out
}
```

#### 20) Build, lint, and CI

Commands to run locally:
```bash
go fmt ./...
go vet ./...
go test ./...
Optional: staticcheck ./...
```

Add -race for tests where applicable: `go test -race ./...`
Use `GOFLAGS=-buildvcs=false` in reproducible builds if needed.

#### 21) Common patterns and snippets

Constructor with validation:

```go
func NewEmail(s string) (Email, error) {
  if !strings.Contains(s, "@") { return Email{}, fmt.Errorf("invalid email %q", s) }
  return Email(s), nil
}
```

Retry with context (exponential backoff simplified):

```go
func Retry(ctx context.Context, attempts int, base time.Duration, fn func() error) error {
  var err error
  for i := 0; i < attempts; i++ {
    if err = fn(); err == nil { return nil }
    d := time.Duration(1<<i) * base
    t := time.NewTimer(d)
    select {
    case <-ctx.Done():
      t.Stop()
      return ctx.Err()
    case <-t.C:
    }
  }
  return err
}
```

Rate limiter (token bucket via time.Ticker):

```go
func RateLimit(ctx context.Context, rps int, work func() error) error {
  tick := time.NewTicker(time.Second / time.Duration(rps))
  defer tick.Stop()
  for {
    select {
    case <-ctx.Done():
      return ctx.Err()
    case <-tick.C:
      if err := work(); err != nil { return err }
    }
  }
}
```

File read with size cap:

```go
func ReadFileMax(path string, max int64) ([]byte, error) {
  f, err := os.Open(path)
  if err != nil { return nil, err }
  defer f.Close()
  r := io.LimitReader(f, max+1)
  b, err := io.ReadAll(r)
  if err != nil { return nil, err }
  if int64(len(b)) > max { return nil, fmt.Errorf("file too large: >%d bytes", max) }
  return b, nil
}
```

#### 22) Ready-to-use mini-templates

A) Library package template:

```go
// Package calc provides simple arithmetic utilities.
package calc

// Sum returns the sum of the provided integers.
func Sum(nums ...int) int {
  s := 0
  for _, n := range nums { s += n }
  return s
}
```

Test:

```go
package calc_test

import "testing"
import "example.com/you/repo/pkg/calc"

func TestSum(t *testing.T) {
  got := calc.Sum(1,2,3)
  if got != 6 { t.Fatalf("got %d, want 6", got) }
}
```

B) Worker pool CLI:

```go
package main

func main() {
  ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
  defer stop()
  log := slog.New(slog.NewTextHandler(os.Stderr, nil))

  tasks := make(chan Task, 100)
  go func() {
    defer close(tasks)
    for i := 0; i < 1000; i++ {
      n := i
      tasks <- func(ctx context.Context) error {
        // do work with n
        _ = n
        return nil
      }
    }
  }()

  if err := RunPool(ctx, runtime.NumCPU(), tasks); err != nil {
    log.Error("pool failed", "err", err)
    os.Exit(1)
  }
}
```

C) HTTP JSON handler with validation:

```go
func createUser(w http.ResponseWriter, r *http.Request) {
  ctx := r.Context()
  var req struct {
    Email string `json:"email"`
    Name  string `json:"name"`
  }
  dec := json.NewDecoder(io.LimitReader(r.Body, 1<<20))
  dec.DisallowUnknownFields()
  if err := dec.Decode(&req); err != nil {
    http.Error(w, "invalid JSON: "+err.Error(), http.StatusBadRequest)
    return
  }
  if req.Email == "" || !strings.Contains(req.Email, "@") {
    http.Error(w, "invalid email", http.StatusBadRequest)
    return
  }
  userID, err := createUserInDB(ctx, req.Email, req.Name)
  if err != nil {
    http.Error(w, "server error", http.StatusInternalServerError)
    return
  }
  w.Header().Set("Content-Type", "application/json")
  w.WriteHeader(http.StatusCreated)
  _ = json.NewEncoder(w).Encode(map[string]any{"id": userID})
}
```

#### 23) Code review checklist (for the LLM and humans)

- Does the code build and pass `go vet`? Are tests included and meaningful?
- Are names clear and stutter-free? Is the public API minimal?
- Are errors wrapped with context and checked with errors.Is/As?
- Are contexts used correctly and respected?
- Any potential goroutine leaks or data races? Buffered channels sized appropriately?
- Are resources closed and defers placed immediately after acquisition?
- Any unnecessary allocations or conversions?
- Are inputs validated and limits enforced?
- Are logs structured, informative, and free of secrets?
- Is the code documented with package and exported symbol comments?

#### 24) Things to avoid (anti-patterns)

- Global mutable state; singletons without need.
- Panicking in libraries (except truly unrecoverable situations).
- Shadowing packages with local vars named like json, time, err.
- Writing to closed channels; closing channels from multiple senders.
- Double-encoding JSON or reading entire unbounded bodies into memory.
- Swallowing errors or returning nil, nil when something failed.
- Overusing generics or reflection when simple code suffices.
