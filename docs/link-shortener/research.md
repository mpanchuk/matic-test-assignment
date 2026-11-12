# Research: buy prices and build capacity

Inputs for the build vs. buy section of the spec. Volume is the team's figure: ~1.5M links created per month (`docs/clarifications.md`, Task 2 Q3), which is about 49,000 a day and 18M a year.

Prices checked on 12 Nov 2026. Vendors change plans often (Rebrandly raised its Growth price in Oct 2026), so re-check before quoting numbers to the team.

## Part 1: Off-the-shelf shorteners at 1.5M links per month

All four offer an API and custom domains. None of their self-serve plans comes close to 1.5M links a month: the largest ones allow 3,000–50,000. Every option therefore needs an enterprise or contract plan, and only Short.io lists a price for one.

| Vendor | Plan needed | Cost at 1.5M links/month | Largest self-serve plan |
|---|---|---|---|
| Bitly | Enterprise | Not published. One competitor estimates ~$10,000/year or more, with no stated basis. | Premium: 3,000 links/month, $199/month billed annually |
| Rebrandly | High Volume API or Enterprise (contract) | Not published, quote only | Growth: 3,500 links/month, $149/month ($104 billed annually) |
| Short.io | Enterprise | Listed at $148/month (~$1,800/year). Not confirmed for this volume, see below. | Team: 100,000 API-created links/year, $48/month |
| Dub | Enterprise | Not published ("Custom") | Advanced: 600,000 links/year (50,000/month), $270/month as shown |

Real figures for any of them require a sales quote.

### Bitly

- **Plan needed:** Enterprise. Premium, the top public plan, allows 3,000 links a month, 500 times less than needed.
- **Cost:** "Custom Pricing". The only public figure is Linkly's estimate of "around $10,000 per year or more" (Feb 2026). Linkly is a competitor and gives no basis for the estimate, so treat it as a rough floor, not a price.
- **Limits that matter:**
  - The API has per-hour and per-minute limits on top of the monthly quota. Going over returns HTTP 429, and the caller must wait for the window to reset. Bitly doesn't publish the numbers. Its docs use 1,000 calls/hour on `/v4/shorten` as an example, and at our volume that wouldn't cover even the average rate of ~2,050 links an hour.
  - Raising the hourly limits "requires a subscription to a custom enterprise-level account", so the contract must state the hourly limit, not just the monthly one.
