
import numpy as np
import os
import random
from sklearn.model_selection import train_test_split
from sklearn.utils.class_weight import compute_class_weight
from tensorflow.keras.utils import to_categorical
from models.gru_model import build_model
from tensorflow.keras.callbacks import (
    EarlyStopping, ModelCheckpoint, TensorBoard
)

# ─────────────────────────────────────────────
#  CONFIGURATION
# ─────────────────────────────────────────────
DATA_PATH        = r"C:/Users/Lenovo/Desktop/2nd_Group/dataset_keypoints_hands_only"
MODEL_SAVE_PATH  = r"C:/Users/Lenovo/Desktop/2nd_Group/models/best_model_weights.weights_new.h5"
LOG_DIR          = r"C:/Users/Lenovo/Desktop/2nd_Group/logs"
SEQ_LENGTH       = 30
NUM_FEATURES     = 128
EPOCHS           = 150
BATCH_SIZE       = 128    
AUG_COPIES       = 5       
MIXUP_ALPHA      = 0.25    
TEST_SIZE        = 0.20    

# ─────────────────────────────────────────────
#  LOAD DATASET
# ─────────────────────────────────────────────
print("🔄 Loading dataset...")
sequences, labels = [], []
label_map = {}

for i, label in enumerate(sorted(os.listdir(DATA_PATH))):
    label_map[label] = i
    folder = os.path.join(DATA_PATH, label)
    for file in os.listdir(folder):
        seq = np.load(os.path.join(folder, file))
        # Safety: ensure correct shape
        if seq.shape != (SEQ_LENGTH, NUM_FEATURES):
            if len(seq) < SEQ_LENGTH:
                pad = np.zeros((SEQ_LENGTH - len(seq), NUM_FEATURES))
                seq = np.vstack([seq, pad])
            else:
                seq = seq[:SEQ_LENGTH]
        sequences.append(seq)
        labels.append(i)

X = np.array(sequences)    
y_int = np.array(labels)   
NUM_CLASSES = len(label_map)
print(f"✅ Loaded {X.shape[0]} sequences | {NUM_CLASSES} classes")
print(f"   Label map: {list(label_map.keys())[:5]} ...")

# ─────────────────────────────────────────────
#  TRAIN / TEST SPLIT  (stratified)
# ─────────────────────────────────────────────
X_train, X_test, y_train_int, y_test_int = train_test_split(
    X, y_int,
    test_size=TEST_SIZE,
    stratify=y_int,
    random_state=42
)
y_train = to_categorical(y_train_int, NUM_CLASSES)
y_test  = to_categorical(y_test_int,  NUM_CLASSES)
print(f"📊 Train: {X_train.shape[0]} | Test: {X_test.shape[0]}")

# ─────────────────────────────────────────────
#  DATA AUGMENTATION  (5 techniques)
# ─────────────────────────────────────────────
print(f"\n🚀 Applying {AUG_COPIES}x Data Augmentation...")

def augment_sequence(seq: np.ndarray) -> np.ndarray:
    
    seq = seq.copy()

    # 1. Gaussian noise
    if random.random() > 0.2:
        noise_std = random.uniform(0.004, 0.012)
        seq += np.random.normal(0, noise_std, seq.shape)

    # 2. Scale
    if random.random() > 0.2:
        scale = random.uniform(0.88, 1.12)
        seq *= scale

    # 3. Positional shift (x and y only, skip z)
    if random.random() > 0.3:
        shift = random.uniform(-0.02, 0.02)
        # Apply only to coordinate channels, not flag channels (63 and 127)
        coord_mask = np.ones(NUM_FEATURES, dtype=bool)
        coord_mask[63] = False
        coord_mask[127] = False
        seq[:, coord_mask] += shift

    # 4. Temporal warp / speed variation
    if random.random() > 0.4:
        roll_by = random.randint(-3, 3)
        seq = np.roll(seq, roll_by, axis=0)

    # 5. Mirror: swap left hand (0:64) ↔ right hand (64:128)
    if random.random() > 0.5:
        lh = seq[:, :64].copy()
        rh = seq[:, 64:].copy()
        seq[:, :64] = rh
        seq[:, 64:] = lh
        # Flip x-coordinates (index 0, 3, 6, ...) for realistic mirror
        for start in [0, 64]:
            for j in range(start, start + 63, 3):  # every 3rd = x coord
                seq[:, j] = -seq[:, j]

    return seq


def mixup(X_a, y_a, X_b, y_b, alpha=MIXUP_ALPHA):
    
    lam = np.random.beta(alpha, alpha)
    X_mix = lam * X_a + (1 - lam) * X_b
    y_mix = lam * y_a + (1 - lam) * y_b
    return X_mix, y_mix


