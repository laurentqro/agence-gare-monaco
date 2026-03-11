# GEO Audit Report — Agence Immobilière de la Gare Monaco

**Site:** agencegaremonaco.com
**Date:** 2026-03-11 (Re-audit)
**Previous audit:** 2026-03-10 (Baseline: 48/100)
**Auditor:** Automated GEO Analysis

---

## 1. Executive Summary

Since the baseline audit (2026-03-10, score 48/100), three high-priority quick wins have been implemented:

1. **llms.txt added** — A comprehensive `/llms.txt` endpoint now exists, served via `LlmsController`, with key facts, services, leadership, and social profiles. Route registered at `GET /llms.txt`.
2. **AI bot rules added to robots.txt** — Explicit `User-agent` / `Allow: /` directives now exist for GPTBot, ClaudeBot, PerplexityBot, and Google-Extended.
3. **FAQPage JSON-LD added** — A new `json_ld_faq` helper generates FAQPage schema, deployed on both the gestion (5 Q&As) and vendre (5 Q&As) pages.
4. **Headings rewritten as questions** — The gestion and vendre page headings across all 8 locales are now phrased as natural-language questions (e.g., "Quelles sont les missions de notre agence ?", "How much is your property in Monaco worth?").

These changes address items #1, #2, #3, and #5 from the priority action plan. **Updated overall GEO readiness: 68/100** (+20 points).

---

## 2. Scores

| Category                          | Baseline (Mar 10) | Current (Mar 11) | Delta | Status       |
|-----------------------------------|-------------------|-------------------|-------|--------------|
| AI Crawler Access                 | 60/100            | 85/100            | +25   | Good         |
| llms.txt                          | 0/100             | 90/100            | +90   | Strong       |
| Citability                        | 40/100            | 45/100            | +5    | Fair         |
| Structured Data (JSON-LD)         | 72/100            | 82/100            | +10   | Strong       |
| Content Structure for AI          | 35/100            | 55/100            | +20   | Fair         |
| Brand & Entity Signals            | 82/100            | 82/100            | —     | Strong       |
| **Overall GEO Readiness**         | **48/100**        | **68/100**        | **+20** | **Good** |

---

## 3. What Was Fixed

### 3.1 llms.txt (0 → 90)

- **Created** `app/controllers/llms_controller.rb` — serves plain text at `/llms.txt`
- **Created** `app/views/llms/show.text.erb` — structured content with Key Facts, Leadership, Services, Coverage, Professional Affiliations, and Social Profiles
- **Route** added: `get "llms.txt", to: "llms#show", defaults: { format: :text }`
- **Tests** added in `test/controllers/llms_controller_test.rb`
- **Why not 100:** Could add links to specific property listings and articles; could add `llms-full.txt` with expanded content

### 3.2 AI Crawler Access (60 → 85)

- **robots.txt** now has explicit `User-agent` blocks for:
  - GPTBot (ChatGPT Search)
  - ClaudeBot (Claude)
  - PerplexityBot (Perplexity)
  - Google-Extended (Google AI)
- **Tests** added in `test/controllers/robots_controller_test.rb`
- **Why not 100:** Missing explicit rules for ChatGPT-User, OAI-SearchBot, Claude-Web, Applebot-Extended, Bytespider, cohere-ai, Diffbot, FacebookBot. French homepage sitemap URL inconsistency (`/fr` vs `/`) still present.

### 3.3 Structured Data (72 → 82)

- **FAQPage JSON-LD** added via new `json_ld_faq` helper in `seo_helper.rb`
- **Gestion page** emits FAQPage with 5 Q&A pairs (missions, publication, contract, property life, funds)
- **Vendre page** emits FAQPage with 5 Q&A pairs (estimate, documents, mandate, selling, funds)
- **Tests** added in `test/helpers/seo_helper_test.rb`
- **Why not 100:** WebSite JSON-LD still missing from homepage. `RealEstateListing` still uses `InStock` availability. No `VideoObject` schema for YouTube videos.

### 3.4 Content Structure for AI (35 → 55)

- **Gestion headings** (all 8 locales) rewritten as questions:
  - "Quelles sont les missions de notre agence ?"
  - "Comment publions-nous votre bien et sélectionnons-nous les candidats ?"
  - "Comment rédigeons-nous le contrat de location ?"
  - "Comment suivons-nous la vie de votre bien ?"
  - "Comment gérons-nous vos fonds ?"
- **Vendre headings** (all 8 locales) rewritten as questions:
  - "Comment estimer la valeur de votre bien à Monaco ?"
  - "Quels documents sont nécessaires pour vendre à Monaco ?"
  - "Comment vendons-nous votre bien ?"
  - "Quand et comment les fonds sont-ils versés ?"
