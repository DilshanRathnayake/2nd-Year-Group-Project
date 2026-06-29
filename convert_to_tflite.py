
import tensorflow as tf
import numpy as np
import os
import sys

# -------- PATH CONFIGURATION (EDIT THESE) --------
WEIGHTS_PATH = r"C:/Users/Lenovo/Desktop/2nd_Group/models/best_model_weights.weights_new.h5"
TFLITE_PATH = r"C:/Users/Lenovo/Desktop/2nd_Group/models/sinhala_sign_model.tflite"
# -------- END OF CONFIG ---------------------------


from models.gru_model import build_model  
SEQ_LENGTH = 30
NUM_FEATURES = 128
NUM_CLASSES = 53

def main():
    # 1. Load the Keras model architecture and weights
    print("🔄 Building model architecture...")
    model = build_model((SEQ_LENGTH, NUM_FEATURES), NUM_CLASSES)
    print("📥 Loading weights from:", WEIGHTS_PATH)
    model.load_weights(WEIGHTS_PATH)
    print("✅ Model loaded successfully.")

    # 2. Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)

    # For GRU/LSTM models
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS
    ]

    converter._experimental_lower_tensor_list_ops = False

    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    converter.allow_custom_ops = True

    # Convert
    print("🔄 Converting to TFLite...")
    tflite_model = converter.convert()
    print("✅ Conversion complete.")

    # 3. Save the .tflite file
    os.makedirs(os.path.dirname(TFLITE_PATH), exist_ok=True)
    with open(TFLITE_PATH, 'wb') as f:
        f.write(tflite_model)
    print(f"💾 TFLite model saved to: {TFLITE_PATH}")

    # 4. Quick test inference with the converted model
    print("\n🧪 Running test inference on random input...")
    interpreter = tf.lite.Interpreter(model_path=TFLITE_PATH)
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # Create dummy input (batch=1, seq_len=30, features=128)
    test_input = np.random.rand(1, SEQ_LENGTH, NUM_FEATURES).astype(np.float32)
    interpreter.set_tensor(input_details[0]['index'], test_input)
    interpreter.invoke()
    output = interpreter.get_tensor(output_details[0]['index'])

    print(f"   Input shape : {test_input.shape}")
    print(f"   Output shape: {output.shape}")
    print(f"   Top predicted class index: {np.argmax(output)}")
    print("✅ TFLite model works correctly.")

    # (Optional) Print model size comparison
    size_original = os.path.getsize(WEIGHTS_PATH) / (1024 * 1024)
    size_tflite = os.path.getsize(TFLITE_PATH) / (1024 * 1024)
    print(f"\n📊 Model size: original weights = {size_original:.2f} MB, TFLite = {size_tflite:.2f} MB")

if __name__ == "__main__":
    main()