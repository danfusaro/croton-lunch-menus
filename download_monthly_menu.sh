url_encode() {
  local string="$1"
  local length="${#string}"

  local encoded=""
  local start_index=0

  # Check if the string contains a protocol (e.g., "https://") and extract it
  local protocol=""
  if [[ "$string" =~ ^[a-zA-Z]+:// ]]; then
    protocol="${BASH_REMATCH[0]}"
    start_index="${#protocol}"
  fi

  for ((i = start_index; i < length; i++)); do
    local char="${string:i:1}"
    case "$char" in
      [a-zA-Z0-9.~_-])
        encoded+="$char"
        ;;
      /)
        encoded+="$char"
        ;;
      *)
        encoded+="%$(printf "%02X" "'$char")"
        ;;
    esac
  done

  echo "$protocol$encoded"
}

# Define the URL of the HTML page
html_url="https://www.chufsd.org/Page/3189"

# Define the target text with the current month abbreviation and year
target_text=$(date +"CET Lunch %b. %Y")

# Download the HTML page and save it to a local file
curl -s -o "/tmp/page.html" "$html_url"

# Search for the anchor tag with the target text using basic regular expressions
link=$(grep -o -m 1 -E "<a [^>]*>$target_text</a>" "/tmp/page.html")

if [ -n "$link" ]; then
    # Extract the href attribute from the anchor tag
    href=$(echo "$link" | sed -n 's/.*href="\([^"]*\).*/\1/p')

    # Save the PDF file to a local location with the same name as target_text and a .pdf extension
    pdf_filename="$TMPDIR$(date +"CET_Lunch_%b_%Y").pdf"
    pdf_url=$(url_encode "$href")
    #curl -s -o "$pdf_filename" "$pdf_url" 2>&1
    echo $pdf_url
    curl "$pdf_url" --output "$pdf_filename"
    # echo $pdf_filename
    # echo $pdf_url
    # echo $TMPDIR

    # Check if the PDF file was successfully downloaded
    if [ -s "$pdf_filename" ]; then
        # Print the saved PDF file
        lp -o page-ranges=1 -o fit-to-page=width "$pdf_filename"
        # xdg-open $pdf_filename;
        echo "Wrote to $pdf_filename"
    else
        echo "Error: PDF file at '$pdf_url' was not downloaded and is not present in '$pdf_filename'"
    fi
else
    echo "Error: Anchor tag not found for the target text."
fi
