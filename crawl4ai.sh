#!/bin/bash
# Configuration
OUTPUT_DIR="./output"
CRAWL4AI_URL="http://your-server-ip:11235/"  #replace with your server IP or in the same machine use localhost or host.docker.internal
SLEEP_TIME=1  # Seconds to wait between requests
# --- Functions ---
urlencode() {
  python3 -c "import urllib.parse; print(urllib.parse.quote('$1'))"
}
check_robots() {
  local url="$1"
  local robots_url=$(dirname "$url")/robots.txt
  curl -s "$robots_url" | grep -q "Disallow: $(echo "$url" | sed 's/.*\///')"
  return $?
}
download_md() {
  local url="$1"
  local filename="${OUTPUT_DIR}/$(echo "$url" | sed 's/[^a-zA-Z0-9._-]/-/g').md"

  # Check if html2text is installed.  Provide a helpful error message if not.
  if ! command -v html2text &> /dev/null; then
    echo "Error: html2text is not installed. Please install it (e.g., apt install html2text or yum install html2text)." >&2
    return 1
  fi

  # Use curl to download the HTML and pipe it to html2text
  curl -sL "$url" | html2text -width 0 > "$filename"

  # Check for errors
  if [ $? -ne 0 ]; then
    echo "Error downloading or processing '$url'" >&2
    return 1
  fi

  echo "Downloaded and converted '$url' to '$filename'"
}
crawl() {
  local url="$1"
  # Check if the URL has already been visited
  if [[ -v visited_urls ]]; then  # Check if the array is defined
    if [[ " ${visited_urls[@]} " =~ " ${url} " ]]; then
      echo "Skipping already visited URL: $url" >&2
      return 1
    fi
  fi
  if check_robots "$url"; then
    echo "Skipping $url (robots.txt)" >&2
    return 1
  fi
  echo "Crawling $url"
  html=$(curl -sL -A "My Web Crawler/1.0" "$url")
  if [ $? -ne 0 ]; then
    echo "Error fetching HTML from $url" >&2
    return 1
  fi
  download_md "$url" # Add this line
  # Add the URL to the visited array
  if [[ -v visited_urls ]]; then
      visited_urls+=("$url")
  else
      visited_urls=("$url")
  fi
}
# --- Main ---
mkdir -p "$OUTPUT_DIR"
# Ask the user for the sitemap URL
read -p "Enter the URL of the sitemap: " sitemap_url
# Basic URL validation
if [[ -z "$sitemap_url" ]]; then
  echo "Error: Sitemap URL cannot be empty."
  exit 1
fi
if ! [[ "$sitemap_url" =~ ^(http|https):// ]]; then
  echo "Error: Invalid Sitemap URL.  Must start with http:// or https://."
  exit 1
fi
# Crawl from sitemap
sitemap_urls=$(curl -sL -A "My Web Crawler/1.0" "$sitemap_url" | grep -oP '<loc>(.*?)</loc>' | sed 's/<loc>//g' | sed 's/<\/loc>//g')
if [[ -z "$sitemap_urls" ]]; then
  echo "Error: Could not retrieve URLs from the sitemap. Check the URL and sitemap format."
  exit 1
fi
# Initialize the visited URLs array
visited_urls=()
while IFS= read -r sitemap_url_item; do
  crawl "$sitemap_url_item"
  sleep "$SLEEP_TIME"
done <<< "$sitemap_urls"
echo "Crawling completed."
