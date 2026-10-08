---
name: walkthrough
description: Walk the user through pages one at a time in the embedded browser, explaining each in chat and waiting for "next" before moving on. Use when the user says "walk me through", "walkthrough", "give me a tour", "show me X in the browser", or "open all this and walk me through it".
argument-hint: "[what to walk through, e.g. 'billing' or 'the new pricing']"
---

# Walkthrough

A guided tour of pages in the built-in browser pane (the `mcp__Claude_Browser__*`
tools), narrated in chat. The user reads at their own pace; you move only when
they say so.

## 1. Plan the tour, then start

Work out the stops from the request and the recent work in the conversation: the
public page, the signed-in page, the third-party dashboard, the email, whatever
the thing touches, in the order a user meets it.

Post the plan as a short numbered list, one line per stop with the URL, then
open stop 1 in the same turn. Don't ask "shall I start?" — the request was the
yes.

```
Tour: billing (5 stops)
1. Public pricing — https://example.com/#pricing
2. Your Billing page — https://example.com/acme/billing
3. Stripe Checkout (test session)
4. Stripe products and prices — https://dashboard.stripe.com/products
5. Stripe webhook — https://dashboard.stripe.com/webhooks
```

## 2. One stop per turn

For each stop:

1. Navigate, wait 2–4 s, and bring the section into view
   (`javascript_tool`: `document.getElementById('…')?.scrollIntoView()`).
2. Screenshot at `scale: 0.6`. For a long page, take one screenshot per
   section rather than one tall one.
3. Quote copy from `get_page_text`, not from reading pixels.
4. Explain in **3–6 bullets**: what this page is, what to look at, why it's
   built this way (link the doc or file), and anything you'd change or that
   looks wrong. Say plainly when something is broken. Don't paper over it.
5. End with exactly one line: `Say **next** for <stop N+1>, or ask about anything here.`
6. **End the turn.** Do not open the next stop until the user says so.

The user drives:

| They say | You do |
|---|---|
| next, ok, go on | the next stop |
| back | the previous stop again |
| skip | the stop after next |
| a question | answer it from this page; stay on this stop |
| "change X" | add it to the **Changes requested** list (below); ask whether to do it now or at the end |
| stop | stop at once: no more tool calls. Say where you got to and how to resume |
| "I'm still reading" | nothing; wait |

## 3. Browser realities (learned the hard way)

- **The pane has its own cookies.** Being signed in to a local dev server says
  nothing about production. If a page bounces to the home or sign-in page,
  say so and ask the user to sign in *in the pane*. Never type a password,
  never pick an account for them.
- **Don't start a dev server that other sessions share.** Check the project's
  CLAUDE.md (many projects say "never run `pnpm dev`, it kills the other
  session's server"). If the local server is down, say so and use production
  or another stop.
- **Third-party dashboards may refuse navigation** (Stripe, Google Cloud,
  Vercel). If `navigate` is denied, give the direct URL as a link and carry
  on. Don't retry in a loop.
- **Never read or repeat secrets** shown on a page (API keys, tokens, webhook
  secrets). Point at where they are; let the user copy them.
- **The pane is narrow.** To show a desktop layout, `resize_window` to
  1280×900, screenshot, then reset with `preset: "desktop"` before the turn ends.
- **Tabs come and go.** If the user closed the pane, `navigate` with a URL
  reopens it and tab ids change: read `tabs_context` before reusing an id.
  Use the tab the user is looking at, and `tabs_select` it if you opened a
  new one.
- **Don't click anything irreversible** (buy, send, delete, publish, save
  settings) during a tour. A tour shows; it doesn't change things. If a stop
  needs an action (e.g. "save the portal settings"), tell the user which
  button, and let them press it.
- **Test sessions you create are yours to clean up** (a test Checkout, a draft):
  expire or cancel them at the end and say so.

## 4. Changes requested

Keep a running list in your replies whenever the user asks for a change
mid-tour:

```
Changes requested so far
1. Pricing: name example agents next to "your own AI agent"
2. Billing: rename "image credit left" once audio/video ship
```

Small copy changes can be done on the spot if the user says "do it now". Then
re-show the stop. Anything bigger waits for the end.

## 5. End of the tour

When the last stop is done (or the user stops early):

- One line per stop: what it showed and its state (fine / changed / needs work).
- The **Changes requested** list, each marked done or open.
- Anything the user must do themselves (a dashboard switch, a sign-in, a
  setting only they can save), with direct links.

Then stop. Don't start on the open changes unless they ask.
