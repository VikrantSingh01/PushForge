# Agentic Push Notification Patterns

A comprehensive guide to push notification paradigms for AI agent developers — with real-world use cases, platform-specific payloads, and direct mapping to PushForge templates.

---

## Table of Contents

1. [Task Completion](#1-task-completion)
2. [Human-in-the-Loop Approval](#2-human-in-the-loop-approval)
3. [Agent Error & Recovery](#3-agent-error--recovery)
4. [Background Memory Sync](#4-background-memory-sync)
5. [Streaming Response Complete](#5-streaming-response-complete)
6. [Live Progress Updates](#6-live-progress-updates)
7. [Multi-Agent Handoff](#7-multi-agent-handoff)
8. [Proactive Recommendations](#8-proactive-recommendations)
9. [Scheduled Agent Reports](#9-scheduled-agent-reports)
10. [Monitoring & Observability Alerts](#10-monitoring--observability-alerts)
11. [Conversational Follow-Up](#11-conversational-follow-up)
12. [Autonomous Code Review](#12-autonomous-code-review)

---

## 1. Task Completion

> **Your agent finished working. The user needs to know — now.**

### The Pattern

The most fundamental agentic notification. The user kicks off an async task, closes the app, and the agent works in the background. When it's done, a push notification pulls the user back to the result.

### Real-World Use Cases

| Product | What the agent does | What the notification says |
|---|---|---|
| **ChatGPT Agent** | Researches a topic, plans travel, books appointments | "Your travel itinerary is ready" |
| **Cursor Background Agent** | Clones a repo, writes code, runs tests, opens a PR | "PR #47 ready for review — all tests passed" |
| **Devin** | Implements a feature end-to-end in a cloud sandbox | "Feature complete: user authentication flow" |
| **Microsoft Copilot** | Generates a PowerPoint from a brief | "Your presentation is ready to review" |

### Why This Notification Matters

- Must be **time-sensitive** — the user asked for this work, they want to know it's done
- Must be **thread-grouped** — if the user has 5 agents running, notifications shouldn't pile up
- Must have a **deep link** — tapping should open the exact result, not the app's home screen

### PushForge Templates

**iOS** — `iOS` tab → `Basic` sub-tab → **Agent Task Complete**

```json
{
  "aps": {
    "alert": {
      "title": "Task Complete",
      "subtitle": "Research Agent",
      "body": "Your research on quantum computing trends is ready. Tap to view the full report."
    },
    "sound": "default",
    "badge": 1,
    "thread-id": "agent-tasks",
    "interruption-level": "time-sensitive"
  },
  "task_id": "task_abc123",
  "agent": "research",
  "deep_link": "myapp://tasks/abc123",
  "completed_at": "2026-02-16T12:00:00Z"
}
```

**Android** — `Android` tab → `Basic` sub-tab → **Agent Task Complete**

```json
{
  "notification": {
    "title": "Task Complete",
    "body": "Your research on quantum computing trends is ready. Tap to view the full report.",
    "channel_id": "agent_tasks",
    "sound": "default",
    "click_action": "OPEN_TASK_RESULT",
    "icon": "ic_agent"
  },
  "data": {
    "task_id": "task_abc123",
    "agent": "research",
    "deep_link": "myapp://tasks/abc123",
    "completed_at": "2026-02-16T12:00:00Z"
  }
}
```

**Key Differences:**
| Field | iOS (APNs) | Android (FCM) |
|---|---|---|
| Priority | `interruption-level: time-sensitive` | `priority: high` |
| Grouping | `thread-id` | `channel_id` + `tag` |
| Navigation | Custom `deep_link` key | `click_action` |
| Badge | `badge: 1` (number) | `notification_count` |

---

## 2. Human-in-the-Loop Approval

> **Your agent wants to do something consequential. It needs the human to say yes.**

### The Pattern

The agent reaches a decision point that requires explicit human authorization — deploying code, spending money, deleting data, sending external communications. The agent is **blocked** until the user responds.

### Real-World Use Cases

| Product | What needs approval | What happens if notification fails |
|---|---|---|
| **Claude Code** | Execute a shell command, write to files | Agent stuck waiting indefinitely |
| **Copilot Studio** | Submit a regulatory filing, approve a refund | Compliance workflow stalls |
| **Salesforce Agentforce** | Modify CRM records, trigger external integration | Data pipeline blocked |
| **Trading Bots** | Execute a trade above threshold | Missed market opportunity |

### Why This Notification Matters

- Must be **actionable** — Approve/Reject buttons, not just a tap target
- Must be **high priority** — this can't be buried under marketing pushes
- Must have **expiry context** — some approvals are time-sensitive (market windows, deployment windows)
- If this notification doesn't render correctly, the **agent is stuck indefinitely** — no timeout, no fallback

### PushForge Templates

**iOS** — `iOS` tab → `Rich` sub-tab → **Agent Needs Approval**

```json
{
  "aps": {
    "alert": {
      "title": "Action Required",
      "subtitle": "Deploy Agent",
      "body": "Ready to deploy v2.3.1 to production. 47 tests passed, 0 failed. Approve or reject."
    },
    "sound": "default",
    "category": "AGENT_APPROVAL",
    "interruption-level": "time-sensitive"
  },
  "agent": "deploy",
  "action_id": "deploy_v231",
  "environment": "production",
  "tests_passed": 47,
  "tests_failed": 0
}
```

**Android** — `Android` tab → `Rich` sub-tab → **Agent Needs Approval**

```json
{
  "notification": {
    "title": "Action Required",
    "body": "Ready to deploy v2.3.1 to production. 47 tests passed, 0 failed.",
    "channel_id": "agent_approvals",
    "sound": "default",
    "click_action": "APPROVE_ACTION"
  },
  "android": {
    "priority": "high"
  },
  "data": {
    "agent": "deploy",
    "action_id": "deploy_v231",
    "environment": "production",
    "tests_passed": "47",
    "tests_failed": "0"
  }
}
```

**Key Differences:**
| Field | iOS (APNs) | Android (FCM) |
|---|---|---|
| Action buttons | `category: AGENT_APPROVAL` (registered in app) | `click_action` + app-side handling |
| Priority | `interruption-level: time-sensitive` | `priority: high` |
| Data types | Native types (`47` as integer) | All strings (`"47"`) |

---

## 3. Agent Error & Recovery

> **Your agent crashed. Silence is the worst possible response.**

### The Pattern

The agent encounters a terminal failure — API timeout, invalid data, rate limit exhaustion, unrecoverable state. Automatic retries have been exhausted. The user must be notified immediately so they can intervene, retry, or cancel.

### Real-World Use Cases

| Product | Error scenario | User impact |
|---|---|---|
| **LangGraph** | Agent state machine hits invalid transition | Workflow frozen at checkpoint |
| **CrewAI** | API rate limit after exponential backoff | Multi-agent crew stalled |
| **n8n AI Agents** | External service down after 5 retries | Automation pipeline broken |
| **Data Pipeline Agents** | Database connection timeout | ETL job incomplete, stale data |

### Why This Notification Matters

- Must use **critical interruption** — bypasses Do Not Disturb
- Must include **error context** — what failed, at which step, is retry available
- Must be **immediate** — delayed error notifications compound damage

### PushForge Templates

**iOS** — `iOS` tab → `Advanced` sub-tab → **Agent Error**

```json
{
  "aps": {
    "alert": {
      "title": "Agent Failed",
      "subtitle": "Data Pipeline",
      "body": "ETL job failed at step 3/5: Connection timeout to database. Retry available."
    },
    "sound": {
      "critical": 1,
      "name": "alarm.caf",
      "volume": 0.8
    },
    "interruption-level": "critical",
    "thread-id": "agent-errors"
  },
  "agent": "data_pipeline",
  "error_code": "CONN_TIMEOUT",
  "step": "3/5",
  "retry_available": true,
  "job_id": "job_etl_456"
}
```

**Android** — `Android` tab → `Advanced` sub-tab → **Agent Error**

```json
{
  "notification": {
    "title": "Agent Failed — Data Pipeline",
    "body": "ETL job failed at step 3/5: Connection timeout to database. Retry available.",
    "channel_id": "agent_errors",
    "sound": "alarm",
    "color": "#FF3B30"
  },
  "android": {
    "priority": "high"
  },
  "data": {
    "agent": "data_pipeline",
    "error_code": "CONN_TIMEOUT",
    "step": "3/5",
    "retry_available": "true",
    "job_id": "job_etl_456"
  }
}
```

**Key Differences:**
| Field | iOS (APNs) | Android (FCM) |
|---|---|---|
| Sound override | `sound: { critical: 1, name, volume }` | `sound: "alarm"` |
| DND bypass | `interruption-level: critical` (requires entitlement) | Channel importance `IMPORTANCE_HIGH` |
| Visual | Standard banner with critical badge | `color: "#FF3B30"` (red tint) |

---

## 4. Background Memory Sync

> **Your agent refreshes its context. The user never sees a thing.**

### The Pattern

Silent push — no banner, no sound, no badge. The agent syncs conversation history, user preferences, tool results, or model state in the background. The user is unaware this happened. If it fails, there's nothing visible to indicate the problem.

### Real-World Use Cases

| Product | What syncs | Why it matters |
|---|---|---|
| **ChatGPT** | Conversation history across devices | Seamless multi-device experience |
| **Claude** | User preferences, memory fragments | Agent remembers context |
| **Microsoft Copilot** | Document context, meeting notes | Agent has up-to-date workspace state |
| **Replika** | Personality model, conversation tone | Consistent personality across sessions |

### Why This Notification Matters

- Must be **completely silent** — `content-available: 1` only
- Must include **sync metadata** — what collections, since when, compression flag
- **If this fails, you'd never know** — there's nothing visible. This is why you must test it explicitly.

### PushForge Templates

**iOS** — `iOS` tab → `Silent` sub-tab → **Agent Memory Sync**

```json
{
  "aps": {
    "content-available": 1
  },
  "sync": {
    "type": "agent_memory",
    "agent_id": "assistant_main",
    "collections": [
      "conversation_history",
      "user_preferences",
      "tool_results"
    ],
    "since": "2026-02-16T00:00:00Z",
    "priority": "high",
    "compressed": true
  }
}
```

**Android** — `Android` tab → `Silent` sub-tab → **Agent Memory Sync**

```json
{
  "data": {
    "type": "agent_memory_sync",
    "agent_id": "assistant_main",
    "collections": "conversation_history,user_preferences,tool_results",
    "since": "2026-02-16T00:00:00Z",
    "priority": "high"
  }
}
```

**Key Differences:**
| Field | iOS (APNs) | Android (FCM) |
|---|---|---|
| Silent trigger | `content-available: 1` in `aps` | Data-only message (no `notification` key) |
| Data structure | Nested objects (arrays, booleans) | Flat strings only in `data` |
| Wake behavior | Wakes app for ~30 seconds | Firebase `onMessageReceived` fires |

---

## 5. Streaming Response Complete

> **The LLM finished generating. The response is ready.**

### The Pattern

The agent was streaming a response (token-by-token, like ChatGPT's typing effect). The user closed the app mid-stream. When generation completes, a push notification tells them the full response is available.

### Real-World Use Cases

| Product | What finished streaming | What the user sees |
|---|---|---|
| **GitHub Copilot** | Code review with inline comments | "Code review ready — 2 open comments" |
| **Claude** | Long research analysis | "Analysis complete — 3,400 words" |
| **ChatGPT** | Multi-step reasoning chain | "Response ready" |
| **Vercel AI SDK agents** | Tool call chain execution | "Results from 4 tool calls ready" |

### Why This Notification Matters

- Hybrid: visible notification **plus** `content-available` to trigger background data fetch
- Must include **result metadata** — token count, duration, output size
- Deep link opens the specific conversation/review

### PushForge Templates

**iOS** — `iOS` tab → `Basic` sub-tab → **Streaming Complete**

```json
{
  "aps": {
    "alert": {
      "title": "Code Review Ready",
      "body": "GitHub Copilot has finished reviewing your code review. 2 open comments to resolve."
    },
    "sound": "default",
    "content-available": 1,
    "thread-id": "code-reviews"
  },
  "review_id": "pr_review_42",
  "model": "copilot",
  "open_comments": 2,
  "deep_link": "myapp://reviews/pr_review_42"
}
```

**Android** — `Android` tab → `Basic` sub-tab → **Streaming Complete**

```json
{
  "notification": {
    "title": "Code Review Ready",
    "body": "GitHub Copilot has finished reviewing your code review. 2 open comments to resolve.",
    "channel_id": "code-reviews",
    "sound": "default"
  },
  "data": {
    "review_id": "pr_review_42",
    "model": "copilot",
    "open_comments": "2",
    "deep_link": "myapp://reviews/pr_review_42"
  }
}
```

---

## 6. Live Progress Updates

> **Your agent is 75% done. Here's what it's doing right now.**

### The Pattern

For long-running tasks, the agent reports progress in real-time via iOS Live Activities. Shows completion percentage, current step, tokens used, and estimated time remaining. Keeps the user informed without requiring them to open the app.

### Real-World Use Cases

| Product | What's progressing | Live Activity shows |
|---|---|---|
| **Cursor** | Multi-file code generation | "Writing tests — step 3/4 — 75%" |
| **Devin** | Feature implementation | "Running CI — 12 tests remaining" |
| **ChatGPT Agent** | Research across multiple sources | "Analyzing source 34/47" |
| **Copilot Workspace** | Multi-file refactor | "Updating 8/12 files" |

### Why This Notification Matters

- **iOS only** — Live Activities are an iOS 16.1+ feature
- Uses `content-state` for real-time updates without new notifications
- Must include progress metadata — percentage, step count, ETA

### PushForge Template

**iOS** — `iOS` tab → `Advanced` sub-tab → **Live Activity Update**

```json
{
  "aps": {
    "timestamp": 1708000000,
    "event": "update",
    "content-state": {
      "progress": 0.75,
      "current_step": "Analyzing code",
      "steps_completed": 3,
      "total_steps": 4,
      "tokens_used": 2847,
      "estimated_remaining_seconds": 12
    },
    "alert": {
      "title": "Code Review: 75% Complete",
      "body": "Analyzing code — 3 of 4 steps done"
    }
  }
}
```

*No Android equivalent — Live Activities are iOS-only. Android uses ongoing notifications with progress bars, managed client-side.*

---

## 7. Multi-Agent Handoff

> **Triage agent just transferred you to a specialist. Here's why.**

### The Pattern

Multiple agents collaborate. A triage agent receives the initial request, determines which specialist should handle it, and transfers context. The user is notified about who's now working on their request and why the transfer happened.

### Real-World Use Cases

| Product | Source Agent | Target Agent | Why |
|---|---|---|---|
| **OpenAI Agent SDK** | Triage agent | Refunds specialist | Billing expertise needed |
| **Salesforce Agentforce** | General support | Technical support | Code-level debugging required |
| **Microsoft Copilot Studio** | Router agent | HR policy agent | Policy question detected |
| **CrewAI Crews** | Research agent | Writing agent | Research complete, synthesis needed |

### Why This Notification Matters

- Builds **transparency and trust** — user knows which agent has their request
- Must identify **source and destination** agents clearly
- Should explain **why** the handoff happened

### Sample Payloads

**iOS:**
```json
{
  "aps": {
    "alert": {
      "title": "Request Transferred",
      "subtitle": "Billing Specialist",
      "body": "General support transferred your refund request to billing specialist for faster resolution."
    },
    "sound": "default",
    "thread-id": "support-request-789",
    "category": "AGENT_HANDOFF"
  },
  "source_agent": "general_support",
  "target_agent": "billing_specialist",
  "handoff_reason": "specialized_expertise",
  "request_id": "789"
}
```

**Android:**
```json
{
  "notification": {
    "title": "Request Transferred to Billing Specialist",
    "body": "General support transferred your refund request for faster resolution.",
    "channel_id": "agent_handoffs",
    "sound": "default"
  },
  "data": {
    "source_agent": "general_support",
    "target_agent": "billing_specialist",
    "handoff_reason": "specialized_expertise",
    "request_id": "789",
    "click_action": "OPEN_SUPPORT_REQUEST"
  }
}
```

---

## 8. Proactive Recommendations

> **Your agent noticed something. It wants to help — without being asked.**

### The Pattern

The agent analyzes user context, behavior patterns, and available data to proactively suggest actions. Not triggered by a user request — the agent initiates based on its own analysis. Must be throttled carefully to avoid notification fatigue.

### Real-World Use Cases

| Product | What the agent noticed | Recommendation |
|---|---|---|
| **Microsoft 365 Copilot** | 3 meetings tomorrow with no agenda | "Want me to draft agendas?" |
| **Salesforce Einstein** | Deal probability dropped below threshold | "Suggest scheduling a check-in call" |
| **Google Gemini** | Duplicate calendar events | "You have overlapping meetings — resolve?" |
| **Notion AI** | Stale project status | "This project hasn't been updated in 2 weeks" |

### Why This Notification Matters

- Must be **low priority** — this is proactive, not user-initiated
- Must be **throttled** — max 1-2 per day to avoid fatigue
- Must use **relevance-score** (iOS) for notification summary ranking

### Sample Payloads

**iOS:**
```json
{
  "aps": {
    "alert": {
      "title": "Meeting Prep",
      "body": "You have 3 meetings tomorrow with no agenda. Want me to draft them?"
    },
    "sound": "",
    "relevance-score": 0.5,
    "interruption-level": "passive",
    "thread-id": "recommendations"
  },
  "recommendation_type": "meeting_prep",
  "meeting_count": 3,
  "action_url": "myapp://meetings/prep"
}
```

**Android:**
```json
{
  "notification": {
    "title": "Meeting Prep",
    "body": "You have 3 meetings tomorrow with no agenda. Want me to draft them?",
    "channel_id": "recommendations"
  },
  "android": {
    "priority": "normal"
  },
  "data": {
    "recommendation_type": "meeting_prep",
    "meeting_count": "3",
    "click_action": "OPEN_MEETING_PREP"
  }
}
```

---

## 9. Scheduled Agent Reports

> **Your daily digest is ready. Same time tomorrow.**

### The Pattern

Agents run on a schedule — daily, hourly, weekly — to generate reports, pull data, run analysis. The output is delivered as a push notification at a predictable time.

### Real-World Use Cases

| Product | Schedule | What it produces |
|---|---|---|
| **MindStudio** | Daily 8am | Sales analytics summary |
| **Zapier AI** | Hourly | Social media sentiment report |
| **n8n Workflows** | Weekly Monday | Sprint retrospective draft |
| **Monday.com AI** | Daily EOD | Project status roll-up |

### Sample Payloads

**iOS:**
```json
{
  "aps": {
    "alert": {
      "title": "Daily Sales Report",
      "body": "Revenue up 12% — $47,230 today. 3 new enterprise leads. Tap for full report."
    },
    "sound": "default",
    "badge": 1,
    "thread-id": "scheduled-reports",
    "relevance-score": 0.6
  },
  "report_type": "daily_sales",
  "report_url": "myapp://reports/2026-02-17",
  "next_run": "2026-02-18T08:00:00Z"
}
```

**Android:**
```json
{
  "notification": {
    "title": "Daily Sales Report",
    "body": "Revenue up 12% — $47,230 today. 3 new enterprise leads.",
    "channel_id": "scheduled_reports",
    "sound": "default"
  },
  "data": {
    "report_type": "daily_sales",
    "report_url": "myapp://reports/2026-02-17",
    "click_action": "OPEN_REPORT"
  }
}
```

---

## 10. Monitoring & Observability Alerts

> **Your agent's failure rate just spiked. Something is wrong in production.**

### The Pattern

Meta-monitoring — agents watching other agents. When an agent's performance degrades, error rate spikes, latency increases, or hallucination rate exceeds threshold, a monitoring agent sends a critical alert to the on-call team.

### Real-World Use Cases

| Product | What's monitored | Alert trigger |
|---|---|---|
| **Braintrust** | Agent quality scores | Score drops below threshold |
| **AgentOps** | Hallucination rate | Rate exceeds 5% |
| **Langfuse** | Agent latency, cost | P99 latency > 10s |
| **Galileo** | Multi-agent pipeline | Cascading failure detected |

### Sample Payloads

**iOS:**
```json
{
  "aps": {
    "alert": {
      "title": "CRITICAL: Agent Failure Spike",
      "body": "Customer support agent failure rate at 23% (threshold: 5%). 47 users affected."
    },
    "sound": {
      "critical": 1,
      "name": "alarm.caf",
      "volume": 1.0
    },
    "interruption-level": "critical",
    "thread-id": "monitoring-alerts"
  },
  "severity": "critical",
  "alert_type": "failure_rate",
  "metric_value": 23,
  "threshold": 5,
  "affected_users": 47,
  "dashboard_url": "myapp://monitoring/alerts/123"
}
```

**Android:**
```json
{
  "notification": {
    "title": "CRITICAL: Agent Failure Spike",
    "body": "Customer support agent failure rate at 23% (threshold: 5%). 47 users affected.",
    "channel_id": "critical_alerts",
    "sound": "alarm",
    "color": "#FF0000"
  },
  "android": {
    "priority": "high"
  },
  "data": {
    "severity": "critical",
    "alert_type": "failure_rate",
    "metric_value": "23",
    "threshold": "5",
    "affected_users": "47",
    "click_action": "OPEN_MONITORING"
  }
}
```

---

## 11. Conversational Follow-Up

> **Your agent has a follow-up question. The conversation isn't over.**

### The Pattern

The agent needs more information, found something interesting since the last interaction, or wants to check in on a previous recommendation. Maintains conversation continuity across sessions.

### Real-World Use Cases

| Product | Follow-up reason | Notification |
|---|---|---|
| **ChatGPT** | Clarification needed for pending task | "I need one more detail about your budget range" |
| **Claude** | Found updated information | "The API docs were updated — want me to revise my analysis?" |
| **Character.AI** | Proactive conversation | "Continued thinking about your project idea..." |
| **Replika** | Engagement prompt | "How did the presentation go?" |

### Sample Payloads

**iOS:**
```json
{
  "aps": {
    "alert": {
      "title": "Claude",
      "body": "I found updated pricing for the APIs you asked about. Want me to revise the comparison?"
    },
    "sound": "default",
    "thread-id": "conversation-456",
    "interruption-level": "active"
  },
  "conversation_id": "456",
  "message_type": "follow_up",
  "requires_response": true
}
```

**Android:**
```json
{
  "notification": {
    "title": "Claude",
    "body": "I found updated pricing for the APIs you asked about. Want me to revise the comparison?",
    "channel_id": "conversations",
    "sound": "default"
  },
  "data": {
    "conversation_id": "456",
    "message_type": "follow_up",
    "requires_response": "true",
    "click_action": "OPEN_CONVERSATION"
  }
}
```

---

## 12. Autonomous Code Review

> **Your AI submitted a PR. Tests pass. Ready for human review.**

### The Pattern

AI coding agents autonomously review code, implement features, create pull requests, and run CI pipelines. When the work is ready for human review, they send a push notification with the PR details and test results.

### Real-World Use Cases

| Product | What it did | Notification |
|---|---|---|
| **GitHub Copilot Workspace** | Multi-file implementation + tests | "PR #47: All 23 tests pass, ready for review" |
| **Cursor Background Agent** | Bug fix from issue description | "Fixed #182: null pointer in auth flow" |
| **Devin** | Full feature implementation | "feat/user-auth: 4 files changed, CI green" |
| **Amazon CodeGuru** | Security review | "2 critical findings in payment module" |

### Sample Payloads

**iOS:**
```json
{
  "aps": {
    "alert": {
      "title": "PR Ready for Review",
      "subtitle": "feat/user-authentication",
      "body": "All 23 tests passed. 4 files changed. Copilot requests your review."
    },
    "sound": "default",
    "badge": 1,
    "thread-id": "code-reviews",
    "category": "CODE_REVIEW"
  },
  "pr_number": 47,
  "branch": "feat/user-authentication",
  "tests_passed": 23,
  "files_changed": 4,
  "pr_url": "https://github.com/user/repo/pull/47"
}
```

**Android:**
```json
{
  "notification": {
    "title": "PR Ready for Review — feat/user-authentication",
    "body": "All 23 tests passed. 4 files changed. Copilot requests your review.",
    "channel_id": "code_reviews",
    "sound": "default"
  },
  "android": {
    "priority": "high"
  },
  "data": {
    "pr_number": "47",
    "branch": "feat/user-authentication",
    "tests_passed": "23",
    "files_changed": "4",
    "pr_url": "https://github.com/user/repo/pull/47",
    "click_action": "OPEN_PR"
  }
}
```

---

## Quick Reference: PushForge Template Locations

| Paradigm | iOS Tab → Sub-tab → Template | Android Tab → Sub-tab → Template |
|---|---|---|
| Task Completion | `iOS` → `Basic` → **Agent Task Complete** | `Android` → `Basic` → **Agent Task Complete** |
| Human-in-the-Loop | `iOS` → `Rich` → **Agent Needs Approval** | `Android` → `Rich` → **Agent Needs Approval** |
| Agent Error | `iOS` → `Advanced` → **Agent Error** | `Android` → `Advanced` → **Agent Error** |
| Background Sync | `iOS` → `Silent` → **Agent Memory Sync** | `Android` → `Silent` → **Agent Memory Sync** |
| Streaming Complete | `iOS` → `Basic` → **Streaming Complete** | `Android` → `Basic` → **Streaming Complete** |
| Live Progress | `iOS` → `Advanced` → **Live Activity Update** | *(iOS only)* |
| Standard Silent | `iOS` → `Silent` → **Silent Push** | `Android` → `Silent` → **Android Silent** |
| Standard Alert | `iOS` → `Basic` → **Basic Alert** | `Android` → `Basic` → **Android Basic** |

---

## Cross-Platform Payload Cheat Sheet

| Concept | iOS (APNs) | Android (FCM) |
|---|---|---|
| **Root key** | `aps` | `notification` + `data` |
| **Title** | `aps.alert.title` | `notification.title` |
| **Body** | `aps.alert.body` | `notification.body` |
| **Silent push** | `content-available: 1` | Data-only (no `notification` key) |
| **Priority: urgent** | `interruption-level: time-sensitive` | `priority: high` |
| **Priority: critical** | `interruption-level: critical` | Channel importance `IMPORTANCE_HIGH` |
| **Priority: passive** | `interruption-level: passive` | `priority: normal` |
| **Grouping** | `thread-id` | `tag` + `channel_id` |
| **Action buttons** | `category` (registered in app) | `click_action` + app handling |
| **Sound** | `sound: "default"` or `{ critical: 1, name, volume }` | `sound: "default"` or custom filename |
| **Badge** | `badge: 3` (number) | `notification_count: 3` |
| **Deep link** | Custom key in payload | `click_action` or custom key in `data` |
| **Max payload** | 4,096 bytes | 4,096 bytes |
| **DND bypass** | `interruption-level: critical` (requires entitlement) | Full-screen intent (requires permission) |
| **Data types** | Native (int, bool, array, object) | Strings only in `data` |

---

## Notification Priority Matrix

| Paradigm | iOS Interruption Level | Android Priority | Rationale |
|---|---|---|---|
| Agent Error | `critical` | `high` | Failure with user data — immediate attention |
| Human-in-the-Loop | `time-sensitive` | `high` | Agent blocked, decision needed |
| Task Completion | `time-sensitive` | `high` | User-initiated, result ready |
| Monitoring Alert | `critical` | `high` | Production incident |
| Streaming Complete | `active` | `high` | Response ready to view |
| Code Review | `active` | `high` | Developer workflow |
| Multi-Agent Handoff | `active` | `normal` | Informational, not urgent |
| Conversational | `active` | `normal` | Can wait, not blocking |
| Scheduled Report | `active` | `normal` | Expected, not urgent |
| Recommendation | `passive` | `normal` | Proactive, user didn't ask |
| Background Sync | *(silent)* | *(data-only)* | Invisible to user |
| Live Progress | *(Live Activity)* | *(ongoing notification)* | Real-time, non-interruptive |

---

*This document is part of [PushForge](https://github.com/VikrantSingh01/PushForge) — the push notification playground for mobile and AI agent developers.*
