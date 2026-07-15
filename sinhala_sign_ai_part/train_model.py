import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input, Dense, Embedding, MultiHeadAttention, LayerNormalization, Dropout
import keras  # Keras 3 operations සඳහා
import json
import os
import time
import re

MAX_LEN = 8


def clean_and_split_punctuation(text):
    
    text = re.sub(r'([?])', r' \1 ', text)  
    return " ".join(text.split())           

input_sentences = []
target_videos = []

if not os.path.exists("dataset.txt"):
    print("Error: dataset.txt not found! Please run dataset_generator.py first.")
    exit()

with open("dataset.txt", "r", encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line or "\t" not in line:
            continue
        parts = line.split("\t")
        if len(parts) == 2:
           
            cleaned_sin = clean_and_split_punctuation(parts[0].strip())
            input_sentences.append(cleaned_sin)
            target_videos.append(parts[1].strip())

print(f"✅ Dataset Loaded Successfully. Total clean samples: {len(input_sentences)}")


sinhala_tokenizer = tf.keras.preprocessing.text.Tokenizer(filters='!"#$%&()*+,-./:;<=>@[\\]^_`{|}~\t\n')
sinhala_tokenizer.fit_on_texts(input_sentences)
X = tf.keras.preprocessing.sequence.pad_sequences(
    sinhala_tokenizer.texts_to_sequences(input_sentences), maxlen=MAX_LEN, padding='post'
)

video_tokenizer = tf.keras.preprocessing.text.Tokenizer(filters='')
video_tokenizer.fit_on_texts(target_videos)

Y = tf.keras.preprocessing.sequence.pad_sequences(
    video_tokenizer.texts_to_sequences(target_videos), maxlen=MAX_LEN, padding='post'
)

num_sinhala_words = len(sinhala_tokenizer.word_index) + 1
num_video_words = len(video_tokenizer.word_index) + 1


with open('sinhala_vocab.json', 'w', encoding='utf-8') as f:
    json.dump(sinhala_tokenizer.word_index, f, ensure_ascii=False)
with open('sign_vocab.json', 'w', encoding='utf-8') as f:
    reverse_video_map = {v: k for k, v in video_tokenizer.word_index.items()}
    json.dump(reverse_video_map, f, ensure_ascii=False)
    
reverse_sinhala_map = {v: k for k, v in sinhala_tokenizer.word_index.items()}

indices = np.arange(X.shape[0])
np.random.seed(42)
np.random.shuffle(indices)
X, Y = X[indices], Y[indices]

split_idx = int(len(X) * 0.8)
X_train, X_test = X[:split_idx], X[split_idx:]
Y_train, Y_test = Y[:split_idx], Y[split_idx:]


inputs = Input(shape=(MAX_LEN,), dtype=tf.int32, name="input_ids")


masking_mask = keras.ops.not_equal(inputs, 0)
attention_mask = keras.ops.cast(masking_mask, dtype="bool")
attention_mask = keras.ops.expand_dims(attention_mask, 1)
attention_mask = keras.ops.expand_dims(attention_mask, 1)


embedding = Embedding(num_sinhala_words, 512, name="embedding")(inputs)


attn1 = MultiHeadAttention(num_heads=8, key_dim=512)(embedding, embedding, attention_mask=attention_mask)
attn1 = Dropout(0.3)(attn1) 
norm1 = LayerNormalization()(attn1 + embedding)

attn2 = MultiHeadAttention(num_heads=8, key_dim=512)(norm1, norm1, attention_mask=attention_mask)
attn2 = Dropout(0.3)(attn2)
norm2 = LayerNormalization()(attn2 + norm1)


ffn = Dense(1024, activation="relu")(norm2)
ffn = Dropout(0.3)(ffn)
ffn_output = Dense(512)(ffn)
sequence_output = LayerNormalization()(ffn_output + norm2)

outputs = Dense(num_video_words, activation='softmax', name="output")(sequence_output)

model = Model(inputs, outputs)
model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=5e-4), 
              loss='sparse_categorical_crossentropy', 
              metrics=['accuracy'])

print(f"\nAI Model Training Started... (Punctuation Tokenization Fixed)")
early_stop = tf.keras.callbacks.EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True)

history = model.fit(X_train, np.expand_dims(Y_train, -1), 
                    batch_size=32, 
                    epochs=30, 
                    validation_data=(X_test, np.expand_dims(Y_test, -1)),
                    callbacks=[early_stop])

print("\n📊 Calculating Final Metric Scores across data pools...")
train_loss, train_acc = model.evaluate(X_train, np.expand_dims(Y_train, -1), verbose=0)
test_loss, test_acc = model.evaluate(X_test, np.expand_dims(Y_test, -1), verbose=0)

# ==============================================================================
# 4. Pure AI Live Evaluation Loop
# ==============================================================================
print("\n==================================================")
print("     STARTING LIVE SEQUENTIAL AUTOMATED TESTING   ")
print("==================================================")

predictions = model.predict(X_test, batch_size=128)
display_limit = min(1000, len(X_test))

for i in range(display_limit):
    input_words = [reverse_sinhala_map.get(idx, '') for idx in X_test[i] if idx != 0]
    sinhala_text = " ".join(input_words)
    
    pred_array = [np.argmax(word_probs) for word_probs in predictions[i]]
    actual_array = list(Y_test[i])
    
    clean_pred = [reverse_video_map.get(idx, '') for idx in pred_array if idx != 0]
    clean_actual = [reverse_video_map.get(idx, '') for idx in actual_array if idx != 0]
    
    final_pred = []
    for token in clean_pred:
        if token and (len(final_pred) == 0 or token != final_pred[-1]):
            final_pred.append(token)
    
    print(f"\n[Test Line {i+1} / {display_limit}]")
    print(f" ⌨️ Input Text       : {sinhala_text}")
    print(f" 🎯 Actual Array     : {clean_actual}")
    print(f" 🤖 Predicted Array  : {final_pred}")
    
    time.sleep(0.01)

print("\n==================================================")
print(f" 📈 Final Training Accuracy : {train_acc * 100:.2f}%")
print(f" 🧪 Final Testing Accuracy  : {test_acc * 100:.2f}%")
print("==================================================")


print("\nConverting model to TFLite format...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS, tf.lite.OpsSet.SELECT_TF_OPS]
converter._experimental_lower_tensor_list_ops = False
tflite_model = converter.convert()

with open('sign_model.tflite', 'wb') as f:
    f.write(tflite_model)
print("Saved sign_model.tflite successfully.")


