import json
import urllib.parse
import re

def normalize_name(name):
    # Remove "GIF" and "(THC)", "(PCP)", "(MDMA)", "(LSD)", "(GHB)", "(DMT)", "(GABA)" etc
    name = re.sub(re.escape("GIF"), "", name, flags=re.IGNORECASE)
    name = re.sub(r'\(.*?\)', '', name)
    # Remove leading/trailing symbols and whitespace
    name = name.strip(' \t\n\r"\'')
    # Convert to lowercase for comparison
    return name.lower()

def get_makerworld_url(title):
    # MakerWorld URLs seem to follow a pattern or can be searched.
    # Since I don't have the exact IDs, I will generate a search URL or 
    # a slug-based URL if I can guess it.
    # However, the user said they have over 200 links and doesn't want to copy paste.
    # If I can't scrape, I might need to provide a way to generate the search link
    # or use the provided text to match.
    
    # Actually, MakerWorld URLs usually look like:
    # https://makerworld.com/en/models/123456#profileId-789012
    # Without the IDs, I can't generate the "specific molecule" link directly.
    
    # WAIT! The user provided a list of titles. If I can't scrape the URLs,
    # I can't match them to specific IDs.
    
    # Let me try to see if I can use a search URL as a fallback or 
    # if there is a common pattern for "Mira's" models.
    
    # The user's request says: "the link should take me to the specific molecule"
    # Without the URL from the scrape, I can't do that.
    
    # Let me double check if I can get the URLs using another method.
    # Maybe `read_url_content` on the profile page?
    return None

def match_molecules():
    with open('molecules.json', 'r', encoding='utf-8') as f:
        molecules = json.load(f)
    
    with open('titles.txt', 'r', encoding='utf-8') as f:
        titles = [line.strip() for line in f if line.strip()]

    # Create a mapping of normalized titles to original titles
    title_map = {}
    for t in titles:
        norm = normalize_name(t)
        title_map[norm] = t

    updated_count = 0
    for mol in molecules:
        mol_name = normalize_name(mol['name'])
        
        # Try direct match
        if mol_name in title_map:
            # We found a match, but still need the URL.
            # I will mark these as "Match Found: [Title]" for now
            # and search for the URL in a second pass if I can get them.
            pass
        
    print(f"Matched {updated_count} molecules.")

if __name__ == "__main__":
    # Since I can't scrape, I will try to see if I can get the page content via read_url_content
    # which might contain the links in the HTML.
    pass
