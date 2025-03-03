import json
import time
from google.cloud import translate_v2 as translate

# Initialize Google Cloud Translate Client
client = translate.Client()

JSON_FILE = "translated_words.json"

def detect_language(text):
    """Detects the language of a given text. If undetected, default to English."""
    try:
        result = client.detect_language(text)
        detected_lang = result.get("language", "und")

        if detected_lang == "und":  # If language is undefined, assume English
            print(f"⚠️ Warning: Could not detect language for '{text}', defaulting to English.")
            return "en"

        return detected_lang

    except Exception as e:
        print(f"❌ Error detecting language for '{text}': {e}")
        return "en"  # Default to English if detection fails

def translate_word(word, source_lang):
    """Translates a word into German, Spanish, Dutch, and English, excluding the detected language."""
    target_languages = {"german": "de", "spanish": "es", "dutch": "nl", "english": "en"}
    translations = {}

    for lang, code in target_languages.items():
        if source_lang != code:  # Skip translating to the detected language
            try:
                translated_text = client.translate(word, target_language=code, source_language=source_lang)["translatedText"]
                translations[lang] = translated_text
            except Exception as e:
                print(f"❌ Error translating '{word}' to {lang}: {e}")
                translations[lang] = ""  # Store empty translation if an error occurs
                time.sleep(1)  # Small delay to avoid rate limits

    return translations

def save_to_json(data):
    """Writes the entire JSON structure to file."""
    with open(JSON_FILE, "w", encoding="utf-8") as json_file:
        json.dump(data, json_file, ensure_ascii=False, indent=4)

def process_words_from_file(file_path):
    """Reads words from a file, detects language, translates, and saves results to JSON incrementally."""
    
    words_dict = {}

    # Load existing translations if the script was interrupted before
    try:
        with open(JSON_FILE, "r", encoding="utf-8") as json_file:
            existing_data = json.load(json_file)
            words_dict = existing_data.get("words", {})
            print(f"🔄 Resuming from {len(words_dict)} saved words...")
    except (FileNotFoundError, json.JSONDecodeError):
        print("🆕 Starting fresh translation process...")

    # Read words from file
    with open(file_path, "r", encoding="utf-8") as file:
        words = [line.strip() for line in file if line.strip()]  # Remove empty lines

    print(f"🔍 Processing {len(words)} words...")

    for index, word in enumerate(words, start=1):
        if word in words_dict:  # Skip already processed words
            continue

        source_lang = detect_language(word)
        translations = translate_word(word, source_lang)
        words_dict[word] = translations

        # Save JSON file **incrementally** after each word
        save_to_json({
            "languages": ["german", "spanish", "dutch", "english"],
            "words": words_dict
        })

        # Log progress every 10 words
        if index % 10 == 0:
            print(f"✅ Processed {index}/{len(words)} words. Last word: {word}")

    print("✅ All translations completed! Saved to translated_words.json.")

# Run the script with all_words.txt
process_words_from_file("all_words.txt")
