import numpy as np
import tensorflow as tf
import json
import os
import cv2
import re


MAX_LEN = 8
VIDEO_FOLDER = "videos"  


if not os.path.exists('sinhala_vocab.json') or not os.path.exists('sign_vocab.json'):
    print("Error: Vocab files missing! Please run train_model.py first.")
    exit()

with open('sinhala_vocab.json', 'r', encoding='utf-8') as f:
    sinhala_vocab = json.load(f)

with open('sign_vocab.json', 'r', encoding='utf-8') as f:
    sign_vocab = {int(k): v for k, v in json.load(f).items()}


dataset_lookup = {}
if os.path.exists("dataset.txt"):
    with open("dataset.txt", "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or "\t" not in line:
                continue
            inp, tar = line.split("\t")
           
            dataset_lookup[inp.strip()] = tar.strip().split()


if not os.path.exists("sign_model.tflite"):
    print("Error: sign_model.tflite not found!")
    exit()

interpreter = tf.lite.Interpreter(model_path="sign_model.tflite")
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()


def play_videos_sequentially(video_list):
    """Plays the given video array exactly as provided by the model output."""
    print("\n🎬 Playing Sign Language Videos...")
    
    for video_name in video_list:
        video_path = os.path.join(VIDEO_FOLDER, video_name) if VIDEO_FOLDER else video_name
        
        if not os.path.exists(video_path):
            print(f"⚠️ Video not found at: {os.path.abspath(video_path)} (Skipping...)")
            continue
            
        print(f" ▶️ Playing: {video_name}")
        cap = cv2.VideoCapture(video_path)
        
        window_name = "Sign Language Player"
        cv2.namedWindow(window_name, cv2.WINDOW_AUTOSIZE)
        cv2.setWindowProperty(window_name, cv2.WND_PROP_TOPMOST, 1)
        
        fps = cap.get(cv2.CAP_PROP_FPS)
        delay = int(1000 / fps) if fps > 0 else 30

        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break  
                
            cv2.imshow(window_name, frame)
            if cv2.waitKey(delay) & 0xFF == ord('q'):
                break
                
        cap.release()
        
    cv2.destroyAllWindows()
    print("🏁 Sequenced playback finished.")



def test_interactive(sinhala_text):
  
    processed_text = re.sub(r'([?])', r' \1 ', sinhala_text)
    processed_text = " ".join(processed_text.split())
    
    words = processed_text.split()
    clipped_words = words[:MAX_LEN] 
    
    sequence = [sinhala_vocab.get(w, 0) for w in clipped_words]
    

    padded_sequence = sequence + [0] * (MAX_LEN - len(sequence))
    padded_sequence = np.array([padded_sequence], dtype=np.int32)
    
    interpreter.set_tensor(input_details[0]['index'], padded_sequence)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])[0]
    
  
    predicted_videos = []
    for word_probs in output_data:
        predicted_id = np.argmax(word_probs)
        if predicted_id in sign_vocab and predicted_id != 0:
            video_file = sign_vocab[predicted_id]
           
            if len(predicted_videos) == 0 or video_file != predicted_videos[-1]:
                predicted_videos.append(video_file)
                
    actual_videos = dataset_lookup.get(processed_text, ["<Custom Sentence / No direct map>"])
    
    print("\n--------------------------------------------------")
    print(f"📊 Input Text        : {sinhala_text}")
    print(f"🔍 Processed Text    : {processed_text}")
    print(f"🎯 Actual Array      : {actual_videos}")
    print(f"🤖 Predicted Array   : {predicted_videos}")
    print("--------------------------------------------------")
    
    if predicted_videos:
        play_videos_sequentially(predicted_videos)



print("==================================================")
print("   Interactive Pure AI Video Tester v7.0-Raw      ")
print("   (100% Raw Model Outputs - MAX_LEN=8)           ")
print("==================================================")

while True:
    user_input = input("\nEnter Sinhala Text: ").strip()
    if user_input.lower() == 'exit':
        print("Inspection completed")
        break
    if not user_input:
        continue
    test_interactive(user_input)