- **Why not 100:** Homepage about text still too long (~250 words). No dedicated FAQ page. No business hours. Listing page headings still generic ("Sales", "Rentals").

### 3.5 Citability (40 → 45)

- Slight improvement from question-style headings making sections more extractable
- **Why not higher:** Homepage about text still not chunked. Meta descriptions not yet enriched with specific data points.

---

## 4. Remaining Action Items

Ordered by **impact vs effort** (highest ROI first):

| # | Action | Impact | Effort | Category | Baseline Item |
|---|--------|--------|--------|----------|---------------|
| 1 | Add `WebSite` JSON-LD to homepage | Medium | 15 min | Structured Data | #4 |
| 2 | Fix `RealEstateListing` availability value (remove `InStock`) | Low | 10 min | Structured Data | #11 |
| 3 | Add remaining AI bot rules (ChatGPT-User, OAI-SearchBot, etc.) | Medium | 15 min | AI Crawler Access | #2 (partial) |
| 4 | Add business hours to Organization schema and contact page | Medium | 20 min | Entity Signals | #6 |
| 5 | Standardize brand name to "Agence Immobilière de la Gare" everywhere | Medium | 30 min | Entity Signals | #7 |
| 6 | Break homepage "About Us" text into ~150-word citation blocks | Medium | 30 min | Citability | #8 |
| 7 | Enrich meta descriptions with specific data points | Medium | 45 min | Citability | #10 |
| 8 | Add fact-rich FAQ section to homepage | High | 1-2 hours | Content Structure | #9 |
| 9 | Fix French homepage sitemap URL inconsistency | Low | 15 min | AI Crawler Access | #12 |
| 10 | Create dedicated FAQ page with common Monaco real estate questions | High | 2-3 hours | Content Structure | #14 |
| 11 | Add individual team member pages with bios | Medium | 2-3 hours | Entity Signals | #13 |
| 12 | Add `VideoObject` JSON-LD for YouTube videos | Low | 30 min | Structured Data | #15 |

---

## 5. Score Methodology

Each category is scored 0-100 based on:
- **AI Crawler Access:** Explicit bot rules, sitemap quality, staging protection
- **llms.txt:** Presence, completeness, structured format, key facts coverage
- **Citability:** Self-contained blocks, fact density, optimal length (134-167 words), Q&A phrasing
- **Structured Data:** Schema types present, validation correctness, coverage of pages
- **Content Structure for AI:** Question-style headings, FAQ sections, business hours, JS rendering
- **Brand & Entity Signals:** NAP consistency, sameAs links, author signals, founding date

**Overall** = weighted average (AI Crawler Access 15%, llms.txt 15%, Citability 20%, Structured Data 20%, Content Structure 15%, Brand & Entity 15%).

---

## 6. Current State of AI Crawler Access

The production robots.txt now renders as:
```
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /rails/

User-agent: GPTBot
Allow: /

User-agent: ClaudeBot
Allow: /

User-agent: PerplexityBot
Allow: /

User-agent: Google-Extended
Allow: /

Sitemap: https://agencegaremonaco.com/sitemap.xml
```

| Crawler            | Bot Name           | Status               |
|--------------------|--------------------|----------------------|
| ChatGPT Search     | GPTBot             | ALLOWED (explicit)   |
| ChatGPT Browse     | ChatGPT-User       | ALLOWED (implicit)   |
| Claude             | ClaudeBot           | ALLOWED (explicit)   |
| Claude Web         | Claude-Web          | ALLOWED (implicit)   |
| Perplexity         | PerplexityBot       | ALLOWED (explicit)   |
| Google AI          | Google-Extended     | ALLOWED (explicit)   |
| Google Search      | Googlebot           | ALLOWED (implicit)   |
| Bing               | Bingbot             | ALLOWED (implicit)   |
| OpenAI Search      | OAI-SearchBot       | ALLOWED (implicit)   |
| Apple              | Applebot-Extended   | ALLOWED (implicit)   |
| ByteDance          | Bytespider          | ALLOWED (implicit)   |
| Cohere             | cohere-ai           | ALLOWED (implicit)   |
| Diffbot            | Diffbot             | ALLOWED (implicit)   |
| Facebook           | FacebookBot         | ALLOWED (implicit)   |

---

## 7. Current Structured Data Inventory

| Schema Type        | Present? | Location | Status |
|-------------------|----------|----------|--------|
| RealEstateAgent   | Yes      | All pages | Good |
| RealEstateListing | Yes      | Property detail pages | Good (minor: `InStock` issue) |
| Article           | Yes      | Article pages | Good |
| BreadcrumbList    | Yes      | Listing pages | Good |
| FAQPage           | **Yes (NEW)** | Gestion + Vendre pages | Good — 5 Q&As each |
| WebSite           | No       | — | Recommended for homepage |
| VideoObject       | No       | — | Optional for YouTube videos |
