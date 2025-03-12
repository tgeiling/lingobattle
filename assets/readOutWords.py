import re
import json

def extract_words_from_insert_questions(file_path):
    extracted_words = set()
    
    question_pattern = re.compile(r'question\s*:\s*"([^"]+)"')  
    answer_pattern = re.compile(r'answers\s*:\s*\[(.*?)\]')  

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
                answers_words = re.findall(r'"([^"]+)"', answers_text)
                for answer in answers_words:
                    words = re.findall(r"\b\w+\b", answer)
                    extracted_words.update(words)

    return extracted_words

def extract_words_from_provider(file_path):
    extracted_words = set()
    
    with open(file_path, "r", encoding="utf-8") as file:
        content = file.read()
        
        # Extract everything inside "question" fields
        question_matches = re.findall(r'"question"\s*:\s*"([^"]+)"', content)
        for question in question_matches:
            words = re.findall(r"\b\w+\b", question)
            extracted_words.update(words)

        # Extract everything inside "answers" fields
        answer_matches = re.findall(r'"answers"\s*:\s*\[(.*?)\]', content)
        for answer_set in answer_matches:
            answers_words = re.findall(r'"([^"]+)"', answer_set)
            for answer in answers_words:
                words = re.findall(r"\b\w+\b", answer)
                extracted_words.update(words)

    return extracted_words

# ✅ Define file paths
provider_file = "provider.txt"
insert_questions_file = "insertQuestions.js"
output_file = "extracted_words.txt"

# ✅ Extract words from both files
words_from_provider = extract_words_from_provider(provider_file)
words_from_insert_questions = extract_words_from_insert_questions(insert_questions_file)

# ✅ Combine words and save to file
all_extracted_words = sorted(words_from_provider.union(words_from_insert_questions))

with open(output_file, "w", encoding="utf-8") as output:
    for word in all_extracted_words:
        output.write(word + "\n")

print(f"✅ Extracted words saved to {output_file}")
