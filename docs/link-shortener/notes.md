# Personal notes (thinking)

## Interface
- I think interface needs deeper knowladges of SMS system, I see few possible interfaces:
  - Per link: the SMS system sends one URL, gets one short URL, and replaces it in the text itself
  - Batch: it sends a list of URLs and gets a list back in one call. Why: it may be good way to reduce latency for each URL. Unsure: again it depends on how SMS system works, maybe they don't need batch at all.
  - Whole text: it sends the full SMS text, and the service finds the links and returns the text with them replaced. Why: it looks like could be easier to use for CallCenter
- In the first version I would go with Batch, because it also covers the per-link case, and whole text can be built on top of it later.

## Tracking
- Let's count clicks per link, plus time of first click, it's enough in first version
- Why: the Call Center can see whether customers open the SMS links at all, maybe they will need to know which message templates work, cheap to store
- Not doing: IP, location, device, because it's personal data and no mentionned in requirements
- Unsure: how analytics will be consummed by CallCenter team. Do they want reports per agent or per SMS template? Need a "source" tag on each link to make that possible later.

## Security and expiry
- random code should be 6-8 (I would choose depending on how long the short domain is).
- why: to make it short enough, but uniq and safe
- let's add expiry as an option
- unsure: whether only Matic domains can be shortened, whether the destination page still needs a login


## Build or buy
- It sounds like better to build
- Why: because of sensative data, large SaaS bill

## Stack and infrastructure
- Easy way: the best is to use same stack team already runs, with a relational database
- Unsure: how deep this service will be with existing app, or it should be isolated
