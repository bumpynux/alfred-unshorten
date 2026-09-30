q="$1"
if [ -z "$q" ]; then
  printf '{"items":[{"title":"Paste a shortlink","subtitle":"Clean row strips tracking params, Full row keeps them","valid":false}]}'
  exit
fi
# first URL in whatever was pasted, or treat the input as a bare host
url=$(printf '%s' "$q" | grep -oE 'https?://[^[:space:]<>"]+' | head -n 1)
[ -z "$url" ] && url="https://$q"
esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\000-\037'; }
# tracking-params.txt is one name per line; a trailing * matches a prefix
tracking="^($(grep -v '^$' tracking-params.txt | sed 's/\*/.*/g' | paste -sd '|' -))$"
clean() {  # sets $cleaned and $removed
  local u="$1" base q frag="" out="" p
  cleaned="$1"; removed=""
  case "$u" in *'#'*) frag="#${u#*#}"; u="${u%%#*}";; esac
  case "$u" in *'?'*) base="${u%%\?*}"; q="${u#*\?}";; *) return;; esac
  IFS='&' read -r -a parts <<< "$q"
  for p in "${parts[@]}"; do
    if [[ ${p%%=*} =~ $tracking ]]; then removed="${removed:+$removed, }${p%%=*}"
    else out="${out:+$out&}$p"; fi
  done
  cleaned="$base${out:+?$out}$frag"
}
# print the destination when a tracker wraps it in a query param, else nothing
unwrap() {
  local u="$1" q p v
  case "$u" in *'?'*) q="${u#*\?}"; q="${q%%#*}";; *) return;; esac
  IFS='&' read -r -a parts <<< "$q"
  for p in "${parts[@]}"; do
    case "${p%%=*}" in url|u|q|target|dest|destination|redirect|redirect_url|link)
      v=${p#*=}; v=$(printf '%b' "${v//%/\\x}")
      case "$v" in http://*|https://*) printf '%s' "$v"; return;; esac;;
    esac
  done
}
inner=$(unwrap "$url"); url=${inner:-$url}
doh=(); [ -n "$doh_url" ] && doh=(--doh-url "$doh_url")
fetch() { curl -sL "$@" --max-time 15 "${doh[@]}" -o /dev/null -w '%{url_effective}\t%{http_code}\t%{num_redirects}' "$url"; }
item() { local u; u=$(esc "$1"); printf '{"title":"%s","subtitle":"%s  │  ↩ copy  ⌘↩ paste  ⌥↩ open","arg":"%s","icon":{"path":"%s"}}' "$u" "$(esc "$2")" "$u" "$3"; }
out=$(fetch -I); rc=$?
IFS=$'\t' read -r final code hops <<< "$out"
# some servers refuse HEAD; retry once with GET and throw the body away
case "$code" in 403|405) out=$(fetch); rc=$?;; esac
IFS=$'\t' read -r final code hops <<< "$out"
if [ "$rc" -ne 0 ] && [ "${hops:-0}" -eq 0 ]; then
  printf '{"items":[{"title":"Could not resolve","subtitle":"%s","valid":false}]}' "$(esc "$url")"
  exit
fi
hopword=redirects; [ "$hops" = 1 ] && hopword=redirect
info="HTTP $code · $hops $hopword"
[ "$rc" -ne 0 ] && info="$info · final hop unreachable"
clean "$final"
items=""
[ "$cleaned" != "$final" ] && items="$(item "$cleaned" "Clean · removed $removed" clean.png),"
items="$items$(item "$final" "Full · as received · $info" full.png)"
printf '{"items":[%s]}' "$items"
