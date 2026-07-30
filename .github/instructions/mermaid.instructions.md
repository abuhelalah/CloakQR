# Mermaid Diagram Instructions

Use these conventions when adding or updating Mermaid diagrams in this repository.

---

## Diagram types

| Purpose | Type |
|---------|------|
| Component / dependency relationships | `graph TD` (top-down) or `graph LR` (left-right) |
| Class hierarchy | `classDiagram` |
| Data flow / sequence | `sequenceDiagram` |
| Build phases or milestones | `gantt` |
| State machines | `stateDiagram-v2` |

---

## graph TD / LR conventions

- **Node IDs** use `camelCase` matching the C++ class or QML file name.
  e.g. `ScanHistoryModel`, `main_qml`
- **Node labels** (inside `["…"]`) use the display name as it appears in code.
- Use `-->` for a direct dependency or data flow.
- Annotate edges with a short label when the relationship type is not obvious:
  ```
  QrDecoder -->|urlDetected| main_qml
  ```
- Group related nodes with `subgraph`:
  ```mermaid
  graph TD
    subgraph Services
      AppEngine
      CryptoHelper
      ScanHistoryModel
    end
  ```

## classDiagram conventions

- Show only public API members — omit private implementation details unless
  they are architecturally significant.
- Use `+` for public, `-` for private, `#` for protected.
- Show inheritance with `<|--` and composition with `*--`.

## sequenceDiagram conventions

- Actors are named after their Qt class or QML component.
- Use `activate` / `deactivate` to show blocking calls.
- Prefix async signal emissions with `emit`:
  ```
  QrDecoder->>main_qml: emit urlDetected(url)
  ```

## General rules

- Keep diagrams focused: one diagram per concept. Prefer several small diagrams
  over one large diagram.
- Always place diagrams inside a fenced code block tagged `mermaid`:
  ````markdown
  ```mermaid
  graph TD
      A --> B
  ```
  ````
- Diagrams in `PLAN.md` describe the intended target architecture, not the
  current (possibly incomplete) state. Add a `<!-- current -->` comment near any
  node that is already implemented.
- Re-render and visually verify diagrams after editing them (GitHub renders
  Mermaid natively in Markdown previews).

---

## CloakQR reference diagram

The canonical component diagram lives in `PLAN.md` under **Dependency Map**.
Update it whenever a new service, model, or provider is added.
