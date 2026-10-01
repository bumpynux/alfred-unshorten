# Unshorten

An Alfred workflow that resolves shortlinks to their final URL and strips tracking parameters.

DNS filters, like Pi-hole and NextDNS, block most link shorteners. Sometimes you still need to resolve a shortlink to see where it's going. This workflow follows the redirects, expands the shortlink, optionally cleans the tracking parameters off it, and lets you copy, paste, or open the result.

## Usage

Resolve a shortlink via the `unshort` keyword. The final URL appears as a result. When the destination carries tracking parameters, a second Clean row shows the URL with them removed and the subtitle says which ones.

![Alfred showing two results for a shortlink, a green Clean row with the tracking parameters removed and a grey Full row with the URL as received](images/unshorten.png)

* <kbd>↩</kbd> Copy the URL to the clipboard.
* <kbd>⌘</kbd><kbd>↩</kbd> Paste the URL to the frontmost app.
* <kbd>⌥</kbd><kbd>↩</kbd> Open the URL in the default browser.

The keyword and the DNS-over-HTTPS resolver can be changed in the Workflow's Configuration.

## How it works

* Only headers are fetched, unless the server refuses `HEAD`, in which case it retries once with `GET` and throws the body away. Nothing is rendered either way, so the page's scripts never run.
* DNS lookups go over DNS-over-HTTPS, so shortener domains resolve even when a DNS filter such as Pi-hole or NextDNS blocks them. Clear the resolver in the Workflow's Configuration to use your system DNS.
* Links that wrap the destination in a query parameter (Google's `url?q=`, newsletter click trackers) are decoded locally, so the tracker is never contacted.
* If you paste a whole sentence, it picks out the first link.

## Try it

These are real links that resolve to pages with tracking parameters, so you can see both rows.

```
https://tinyurl.com/2das3jjf
https://tinyurl.com/26c7hu7s
```

## Building from source

The script lives in `src/unshorten.sh` so it's readable. `build.sh` embeds it into `info.plist` and zips the bundle.

```
./build.sh
open Unshorten.alfredworkflow
```

## How this was built

I wrote a prototype first, a shell script that used `curl` to follow a shortlink's redirects. I then rebuilt it as an Alfred workflow with Claude Code, which wrote the code in this repo. I scoped it, made the design decisions (what it does, how the results and actions behave, what gets stripped), and tested each iteration in Alfred. I audited it with two Claude Code skills, ponytail for over-engineering and secscan for security triage.

## Notes

The list of tracking parameters is in [`src/tracking-params.txt`](src/tracking-params.txt), one name per line, with a trailing `*` for prefixes like `utm_*`. Affiliate tags such as Amazon's `tag` are left alone on purpose, since they credit whoever shared the link rather than track you. If you find a tracking parameter it misses, please let me know by opening an [issue](https://github.com/bumpynux/alfred-unshorten/issues/new) or a [pull request](https://github.com/bumpynux/alfred-unshorten/pulls).

There's also a [thread on the Alfred forum](https://www.alfredforum.com/topic/24092-unshorten-resolve-shortlinks-and-strip-tracking-parameters/) if you'd rather talk there.

If something else on your Mac already strips tracking parameters from copied links, you will mostly see the Full row. The workflow still does the resolving.
