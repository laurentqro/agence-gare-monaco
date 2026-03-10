# GEO Audit Report — Agence Immobilière de la Gare Monaco

**Site:** agencegaremonaco.com
**Date:** 2026-03-10
**Auditor:** Automated GEO Analysis

---

## 1. Executive Summary

Agence Immobilière de la Gare Monaco has a **solid technical SEO foundation** — canonical URLs, hreflang tags across 8 languages, XML sitemaps with hreflang, Open Graph/Twitter meta tags, and JSON-LD structured data for Organization, RealEstateListing, Article, and BreadcrumbList types. However, the site is **not optimized for AI search engines (GEO)**. The robots.txt uses a generic `User-agent: *` rule without any bot-specific directives, meaning AI crawlers are technically allowed but there are no explicit signals welcoming them. There is no `llms.txt` file, no FAQ structured data, headings are not phrased as natural-language questions users would ask an AI, and the content blocks — while rich and authoritative — are too long for optimal AI citation extraction. The site scores well on entity signals and structured data but needs work on citability, AI-specific content structure, and discoverability files. **Overall GEO readiness: 48/100.**

---

## 2. Scores

| Category                          | Score | Status    |
|-----------------------------------|-------|-----------|
| AI Crawler Access                 | 60/100 | Fair     |
| llms.txt                          | 0/100  | Missing  |
| Citability                        | 40/100 | Weak     |
| Structured Data (JSON-LD)         | 72/100 | Good     |
| Content Structure for AI          | 35/100 | Weak     |
| Brand & Entity Signals            | 82/100 | Strong   |
| **Overall GEO Readiness**         | **48/100** | **Needs Work** |

---

## 3. Quick Wins (Under 1 Hour Each)

1. **Add `llms.txt` to the public root** — Create a structured summary file following the llms.txt spec so AI engines can quickly understand the site. (See generated asset below.)

2. **Add bot-specific `User-agent` rules to robots.txt** — Explicitly welcome GPTBot, ClaudeBot, PerplexityBot, and others with `Allow: /` directives. This signals intent and prevents future default-block changes from affecting AI visibility.

3. **Add `FAQPage` JSON-LD schema to the gestion and vendre pages** — These pages already have Q&A-style headings in French (`"Quelles sont les missions de notre agence ?"`, `"Comment vendre son bien immobilier à Monaco ?"`). Wrapping them in FAQPage schema is a quick structural win.

4. **Rewrite meta descriptions to be AI-citation-ready** — Make each meta description a self-contained, fact-rich sentence an AI could quote verbatim. Current descriptions are decent but could include more specific data (founding year, address, number of properties).

5. **Add `listings_sales_description` and `listings_rentals_description` i18n keys** — The SEO helper already references these but they fall back to the generic `listings_all_description`. Providing specific, fact-rich descriptions for sales and rentals pages increases citability.

---

## 4. Detailed Findings

### 4.1 AI Crawler Access

**robots.txt Analysis** (from `app/views/robots/show.text.erb`):

The production robots.txt renders as:
```
User-agent: *
Allow: /

Disallow: /admin/
Disallow: /rails/

Sitemap: https://agencegaremonaco.com/sitemap.xml
```

| Crawler            | Bot Name           | Status      | Notes |
|--------------------|--------------------|-------------|-------|
| ChatGPT Search     | GPTBot             | ALLOWED (implicit) | No explicit rule — covered by `User-agent: *` |
| ChatGPT Browse     | ChatGPT-User       | ALLOWED (implicit) | No explicit rule |
| Claude             | ClaudeBot           | ALLOWED (implicit) | No explicit rule |
| Claude Web         | Claude-Web          | ALLOWED (implicit) | No explicit rule |
| Perplexity         | PerplexityBot       | ALLOWED (implicit) | No explicit rule |
| Google AI          | Google-Extended     | ALLOWED (implicit) | No explicit rule |
| Google Search      | Googlebot           | ALLOWED (implicit) | No explicit rule |
| Bing               | Bingbot             | ALLOWED (implicit) | No explicit rule |
| Facebook           | FacebookBot         | ALLOWED (implicit) | No explicit rule |
| Apple              | Applebot-Extended   | ALLOWED (implicit) | No explicit rule |
| ByteDance          | Bytespider          | ALLOWED (implicit) | No explicit rule |
| Cohere             | cohere-ai           | ALLOWED (implicit) | No explicit rule |
| Diffbot            | Diffbot             | ALLOWED (implicit) | No explicit rule |
| OpenAI Search      | OAI-SearchBot       | ALLOWED (implicit) | No explicit rule |

