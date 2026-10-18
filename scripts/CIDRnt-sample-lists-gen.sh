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

GROUP_PAIRS="
eu|european-union
europe|europe
"

mkdir -p "$OUTPUT_DIR"

if [ ! -s ./resources/locales_map/locales.map ]; then
    printf '%s\n' "locales map missing, regenerating" >&2

    sh ./scripts/CIDRnt-locales-map-gen.sh ./resources/locales_map/locales.map

fi

if [ ! -s ./resources/groups_map/groups.map ]; then
    printf '%s\n' "groups map missing, regenerating" >&2

    sh ./scripts/CIDRnt-groups-map-gen.sh ./resources/locales_map/locales.map ./resources/groups_map/groups.map

fi

for locale in $LOCALES; do

    output="$OUTPUT_DIR/$(printf '%s' "$locale" | tr '[:lower:]' '[:upper:]').txt"

    printf '%s\n' "./CIDRnt --allocated-only --ipv4-only $locale --output $output" >&2

    "$CIDRNT" --allocated-only --ipv4-only "$locale" > "$output"

done

for pair in $GROUP_PAIRS; do

    case "$pair" in
        *'|'?*)
            ;;
        *)
            printf 'invalid group entry: %s (expected group|output-name)\n' "$pair" >&2
            exit 1
            ;;
    esac

    group=${pair%%|*}
    name=${pair##*|}
    output="$OUTPUT_DIR/$name.txt"

    printf '%s\n' "./CIDRnt --allocated-only --ipv4-only @$group --output $output" >&2

    "$CIDRNT" --allocated-only --ipv4-only "@$group" > "$output"

done

printf 'Sample lists generated in %s\n' "$OUTPUT_DIR"
