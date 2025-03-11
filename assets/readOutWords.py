import re

def extract_words_from_code(file_paths, output_file):
    extracted_words = set()  # Use a set to store unique words

    # Regular expressions to match words inside `question: "..."` and `answers: ["..."]`
    question_pattern = re.compile(r'question\s*:\s*"([^"]+)"')  # Matches question: "text here"
    answer_pattern = re.compile(r'answers\s*:\s*\[(.*?)\]')  # Matches answers: ["word1", "word2"]

    for file_path in file_paths:
        with open(file_path, "r", encoding="utf-8") as file:
            for line in file:
                # Extract words from "question" field
                question_match = question_pattern.search(line)
                if question_match:
                    words = re.findall(r"\b\w+\b", question_match.group(1))
                    extracted_words.update(words)

                # Extract words from "answers" list
                answer_match = answer_pattern.search(line)
                if answer_match:
                    answers_text = answer_match.group(1)
                    answers_words = re.findall(r'"([^"]+)"', answers_text)  # Extract words inside quotes
                    for answer in answers_words:
                        words = re.findall(r"\b\w+\b", answer)  # Extract words from answers
                        extracted_words.update(words)

    # ✅ Save words to a .txt file, one word per line
    with open(output_file, "w", encoding="utf-8") as output:
        for word in sorted(extracted_words):  # Sort for readability
            output.write(word + "\n")

# ✅ Run the function with JS and Dart files
file_paths = ["provider.txt", "insertQuestions.js"]  # Keep this part as requested
output_file = "extracted_words.txt"
extract_words_from_code(file_paths, output_file)

print(f"✅ Extracted words saved to {output_file}")