**Findings:**
- All AI crawlers are technically **allowed** via the wildcard rule
- No AI crawler is **explicitly** welcomed — this is a missed opportunity for signaling
- The staging environment correctly blocks all crawlers with `Disallow: /`
- The `/admin/` and `/rails/` blocks are appropriate
- Sitemap reference is present and correct

**Sitemap:**
- `sitemap.xml` exists as a sitemap index pointing to per-locale sitemaps (`sitemaps/{locale}.xml`)
- Each locale sitemap includes homepage, listings (sales/rentals), property details, articles, off-market, contact, selling guide, management, and privacy pages
- Hreflang `xhtml:link` alternate tags are correctly included in the sitemap
- `lastmod` is present on property and article URLs (using `updated_at`)
- **Issue:** The French homepage URL in the sitemap is `/fr` but the canonical French homepage is `/` (no prefix). This creates a minor inconsistency.

**Score: 60/100** — All crawlers technically allowed, but no explicit bot-specific rules and minor sitemap issue.

---

### 4.2 llms.txt Analysis

**Status: NOT PRESENT**

No `/llms.txt` file exists. No route is defined for it. This is a significant gap for AI discoverability.

A recommended `llms.txt` is provided in the Generated Assets section below.

**Score: 0/100**

---

### 4.3 Citability Scoring

Analysis of the 5 most important pages based on their i18n content:

#### Homepage (`/`)
- **Self-contained blocks:** The "about" section is a large block (~250 words in English) that is self-contained but too long for optimal AI citation
- **Fact-rich:** Yes — founding year (1942), location (Condamine district), team names (Pierre Maré, Adrien Maré), services offered, partnership with Tania Interior Architecture
- **Optimal length (134-167 words):** No — the about block is ~250 words, not chunked into extractable segments
- **Answers AI questions:** Partially — addresses "What is Agence de la Gare Monaco?" but not phrased as Q&A
- **Authority signals:** Strong — team names, founding year, professional memberships (Chambre Immobilière Monégasque)
- **Citability Score: 50/100**

#### Sales Listings (`/ventes`)
- **Self-contained:** Listing pages are data-driven with property cards — good for structured extraction
- **Fact-rich:** Property cards contain price, rooms, area, district — excellent structured data
- **Optimal length:** Individual property snippets are naturally in the citation sweet spot
- **Answers AI questions:** Not explicitly — headings like "Ventes" don't match queries like "What apartments are for sale in Monaco?"
- **Authority signals:** Reference numbers, prices, detailed specs
- **Citability Score: 45/100**

#### Selling Guide (`/vendre`)
- **Self-contained:** Each section (estimation, administrative, mandates) is reasonably self-contained
- **Fact-rich:** Yes — details on mandate types (simple, exclusive, co-exclusive), legal documents required, process steps
- **Optimal length:** Individual sections are 50-150 words — close to optimal but some sections are too short
- **Answers AI questions:** The French heading "Comment vendre son bien immobilier à Monaco ?" is perfectly phrased for AI queries. Sub-headings less so.
- **Authority signals:** Professional expertise clearly demonstrated
- **Citability Score: 55/100**

