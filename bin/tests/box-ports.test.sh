#!/bin/bash
# Tests for box-ports listener parsing. Sources box-ports as a library (BASH_SOURCE
# guard) so no ssh or network is touched.
#
#   bash ~/.dotfiles/bin/tests/box-ports.test.sh
BOXPORTS="$HOME/.dotfiles/bin/box-ports"
P=0; F=0
ok(){ P=$((P+1)); echo "ok $((P+F)) - $1"; }
no(){ F=$((F+1)); echo "NOT OK $((P+F)) - $1"; }
assert_eq(){ if [ "$2" = "$3" ]; then ok "$1"; else no "$1 (want [$2], got [$3])"; fi; }

parse(){ ( source "$BOXPORTS"; printf '%s\n' "$1" | parse_listeners ); }

# Real `ss -ltnH` lines from artem-2.
SS='LISTEN 0 4096 0.0.0.0:22 0.0.0.0:*
LISTEN 0 511 100.80.63.46:4321 0.0.0.0:*
LISTEN 0 4096 100.80.63.46%tailscale0:53329 0.0.0.0:*
LISTEN 0 511 [::1]:18083 [::]:*
LISTEN 0 511 127.0.0.1:18083 0.0.0.0:*
LISTEN 0 511 127.0.0.1:40187 0.0.0.0:*
LISTEN 0 4096 127.0.0.53%lo:53 0.0.0.0:*
LISTEN 0 4096 [::]:22 [::]:*
LISTEN 0 4096 [fd7a:115c:a1e0::b638:3f30]%tailscale0:63402 [::]:*'

echo "# parse_listeners"
out="$(parse "$SS")"
assert_eq "tailnet-only bind dials the tailnet IP" "4321 100.80.63.46" "$(echo "$out" | grep '^4321 ')"
assert_eq "loopback beats ::1 for the same port" "18083 127.0.0.1" "$(echo "$out" | grep '^18083 ')"
assert_eq "privileged, ephemeral and interface-scoped ports are dropped" "4321 100.80.63.46
18083 127.0.0.1" "$out"
assert_eq "::1-only bind dials [::1]" "5173 [::1]" "$(parse 'LISTEN 0 511 [::1]:5173 [::]:*')"
assert_eq "wildcard bind dials loopback" "3000 127.0.0.1" "$(parse 'LISTEN 0 511 *:3000 *:*')"
assert_eq "[::] bind dials loopback" "8080 127.0.0.1" "$(parse 'LISTEN 0 511 [::]:8080 [::]:*')"
assert_eq "empty input yields nothing" "" "$(parse '')"

echo "# $P passed, $F failed"
[ "$F" = 0 ]
