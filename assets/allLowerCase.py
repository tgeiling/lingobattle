import json
import re

def to_lowercase_alpha(text):
    """Converts only alphabetical characters to lowercase."""
    return ''.join(char.lower() if char.isalpha() else char for char in text)

def process_json(file_path):
    """Reads the JSON file, converts alphabetical characters to lowercase, and saves the result."""
    with open(file_path, "r", encoding="utf-8") as file:
        data = json.load(file)

    # Process the words dictionary
    processed_words = {}
    for word, translations in data["words"].items():
        processed_word = to_lowercase_alpha(word)  # Convert word key
        processed_translations = {lang: to_lowercase_alpha(translation) for lang, translation in translations.items()}
        processed_words[processed_word] = processed_translations

    # Update the JSON structure
    data["words"] = processed_words

    # Save the modified JSON file
    with open(file_path, "w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=4)

    print("✅ Translations converted to lowercase (alphabetical characters only) and saved!")

# Run the script
process_json("translations.json")