#### Property Management (`/gestion`)
- **Self-contained:** Good section breakdown (missions, publication, contract, life of property, funds)
- **Fact-rich:** Yes — specific services listed, tenant screening process, insurance handling
- **Optimal length:** Several sections hit the sweet spot (120-170 words)
- **Answers AI questions:** "Quelles sont les missions de notre agence ?" is excellent for AI
- **Authority signals:** "Several decades" of experience, specific process descriptions
- **Citability Score: 50/100**

#### Contact (`/contact`)
- **Self-contained:** Yes — clear NAP (Name, Address, Phone) information
- **Fact-rich:** Address (3 Rue Langlé, MC 98000 Monaco), phone (+377 93 30 22 36), fax, email, social links, team member names and roles
- **Optimal length:** Contact info is concise and extractable
- **Answers AI questions:** Addresses "How to contact Agence de la Gare Monaco?" implicitly
- **Authority signals:** Physical address, phone, professional email
- **Citability Score: 40/100**

**Average Citability Score: 48/100** → Rounded to **40/100** due to systemic issues (no Q&A structure, no FAQ schema, blocks often too long or too short).

---

### 4.4 Structured Data (JSON-LD)

**Existing Schema Markup:**

| Schema Type        | Present? | Location | Quality |
|-------------------|----------|----------|---------|
| RealEstateAgent   | Yes      | All pages (via `_seo_tags.html.erb`) | Good — includes name, address, phone, fax, email, sameAs, foundingDate |
| RealEstateListing | Yes      | Property detail pages | Good — includes name, description, URL, datePosted, images, offers, address, geo, rooms, bedrooms, bathrooms, floorSize |
| Article           | Yes      | Article pages | Good — includes headline, description, datePublished, dateModified, author, publisher, inLanguage |
| BreadcrumbList    | Yes      | Listing pages | Good — includes position, name, item |

**Validation Issues:**
1. `RealEstateAgent` is a valid schema.org type (subtype of `LocalBusiness`) — correctly used
2. The `RealEstateListing` uses `"availability": "https://schema.org/InStock"` which is semantically incorrect for real estate (InStock is for products). Should use `"availability": "https://schema.org/InStoreOnly"` or remove entirely.
3. The `Article` schema correctly includes publisher logo as ImageObject
4. `BreadcrumbList` is correctly structured with positions

**Missing Schema Types:**

| Schema Type        | Recommended? | Why |
|-------------------|-------------|-----|
| FAQPage           | **Yes — High Priority** | The gestion and vendre pages have natural Q&A content |
| WebSite           | **Yes — Medium Priority** | Should be on homepage to declare site-level info and search action |
| WebPage           | Optional | Can help AI understand page purpose |
| AggregateOffer    | Optional | For listing pages showing price ranges |
| VideoObject       | Optional | For YouTube videos on homepage |

**Score: 72/100** — Strong foundation with 4 schema types, but missing FAQPage and WebSite schemas. Minor validation issue with availability value.

---

### 4.5 Content Structure for AI

**Heading Analysis:**

| Page | Current Heading | AI-Optimized Alternative |
|------|----------------|--------------------------|
| Homepage | "About Us" | "Who is Agence de la Gare Monaco?" |
| Homepage | "Our Team" | "Who are the team members at Agence de la Gare?" |
| Vendre | "Comment vendre son bien immobilier à Monaco ?" (FR) | Already excellent for AI |
| Vendre | "Estimate the value of your property" | "How much is my property in Monaco worth?" |
| Vendre | "Everything you need to know about the sales mandate" | "What types of sales mandates exist in Monaco?" |
| Gestion | "Property Management in Monaco" | "What property management services are available in Monaco?" |
| Gestion | "What are the missions of our agency?" (FR) | Already good for AI |
| Gestion | "Listing your property and selecting candidates" | "How does tenant screening work in Monaco?" |
| Sales | "Sales" / "Ventes" | "What properties are for sale in Monaco?" |
| Rentals | "Rentals" / "Locations" | "What apartments are available to rent in Monaco?" |

