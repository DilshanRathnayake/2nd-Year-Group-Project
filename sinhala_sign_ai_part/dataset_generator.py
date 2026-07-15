import csv
import random
import sys


def authenticate_user():
    print("==================================================")
    print("    🔒 Athwela System Access Control Panel         ")
    print("==================================================")
    CORRECT_USERNAME = "admin"
    CORRECT_PASSWORD = "password123"
    attempts = 3
    while attempts > 0:
        username = input("👤 Enter Username: ").strip()
        password = input("🔑 Enter Password: ").strip()
        if username == CORRECT_USERNAME and password == CORRECT_PASSWORD:
            print("\n✅ Access Granted! Initializing Natural Sequence Generator...")
            return True
        else:
            attempts -= 1
            print(f"❌ Invalid Credentials! Attempts remaining: {attempts}\n")
    sys.exit()

authenticate_user()


word_to_video_map = {
    "මම": "i.mp4", "මගේ": "my.mp4", "ඔයා": "you.mp4", "ඔහු": "he.mp4", "අපි": "us.mp4",
    "සීයා": "grand_father.mp4", "මිනිසා": "man.mp4", "අම්මා": "mother.mp4", "පුතා": "son.mp4",
    "එක": "one.mp4", "දෙක": "two.mp4", "තුන": "three.mp4", "හතර": "four.mp4", "පහ": "five.mp4",
    "කළු": "black.mp4", "කොළ": "green.mp4", "දම්": "purple.mp4", "රතු": "red.mp4", "සුදු": "white.mp4", "කහ": "yellow.mp4",
    "ජනවාරි": "january.mp4", "පෙබරවාරි": "february.mp4", "දවස": "day.mp4", "වේලාව": "time.mp4", "සල්ලි": "money.mp4",
    "ගෙදර": "house.mp4", "ආයුබෝවන්": "ayubowan.mp4", "හෙලෝ": "hello.mp4", "හලෝ": "hello.mp4", "ස්තුතියි": "thank_you.mp4",
    "ස්තූතියි": "thank_you.mp4", "කොහෙද": "where.mp4", "කොහේද": "where.mp4", 
    "කවදාද": "when.mp4", "ඇයි": "why.mp4", "පුළුවන්ද": "can.mp4",
    "?": "question.mp4"
}


verbs_config = {
    "eat.mp4": ["කනවා", "කනව", "කන්නේ", "කන්න", "කෑවා", "කනවාද", "කනවද", "කන්නද"],
    "drink.mp4": ["බොනවා", "බොනව","බොන්නේ", "බොන්න", "බිව්වා", "බොනවාද", "බොනවද", "බොන්නද"],
    "cook.mp4": ["උයනවා", "උයනව","උයන්නේ", "උයන්න", "උයලා", "උයනවාද", "උයනවද", "උයන්නද"],
    "go.mp4": ["යනවා", "යනව", "යන්නේ", "යන්න", "ගියා", "යනවාද", "යනවද", "යන්නද"],
    "come.mp4": ["එනවා", "එනව", "එන්නේ", "එන්නෙ", "එන්න", "ආවා", "එනවාද", "එනවද", "එන්නද"],
    "run.mp4": ["දුවනවා", "දුවනව", "දුවන්නේ", "දුවන්න", "දිව්වා", "දුවනවාද", "දුවනවද", "දුවන්නද", "දිව්වාද"],
    "write.mp4": ["ලියනවා", "ලියනව", "ලියන්නේ", "ලියන්න", "ලිව්වා", "ලියනවාද", "ලියනවද", "ලියන්නද", "ලිව්වාද"],
    "help.mp4": ["උදව් කරනවා", "උදව් කරනව", "උදව් කරන්නේ", "උදව් කරන්න", "උදව් කරනවාද", "උදව් කරනවද", "උදව් කරන්නද"],
    "play.mp4": ["සෙල්ලම් කරනවා", "සෙල්ලම් කරනව","සෙල්ලම් කරන්නේ", "සෙල්ලම් කරන්න", "සෙල්ලම් කරනවාද", "සෙල්ලම් කරනවද", "සෙල්ලම් කරන්නද"],
    "love.mp4": ["ආදරය කරනවා", "ආදරය කරනව", "ආදරය කරන්නේ", "ආදරය කරන්න", "ආදරය කරනවාද", "ආදරය කරනවද", "ආදරය කරන්නද"],
    "meet.mp4": ["හමුවෙනවා", "හමුවෙනව", "හමුවෙන්නේ", "හමුවෙන්න", "හමුවුණා", "හමුවෙනවාද", "හමුවෙනවද", "හමුවෙන්නද"],
    "sell.mp4": ["විකුණනවා", "විකුණනව", "විකුණන්නේ", "විකුණන්න", "විකුණනවාද", "විකුණනවද", "විකුණන්නද"],
    "cut.mp4": ["කපනවා", "කපනව", "කපන්නේ", "කපන්න", "කපනවාද", "කපනවද", "කපන්නද"],
    "cry.mp4": ["අඬනවා", "අඬනව", "අඬන්නේ", "අඬන්න", "අඬනවාද", "අඬනවද", "අඬන්නද"],
    "look.mp4": ["බලනවා", "බලනව", "බලන්නේ", "බලන්න", "බලනවාද", "බලනවද", "බලන්නද"],
    "see.mp4": ["දකිනවා", "දකිනව", "දකින්නේ", "දකින්න්න", "දකිනවාද", "දකිනවද"],
    "sleep.mp4": ["නිදාගන්නවා", "නිදාගන්නව", "නිදාගන්නේ", "නිදාගන්න", "නිදාගන්නවාද", "නිදාගන්නවද"],
    "teach.mp4": ["උගන්වනවා", "උගන්වනව", "උගන්වන්නේ", "උගන්වන්න", "උගන්වනවාද", "උගන්වනවද", "උගන්වන්නද"],
    "tell.mp4": ["කියනවා", "කියනව", "කියන්නේ", "කියන්න", "කියනවද", "කියනවාද", "කියන්නද"],
    "walk.mp4": ["ඇවිදිනවා", "ඇවිදිනව", "ඇවිදින්නේ", "ඇවිදින්න", "ඇවිදිනවද", "ඇවිදිනවාද", "ඇවිදින්නද"]
}


