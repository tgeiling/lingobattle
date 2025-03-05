import re

def extract_all_words(file_paths, output_file):
    extracted_words = set()  # Use a set to avoid duplicates

    for file_path in file_paths:
        with open(file_path, "r", encoding="utf-8") as file:
            for line in file:
                words = re.findall(r"\b\w+\b", line)  # Extract words (ignore symbols, numbers)
                extracted_words.update(words)

    # ✅ Save words to a .txt file, one word per line
    with open(output_file, "w", encoding="utf-8") as output:
        for word in sorted(extracted_words):  # Sort for readability
            output.write(word + "\n")

# ✅ Run the function
file_paths = ["provider.txt", "insertQuestions.dart"]  # Your file names
output_file = "all_words.txt"
extract_all_words(file_paths, output_file)

print(f"✅ All words extracted and saved to {output_file}")