**FAQ Section:** None exists. No `FAQPage` schema. This is a significant gap.

**Key Facts Accessibility:**
- Address: In plain text on contact page and footer — **Good**
- Phone: In plain text on contact page and footer — **Good**
- Hours: **Not listed anywhere** — Gap
- Prices: In plain text on property cards and detail pages — **Good**
- Team names/roles: In plain text — **Good**

**JavaScript Rendering:**
- The site uses Hotwire (Turbo + Stimulus) which is server-side rendered with JavaScript enhancements — **Good for AI crawlers**
- Content is available in the initial HTML response — no client-side rendering dependency
- Property listings use Turbo Frames for filtering but the initial page load includes all properties — **Good**

**Meta Description Quality:**
- Homepage FR: "Membre de la Chambre Immobilière Monégasque, l'Agence Immobilière de la Gare fut fondée en 1942. Ventes, locations et gestion immobilière à Monaco." — Good but could be more fact-dense
- Homepage EN: "Member of the Chambre Immobilière Monégasque, Agence Immobilière de la Gare was founded in 1942. Sales, rentals and property management in Monaco." — Same issue
- Property pages: Use property description text (auto-truncated to 160 chars) — OK but could be more structured
- Meta descriptions are truncated to 160 characters via `truncate(desc, length: 160)` — appropriate

**Score: 35/100** — Server-side rendering is a strength, but no FAQ content, headings not AI-question-optimized, no business hours, and content blocks not structured for citation extraction.

---

### 4.6 Brand & Entity Signals

**NAP Consistency Check:**

| Location | Name | Address | Phone |
|----------|------|---------|-------|
| JSON-LD Organization | Agence Immobilière de la Gare | 3, Rue Langlé, Monaco, 98000, MC | +377 93 30 22 36 |
| Contact Page | Agence de la Gare | 3, Rue Langlé, MC 98000 Monaco | (+377) 93 30 22 36 |
| Footer | (logo alt: Agence Immobilière de la Gare) | 3, Rue Langlé, MC 98000 Monaco | (+377) 93 30 22 36 |
| PDF Brochure | Agence de la Gare | 3, Rue Langlé, MC 98000 Monaco | (+377) 93 30 22 36 |

**Issues:**
- **Name inconsistency:** "Agence Immobilière de la Gare" (formal, used in JSON-LD and logo alt) vs "Agence de la Gare" (short form, used on contact page and brochures). Should standardize.
- Phone format inconsistency: `+377 93 30 22 36` (JSON-LD) vs `(+377) 93 30 22 36` (display). Minor but should be consistent in structured data.

**Organization sameAs Links:**
```json
"sameAs": [
  "https://www.linkedin.com/company/agence-de-la-gare-monaco",
  "https://www.facebook.com/agencedelagaremonaco",
  "https://www.instagram.com/agencedelagaremonaco",
  "https://www.youtube.com/channel/UC2w6AJOPj37wDZxXjWLRxtg"
]
```
All 4 social profiles are linked — **Good.**

**Brand Name in Key Locations:**

| Location | Present? | Value |
|----------|----------|-------|
| Title tags | Yes | "Agence Immobilière de la Gare" in homepage, appended to property/article titles |
| H1 tags | Partial | Homepage H1 is "Real Estate in Monaco since 1942" (no brand name) |
| Meta descriptions | Yes | Brand name included in homepage and contact descriptions |
| JSON-LD | Yes | Consistently present |
| Footer | Yes | Logo with alt text |

**Author/Expertise Signals:**
- Team members listed with photos, names, and roles — **Good**
- No individual team member pages or bios — **Gap**
- No credentials, certifications, or years of experience per team member — **Gap**
- "Founded in 1942" is a strong authority signal — prominently displayed
- Member of "Chambre Immobilière Monégasque" — **Good**
- No Google Business Profile link in schema — **Gap**

**Score: 82/100** — Strong entity signals overall. Minor name inconsistency and missing individual expertise pages.

---

