# Personal notes (thinking)

## Interface
- I think interface needs deeper knowladges of SMS system, I see few possible interfaces:
  - Per link: the SMS system sends one URL, gets one short URL, and replaces it in the text itself
  - Batch: it sends a list of URLs and gets a list back in one call. Why: it may be good way to reduce latency for each URL. Unsure: again it depends on how SMS system works, maybe they don't need batch at all.
  - Whole text: it sends the full SMS text, and the service finds the links and returns the text with them replaced. Why: it looks like could be easier to use for CallCenter
- In the first version I would go with Batch, because it also covers the per-link case, and whole text can be built on top of it later.

## Tracking
- It's better to do tracking only if it's a requirement (if Call Center will ask for that)
- Why: it's not easy task, as it looks. Argument from AI: "Link-preview generators and carrier or security scanners fetch SMS links, often seconds after delivery. So "first click time" will often record a bot, and every click count will be too high. To filter bots you need at least the User-Agent, which you've ruled out."

## Security and expiry
- random code should be not less then 8.
- why: to make it uniq and safe. AI argument: "You're choosing the length for how the SMS looks, but the code may be the only thing protecting a customer's documents. Six base62 characters give 5.7×10¹⁰ codes. If expiry is optional, most links will never expire, so after a year there are about 18M live codes. At that point about 1 random guess in 3,000 opens a real customer's link, and a million requests would find about 300. Per-IP rate limiting doesn't stop an attacker who spreads requests across many IPs. Eight characters with 30-day expiry gives about 1 in 145M."
- let's add expiry as an option
- unsure: whether only Matic domains can be shortened, whether the destination page still needs a login

## Build or buy
- It sounds like better to build
- Why: because of sensitive data, large SaaS bill
- Unsure: looks like the biggest challenge may be to support 99.9% SLA uptime. The code is a few days of work. The real cost is running a public, always-on, security-sensitive endpoint indefinitely, and your notes don't count it

## Stack and infrastructure
- Easy way: the best is to use same stack team already runs, with a relational database
- Unsure: how deep this service will be with existing app, or it should be isolated

## Goal and scope
- Unsure: why exactly the Call Center wants short links: SMS length and cost, readability, or tracking. I assume mostly SMS length, and tracking as a bonus.
- First version: create links by API, public redirect, expiry, click count. Not in first version: UI for agents, reports, custom codes.

## Security (added after review)
- Only Matic domains can be shortened. Why: otherwise our trusted short domain can be used for phishing.
- The create API is internal only, and each calling system has its own key.
- A code is never reused, even after expiry. Why: an old SMS must never open another customer's document.
- Rate limit on the redirect, and an alert when there are many "not found" hits. Why: someone is guessing codes.
- We need a way to disable a link quickly, for example when an SMS went to the wrong number.
- Codes without confusing characters (0/O, l/1), in case a customer types it by hand.
- Unsure: how long to keep links and click data.

## Reliability
- If the shortener is down, I would send the SMS with the long URL and not block it. Why: a long SMS is better than no SMS. Unsure: whether the long URL is safe to send as is.
- An expired or unknown link shows a simple page with what to do next, not a bare error. Why: otherwise the customer calls the Call Center.
- The redirect matters more than creation, because customers hit it. Backups are a must: losing the table breaks every link ever sent.
- Use a Matic-branded short domain. Why: carriers can filter public shorteners, and customers trust it more.

## Rollout
- Start with one SMS template behind a feature flag in the SMS system, with an easy way back to long URLs.
- Then go template by template, when the click and error numbers look fine.
- Unsure: who owns the service after launch and who is on call.