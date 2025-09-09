#!/bin/bash
RESET="\e[0m"
reset

search_pacman() {
    echo -e "${YELLOW}Searching official repositories...${RESET}"
    pacman -Ss "$1" | awk -F/ '{print $2}' | awk '{print $1}' | fzf --preview-window=up:30%:wrap
}

search_aur() {
    echo -e "${YELLOW}Searching AUR (via yay)...${RESET}"
    yay -Ss "$1" | awk '{print $1}' | fzf --preview-window=up:30%:wrap
}

aur_preview() {
    pkg="$1"
    cache_dir="${HOME}/.cache/custompkgr"
    cache_file="${cache_dir}/${pkg}.json"

    mkdir -p "$cache_dir"

    if [ -f "$cache_file" ]; then
        data=$(cat "$cache_file")
    else
        data=$(curl -s "https://aur.archlinux.org/rpc/v5/info?arg[]=$pkg")
        echo "$data" > "$cache_file"
    fi

    result=$(echo "$data" | jq ".results[0]")

    if [[ "$result" = "null" ]] || [ -z "$result" ]; then
        echo "No data found for: $pkg"
        return
    fi

    first_submitted=$(echo "$result" | jq ".FirstSubmitted")
    last_modified=$(echo "$result" | jq ".LastModified")

    first_submitted_fmt=$(date -d "@$first_submitted" "+%Y-%m-%d %H:%M:%S")
    last_modified_fmt=$(date -d "@$last_modified" "+%Y-%m-%d %H:%M:%S")

    echo "$result" | jq -r "
    \"Git Clone URL: https://aur.archlinux.org/\(.Name).git
Package Base: \(.PackageBase // \"N/A\")
Description: \(.Description // \"N/A\")
Upstream URL: \(.URL // \"N/A\")
Licenses: \(.License // [\"N/A\"] | join(\", \"))
Conflicts: \(.Conflicts // [] | join(\", \"))
Provides: \(.Provides // [] | join(\", \"))
Submitter: \(.Submitter // \"N/A\")
Maintainer: \(.Maintainer // \"N/A\")
Last Packager: \(.LastPackager // \"N/A\")
Votes: \(.NumVotes)
Popularity: \(.Popularity)\"
    "

    echo "First Submitted: $first_submitted_fmt"
    echo "Last Updated: $last_modified_fmt"
}

search_online() {
    echo -e "${YELLOW}Searching online AUR...${RESET}"
    curl -s "https://aur.archlinux.org/rpc/v5/search/$1" |
        jq -r '.results[].Name' |
        fzf --ansi --preview='aur_preview {}' --preview-window=right:60%
}

main() {
    echo -e "\e[32m\033[1m┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${RESET}"
    echo -e "\e[32m\033[1m┃An extremely convoluted script to search for arch pkgs for absolutely zero reason but because it looks pretty┃${RESET}"
    echo -e "\e[32m\033[1m┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${RESET}"
    echo -e "\e[34m1. Search Official Repos"
    echo -e "2. Search local packages"
    echo -e "3. Search online AUR packages${RESET}"
    echo -e "\e[31m4. Exit${RESET}"

    read -rp "Choose an option: " choice

    case $choice in
        1)
            read -rp "Enter search term: " term
            search_pacman "$term"
            ;;
        2)
            read -rp "Enter search term: " term
            search_aur "$term"
            ;;
        3)
            read -rp "Enter search term: " term
            search_online "$term"
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
}

main

