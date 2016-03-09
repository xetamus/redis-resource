payload=$(mktemp $TMPDIR/git-resource-request.XXXXXX)

cat > $payload <&0

host=$(jq -r '.source.host // ""' < $payload)
port=$(jq -r '.source.port // "6379"' < $payload)
password=$(jq -r '.source.password // ""' < $payload)
dbnum=$(jq -r '.source.db_number // "0"' < $payload)

if [ -z "$host" ]
then
  echo "invalid payload (missing host):" >&2
  cat $payload >&2
  exit 1
fi

connect_opts="-h '${host}'${port:+" -p $port"}${db_num:+" -n $dbnum"}${password:+" -a '$password'"}"

# Keys contain globs, so need to put them in an array the hard way
keys=()
while read -r
do
  keys+=("$REPLY")
done < <(jq -r '(.source.keys // [])[]' < $payload)

if [ -z "$host" ]
then
  echo "invalid payload (missing host):" >&2
  cat $payload >&2
  exit 1
fi

key_metadata() {
  key_list="$(printf "%s\n" "${all_keys[@]}")"
  jq -ncM --arg keys "$key_list" '[{"name": "keys", "value": $keys }]'
}

calc_reference() {
  for file in "${all_files[@]}"
  do 
    sha1sum "$file"
  done | sha1sum | cut -d' ' -f1
}
