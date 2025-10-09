c=$(swaync-client -c 2>/dev/null | tr -dc '0-9')
c=${c:-0}
if ((c > 0)); then
  printf '{"text":"%d","class":"has-unread"}\n' "$c"
else
  printf '{"text":""}\n'
fi
