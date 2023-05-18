# hfuzz
hfuzz is a powerful tool to fuzzing host header in three method using `ffuf` tool.
 1. host: `<word>`
 2. host: `<word>.domain.tld`
 3. host: `<subdomain>`


## Requirements
  - ffuf

## Installation
  1. Run `chmod +x hfuzz.sh`
  2. `./hfuzz.sh ./hfuzz.sh -d domain.tld -w wordlist.txt -s subdomain.txt [-t <int>] [-m <int>] [-f <int>]`

Note: `-t` -> thread, `-m` -> match response code and `-f` -> filter response code
