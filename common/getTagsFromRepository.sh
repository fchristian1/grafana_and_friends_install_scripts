tags=($(git ls-remote --tags $1 | awk -F'/' '{print $3}' | sed 's/\^{}//' | grep -E '^v[0-9]*\.[0-9]*\.[0-9]' | sed 's/^v//' | sed 's/^V//' | sort -V -u))
echo ${tags[@]}
