# Sceptical review of notes.md

An AI review of `notes.md`, written from the point of view of a sceptical staff engineer: the strongest argument against each position, what the notes leave out, and the first open question.

## 1. The strongest argument against each position

**Interface: batch first**
Batch leaves the hardest part with the caller. The difficult work is finding URLs in free SMS text and putting the short ones back correctly: trailing punctuation, parentheses, query strings, links that are already short. With batch or per-link, every system that sends SMS has to do that itself, and each one will get it wrong in its own way. The team described the problem as "the text can contain zero or more links". That is a whole-text problem, and whole-text also covers the zero-link case with no work for the caller. The latency reason doesn't hold up: a message has one or two links, and you're averaging less than one link created per second. Your notes also say the SMS system "maybe doesn't need batch at all", so you're choosing an API for its flexibility, not for the system that will call it. (If you switch to whole-text, expect this pushback: the shortener would then receive full message bodies, including customer data.)

**Tracking: click count and first click time, no IP or device**
These numbers won't measure what you say they measure. Link-preview generators and carrier or security scanners fetch SMS links, often seconds after delivery. So "first click time" will often record a bot, and every click count will be too high. To filter bots you need at least the User-Agent, which you've ruled out. "No IP because it's personal data" is also not true by default. Your load balancer and web server logs record the IP and code of every redirect unless you deliberately remove them. And for links that open policy documents, access records are arguably a security need, for investigating a leaked or misdirected link, not just analytics. "Cheap to store" doesn't justify collecting first click time. What decision would it inform?

**Security: 6–8 character random code, optional expiry**
You're choosing the length for how the SMS looks, but the code may be the only thing protecting a customer's documents. Six base62 characters give 5.7×10¹⁰ codes. If expiry is optional, most links will never expire, so after a year there are about 18M live codes. At that point about 1 random guess in 3,000 opens a real customer's link, and a million requests would find about 300. Per-IP rate limiting doesn't stop an attacker who spreads requests across many IPs. Eight characters with 30-day expiry gives about 1 in 145M.

What you save is 2 characters in a 160-character segment. A single curly quote in the template costs more, because it forces the whole message into 70-character segments. And "optional" in practice means callers won't set it. The number of live codes then grows forever, and every forwarded SMS, or SMS sent to a phone number that has since been reassigned, stays a working path to policy documents.

**Build vs buy: build**
Neither reason has been checked.
- **"Large SaaS bill":** you haven't priced it, and the team asked specifically what this will cost.
- **"Sensitive data":** a vendor would store the destination URL. Whether that's sensitive depends on whether the URL carries an access token, which your notes list as unknown. Also, an outside company (the SMS provider) already sees every link you send, short or long.
- **What "buy" might be:** some SMS providers, Twilio for example, offer branded link shortening and click tracking as part of their messaging product. So "buy" could be a setting on a contract Matic already has, and that would also settle the interface question.
- **What "build" costs:** the code is a few days of work. The real cost is running a public, always-on, security-sensitive endpoint indefinitely, and your notes don't count it.

**Stack: same stack, relational database**
You don't know what the team runs; they said "no constraints". The decision that matters is the one you put off: whether the shortener runs inside the main app or as its own service.
- **Inside the main app:** every deploy or incident there breaks every link in every customer's inbox, and the short domain becomes a new public way into the main app.
- **Separate service:** it's one more service to own and keep running.

A relational database is fine, but justify it with numbers, not "easy way".

## 2. What the notes don't address

First, the framing. At 1.5M links a month, scale isn't the problem: that's about 0.6 writes/s on average, about 12/s even at a 20× business-hours peak, and a few GB a year. One Postgres instance is plenty. What the volume does change is how many codes are live at once, which drives guessability, and how many customers a single outage or leak affects.

**Missing from the deliverable itself**
- **Problem statement and success criteria.** Why does the Call Center want short links: SMS cost, deliverability, readability, or tracking? Each answer leads to a different design and a different case for the cost.
- **Rollout plan.** The notes have none, and it's a third of the assignment. It needs a pilot scope (one template?), a feature flag in the SMS system, rollback, and criteria for moving to the next phase.
- **Cost figures.** Build effort, running cost, operating cost, and vendor pricing at 1.5M links a month.
- **v1 scope and non-goals.**

**Security**
- **Threat model.** Is the short code effectively a password to the document?
- **Destination allowlist.** Without one, the trusted short domain becomes a phishing tool for anything that can reach the create API.
- **Auth on the create API.** Which systems can call it, how they authenticate, and who can read link and click data.
- **Protection against guessing codes.** Rate limits on the redirect, plus an alert when "not found" responses spike.
- **Revocation.** If a link goes to the wrong number or a reassigned number, you need to disable it quickly, one at a time or in bulk.
- **Handling destination URLs as data.** How they're classified, whether they're encrypted, keeping them out of logs, and which insurance or privacy rules apply.

**Link lifecycle and data**
- **Codes are never reused.** An old SMS must never open a different customer's document, so expired codes have to stay reserved.
- **Retention** for links and click data, at 18M rows a year.
- **What the customer sees** on an expired, revoked or unknown link. A dead end turns into a call to the Call Center.
- **Duplicates and failures.** Requests from the SMS system need to be safe to retry without creating duplicate links, and you need to define what happens when one link in a message fails.
- **Character set for codes.** Upper/lower case, and confusable characters like 0/O and l/1.

**Reliability**
- **What the SMS system does when the shortener is down.** Block, retry, or send the long URL? And is the long URL safe to send?
- **Availability and latency targets** for both creating links and redirecting. The redirect is what customers hit.
- **Backups and recovery.** Losing the links table breaks every link ever sent.
- **Domain.** If the short domain's registration lapses, whoever registers it next controls every link ever sent. It also needs to be a Matic-branded domain, because US carriers filter SMS containing generic public shorteners.

**Operations**
- **An owner and on-call rotation.**
- **Support without a UI.** How an agent handles "the link doesn't work" or checks whether a link was opened.
- **Test links** kept off the production domain.

## 3. Questions

Asked one at a time, starting with the one that affects the most decisions.

**Q1.** When a customer taps the link and lands on their policy declarations page, what protects the document?
- **(a)** The customer must log in or verify their identity (e.g. date of birth or a one-time code) on that page.
- **(b)** The long URL contains a token that opens the document without logging in.
- **(c)** You don't know. In that case, will you ask the team on Slack, or should the spec assume the worst case, (b)?

This matters because in (a) the short code is just a convenience, and 6–7 characters with optional expiry is defensible. In (b) the code works like a password to someone's insurance documents, and code length, mandatory expiry, rate limiting, revocation and the data argument in build vs. buy all change.