# ── Build augmented training set ──────────────────────────────────
aug_X, aug_y = [], []
N = len(X_train)

for i in range(N):
    # Always include original
    aug_X.append(X_train[i])
    aug_y.append(y_train[i])

    # AUG_COPIES augmented versions
    for _ in range(AUG_COPIES):
        aug_X.append(augment_sequence(X_train[i]))
        aug_y.append(y_train[i])

aug_X = np.array(aug_X)   # (N × (1 + AUG_COPIES), 30, 128)
aug_y = np.array(aug_y)
print(f"📈 After standard aug: {aug_X.shape[0]} samples")

# ── MixUp pass (adds another N mixed samples) ─────────────────────
mix_X, mix_y = [], []
indices = np.random.permutation(len(aug_X))
for i in range(0, len(indices) - 1, 2):
    mx, my = mixup(aug_X[indices[i]], aug_y[indices[i]],
                   aug_X[indices[i+1]], aug_y[indices[i+1]])
    mix_X.append(mx)
    mix_y.append(my)

mix_X = np.array(mix_X)
mix_y = np.array(mix_y)

X_train_final = np.concatenate([aug_X, mix_X], axis=0)
y_train_final = np.concatenate([aug_y, mix_y], axis=0)

# Shuffle
perm = np.random.permutation(len(X_train_final))
X_train_final = X_train_final[perm]
y_train_final = y_train_final[perm]

print(f"📈 After MixUp: {X_train_final.shape[0]} total training samples")

# ─────────────────────────────────────────────
#  CLASS WEIGHTS  (handle imbalanced classes)
# ─────────────────────────────────────────────

class_weights = compute_class_weight(
    class_weight='balanced',
    classes=np.unique(y_train_int),
    y=y_train_int
)
class_weight_dict = dict(enumerate(class_weights))

# ─────────────────────────────────────────────
#  BUILD MODEL
# ─────────────────────────────────────────────
model = build_model((SEQ_LENGTH, NUM_FEATURES), NUM_CLASSES)
model.summary()
print(f"\n🔢 Total parameters: {model.count_params():,}")

# ─────────────────────────────────────────────
#  CALLBACKS
# ─────────────────────────────────────────────
os.makedirs(os.path.dirname(MODEL_SAVE_PATH), exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)

callbacks = [
    ModelCheckpoint(
        MODEL_SAVE_PATH,
        monitor='val_accuracy',
        save_best_only=True,
        save_weights_only=True,
        mode='max',
        verbose=1
    ),

    
    EarlyStopping(
        monitor='val_loss',
        patience=25,
        restore_best_weights=True,
        verbose=1
    ),

    TensorBoard(log_dir=LOG_DIR, histogram_freq=1)
]

# ─────────────────────────────────────────────
#  TRAIN
# ─────────────────────────────────────────────
print("\n🏋️ Training started...")
print(f"   Epochs: {EPOCHS} | Batch: {BATCH_SIZE} | Classes: {NUM_CLASSES}")

history = model.fit(
    X_train_final, y_train_final,
    epochs=EPOCHS,
    batch_size=BATCH_SIZE,
    validation_data=(X_test, y_test),
    class_weight=class_weight_dict,
    callbacks=callbacks,
    verbose=1
)

# ─────────────────────────────────────────────
#  EVALUATE
# ─────────────────────────────────────────────
loss, acc = model.evaluate(X_test, y_test, verbose=0)
print(f"\n🎯 Final Test Accuracy : {acc:.4f}  ({acc*100:.1f}%)")
print(f"   Test Loss           : {loss:.4f}")
print(f"💾 Best weights saved to: {MODEL_SAVE_PATH}")

# ── Per-class accuracy report ─────────────────────────────────────
print("\n📋 Per-class accuracy (top confusions):")
y_pred_prob = model.predict(X_test, verbose=0)
y_pred = np.argmax(y_pred_prob, axis=1)
y_true = y_test_int

inv_label_map = {v: k for k, v in label_map.items()}
class_acc = {}
for cls_idx in range(NUM_CLASSES):
    mask = (y_true == cls_idx)
    if mask.sum() == 0:
        continue
    cls_acc_val = (y_pred[mask] == cls_idx).mean()
    class_acc[cls_idx] = cls_acc_val

# Print worst 10 classes
worst = sorted(class_acc.items(), key=lambda x: x[1])[:10]
print("   Worst performing signs (fix these first):")
for idx, a in worst:
    print(f"     {inv_label_map[idx]:<35} {a*100:.1f}%")