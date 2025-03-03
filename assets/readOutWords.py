import re

def extract_all_words(file_path, output_file):
    extracted_words = set()  # Use a set to avoid duplicates

    with open(file_path, "r", encoding="utf-8") as file:
        for line in file:
            words = re.findall(r"\b\w+\b", line)  # Extract words (ignore symbols, numbers)
            extracted_words.update(words)

    # ✅ Save words to a .txt file, one word per line
    with open(output_file, "w", encoding="utf-8") as output:
        for word in sorted(extracted_words):  # Sort for readability
            output.write(word + "\n")

# ✅ Run the function
file_path = "insertQuestions.js"  # Your file name
output_file = "all_words.txt"
extract_all_words(file_path, output_file)

print(f"✅ All words extracted and saved to {output_file}")
