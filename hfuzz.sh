#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
NC='\033[0m'

printf "

 _      __               
| |__  / _|_   _ ________
| '_ \| |_| | | |_  /_  /
| | | |  _| |_| |/ / / / 
|_| |_|_|  \__,_/___/___|
                         
        ${cyan}Developed by MHA & Meweez${NC}             
                 ${yellow}mha4065.com${NC}

"

usage() {
    echo -e "${yellow}Usage:${NC} ./hfuzz.sh   
    [-d (domain just for append mode)] 
    [-s (For TLS (By default, the scheme is http) )] {-i|-I} [-w wordlist] [-S] [-t] [-m] [-f]

    [-i (just a single IP -> 1.2.3.4)]
    [-I (a list of IP -> ip.txt)]
    [-w (a wordlist -> words.txt)]
    [-S (a wordlist of subdomains -> subdomains.txt)]
    [-t thread]
    [-m match-codes]
    [-f filter-codes]
    " 1>&2;
    exit 1;
}

ip=
protocol="http"
domain=
ips=
wordlist=
swordlist=

matchcode=" -mc "
filtercode=" -fc "
thread=" -t "

while getopts "h:d:i:I:w:t:m:f:S:s" o; do
    case $o in
        i)
            ip=$OPTARG
            ;;
        m)
            matchcode="$matchcode$OPTARG"
            ;;
        f)
            filtercode="$filtercode$OPTARG"
            ;;
        d)
            domain=$OPTARG
            ;;
        I)
            ips=$OPTARG
            ;;
        t)
            thread="$thread$OPTARG"
            ;;
        w)
            wordlist=$OPTARG
            ;;
        s)
            protocol="https"
            ;;
        S)
            swordlist=$OPTARG
            ;;
        h | *)
            echo "$o"
            usage
            ;;
    esac
done

 

# Check results/domain is exist or not
#=======================================================================
if [ ! -d "hfuzz-result" ]; then
    mkdir "hfuzz-results"
    if [ ! -d "hfuzz-results/$domain" ]; then
    	mkdir "hfuzz-results/$domain"
    fi
fi
#=======================================================================


# Check the requirements
#=======================================================================
echo
echo -e "${blue}[!]${NC} Check the requirements :"

if ! command -v ffuf &> /dev/null
then
    echo -e "   ${red}[-]${NC} ffuf could not be found !"
    exit
fi

echo -e "   ${green}[+]${NC} All requirements are installed :)"
#=======================================================================

#get options ready
options=
if [ ! "$matchcode" = " -mc " ]; then
    options="$matchcode "
fi
if [ ! "$filtercode" = " -fc " ]; then
    options="$options$filtercode "
fi
if [ ! "$thread" = " -t " ]; then
    options="$options$thread "
fi
#echo -e "$options"


echo
echo -e "${blue}[!]${NC} Host header fuzzing : "

# Step 1 : only static wordlist as host header
#=======================================================================
echo -e "   ${green}[+]${NC} Fuzzing step 1 - fuzzing method -> host: <word>"
if ([ -z "$ip" ] && [ -z "$ips" ]) || ([ -z "$wordlist" ]);then
    echo -e "Please define Ip, wordlist"
    usage
else
    if [ -z "$ip" ];then
        # fuzz list of ips with the wordlist
        for i in $(cat "$ips");do
            # with this filter we want to remove those are showing the same website as default
            filterrespsize=$(curl -s -k -I "$protocol://$i" | grep -i Content-Length | cut -f2 -d' ' | tr -d '\r\n')
            ffuf -c -w "$wordlist" -u "$protocol://$i" -H "Host: FUZZ" -fs "$filterrespsize" "$options" -H 'User-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0'  -s > hfuzz-results/$domain/step1-$i.txt 2>/dev/null
        done
    else
        # fuzz one ip with the wordlist
        filterrespsize=$(curl -s -k -I "$protocol://$ip" | grep -i Content-Length | cut -f2 -d' ' | tr -d '\r\n')
        ffuf -c -w "$wordlist" -u "$protocol://$ip" -H "Host: FUZZ" -fs "$filterrespsize" "$options" -H 'User-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0'  -s > hfuzz-results/$domain/step1.txt 2>/dev/null
    fi
    
fi
#=======================================================================


# Step 2 : static wordlist+domain.tld as host header
#=======================================================================
echo -e "   ${green}[+]${NC} Fuzzing step 2 - fuzzing method -> host: <word>.domain.tld"
if ([ -z "$ip" ] && [ -z "$ips" ]) || ([ -z "$wordlist" ]) || ([ -z "$domain" ]);then
    echo -e "Please define Ip, wordlist and Domain"
    usage
else
    if [ -z "$ip" ];then
        # fuzz list of ips with the wordlist
        for i in $(cat "$ips");do
            # with this filter we want to remove those are showing the same website as default
            filterrespsize=$(curl -s -k -I "$protocol://$i" | grep -i Content-Length | cut -f2 -d' ' | tr -d '\r\n')
            ffuf -c -w "$wordlist" -u "$protocol://$i" -H "Host: FUZZ.$domain" -fs "$filterrespsize" "$options" -H 'User-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0'  -s > hfuzz-results/$domain/step2-$i.txt   2>/dev/null
        done
    else
        # fuzz one ip with the wordlist
        filterrespsize=$(curl -s -k -I "$protocol://$ip" | grep -i Content-Length | cut -f2 -d' ' | tr -d '\r\n')
        ffuf -c -w "$wordlist" -u "$protocol://$ip" -H "Host: FUZZ.$domain" -fs "$filterrespsize" "$options" -H 'User-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0'  -s > hfuzz-results/$domain/step2.txt 2>/dev/null
    fi
    
fi
#=======================================================================


# Step 3 : subdomians as host header
#=======================================================================
echo -e "   ${green}[+]${NC} Fuzzing step 3 - fuzzing method -> host: <subdomain>"
if ([ -z "$ip" ] && [ -z "$ips" ]) || ([ -z "$swordlist" ]) ;then
    echo -e "Please define Ip and Subdomain wordlist"
    usage
else
    if [ -z "$ip" ];then
        # fuzz list of ips with the wordlist
        for i in $(cat "$ips");do
            # with this filter we want to remove those are showing the same website as default
            filterrespsize=$(curl -s -k -I "$protocol://$i" | grep -i Content-Length | cut -f2 -d' ' | tr -d '\r\n')
            ffuf -c -w "$swordlist" -u "$protocol://$i" -H "Host: FUZZ" -fs "$filterrespsize" "$options" -H 'User-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0'  -s > hfuzz-results/$domain/step3-$i.txt 2>/dev/null
        done
    else
        # fuzz one ip with the wordlist
        filterrespsize=$(curl -s -k -I "$protocol://$ip" | grep -i Content-Length | cut -f2 -d' ' | tr -d '\r\n')
        ffuf -c -w "$swordlist" -u "$protocol://$ip" -H "Host: FUZZ" -fs "$filterrespsize" "$options" -H 'User-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0'  -s > hfuzz-results/$domain/step3.txt 2>/dev/null
    fi
    
fi
#=======================================================================






















