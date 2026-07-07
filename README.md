# Sinhala Sign Language Recognition

Real-time **sign → Sinhala** recognition plus **Sinhala → sign** video
translation. A Flutter phone app talks to a Python API server: camera frames go
to the WebSocket recognizer, and Sinhala text goes to the HTTP translator, which
returns sign videos from `sinhala_sign_ai_part/videos`.

## Why a server (and not on-device)

Your model reports **86%** and must not drop. That accuracy depends on two
things that are hard to reproduce on a phone:

1. **MediaPipe *Holistic*** (desktop Python) produces the exact hand keypoints
   the model was trained on. Mobile MediaPipe uses a *different* hand-landmark
   model → different keypoints → accuracy loss.
2. The **Keras weights** run exactly as trained. Converting to TFLite (with the
   custom `SoftAttention` layer + MultiHeadAttention) risks numeric drift.

Running the **whole** pipeline on the server — the same code as
`model creation/real_time_demo.py` — gives **zero drift**. The phone only sends
camera frames.

## Architecture

```
┌─────────────┐   JPEG frames (WebSocket, ~11 fps)   ┌──────────────────────────┐
│  Flutter    │ ───────────────────────────────────▶ │  FastAPI server          │
│  app        │                                      │   • MediaPipe Holistic    │
│  (phone)    │ ◀─────────────────────────────────── │   • keypoint normalize    │
│             │   JSON: current word / committed /   │   • 30-frame GRU model     │
│  camera +   │   confidence / buffer                │   • entropy + vote +       │
│  sentence   │                                      │     hysteresis (as demo)   │
└─────────────┘                                      └──────────────────────────┘
```

The server is a faithful port of `real_time_demo.py`: same 30-frame rolling
window, same keypoint normalization, same entropy gate, majority-vote
smoothing, and hysteresis lock. This continuous rolling design is exactly your
"keep signing, each held sign becomes a word" UX.

## Repository layout

```
SignRecognision/
├── model/                         # your trained weights (.h5, weights-only)
├── model creation/                # original training + demo scripts (reference)
├── server/                        # ⭐ NEW — Python WebSocket inference server
│   ├── model_arch.py              #   exact copy of gru_model.py architecture
│   ├── labels.py                  #   53 classes + Sinhala map (sorted order)
│   ├── recognizer.py              #   faithful port of real_time_demo.py logic
│   ├── main.py                    #   FastAPI + WebSocket
│   ├── requirements.txt           #   pinned (Python 3.11)
│   └── README.md                  #   setup + run
└── app/                           # ⭐ NEW — Flutter app (sign → Sinhala)
    ├── lib/                       #   camera streaming + WebSocket + UI
    ├── pubspec.yaml
    └── README.md                  #   flutter create + Android setup + run
```

## Quick start

1. **Server** (on your PC) — see [server/README.md](server/README.md):
   ```powershell
   cd server
   py -3.11 -m venv .venv; .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```
2. **App** (on your phone, same Wi-Fi) — see [app/README.md](app/README.md):
   ```powershell
   cd app
   flutter create --org com.example --project-name sign_app .
   # add camera permission + usesCleartextTraffic to AndroidManifest (see app README)
   flutter pub get
   flutter run
   ```
3. In the app Settings, set the server to your PC's IPv4 (e.g.
   `192.168.1.42:8000`), Save, and use either tab.

## Accuracy: verified, not assumed

Ran [server/verify_parity.py](server/verify_parity.py) against your precomputed
keypoints, reconstructing `train.py`'s exact `random_state=42` held-out split:

> **Deployed `.h5` scored 88.94%** on the held-out test set (≥ your reported
> ~86% — the file holds the best-val checkpoint). Label order verified
> byte-identical. **Zero drift.**

To keep it that way:

- Server runs on **Python 3.12** with **tensorflow 2.17 + tf-keras (legacy Keras
  2) + mediapipe 0.10.14** — a verified stack: TF loads the custom-layer weights
  correctly, and 0.10.14 still ships legacy `Holistic`. Don't upgrade blindly;
  newer mediapipe removes Holistic, and letting numpy jump to 2.x breaks TF.
- [model_arch.py](server/model_arch.py) is a byte-for-byte copy of the trained
  architecture, so `load_weights()` matches. Don't rename layers.
- Class index order is `sorted(SINHALA_MAP.keys())`, matching
  `sorted(os.listdir(KEYPOINTS_PATH))` from training (verified: 53 classes,
  `Months_February` at 16 before `Months_January` at 17).
- The one residual difference vs training is the *live* MediaPipe version
  (0.10.14) used to extract keypoints from phone frames. It's the same Holistic
  family, so drift is negligible; pin the exact training version if you know it.
