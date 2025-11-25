# My Project Rules

## Code Style
- TypeScript everywhere (no exceptions)
- Functional components with hooks only
- 2-space indentation
- camelCase for variables, PascalCase for components
## Architecture Notes
- State management with Zustand
- New components need tests alongside them
- Performance matters—always consider bundle size
## Don't Do This
- Don't use class components (legacy codebase reasons)
- Don't bypass our error boundary setup
- Don't write 500-line components (break them up!)

use bun as much as possible

