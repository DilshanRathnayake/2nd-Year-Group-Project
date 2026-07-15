
import tensorflow as tf
from tensorflow.keras.models import Model
from tensorflow.keras.layers import (
    Input, GRU, Bidirectional, Dense, Dropout,
    BatchNormalization, LayerNormalization, Add,
    MultiHeadAttention, GlobalAveragePooling1D, Reshape, Multiply
)


# ──────────────────────────────────────────────
#  SOFT ATTENTION BLOCK
# ──────────────────────────────────────────────
class SoftAttention(tf.keras.layers.Layer):
    """
    Computes a scalar attention weight per time-step.
    Output: weighted sum of the sequence → single vector.
    """
    def __init__(self, units, **kwargs):
        super().__init__(**kwargs)
        self.W = Dense(units, activation='tanh', use_bias=False)
        self.V = Dense(1, use_bias=False)

    def call(self, sequence):                          
        score = self.V(self.W(sequence))               
        weights = tf.nn.softmax(score, axis=1)         
        context = tf.reduce_sum(sequence * weights, axis=1)  
        return context


def build_model(input_shape, num_classes):
    """
    input_shape : (SEQ_LENGTH, NUM_FEATURES) e.g. (30, 128)
    num_classes : 53 for your dataset
    """
    inputs = Input(shape=input_shape, name="keypoints_input")

    # ── BLOCK 1: Bidirectional GRU ──────────────────────────────
 
    x = Bidirectional(GRU(192, return_sequences=True), name="biGRU_1")(inputs)
    x = BatchNormalization(name="bn_1")(x)
    x = Dropout(0.35, name="drop_1")(x)

    # ── BLOCK 2: Multi-Head Self-Attention ──────────────────────
  
    attn_out = MultiHeadAttention(
        num_heads=4, key_dim=48, dropout=0.1, name="mha"
    )(x, x)
    x = LayerNormalization(name="ln_attn")(x + attn_out)  # Residual

    # ── BLOCK 3: Second GRU ─────────────────────────────────────
    x = GRU(128, return_sequences=True, name="GRU_2")(x)
    x = BatchNormalization(name="bn_2")(x)
    x = Dropout(0.30, name="drop_2")(x)

    # ── SOFT ATTENTION POOLING ───────────────────────────────────
    
    context = SoftAttention(64, name="soft_attention")(x)   # (B, 128)

    # ── DENSE BLOCK WITH RESIDUAL ────────────────────────────────
   
    x1 = Dense(256, activation='relu', name="dense_1")(context)
    x1 = BatchNormalization(name="bn_3")(x1)
    x1 = Dropout(0.35, name="drop_3")(x1)

    x2 = Dense(256, activation='relu', name="dense_2")(x1)
    x2 = BatchNormalization(name="bn_4")(x2)

    merged = Add(name="residual_add")([x1, x2])
    merged = LayerNormalization(name="ln_merged")(merged)
    merged = Dropout(0.25, name="drop_4")(merged)

    # Bottleneck before output
    x3 = Dense(128, activation='relu', name="dense_3")(merged)
    x3 = BatchNormalization(name="bn_5")(x3)
    x3 = Dropout(0.20, name="drop_5")(x3)

    # ── OUTPUT ───────────────────────────────────────────────────
    outputs = Dense(num_classes, activation='softmax', name="output")(x3)

    model = Model(inputs, outputs, name="SinhalaSignGRU_v2")

    # ── OPTIMIZER ────────────────────────────────────────────────
    
    lr_schedule = tf.keras.optimizers.schedules.CosineDecay(
        initial_learning_rate=0.001,
        decay_steps=80 * 50,   
    )

    model.compile(
        optimizer=tf.keras.optimizers.AdamW(
            learning_rate=lr_schedule,
            weight_decay=1e-4
        ),
        loss=tf.keras.losses.CategoricalCrossentropy(label_smoothing=0.08),
        metrics=['accuracy']
    )

    return model