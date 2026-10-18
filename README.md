# CIDRnt

Generate geographic CIDR lists from RIR delegated stats.

## Index

- [What Does It Do?](#what-does-it-do)
- [Oh. Uhh. Okay, ...Why?](#oh-uhh-okay-why)
- [Requirements](#requirements)
- [Usage](#usage)
- [Options](#options)
- [Examples](#examples)
- [Something Is Broken](#something-is-broken)
- [License](#license)
- [Notes](#notes)

## What Does It Do?

- Accepts locale input as ISO-3166 alpha-2 codes — positional arguments, `-l`/`--locale` (repeatable, list-friendly), or `@group` references to groups defined in a groups map
- Fetches delegated stats from all five RIRs (AFRINIC, APNIC, ARIN, LACNIC, RIPE NCC) with local per-registry cache reuse and stale-cache fallback (`CACHE_TTL_SECONDS` controlled, `-r`/`--refresh` to bypass)
- Fetches only the registries it needs, using a locale→RIR map; unknown mappings are learned automatically from downloaded data and expire via `LOCALE_MAP_TTL_SECONDS`
- Filters records by:
  - locale(s) (ISO-3166 alpha-2)
  - status (`allocated` or `allocated + assigned`)
  - family (`IPv4`, `IPv6`, or both)
- Converts IPv4 `start + count` ranges into minimal CIDR blocks
- Accepts custom IP/CIDR input via `-c`/`--custom` (repeatable, list-friendly, or from a file), normalizing bare IPs to `/32` or `/128`
- Merges registry + custom CIDRs, deduplicates, aggregates, and naturally sorts the final set
- Lists available locale codes (`-L`/`--list-locales`), defined locale groups, or locales within a group (`-g`/`--list-groups`)
- Optionally compresses IPv6 output formatting (`--minimise-ipv6`, RFC5952-style)
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
  Download RIR delegated data.
- `tr`  
  Locale normalization/splitting.
- `diff` *(self-test only)*  
  Required only for `--self-test`.

## Usage

```sh
./CIDRnt [options] LOCALE [LOCALE ...]
```

At least one ISO-3166 alpha-2 locale or `@group` is required.
`LOCALE` may also be `@group`, referencing a group defined in the
groups map (see `-g`).

## Options

- `-a`, `--allocated-only`  
  Include only `status=allocated`.
- `-A`, `--allocated-and-assigned`  
  Include `status=allocated` and `status=assigned` *(default)*.
- `-c`, `--custom LIST`  
  Add custom IP/CIDR entries. May be used multiple times.  
  LIST may be a single entry, a list split by comma/semicolon/space,  
  or a path to a plaintext file containing one entry per line.  
  Bare IPs are accepted and converted to /32 (IPv4) or /128 (IPv6).  
  Also supports `-c=...`, `--custom=...`
- `-g`, `--list-groups [GROUP]`  
  List all locale groups defined in the groups map, and exit.  
  When GROUP is given, list the locales within GROUP instead.  
  GROUP may be given with or without the `@` prefix.  
  Also supports `-g=GROUP` and `--list-groups=GROUP`.
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
- `-L`, `--list`, `--list-locales [LETTER]`  
  Fetch RIR stats, list all available locale codes, and exit.  
  When LETTER (a single character) is given, only locales  
  beginning with that letter are listed (case insensitive).  
  A summary of matched vs total locales is printed to stderr.  
  Also supports `--list=LETTER` and `--list-locales=LETTER`.
- `-m`, `--minimise-ipv6`, `--minimize-ipv6`  
  Minimise IPv6 formatting in output (RFC5952-style compression).
- `-o`, `--output FILE`  
  Write output to file instead of stdout, use `-` for stdout.
- `-r`, `--refresh`  
  Bypass the local RIR data cache and fetch fresh data.  
  Successful downloads still update the cache.
- `-s`, `--self-test`  
  Perform local tests and exit.
- `-v`, `--version`  
  Show version and exit.

## Examples

```sh
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

# Custom entries from a file (one IP/CIDR per line)
./CIDRnt --custom ./custom-list.txt NZ
./CIDRnt -c=./custom-list.txt NZ
./CIDRnt --custom=./custom-list.txt NZ

# Mixed positional + locale flags
./CIDRnt NZ --locale AU -l JP

# Locale groups (defined in the groups map)
./CIDRnt @mygroup
./CIDRnt NZ @mygroup -l "AU,@othergroup"

# List groups
./CIDRnt --list-groups

# List locales within a group
./CIDRnt -g mygroup
./CIDRnt -g @mygroup
./CIDRnt --list-groups=mygroup

# List locales
./CIDRnt --list
./CIDRnt --list-locales

# List locales starting with ...
./CIDRnt --list A
./CIDRnt --list-locales B

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

## Something Is Broken

CIDRnt has a pretty extensive self-test suite that can be run with the `-s` or `--self-test` flag.

Running the self-test suite will exercise various features of CIDRnt, including locale parsing, provider selection, and cache handling. It is a good way to verify that your installation is functioning correctly, and a good way of showing what isn't working when something is functioning incorrectly.

## License

- GNU General Public License v3.0 or later (GPL-3.0+)

## Notes

- Output is plaintext CIDR notation (IPv4/IPv6), one per line.
- Temporary files are created under `$TMPDIR`; cleaned on exit.
- RIR data is cached per registry under `$CACHE_DIR` (`${XDG_CACHE_HOME:-~/.cache}/CIDRnt`).
- Cache TTL is controlled by `CACHE_TTL_SECONDS` (default: 604800).  
  Set `CACHE_TTL_SECONDS=0` to disable cache reuse.
- Learned locale→RIR mappings expire via `LOCALE_MAP_TTL_SECONDS` (default: 2419200).  
  Set `LOCALE_MAP_TTL_SECONDS=0` to disable expiry.
- Map file locations can be overridden with `CIDRNT_LOCALES_MAP` and `CIDRNT_GROUPS_MAP`.
