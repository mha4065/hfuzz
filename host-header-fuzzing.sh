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
                         
        ${cyan}Developed by MHA${NC}             
                 ${yellow}mha4065.com${NC}

"

usage() { echo -e "${yellow}Usage:${NC} ./hfuzz.sh -d domain.tld -w wordlist.txt -s subdomain.txt [-t <int>] [-mc <int>] [-fc <int>]" 1>&2; exit 1; }

while getopts "d:s:w:t:m:f:" flag
do
    case "${flag}" in
        d) domain=${OPTARG#*//};;
        s) subdomain="$OPTARG";;
        w) wordlist="$OPTARG";;
        t) thread="-t $OPTARG";;
        m) match_code="-mc $OPTARG";;
        f) filter_code="-fc $OPTARG";;
        \? ) usage;;
        : ) usage;;
		*) usage;;
    esac
done

if [[ -z "${domain}" ]] || [[ -z "${subdomain}" ]] || [[ -z "${wordlist}" ]]; then
  usage
fi

# Check results/domain is exist or not
#=======================================================================
if [ ! -d "results" ]; then
    mkdir "results"
    if [ ! -d "results/$domain" ]; then
    	mkdir "results/$domain"
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


echo
echo -e "${blue}[!]${NC} Host header fuzzing : "

# Step 1 : only static wordlist as host header
#=======================================================================
echo -e "   ${green}[+]${NC} Fuzzing step 1 - fuzzing method -> host: <word>"
ffuf -w $wordlist -u "https://domaint.tld" -H "host: FUZZ" -H 'User-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0' $thread $match_code $filter_code -s -o results/$domain/step1.txt
#=======================================================================


# Step 2 : static wordlist+domain.tld as host header
#=======================================================================
echo -e "   ${green}[+]${NC} Fuzzing step 2 - fuzzing method -> host: <word>.domain.tld"
ffuf -w $wordlist -u "https://domaint.tld" -H "host: FUZZ.$domain" -H 'User-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0' $thread $match_code $filter_code -s -o results/$domain/step2.txt
#=======================================================================


# Step 3 : only static wordlist as host header
#=======================================================================
echo -e "   ${green}[+]${NC} Fuzzing step 3 - fuzzing method -> host: <subdomain>"
ffuf -w $subdomain -u "https://domaint.tld" -H "host: FUZZ" -H 'User-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X x.y; rv:42.0) Gecko/20100101 Firefox/42.0' $thread $match_code $filter_code -s -o results/$domain/step3.txt
#=======================================================================