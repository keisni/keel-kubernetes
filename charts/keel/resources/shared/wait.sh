if [[ ! -f /keel/update/wait ]]; then
  exit 0
fi
ordinal=${HOSTNAME##*-}
waits=$(cat /keel/update/wait)
for wait in $waits; do
  if [[ $wait -eq $ordinal ]]; then
    exit 1
  fi
done
exit 0