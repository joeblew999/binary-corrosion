# ADR-001: Real-Time Web GUI for Corrosion Demo

## Status

Proposed

## Context

Corrosion is a distributed SQLite replication system that supports real-time subscriptions. We want to build a simple web GUI that demonstrates corrosion's capabilities by:

1. Showing data stored in corrosion's SQLite database
2. Automatically updating the UI when data changes via subscriptions
3. Allowing users to insert/update data and see changes propagate

## Corrosion's Subscription Feature

Corrosion exposes a REST API at the configured `api.addr` (default `127.0.0.1:8080`) with subscription support:

```
GET /v1/subscriptions
POST /v1/subscriptions
DELETE /v1/subscriptions/{id}
```

Subscriptions use Server-Sent Events (SSE) to push changes to clients in real-time.

### Subscription API

```bash
# Create a subscription for a table
curl -X POST http://127.0.0.1:8080/v1/subscriptions \
  -H "Content-Type: application/json" \
  -d '{"sql": "SELECT * FROM kv"}'

# Response returns subscription ID and SSE endpoint
```

The SSE stream sends events when:
- Initial query results arrive
- Rows are inserted
- Rows are updated
- Rows are deleted

## Decision

We will evaluate three approaches for building the real-time web GUI:

### Option 1: Vanilla HTML/JS + SSE (Recommended)

**Pros:**
- Zero dependencies, works in any browser
- Direct SSE integration with `EventSource` API
- Simple to understand and modify
- Single HTML file deployment

**Cons:**
- Manual DOM manipulation
- No component model

**Implementation:**
```html
<!DOCTYPE html>
<html>
<head>
  <title>Corrosion Demo</title>
  <style>
    /* Minimal styling */
  </style>
</head>
<body>
  <h1>Corrosion Real-Time Demo</h1>
  <table id="data"></table>
  <script>
    const API = 'http://127.0.0.1:8080';

    // Subscribe to table changes
    async function subscribe() {
      const res = await fetch(`${API}/v1/subscriptions`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({sql: 'SELECT * FROM kv'})
      });
      const {id} = await res.json();

      // Connect to SSE stream
      const events = new EventSource(`${API}/v1/subscriptions/${id}`);
      events.onmessage = (e) => {
        const data = JSON.parse(e.data);
        updateTable(data);
      };
    }

    function updateTable(rows) {
      // Update DOM with new data
    }

    subscribe();
  </script>
</body>
</html>
```

### Option 2: HTMX + SSE

**Pros:**
- Declarative HTML-driven updates
- Built-in SSE support via `hx-sse`
- Minimal JavaScript
- Progressive enhancement

**Cons:**
- Requires HTMX library (~14KB)
- SSE extension needed
- May need server-side HTML rendering

**Implementation:**
```html
<div hx-sse="connect:/v1/subscriptions/1">
  <table hx-sse="swap:message">
    <!-- Updated by SSE events -->
  </table>
</div>
```

### Option 3: React/Vue/Svelte SPA

**Pros:**
- Rich component model
- State management
- Better for complex UIs

**Cons:**
- Build tooling required
- Larger bundle size
- Overkill for a demo

## Recommended Approach

**Option 1: Vanilla HTML/JS** is recommended because:

1. **Simplicity** - Single HTML file, no build step
2. **Direct SSE** - Native `EventSource` works perfectly with corrosion
3. **Educational** - Easy to understand how subscriptions work
4. **Portable** - Can be served from anywhere, even `file://`

## Implementation Plan

### Phase 1: Basic Demo
1. Create `demo/index.html` with:
   - Table view of key-value data
   - Form to insert new entries
   - SSE subscription for live updates

2. Add Taskfile tasks:
   ```yaml
   demo:serve:
     desc: Serve demo UI
     cmds:
       - python3 -m http.server 3000 --directory demo

   demo:open:
     desc: Open demo in browser
     cmds:
       - open http://localhost:3000
   ```

### Phase 2: Enhanced Features
1. Multiple table views
2. Query builder
3. Node status visualization
4. Cluster topology view

### Phase 3: Multi-Node Demo
1. Docker Compose with 3 corrosion nodes
2. Show replication in action
3. Network partition simulation

## File Structure

```
demo/
  index.html      # Main demo UI
  style.css       # Optional: extracted styles
  app.js          # Optional: extracted JS
docker-compose.yml  # Multi-node setup
```

## API Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/queries` | POST | Execute SQL queries |
| `/v1/subscriptions` | POST | Create subscription |
| `/v1/subscriptions/{id}` | GET | SSE event stream |
| `/v1/subscriptions/{id}` | DELETE | Cancel subscription |

## References

- [Corrosion API Docs](https://superfly.github.io/corrosion/api/)
- [Server-Sent Events MDN](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events)
- [EventSource API](https://developer.mozilla.org/en-US/docs/Web/API/EventSource)

## Next Steps

1. Review corrosion's actual subscription API format
2. Build minimal proof-of-concept
3. Test with running corrosion instance
4. Iterate based on findings
