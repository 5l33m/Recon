#!/bin/bash

# Update and upgrade the system
#sudo apt-get update
#sudo apt-get upgrade -y

# Install required packages
#sudo apt-get install -y amass ffuf aquatone git python3 python3-pip nmap

# Check if a domain name and wordlist are provided as arguments
if [ $# -ne 2 ]
then
    echo "Usage: $0 <domain> <wordlist>"
    exit 1
fi

# Set the domain name and wordlist
domain=$1
wordlist=$2

# Set the directories
ffuf_dir="ffuf"
nmap_dir="nmap"

# Create the directories if they don't exist
mkdir -p $ffuf_dir $nmap_dir

# Amass active subdomain enumeration
#echo "Running Amass for active subdomain enumeration"
#amass enum -active -d $domain -o subdomains.txt

# Use httprobe to verify subdomains
#echo "Running httprobe to verify subdomains"
#cat subdomains.txt | httprobe | tee verified_subdomains.txt

# Use Aquatone to get screenshots
#echo "Running Aquatone to get screenshots"
#cat verified_subdomains.txt | aquatone -out aquatone

# Use massdns to resolve the IP addresses of the verified subdomains
#echo "Running massdns to resolve the IP addresses of the verified subdomains"
#cat verified_subdomains.txt | sed -E 's/^\s*.*:\/\///g' | massdns -r /root/tools/massdns/lists/resolvers.txt -t A -o S -w resolved_subdomains.txt

# Use ffuf for directory enumeration
echo "Running ffuf for directory enumeration"
for url in $(cat verified_subdomains.txt); do
    # Remove "https://" from the URL and assign it to a new variable
    domain_name=$(echo $url | sed 's/https:\/\///g')

ffuf_output_file="$ffuf_dir/$domain_name"

# Use ffuf to enumerate directories and files
ffuf -w $wordlist -u $url/FUZZ -mc 200,301,302,307 -c -v -e .php,.asp,.aspx,.jsp,.html,.htm,.js,.cgi -fl 3 -o $ffuf_output_file -of md

# Find all JS files
echo "Finding all JS files"
grep -Eo "(http|https)://[a-zA-Z0-9./?=_-]*\.(js)" $ffuf_output_file | sort -u > js_files.txt

# Check for sensitive information in JS files using GitLeaks
#echo "Checking for sensitive information in JS files using GitLeaks"
#gitleaks --repo-path . --verbose --pretty

# Search for sensitive information in the contents of the JS files
echo "Searching for sensitive information in the contents of the JS files"
for js_url in $(cat js_files.txt); do
wget $js_url
cat *.js | grep -i -e password -e username -e api_key -e secret_key -e access_key -e authorization -e token
done

    # Scan for open ports using nmap
   # echo "Running nmap to discover open ports"
  #  resolved_ip=$(dig +short $domain_name)
   # nmap -Pn -p- -sV -T4 $resolved_ip -oN $nmap_dir/$resolved_ip
done