def get_exact_video_sequence(sinhala_text):
    corrected_array = []
    is_question = False
    
    text_to_process = sinhala_text
    if "?" in text_to_process:
        is_question = True
        text_to_process = text_to_process.replace("?", "").strip() + " ?"

   
    multi_words = ["උදව් කරනවා", "උදව් කරනව", "උදව් කරන්නේ", "උදව් කරන්න",
                   "සෙල්ලම් කරනවා", "සෙල්ලම් කරනව","සෙල්ලම් කරන්නේ", "සෙල්ලම් කරන්න",
                   "ආදරය කරනවා", "ආදරය කරනව", "ආදරය කරන්නේ", "ආදරය කරන්න",
                   "උදව් කරනවාද", "උදව් කරනවද", "සෙල්ලම් කරනවාද", "සෙල්ලම් කරනවද",
                   "ආදරය කරනවාද", "ආදරය කරනවද", "උදව් කරන්නද", "සෙල්ලම් කරන්නද", "ආදරය කරන්නද"]
    
    for mw in multi_words:
        if mw in text_to_process:
            text_to_process = text_to_process.replace(mw, mw.replace(" ", "_"))

    words = text_to_process.split()
    for word in words:
        word_clean = word.replace("_", " ").replace("?", "").strip()
        if not word_clean: continue
            
        verb_found = False
        for vid, variations in verbs_config.items():
           
            if word_clean in variations:
                corrected_array.append(vid)
                verb_found = True
                break
                
        if verb_found: continue
            
        if word_clean in word_to_video_map:
            video_name = word_to_video_map[word_clean]
            corrected_array.append(video_name)
            if word_clean in ["කොහෙද", "කොහේද", "කවදාද", "ඇයි", "පුළුවන්ද", "?"]:
                is_question = True
        elif "අම්මා" in word_clean: corrected_array.append("mother.mp4")
        elif "පුතා" in word_clean: corrected_array.append("son.mp4")

    if is_question and "question.mp4" not in corrected_array:
        corrected_array.append("question.mp4")
        
    final_vids = []
    for v in corrected_array:
        if len(final_vids) == 0 or v != final_vids[-1]:
            final_vids.append(v)
            
    return " ".join(final_vids)


single_words_set = set()
sentences_set = set()

