
import cv2
import numpy as np
import mediapipe as mp
import tensorflow as tf
from PIL import ImageFont, ImageDraw, Image
import os
from collections import deque
from models.gru_model import build_model

# ─────────────────────────────────────────────
#  CONFIGURATION
# ─────────────────────────────────────────────
SEQ_LENGTH   = 30
NUM_FEATURES = 128

# Confidence thresholds
START_CONF_THRESHOLD = 0.65   
HOLD_CONF_THRESHOLD  = 0.42   
LOCK_HOLD_FRAMES     = 12     

# Prediction smoothing
SMOOTH_WINDOW  = 6     
PREDICT_STRIDE = 1     


ENTROPY_THRESHOLD = 3.50

NO_HAND_RESET_FRAMES = 15

# ── Paths ─────────────────────────────────────
WEIGHTS_PATH      = r"C:/Users/Lenovo/Desktop/2nd_Group/models/best_model_weights.weights_new.h5"
KEYPOINTS_PATH    = r"C:/Users/Lenovo/Desktop/2nd_Group/dataset_keypoints_hands_only"
SINHALA_FONT_PATH = r"C:/Users/Lenovo/Desktop/2nd_Group/fonts/NotoSansSinhala-Regular.ttf"
ENGLISH_FONT_PATH = r"C:/Users/Lenovo/Desktop/2nd_Group/fonts/arial.ttf"

# ─────────────────────────────────────────────
#  LOAD MODEL & CLASSES
# ─────────────────────────────────────────────
CLASSES     = sorted(os.listdir(KEYPOINTS_PATH))
NUM_CLASSES = len(CLASSES)
print(f"📂 Found {NUM_CLASSES} sign classes")

model = build_model((SEQ_LENGTH, NUM_FEATURES), NUM_CLASSES)
model.load_weights(WEIGHTS_PATH)
print("🚀 Model loaded. Input shape:", model.input_shape)

# ─────────────────────────────────────────────
#  FAST INFERENCE (compiled TF function)
# ─────────────────────────────────────────────
@tf.function(reduce_retracing=True)
def fast_predict(model_instance, input_tensor):
    return model_instance(input_tensor, training=False)

# ─────────────────────────────────────────────
#  SINHALA LABEL MAP
# ─────────────────────────────────────────────
SINHALA_MAP = {
    "Adverb_Can": "පුළුවන්",        "Adverb_When": "කවදාද",
    "Adverb_Where": "කොහේද",        "Adverb_Why": "ඇයි",
    "Colors_Black": "කළු",          "Colors_Green": "කොළ",
    "Colors_Purple": "දම්",         "Colors_Red": "රතු",
    "Colors_White": "සුදු",         "Colors_Yellow": "කහ",
    "Days_Day": "දවස",              "Days_Time": "වේලාව",
    "Greetings_Ayubowan": "ආයුබෝවන්","Greetings_Hello": "හෙලෝ",
    "Greetings_How are you": "කොහොමද","Greetings_Thank you": "ස්තූතියි",
    "Months_January": "ජනවාරි",     "Months_February": "පෙබරවාරි",
    "Nouns_He": "ඔහු",              "Nouns_Money": "මුදල්",
    "Nouns_My": "මගේ",              "Nouns_You": "ඔයා",
    "Numbers_1.one": "එක",          "Numbers_2.two": "දෙක",
    "Numbers_3.three": "තුන",       "Numbers_4.four": "හතර",
    "Numbers_5.five": "පහ",         "People_Grand father": "සීයා",
    "People_Man": "මිනිසා",         "People_Mother": "අම්මා",
    "People_Son": "පුතා",           "People_Us": "අපි",
    "Place_House": "නිවස",          "Verbs_Come": "එනවා",
    "Verbs_Cook": "උයනවා",         "Verbs_Cry": "අඬනවා",
    "Verbs_Cut": "කපනවා",           "Verbs_Drink": "බොනවා",
    "Verbs_Eat": "කනවා",            "Verbs_Go": "යනවා",
    "Verbs_Help": "උදව් කරනවා",    "Verbs_Look": "බලනවා",
    "Verbs_Love": "ආදරය කරනවා",    "Verbs_Meet": "හමුවෙනවා",
    "Verbs_Play": "සෙල්ලම් කරනවා", "Verbs_Run": "දුවනවා",
    "Verbs_See": "දකිනවා",          "Verbs_Sell": "විකුණනවා",
    "Verbs_Sleep": "නිදාගන්නවා",    "Verbs_Teach": "උගන්වනවා",
    "Verbs_Tell": "කියනවා",         "Verbs_Walk": "ඇවිදිනවා",
    "Verbs_Write": "ලියනවා"
}

# ─────────────────────────────────────────────
#  MEDIAPIPE SETUP
# ─────────────────────────────────────────────
mp_holistic  = mp.solutions.holistic
mp_drawing   = mp.solutions.drawing_utils
holistic     = mp_holistic.Holistic(
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5,
    model_complexity=1
)

# Drawing styles
LANDMARK_STYLE = mp_drawing.DrawingSpec(color=(0, 200, 255), thickness=2, circle_radius=3)
CONNECTION_STYLE = mp_drawing.DrawingSpec(color=(255, 200, 0), thickness=2)

