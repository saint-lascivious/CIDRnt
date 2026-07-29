# CIDRnt

Generate geographic CIDR lists from APNIC delegated stats.

## What Does It Do?

- Accepts locale input (positional and/or `-l`/`--locale`), defaulting to `NZ` if none is provided
- Fetches APNIC delegated data with local cache reuse/fallback (`CACHE_TTL_SECONDS` controlled)
- Filters records by:
  - locale(s) (ISO-3166 alpha-2)
  - status (`allocated` or `allocated + assigned`)
  - family (`IPv4`, `IPv6`, or both)
- Converts APNIC IPv4 `start + count` ranges into minimal CIDR blocks
- Accepts custom IP/CIDR input via `-c`/`--custom` (repeatable, list-friendly), normalizing bare IPs to `/32` or `/128`
- Merges APNIC + custom CIDRs, deduplicates, aggregates, and naturally sorts the final set
- Optionally compresses IPv6 output formatting (`--minimise-ipv6`)
- Writes final CIDR output to stdout or a file

This has seen quite some development over quite some time locally, the GitHub repo is just a convenient way to share it with the world. It is not intended to be a full-featured or production-ready tool.

## Oh. Uhh. Okay, ...Why?

- I wanted something simple to generate quick and dirty multi-locale CIDR lists for use in firewall rules, allow/deny lists etc. and I'm a fucking nerd so why not one that's POSIX sh and doesn't require any weird dependencies.

## Requirements

- `sh`  
  POSIX-compliant shell runtime.
- `awk`  
  Parsing/transformation, plus fallback CIDR aggregation.
- `sort`  
  Final natural ordering of CIDR output.
- `curl` **or** `wget`  
  Download APNIC delegated data.
- `tr`  
  Locale normalization/splitting.
- `diff` *(self-test only)*  
  Required only for `--self-test`.

## Usage

```sh
./CIDRnt [options] [LOCALE ...]
```

## Options

- `-a`, `--allocated-only`  
  Include only `status=allocated`.
- `-A`, `--allocated-and-assigned`  
  Include `status=allocated` and `status=assigned` *(default)*.
- `-c`, `--custom LIST`  
  Add custom IP/CIDR entries. May be used multiple times.  
  LIST may be a single entry or a list split by comma/semicolon/space.  
  Bare IPs are accepted and converted to /32 (IPv4) or /128 (IPv6).  
  Also supports `-c=...`, `--custom=...`
- `-h`, `--help`  
  Show help and exit.
- `-i`, `--ipv4-only`  
  Include only IPv4 CIDRs.
- `-I`, `--ipv6-only`  
  Include only IPv6 CIDRs.
- `-l`, `--locale LOCALE`  
  Add locale(s) to include. May be used multiple times.  
  LOCALE may be a single code (NZ) or a list (NZ,AU;JP).  
  Also supports `-l=...`, `--locale=...`, `--locales=...`
- `-m`, `--minimise-ipv6`  
  Minimise IPv6 formatting in output (RFC5952-style compression).
- `-o`, `--output`  
  Write output to file instead of stdout, use `-` for stdout.
- `-s`, `--self-test`  
  Perform local tests and exit.
- `-v`, `--version`  
  Show version and exit.

## Examples

```sh
# Default locale (NZ)
./CIDRnt

# Positional locales
./CIDRnt NZ
./CIDRnt NZ AU
./CIDRnt "NZ,AU,JP"

# Locale flags (-l/--locale, repeated or list)
./CIDRnt -l NZ -l AU -l JP
./CIDRnt --locale=NZ,AU,JP

# Custom entries (merged before final aggregation/sort)
./CIDRnt NZ -c 203.0.113.7
./CIDRnt --locale NZ --custom "203.0.113.0/24,2001:db8::/32"
./CIDRnt -c=198.51.100.10 --custom=2001:db8::1 NZ

# Mixed positional + locale flags
./CIDRnt NZ --locale AU -l JP

# Status/family filters
./CIDRnt --allocated-only NZ AU
./CIDRnt --ipv4-only --locale NZ --locale AU
./CIDRnt --ipv6-only -l NZ -l AU

# IPv6 output minimisation
./CIDRnt --minimise-ipv6 NZ

# Write output
./CIDRnt -o ./out/nz.txt NZ
./CIDRnt --output ./out/nz-au.txt NZ AU
./CIDRnt --output=./out/nz-au-jp.txt --locale=NZ,AU,JP

# Force stdout explicitly
./CIDRnt --output=- NZ
```

## License

- GNU General Public License v3.0 or later (GPL-3.0+)

## Notes

- Output is plaintext CIDR notation (IPv4/IPv6), one per line.
- Temporary files created under `$TMPDIR`; cleaned on exit.
- APNIC data is cached at: `$CACHE_FILE`
- Cache TTL is controlled by CACHE_TTL_SECONDS (default: 86400).
  Set CACHE_TTL_SECONDS=0 to disable cache reuse.
