# extract_keypoints.py
import cv2
import mediapipe as mp
import numpy as np
import os

DATA_PATH = r"C:/Users/Lenovo/Desktop/2nd_Group/dataset"
KEYPOINTS_PATH = r"C:/Users/Lenovo/Desktop/2nd_group/dataset_keypoints_hands_only"
SEQ_LENGTH = 30

os.makedirs(KEYPOINTS_PATH, exist_ok=True)

mp_holistic = mp.solutions.holistic
holistic = mp_holistic.Holistic()

VALID_EXTENSIONS = (".mp4", ".mov")

def normalize_hand(hand_landmarks):
    if hand_landmarks is None:
        return np.zeros(63), 0
    hand = np.array([[lm.x, lm.y, lm.z] for lm in hand_landmarks.landmark])
    wrist = hand[0, :2]
    hand[:, :2] -= wrist
    max_dist = np.max(np.linalg.norm(hand[:, :2], axis=1))
    if max_dist > 0:
        hand[:, :2] /= max_dist
    return hand.flatten(), 1

def extract_keypoints(results):
    lh, lh_flag = normalize_hand(results.left_hand_landmarks)
    rh, rh_flag = normalize_hand(results.right_hand_landmarks)
    return np.concatenate([lh, [lh_flag], rh, [rh_flag]])

for category in os.listdir(DATA_PATH):
    category_path = os.path.join(DATA_PATH, category)
    if not os.path.isdir(category_path):
        continue

    for label in os.listdir(category_path):
        label_path = os.path.join(category_path, label)
        if not os.path.isdir(label_path):
            continue

        save_dir = os.path.join(KEYPOINTS_PATH, f"{category}_{label}")
        os.makedirs(save_dir, exist_ok=True)

        videos = [f for f in os.listdir(label_path) if f.lower().endswith(VALID_EXTENSIONS)]
        print(f"\n📂 {category}/{label} - {len(videos)} videos")

        for video in videos:
            video_path = os.path.join(label_path, video)
            save_path = os.path.join(save_dir, video + ".npy")

            cap = cv2.VideoCapture(video_path)
            sequence = []
            frame_count = 0

            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                frame_count += 1
                try:
                    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    results = holistic.process(rgb)
                    keypoints = extract_keypoints(results)
                    sequence.append(keypoints)
                except Exception:
                    continue

            cap.release()

            if frame_count == 0:
                print(f"❌ Broken video: {video}")
                sequence = np.zeros((SEQ_LENGTH, 128))
            else:
                sequence = np.array(sequence)
                if len(sequence) < SEQ_LENGTH:
                    pad = np.zeros((SEQ_LENGTH - len(sequence), 128))
                    sequence = np.vstack((sequence, pad))
                else:
                    sequence = sequence[:SEQ_LENGTH]

            np.save(save_path, sequence)
            print(f"✅ Saved: {video}")