# Fonts
sinhala_font      = ImageFont.truetype(SINHALA_FONT_PATH, 44)
sinhala_font_sm   = ImageFont.truetype(SINHALA_FONT_PATH, 28)
english_font      = ImageFont.truetype(ENGLISH_FONT_PATH, 38)
english_font_sm   = ImageFont.truetype(ENGLISH_FONT_PATH, 24)

# ─────────────────────────────────────────────
#  KEYPOINT EXTRACTION  (unchanged from extract_keypoints.py)
# ─────────────────────────────────────────────
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

# ─────────────────────────────────────────────
#  HELPER: PREDICTION ENTROPY
# ─────────────────────────────────────────────
def softmax_entropy(probs: np.ndarray) -> float:
    
    probs = np.clip(probs, 1e-9, 1.0)
    return float(-np.sum(probs * np.log(probs)))

# ─────────────────────────────────────────────
#  HELPER: DRAW CONFIDENCE BAR
# ─────────────────────────────────────────────
def draw_confidence_bar(frame, conf: float, x=30, y=100, w=300, h=20):
    
    filled = int(conf * w)
    color = (0, 200, 0) if conf >= 0.65 else (0, 165, 255) if conf >= 0.45 else (0, 0, 220)
    cv2.rectangle(frame, (x, y), (x + w, y + h), (50, 50, 50), -1)        
    cv2.rectangle(frame, (x, y), (x + filled, y + h), color, -1)           
    cv2.rectangle(frame, (x, y), (x + w, y + h), (200, 200, 200), 1)       
    cv2.putText(frame, f"{conf*100:.0f}%", (x + w + 8, y + h - 2),
                cv2.FONT_HERSHEY_SIMPLEX, 0.55, color, 2)

# ─────────────────────────────────────────────
#  STATE VARIABLES
# ─────────────────────────────────────────────
seq                 = []                          
pred_deque          = deque(maxlen=SMOOTH_WINDOW) 
last_valid_kp       = np.zeros(NUM_FEATURES)      

# Hysteresis state
active_label_idx    = None     
active_conf         = 0.0      
lock_frames_left    = 0       

# No-hand tracking
no_hand_frames      = 0        

# Display state
display_text        = "Show a sign..."
display_sinhala     = False
debug_mode          = False   

frame_counter       = 0

# ─────────────────────────────────────────────
#  VIDEO CAPTURE LOOP
# ─────────────────────────────────────────────
cap = cv2.VideoCapture(0)
if not cap.isOpened():
    raise RuntimeError("❌ Cannot open webcam. Check camera index.")

print("\n✅ Real-time detection started. Press 'Q' to quit, 'D' for debug mode.\n")