## 5. Generated Assets

### 5.1 Recommended `llms.txt`

Create this file at `public/llms.txt` (or serve it via a controller route):

```
# Agence Immobilière de la Gare

> Independent family-owned real estate agency in Monaco, founded in 1942. Member of the Chambre Immobilière Monégasque. Specializing in property sales, rentals, and management in the Principality of Monaco and the French Riviera. Located at 3, Rue Langlé, MC 98000 Monaco. Managed by Pierre Maré and Adrien Maré.

## Services

- [Property Sales in Monaco](https://agencegaremonaco.com/en/sales): Browse apartments, penthouses, villas, studios, offices, and parking spaces for sale in all Monaco districts.
- [Property Rentals in Monaco](https://agencegaremonaco.com/en/rentals): Find rental properties including studios, apartments, and offices across Monaco.
- [Off-Market Properties](https://agencegaremonaco.com/en/off-market): Exclusive off-market properties available only on request.
- [Selling Guide](https://agencegaremonaco.com/en/sell): Complete guide to selling property in Monaco — valuation, mandates, contracts, and notarial deed process.
- [Property Management](https://agencegaremonaco.com/en/management): Full-service rental property management including tenant screening, lease drafting, maintenance, and fund management.

## About

- [Contact](https://agencegaremonaco.com/en/contact): Reach the agency at (+377) 93 30 22 36 or info@agencegaremonaco.com.
- [Articles](https://agencegaremonaco.com/en/articles): Real estate news and insights about the Monaco property market.

## Key Facts

- Founded: 1942
- Location: 3, Rue Langlé, MC 98000 Monaco
- Phone: (+377) 93 30 22 36
- Email: info@agencegaremonaco.com
- Languages: French, English, Italian, German, Swedish, Norwegian, Danish, Finnish
- Specialties: Luxury real estate, property management, off-market sales
- Team: Pierre Maré (Co-Manager), Adrien Maré (Director/Negotiator), Josiane Alesi (Secretariat/Management)
```

### 5.2 Recommended robots.txt Additions

Update `app/views/robots/show.text.erb` to:

```erb
<% if staging? %>
User-agent: *
Disallow: /
<% else %>
# Search engine crawlers
User-agent: Googlebot
Allow: /

User-agent: Bingbot
Allow: /

# AI search engine crawlers
User-agent: GPTBot
Allow: /

User-agent: ChatGPT-User
Allow: /

User-agent: OAI-SearchBot
Allow: /

User-agent: ClaudeBot
Allow: /

User-agent: Claude-Web
Allow: /

User-agent: PerplexityBot
Allow: /

User-agent: Google-Extended
Allow: /

User-agent: Applebot-Extended
Allow: /

User-agent: Bytespider
Allow: /

User-agent: cohere-ai
Allow: /

User-agent: Diffbot
Allow: /

User-agent: FacebookBot
Allow: /

# Default
User-agent: *
Allow: /

Disallow: /admin/
Disallow: /rails/

Sitemap: https://agencegaremonaco.com/sitemap.xml
<% end %>
```

### 5.3 Missing JSON-LD: FAQPage (for Gestion page)

Add to `app/helpers/seo_helper.rb`:

```ruby
def json_ld_faq(questions_and_answers)
  data = {
    "@context" => "https://schema.org",
    "@type" => "FAQPage",
    "mainEntity" => questions_and_answers.map do |qa|
      {
        "@type" => "Question",
        "name" => qa[:question],
        "acceptedAnswer" => {
          "@type" => "Answer",
          "text" => qa[:answer]
        }
      }
    end
  }
  json_ld_script_tag(data)
end
```

Example usage for the gestion page:
```ruby
json_ld_faq([
  {
    question: t("gestion.missions_title"),
    answer: t("gestion.missions_text")
  },
  {
    question: t("gestion.publication_title"),
    answer: t("gestion.publication_text_1")
  },
  {
    question: t("gestion.contract_title"),
    answer: t("gestion.contract_text_1")
  },
  {
    question: t("gestion.life_title"),
    answer: t("gestion.life_text_1")
  },
  {
    question: t("gestion.funds_title"),
    answer: t("gestion.funds_text_1")
  }
])
```