subjects_list = ["මම", "ඔයා", "ඔහු", "අපි", "මගේ අම්මා", "මගේ පුතා", "සීයා", "මිනිසා"]
months_list = ["ජනවාරි", "පෙබරවාරි"]
time_color_list = ["දවස", "වේලාව", "සල්ලි", "ගෙදර", "රතු", "කොළ", "සුදු", "කළු", "කහ", "දම්"]
q_words_list = ["කොහෙද", "කොහේද", "කවදාද", "ඇයි", "පුළුවන්ද"]

all_verbs_list = []
verbal_questions_list = [] 


for v_vid, v_vars in verbs_config.items():
    for var in v_vars:
        if var.endswith("ද"):
            verbal_questions_list.append(var) 
        else:
            all_verbs_list.append(var) 


for sin in word_to_video_map.keys():
    if sin != "?": single_words_set.add(sin)
for verb in all_verbs_list:
    single_words_set.add(verb)
for q_verb in verbal_questions_list:
    single_words_set.add(q_verb)


for sub in subjects_list:
    for verb in all_verbs_list:
        sentences_set.add(f"{sub} {verb}")
        sentences_set.add(f"{verb} {sub}")
    
    for q_verb in verbal_questions_list:
        sentences_set.add(f"{sub} {q_verb}")

for month in months_list:
    for sub in subjects_list:
        sentences_set.add(f"{month} {sub}")
        sentences_set.add(f"{sub} {month}")

for item in time_color_list:
    sentences_set.add(f"{item}")
    for sub in subjects_list: sentences_set.add(f"{sub} {item}")

# Wh-Questions Permutations
for q in q_words_list:
    for sub in subjects_list:
        sentences_set.add(f"{q} {sub}") 
        sentences_set.add(f"{sub} {q}") 
    for verb in all_verbs_list:
        sentences_set.add(f"{q} {verb}")


for sub in subjects_list:
    for verb in all_verbs_list:
        for month in months_list:
            sentences_set.add(f"{month} {sub} {verb}")
            sentences_set.add(f"{sub} {month} {verb}")
            for item in time_color_list:
                sentences_set.add(f"{month} {sub} {item} {verb}")

        sentences_set.add(f"{sub} පුළුවන්ද {verb}")
        sentences_set.add(f"{sub} {verb} පුළුවන්ද")

   
    for q_verb in verbal_questions_list:
        sentences_set.add(f"{sub} {q_verb}")
        for month in months_list:
            sentences_set.add(f"{sub} {month} {q_verb}")
        for item in time_color_list:
            sentences_set.add(f"{sub} {item} {q_verb}")

    for q in q_words_list:
        sentences_set.add(f"{q} {sub} {verb}") 
        sentences_set.add(f"{sub} {q} {verb}") 

sentences_list = list(sentences_set)
random.shuffle(sentences_list)

final_text_pool = list(single_words_set)
needed_sentences = 65000 - len(final_text_pool)
final_text_pool.extend(sentences_list[:needed_sentences])


raw_dataset = []
for sentence in final_text_pool:
    vids = get_exact_video_sequence(sentence)
    is_actually_a_question = (
        "question.mp4" in vids or 
        any(q in sentence for q in q_words_list) or
        any(sentence.endswith(qv) for qv in verbal_questions_list) or
        "පුළුවන්ද" in sentence
    )
    
    if is_actually_a_question:
        clean_sentence = sentence.replace("?", "").strip()
        clean_sentence = clean_sentence + " ?"
        vids_updated = get_exact_video_sequence(clean_sentence)
        raw_dataset.append((clean_sentence, vids_updated))
    else:
        raw_dataset.append((sentence, vids))


boosted_dataset = []
for s, v in raw_dataset:
    boosted_dataset.append((s, v))
    if len(s.split()) <= 2:
        for _ in range(15):
            boosted_dataset.append((s, v))

normal_sentences = []
question_sentences = []
for s, v in boosted_dataset:
    if "question.mp4" in v: question_sentences.append((s, v))
    else: normal_sentences.append((s, v))

max_allowed_q = int(len(normal_sentences) * 0.45)
random.shuffle(question_sentences)
question_sentences = question_sentences[:max_allowed_q]

final_dataset = normal_sentences + question_sentences
random.shuffle(final_dataset)

# Saving to dataset.txt
with open("dataset.txt", "w", encoding="utf-8") as f:
    for sin, vid in final_dataset:
        f.write(f"{sin}\t{vid}\n")

print(f"\n==================================================")
print(f"   🎉 Natural Sequence Alignment Dataset Prepared!   ")
print(f"   🔢 Total Rows: {len(final_dataset)}")
print("==================================================")