while True:
    ret, frame = cap.read()
    if not ret:
        break

    frame = cv2.flip(frame, 1)
    H, W = frame.shape[:2]
    rgb   = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = holistic.process(rgb)

    # ── Draw hand landmarks ──────────────────────────────────────
    if results.left_hand_landmarks:
        mp_drawing.draw_landmarks(
            frame, results.left_hand_landmarks, mp_holistic.HAND_CONNECTIONS,
            LANDMARK_STYLE, CONNECTION_STYLE
        )
    if results.right_hand_landmarks:
        mp_drawing.draw_landmarks(
            frame, results.right_hand_landmarks, mp_holistic.HAND_CONNECTIONS,
            LANDMARK_STYLE, CONNECTION_STYLE
        )

    # ── Extract keypoints ────────────────────────────────────────
    keypoints = extract_keypoints(results)
    both_hands_absent = (keypoints[63] == 0 and keypoints[127] == 0)

    if both_hands_absent:
        no_hand_frames += 1
        if np.any(last_valid_kp):
            keypoints = last_valid_kp.copy()

        if no_hand_frames >= NO_HAND_RESET_FRAMES:
            seq.clear()
            pred_deque.clear()
            last_valid_kp[:] = 0
            active_label_idx = None
            lock_frames_left = 0
            display_text     = "Show a sign..."
            display_sinhala  = False
            no_hand_frames   = 0
    else:
        no_hand_frames   = 0
        last_valid_kp    = keypoints.copy()

    seq.append(keypoints)
    if len(seq) > SEQ_LENGTH:
        seq.pop(0)

    # ── Prediction (only when buffer is full) ───────────────────
    if len(seq) == SEQ_LENGTH:
        frame_counter += 1

        if frame_counter % PREDICT_STRIDE == 0:
            seq_np = np.array(seq, dtype=np.float32)

            # ── RAW MODEL PREDICTION ──────────────────────────────
            pred = fast_predict(model, np.expand_dims(seq_np, axis=0)).numpy()[0]
            pred_idx  = int(np.argmax(pred))
            pred_conf = float(pred[pred_idx])
            entropy   = softmax_entropy(pred)

            # ── ENTROPY GATE ─────────────────────────────────────
           
            if entropy > ENTROPY_THRESHOLD:
                pass
            else:
                pred_deque.append((pred_idx, pred_conf, pred))

            # ── MAJORITY VOTE SMOOTHING ───────────────────────────
            if len(pred_deque) >= max(3, SMOOTH_WINDOW // 2):
                # Count votes per class
                votes = np.zeros(NUM_CLASSES)
                conf_sum = np.zeros(NUM_CLASSES)

                for p_idx, p_conf, p_full in pred_deque:
                    votes[p_idx] += 1
                    conf_sum += p_full

                # Winner = most voted class
                smoothed_idx  = int(np.argmax(votes))
                # Average confidence for the winning class from raw preds
                avg_conf = float(conf_sum[smoothed_idx] / len(pred_deque))

                # ── HYSTERESIS LOGIC ──────────────────────────────
                if lock_frames_left > 0:
                    # LOCKED: keep displaying the current sign
                    lock_frames_left -= 1
                    # But allow immediate switch if new sign is very confident
                    if smoothed_idx != active_label_idx and avg_conf > START_CONF_THRESHOLD + 0.10:
                        active_label_idx = smoothed_idx
                        active_conf      = avg_conf
                        lock_frames_left = LOCK_HOLD_FRAMES

                elif active_label_idx is None:
                    # IDLE: require START_CONF_THRESHOLD to begin showing
                    if avg_conf >= START_CONF_THRESHOLD:
                        active_label_idx = smoothed_idx
                        active_conf      = avg_conf
                        lock_frames_left = LOCK_HOLD_FRAMES

                else:
                    # ACTIVE: update or clear
                    if smoothed_idx == active_label_idx:
                        active_conf = avg_conf
                        if avg_conf < HOLD_CONF_THRESHOLD:
                            # Same class but confidence dropped → clear
                            active_label_idx = None
                            lock_frames_left = 0
                    else:
                        # Different class: switch if sufficiently confident
                        if avg_conf >= START_CONF_THRESHOLD:
                            active_label_idx = smoothed_idx
                            active_conf      = avg_conf
                            lock_frames_left = LOCK_HOLD_FRAMES
                        elif conf_sum[active_label_idx] / len(pred_deque) < HOLD_CONF_THRESHOLD:
                            # Old class also weak → go idle
                            active_label_idx = None
                            lock_frames_left = 0

                # ── UPDATE DISPLAY TEXT ───────────────────────────
                if active_label_idx is not None:
                    label        = CLASSES[active_label_idx]
                    sinhala      = SINHALA_MAP.get(label, label)
                    display_text = f"{sinhala}  ({active_conf*100:.0f}%)"
                    display_sinhala = True
                else:
                    display_text    = "Analyzing..." if np.any(last_valid_kp) else "Show a sign..."
                    display_sinhala = False

            # ── STORE TOP-3 FOR DEBUG MODE ────────────────────────
            if debug_mode and len(pred_deque) > 0:
                top3_indices = np.argsort(pred)[-3:][::-1]
                top3 = [(CLASSES[i], float(pred[i])) for i in top3_indices]

    # ── RENDER ON FRAME ──────────────────────────────────────────
    img_pil = Image.fromarray(frame)
    draw    = ImageDraw.Draw(img_pil)

    # Main sign display (top-left)
    font  = sinhala_font  if display_sinhala else english_font
    color = (0, 255, 80)  if active_label_idx is not None else (200, 200, 200)
    draw.text((30, 40), display_text, font=font, fill=color)
    frame = np.array(img_pil)

    # Confidence bar
    draw_confidence_bar(frame, active_conf if active_label_idx is not None else 0.0)

    # Debug mode: show top-3 predictions
    if debug_mode and 'top3' in dir() and top3:
        img_pil2 = Image.fromarray(frame)
        draw2    = ImageDraw.Draw(img_pil2)
        for rank, (cls_name, cls_conf) in enumerate(top3):
            sin = SINHALA_MAP.get(cls_name, cls_name)
            txt = f"#{rank+1}: {sin}  {cls_conf*100:.1f}%"
            draw2.text((30, 140 + rank * 36), txt, font=sinhala_font_sm,
                       fill=(255, 220, 80))
        frame = np.array(img_pil2)

    # HUD labels
    mode_txt = "DEBUG ON" if debug_mode else "D=Debug"
    cv2.putText(frame, mode_txt,      (W - 140, 30),  cv2.FONT_HERSHEY_SIMPLEX, 0.55, (150,150,150), 1)
    cv2.putText(frame, "Q=Quit",      (W - 100, 55),  cv2.FONT_HERSHEY_SIMPLEX, 0.55, (150,150,150), 1)
    cv2.putText(frame, f"Buf:{len(seq)}/{SEQ_LENGTH}", (W-150, 80), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (100,100,100), 1)

    cv2.imshow("Sinhala Sign Language — Real Time", frame)

    key = cv2.waitKey(1) & 0xFF
    if key == ord('q') or key == ord('Q'):
        break
    elif key == ord('d') or key == ord('D'):
        debug_mode = not debug_mode
        print(f"🐛 Debug mode: {'ON' if debug_mode else 'OFF'}")

cap.release()
cv2.destroyAllWindows()
holistic.close()
print("👋 Session ended.")