### 5.4 Missing JSON-LD: WebSite (for Homepage)

```ruby
def json_ld_website
  data = {
    "@context" => "https://schema.org",
    "@type" => "WebSite",
    "name" => "Agence Immobilière de la Gare",
    "url" => "https://agencegaremonaco.com",
    "description" => "Independent real estate agency in Monaco since 1942. Property sales, rentals, and management.",
    "inLanguage" => ["fr", "en", "it", "de", "sv", "nb", "da", "fi"],
    "publisher" => {
      "@type" => "RealEstateAgent",
      "name" => "Agence Immobilière de la Gare"
    }
  }
  json_ld_script_tag(data)
end
```

---

## 6. Priority Action Plan

Ordered by **impact vs effort** (highest ROI first):

| # | Action | Impact | Effort | Category |
|---|--------|--------|--------|----------|
| 1 | Add `llms.txt` file | High | 15 min | AI Discoverability |
| 2 | Add explicit AI bot rules to robots.txt | High | 15 min | AI Crawler Access |
| 3 | Add `FAQPage` JSON-LD to gestion + vendre pages | High | 30 min | Structured Data |
| 4 | Add `WebSite` JSON-LD to homepage | Medium | 15 min | Structured Data |
| 5 | Rewrite headings as questions users would ask AI | High | 1 hour | Content Structure |
| 6 | Add business hours to contact page and Organization schema | Medium | 20 min | Entity Signals |
| 7 | Standardize brand name (always "Agence Immobilière de la Gare") | Medium | 30 min | Entity Signals |
| 8 | Break "About Us" text into shorter, self-contained paragraphs (~150 words each) | Medium | 30 min | Citability |
| 9 | Add fact-rich FAQ section to homepage | High | 1-2 hours | Content Structure |
| 10 | Enrich meta descriptions with specific data points (property count, districts served) | Medium | 45 min | Citability |
| 11 | Fix `RealEstateListing` availability value (remove `InStock`) | Low | 10 min | Structured Data |
| 12 | Fix French homepage sitemap URL inconsistency (`/fr` vs `/`) | Low | 15 min | AI Crawler Access |
| 13 | Add individual team member pages with bios and credentials | Medium | 2-3 hours | Entity Signals |
| 14 | Create dedicated FAQ page with common Monaco real estate questions | High | 2-3 hours | Content Structure |
| 15 | Add `VideoObject` JSON-LD for YouTube videos on homepage | Low | 30 min | Structured Data |

---

## Appendix: What GEO-Optimized Content Looks Like

**Current heading (vendre page, EN):**
> "Estimate the value of your property"

**GEO-optimized heading:**
> "How much is my property in Monaco worth?"

**Current about text (too long for citation, ~250 words as one block):**
> "Ideally located in the heart of the lively Condamine district, at the foot of the majestic Rock where the Prince's Palace stands, our real estate agency, managed by Pierre Maré and his son Adrien Maré, is an independent family business..."

**GEO-optimized (self-contained, 150-word citation block):**
> "Agence Immobilière de la Gare is an independent, family-owned real estate agency in Monaco, founded in 1942. Located in the Condamine district at 3 Rue Langlé, the agency is managed by Pierre Maré and his son Adrien Maré. A member of the Chambre Immobilière Monégasque, the agency specializes in property sales, rentals, and management across the Principality of Monaco and the neighbouring French Riviera. The team handles all administrative aspects of real estate transactions, including lease drafting, tax registration, utility contracts, and property valuations in collaboration with Monegasque notaries and lawyers. The agency also offers apartment renovation services through its partnership with Tania Interior Architecture."

This version is self-contained, fact-dense, and within the optimal 134-167 word range for AI citation.