- **Sources:**
  - [Bitly pricing](https://bitly.com/pages/pricing): plans, link quotas, Enterprise "High-volume API & webhook access"
  - [Bitly API rate limits](https://dev.bitly.com/docs/getting-started/rate-limits/): per-hour/per-minute limits, 429 behaviour, how to raise them
  - [Linkly: Bitly Enterprise pricing](https://linklyhq.com/blog/bitly-enterprise-pricing): the ~$10,000/year estimate

### Rebrandly

- **Plan needed:** High Volume API or Enterprise. The link quota is "defined in your subscription plan contract".
- **Cost:** not published. Rebrandly's high-volume developer page refers to the pricing page and the contract, and the pricing page lists Enterprise as "Custom".
- **Limits that matter:**
  - **Expiry is mandatory on the high-volume API:** "Every link must have an expiration", between 1 hour and 90 days. Longer values are capped without an error, and "links are deleted automatically when they expire." That suits SMS links that should expire, but it rules out links that live longer than 90 days.
  - **Throughput:** by default, 1 request per second with up to 25 links each, which is 25 links/s. The "enhanced" limit goes up to 40 requests/s. 25 links/s is above our estimated burst (Part 2), but not by much.
  - **At the contracted limit,** you "may be blocked from creating additional links". Overage is only available if the account manager agrees.
- **Sources:**
  - [Rebrandly pricing](https://www.rebrandly.com/pricing): self-serve plans, Enterprise "Custom"
  - [PulseSignal: Rebrandly pricing](https://getpulsesignal.com/pricing/rebrandly): Growth at $149 monthly / $104 annual, raised from $99 on 2026-10-13, checked 2026-11-10. Used because Rebrandly's own page doesn't show which price belongs to which billing period.
  - [Rebrandly: creating links at scale for SMS](https://developers.rebrandly.com/docs/high-volume-link-creation): mandatory expiry, throughput, contract quota
  - [Rebrandly: reaching the link limit](https://support.rebrandly.com/en/articles/786535-what-happens-if-i-reach-my-link-limit-on-a-billed-plan): blocking at the contracted limit

### Short.io

- **Plan needed:** Enterprise. It is the only plan with unlimited links created through the API. Team allows 100,000 a year and Pro 10,000.
- **Cost:** the pricing page lists Enterprise at $148/month and offers 17% off for annual billing. It doesn't say which billing period the $148 is for. The Enterprise page, however, says "Request a quote" and mentions "tiered volume discounts based on number of links created". So $148 is a listed price, not a confirmed price for 18M links a year.
- **Limits that matter:**
  - **"Unlimited" depends on a fair-use policy:** "we still enforce a fair usage policy to prevent abuse of the service". No thresholds are published. Get written confirmation that 1.5M links a month is acceptable before relying on the $148 figure.
  - **API rate:** 50 requests/s on every plan. Extra capacity costs $50/month per additional 50 requests/s.
  - **Analytics** are kept for 26 months.
  - **SLA:** 99.9% uptime, with service credits issued automatically if they miss it.
- **Sources:**
  - [Short.io pricing](https://www.short.io/pricing): plans, prices, link and API limits
  - [Short.io Enterprise](https://www.short.io/enterprise/): quote, volume discounts, rate-limit add-on, SLA, retention
  - [Short.io: "Unlimited means unlimited"](https://docs.short.io/articles/short.io-basics-and-security/get-started/unlimited-means-unlimited:-understanding-our-link-shortener-service): fair-use policy

### Dub

- **Plan needed:** Enterprise. Advanced, the top public plan, allows 600,000 links a year (50,000 a month), 30 times less than needed.
- **Cost:** "Custom". The pricing page shows Advanced at $270/month and offers 10% off for yearly billing.
- **Limits that matter:**
  - **API rate:** 3,000 requests/minute on Advanced. Enterprise is "Custom", so the contract must state it.
  - **Bulk endpoint:** creates up to 100 links per call, which fits a message with several links.
  - **Limits per year, not per month:** the self-serve quotas are stated per year.
- **Sources:**
  - [Dub pricing (links)](https://dub.co/pricing/links): plans, yearly link quotas, Enterprise "Custom"
  - [Dub API rate limits](https://dub.co/docs/api-reference/rate-limits): limits per plan, bulk creation

### Also relevant: shortening built into the SMS provider (Twilio as an example)

This isn't a standalone shortener, but it's a third way to "buy": some SMS providers shorten links inside the messages they send. It only applies if Matic sends SMS through a provider that offers this, and I don't know which provider Matic uses.

- **Cost:** Twilio's Engagement Suite (link shortening, click tracking and scheduling) "costs $0.015 per outbound SMS (with the first 1,000 free monthly)". It is billed on top of the base $0.0083 per 160-character segment.
  - The page doesn't say whether the fee applies to every outbound SMS or only to messages that use these features.
  - Upper bound if each of the 1.5M links goes in its own SMS: about **$22,500/month**. It's lower if messages often carry several links.
  - At this volume it is likely the most expensive of the options with a known price.
- **Limits that matter:**
  - You must own the short domain.
  - Twilio keeps the mapping from short link to long URL for **90 days**. After that the link redirects to a fallback URL.
  - Click events are reported as either `click` or `preview`, so link previews are separated from real opens.
- **Sources:**
  - [Twilio SMS pricing (US)](https://www.twilio.com/en-us/sms/pricing/us): Engagement Suite and base SMS rates
  - [Twilio link shortening docs](https://www.twilio.com/docs/messaging/features/link-shortening): own domain, 90-day mapping, click/preview events

## Part 2: Capacity estimate for building it

### Assumptions

| # | Assumption | Basis |
|---|---|---|
| A1 | 1.5M links per month, 30.4 days per month: ~49,300 links a day and 18M a year | Team's answer, clarifications Q3 |
| A2 | Links are created when an SMS is generated, during call-center working hours: 22 working days × 10 hours a month. All volume is placed in those hours. | Assumption. Squeezing all volume into working hours raises the peak, so the estimate errs high. |
| A3 | The busiest hour has 2× the average working-hour rate | Assumption |
| A4 | Worst plausible burst: a batch job sends a full day's links within one hour | Assumption. It's unknown whether the SMS system sends in batches. |
| A5 | 3 redirect hits per link: about 2 opens by the customer and 1 by a link preview or security scanner | Clarifications assumed "a handful" of clicks. Preview and scanner fetches of SMS links are covered in `ai-arguments.md`, and Twilio reports them as a separate event type. |
| A6 | Most clicks come soon after the SMS arrives, so redirect peaks follow creation peaks | Assumption |
| A7 | Average destination URL is 200 bytes (a policy page URL with an ID or token) | Assumption. Each extra 100 bytes adds 1.8 GB a year. |
| A8 | Storage uses PostgreSQL. Bytes per row were **measured**, not estimated: 1M rows inserted into a local PostgreSQL 14, with indexes in place before the insert (so they fill up as they would in production), then sized with `pg_total_relation_size`. | Links table: `id`, 8-char `code` (unique), `destination_url`, `client_id`, `idempotency_key` (unique per client), `created_at`, `expires_at` (indexed), `revoked_at`, `click_count` |
| A9 | Creation rates are in links per second. If the API takes a batch of links per call, requests per second will be lower. | |

### Requests per second

| | Per month | Average | Working-hours average (A2) | Peak hour (A3) | Burst (A4) |
|---|---|---|---|---|---|
| Link creation | 1.5M | 0.57/s | 1.9/s | 3.8/s | 13.7/s |
| Redirects (A5, A6) | 4.5M | 1.7/s | 5.7/s | 11.4/s | 41/s |

### Storage per year

| Data | Rows per year | Bytes per row incl. indexes (measured) | Per year |
|---|---|---|---|
| Links | 18M | 437 (heap 315 + indexes 122) | 7.9 GB |
| Click counter only (column on `links`) | none | 0 extra | 0 |
| Click events, minimal (`link_id`, time, click/preview) | 54M | 107 | 5.8 GB |
| Click events including User-Agent (~150 bytes) | 54M | 264 | 14.3 GB |

The figures above leave out backups, WAL, and load balancer or web server access logs. Access logs record every redirect unless they are configured not to, and their size depends on log retention, which isn't decided yet.

### What the numbers say

- **Throughput is small.** The worst burst is about 14 link creations and 41 redirects per second. A redirect is one indexed lookup by code, and a single PostgreSQL instance handles thousands of those per second. Request rates won't drive the architecture.
- **Storage grows by 8 GB a year for links,** or 14–22 GB with per-click events. Keeping everything is affordable, so a retention policy is a question of how much customer data to hold, not of disk space.
- **Peak redirect traffic is likely to come from bots, not customers.** The redirect endpoint is public, so code-guessing attempts and scanners can easily exceed 41 requests/s. That's a rate-limiting question, not a capacity one.
