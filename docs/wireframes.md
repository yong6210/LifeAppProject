# Life App Wireframe Notes (v1.0)

These describe screen structures for design review. Use them as guidance to build high-fidelity mockups in Figma or another tool.

---

## 1. Home Dashboard (Focus of MVP)

**Goals**: quick start, snapshot of daily progress, highlight premium actions.

**Layout (mobile portrait)**
1. **App Bar**: left logo glyph, centered date, right-side icons (analytics, settings, premium badge).
2. **Routine Carousel**: horizontal cards linking to Focus / Rest / Workout / Sleep with next-up segment preview.
3. **Daily Totals Card**: minutes per mode, streak indicator, CTA to stats (premium lock icon if user is free tier).
4. **Quick Actions Row**: buttons “Start Focus”, “Start Sleep”, “Backup Now”.
5. **Sync Status**: small banner when offline or last sync > 24h.
6. **Footer CTA**: premium upsell or tips depending on entitlement.

Accessibility: ensure carousel keyboard focus order, provide semantic labels for totals.

---

## 2. Timer Mode Detail

**Sections**
1. **Header**: selected mode name + preset dropdown.
2. **Segment Timeline**: vertical list (current segment highlighted, upcoming dimmed).
3. **Main Timer**: circular progress, remaining time, start/pause/skip buttons.
4. **Sound Controls**: toggle + mixer sliders (for sleep). Provide visual feedback for active sound profile.
5. **Notes/Tags**: collapsible area for focus mode; hidden for other modes.

Responsive: on tablets, place timeline and controls side-by-side.

---

## 3. Statistics Screen

**Tabs**: Daily / Weekly / Monthly.
- Each tab has KPI cards at top (total minutes, streak).
- Below, chart component (bar chart for totals, line for trend).
- Session list at bottom with filter chips (mode, tag).

Premium gate overlay when user lacks entitlement.

---

## 4. Backup & Restore

- Hero banner showing last backup timestamp.
- Buttons for `One-tap Backup`, `Restore`, `Manage Cloud Provider`.
- History list with statuses (success/warning/error icons).
- Secondary card summarising encryption status + link to privacy doc.

---

## 5. Paywall

- Header image place for variant (focus vs backup theme).
- Value props (3 bullet list) with icon per row.
- Pricing cards (monthly, yearly) with badge for recommended.
- FAQ accordion at bottom.

---

## 6. Account & Settings

- Profile section (UID, sign-in state, buttons).
- Subscription status card.
- Data & privacy card linking to policy & deletion flow.
- Backup history (premium gate as implemented).
- Delete account CTA pinned at bottom.

---

### Deliverables
- Convert these notes into Figma wireframes.
- Ensure component library adheres to spacing 8pt grid, use neutral background (#F5F5F5) and accent (seed purple) as defined in theme.
- Include annotations for accessibility (minimum 44x44 tappable targets, text contrast AA+).

