#!/bin/sh

# CIDRnt-sample-lists-gen.sh - Generate CIDR lists for various locales.

set -eu

CIDRNT="${CIDRNT:-./CIDRnt}"
OUTPUT_DIR="${OUTPUT_DIR:-./resources/sample_lists}"

LOCALES_AFRINIC="
ZA
"

LOCALES_APNIC="
AU
JP
NZ
"

LOCALES_ARIN="
CA
US
"

LOCALES_LACNIC="
BR
MX
"

LOCALES_RIPE_NCC="
DE
GB
"

LOCALES="$LOCALES_AFRINIC $LOCALES_APNIC $LOCALES_ARIN $LOCALES_LACNIC $LOCALES_RIPE_NCC"

mkdir -p "$OUTPUT_DIR"

for locale in $LOCALES; do

    output="$OUTPUT_DIR/$(printf '%s' "$locale" | tr '[:lower:]' '[:upper:]').txt"

    printf '%s\n' "--allocated-and-assigned --ipv4-only $locale -> $output" >&2

    "$CIDRNT" --allocated-and-assigned --ipv4-only "$locale" > "$output"

done
