# Sinhala Sign Language Recognition & Translation System

A two-way real-time communication bridge between **Sinhala language** and **Sri Lankan Sign Language**, built as a Flutter mobile app backed by a Python (FastAPI) server running deep learning models.

The system supports **two independent translation directions**:

1. **Sign → Sinhala** — Live camera-based sign language recognition, converted into Sinhala text in real time.
2. **Sinhala → Sign** — Sinhala text input translated into a sequence of sign language videos.

---

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Features](#features)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Backend Setup & Run](#backend-setup--run)
- [Mobile App Setup](#mobile-app-setup)
- [API Reference](#api-reference)
- [Sinhala → Sign Model Details](#sinhala--sign-model-details)
- [Networking Modes](#networking-modes)
- [Troubleshooting](#troubleshooting)

---

## Overview

The project is split into two cooperating halves:

- **`app/`** – A Flutter Android application. This is the only part that runs on the phone. It handles camera capture, live streaming, the Sinhala sentence UI, Sinhala text input, and sign video playback.
- **`server/`** – A FastAPI backend that runs on a laptop/PC. It hosts both AI pipelines (sign recognition and Sinhala-to-sign translation) and serves the sign videos over HTTP.

The phone and server communicate over the same Wi-Fi network (or via `adb reverse` over USB cable).

---

## System Architecture

### Sign → Sinhala (live recognition)

```
Phone camera
  → Flutter FrameStreamer
  → WebSocket /ws
  → FastAPI server
  → MediaPipe Holistic (keypoint extraction)
  → Keras GRU model (best_model_weights.weights_new.h5)
  → Sinhala word JSON
  → Flutter sentence UI
```

The server buffers a rolling **30-frame** keypoint sequence, runs prediction smoothing, and commits a recognized sign once it locks in. Recognized signs are streamed back to the app as JSON over the same WebSocket connection.

### Sinhala → Sign (text to video)

```
Sinhala text input
  → Flutter TranslateService
  → HTTP POST /translate
  → FastAPI server
  → Multi-Head Attention Transformer (TFLite, sign_model.tflite)
  → Predicted video filenames (via sign_vocab.json)
  → Video URLs served from /sign-videos/<filename>
  → Flutter video_player (sequential playback)
```

Sinhala input text is tokenized, mapped through `sinhala_vocab.json`, and passed through a TFLite Transformer sequence-to-sequence model (max input length: 8 tokens for the translation model / 16 tokens at the API layer) to predict the corresponding sign video sequence.

---

## Features

- 🎥 **Real-time sign recognition** from the phone camera via WebSocket streaming.
- 🔤 **Sinhala sentence building** as signs are recognized and committed.
- 📝 **Sinhala text → Sign video** translation with sequential video playback.
- 📶 Works over **Wi-Fi** or **USB (ADB reverse)**.
- ⚙️ Configurable backend host directly from the app's Settings screen, with a built-in connectivity test.
- 🧠 Two independently trained models: a Keras GRU recognizer and a Transformer-based TFLite translator.

---

## Project Structure

```
SignRecognision/
├── app/                        # Flutter Android app (runs on the phone)
│   ├── lib/
│   │   ├── main.dart                    # App entry point → HomeScreen
│   │   ├── app_config.dart              # Server host storage & URL builder
│   │   ├── screens/
│   │   │   ├── home_screen.dart         # Bottom nav: Sign tab / Sinhala tab
│   │   │   ├── settings_screen.dart     # Server host config + health test
│   │   │   └── sinhala_to_sign_view.dart# Sinhala text input + video playback
│   │   └── services/
│   │       ├── frame_streamer.dart      # Camera capture → JPEG frames
│   │       ├── sign_socket.dart         # WebSocket client for /ws
│   │       └── translate_service.dart   # HTTP client for /translate
│   ├── android/                # Android project files
│   ├── test/                   # Flutter tests (app_config_test.dart)
│   └── build/                  # Generated build output
│
├── server/                     # Python FastAPI backend (runs on laptop/PC)
│   ├── main.py                 # App entry point, defines all routes
│   ├── recognizer.py           # MediaPipe + GRU live recognition pipeline
│   ├── model_arch.py           # Keras GRU model architecture
│   ├── labels.py                # Recognition class list & Sinhala mapping
│   ├── sinhala_to_sign.py       # Sinhala → sign TFLite inference logic
│   ├── requirements.txt         # Python dependencies
│   ├── verify_parity.py         # Verifies .h5 model matches expected behavior
│   ├── verify_tflite.py         # TFLite behavior verification utility
│   ├── .venv312/                # Working Python 3.12 virtual environment
│   ├── debug_frames/            # Debug frame captures
│   ├── backend.out.log          # Stdout log
│   └── backend.err.log          # Stderr log
│
├── model/                      # Sign → Sinhala trained weights
│   └── best_model_weights.weights_new.h5
│
├── model creation/             # Training & demo code for the recognition model
│   ├── train.py
│   ├── real_time_demo.py       # Reference desktop pipeline for parity checks
│   ├── gru_model.py
│   ├── extract_keypoints.py
│   └── dataset_keypoints/      # Keypoint dataset (greetings, verbs, colors, etc.)
│
├── sinhala_sign_ai_part/       # Sinhala → Sign model, vocab, videos
│   ├── sign_model.tflite        # Transformer seq2seq model (TFLite)
│   ├── sinhala_vocab.json       # Sinhala word → token ID
│   ├── sign_vocab.json          # Token ID → video filename
│   ├── videos/                  # MP4 sign videos, served at /sign-videos/*
│   ├── dataset_generator.py     # Synthetic training corpus generator
│   ├── dataset.txt              # Generated training sentence corpus
│   ├── train_model.py           # Transformer training script
│   ├── test_model.py            # OpenCV-based manual validation harness
│   └── Dilshan/                 # Dataset source/conversion files
│
├── dist/                       # Final release artifacts
│   └── sign_app_release_<ip>_8000.apk
│
└── tmp/                        # Local/testing helper files
```

> **⚠️ Handle with care:** `server/recognizer.py`, `server/model_arch.py`, `server/labels.py`, and `model/best_model_weights.weights_new.h5` directly affect sign recognition accuracy. Only change these when intentionally retraining or modifying the recognition model.

---

## Tech Stack

**Mobile App**
- Flutter (Android)
- Packages: `camera`, `web_socket_channel`, `http`, `image`, `video_player`, `shared_preferences`, `permission_handler`, `google_fonts`

**Backend**
- FastAPI + Uvicorn
- MediaPipe Holistic (keypoint extraction)
- TensorFlow / Keras 3 (GRU model — sign recognition)
- TensorFlow Lite (Transformer model — Sinhala-to-sign translation)

**Sinhala → Sign Model Pipeline**
- Multi-Head Attention Transformer sequence-to-sequence architecture
- NumPy for vector/array operations
- OpenCV (`cv2`) for standalone validation/frame rendering
- Regex-based text normalization for tokenization

---

## Backend Setup & Run

### Required files

Make sure these exist before starting the server:

- `model/best_model_weights.weights_new.h5` — sign recognition weights
- `sinhala_sign_ai_part/sign_model.tflite` — translation model
- `sinhala_sign_ai_part/sinhala_vocab.json` and `sign_vocab.json`
- `sinhala_sign_ai_part/videos/` — sign video files

### Run

```powershell
cd server
.\.venv312\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Use `.venv312` (Python 3.12) — this is the working environment for the project. If it doesn't exist yet:

```powershell
cd server
py -3.12 -m venv .venv312
.\.venv312\Scripts\python.exe -m pip install --upgrade pip
.\.venv312\Scripts\python.exe -m pip install -r requirements.txt
```

> Avoid casually upgrading TensorFlow, MediaPipe, Keras, or NumPy — the recognition model depends on a specific compatible stack.

### Verify it's running

```powershell
Invoke-RestMethod http://127.0.0.1:8000/
Invoke-RestMethod http://127.0.0.1:8000/labels
```

Expected health response:

```json
{
  "status": "ok",
  "classes": 53,
  "seq_length": 30,
  "weights": "best_model_weights.weights_new.h5"
}
```

---

## Mobile App Setup

### Build the APK

```powershell
cd app
..\flutter_sdk\bin\flutter.bat build apk --release --dart-define=SIGN_SERVER_HOST=192.168.8.177:8000
```

Replace the IP with your own laptop's Wi-Fi IPv4 address.

Output locations:
- `app/build/app/outputs/flutter-apk/app-release.apk` (generated)
- `dist/sign_app_release_<ip>_8000.apk` (stable copy)

> Note: sign videos are **not** bundled inside the APK — they're streamed live from the server.

### Connect the app to the server

1. Find your laptop's Wi-Fi IPv4 address (`ipconfig` → look under the Wi-Fi adapter).
2. Allow the backend through the firewall (run once, as Administrator):
   ```powershell
   netsh advfirewall firewall add rule name="SignRecognision Backend 8000" dir=in action=allow protocol=TCP localport=8000
   ```
3. On the phone, open **Settings** in the app and enter the server host, e.g. `192.168.8.177:8000`.
4. Tap **Test** to confirm connectivity (calls `GET /`).

Once connected, the app can use:
- `ws://<host>/ws` — sign recognition
- `http://<host>/translate` — Sinhala-to-sign translation
- `http://<host>/sign-videos/<filename>` — video playback

---

## API Reference

Base URL: `http://<PC_WIFI_IPV4>:8000` (or `http://127.0.0.1:8000` when using ADB reverse)

### `GET /`
Health check. Used by the app's Settings screen.

### `GET /labels`
Returns the recognition label list mapped to Sinhala display text.

### `POST /translate`
Sinhala → sign translation.

**Request:**
```json
{ "text": "<Sinhala text here>" }
```

**Response:**
```json
{
  "type": "translation",
  "text": "<Sinhala text here>",
  "tokens": ["<word1>", "<word2>"],
  "truncated": false,
  "unknown_words": [],
  "videos": [
    {
      "file": "you.mp4",
      "asset": "you.mp4",
      "index": 0,
      "url": "http://192.168.8.177:8000/sign-videos/you.mp4"
    }
  ],
  "missing": []
}
```

- `truncated` — `true` if input exceeds the max supported length (16 tokens at the API layer).
- `unknown_words` — words not found in `sinhala_vocab.json`.
- `missing` — predicted filenames not found in the videos folder.

### `GET /sign-videos/<filename>`
Serves sign video files from `sinhala_sign_ai_part/videos`.

### `WebSocket /ws`
Live sign → Sinhala recognition channel.

**Client → Server**
- Binary: JPEG camera frames
- Text control messages:
  ```json
  { "action": "reset" }
  { "action": "config", "flip": true }
  ```

**Server → Client**
```json
{
  "type": "update",
  "state": "active",
  "buffer": 30,
  "seq_length": 30,
  "current_label": "Verbs_Eat",
  "current": "<Sinhala word>",
  "confidence": 0.91,
  "committed": {
    "label": "Verbs_Eat",
    "sinhala": "<Sinhala word>"
  }
}
```

`state` can be `idle` (no keypoints yet), `analyzing` (keypoints detected, no lock yet), or `active` (a sign is currently recognized). `committed` is non-null only when a new sign locks in, which the app appends to the running Sinhala sentence.

---

## Sinhala → Sign Model Details

The Sinhala-to-sign module translates natural Sinhala conversational text into a sequence of sign videos using a custom-trained **Multi-Head Attention Transformer** (sequence-to-sequence), converted to TFLite for lightweight edge inference on the server.

**Pipeline:**
1. **Dataset generation** — `dataset_generator.py` synthesizes a large, balanced sentence corpus (44,990 sentences) covering a vocabulary of 54 distinct sign words/videos, capping question-style sentences at 45% of the dataset to avoid overfitting toward flat statements.
2. **Tokenization** — Regex-based normalization (e.g. isolating `?` from the preceding word) prevents out-of-vocabulary errors caused by punctuation sticking to Sinhala tokens.
3. **Training** — A Transformer seq2seq model (max sequence length: 8) is trained on the generated corpus, using its attention mechanism to naturally resolve multi-word phrases (e.g. two separate tokens) into a single target sign video.
4. **Export** — The trained graph is converted to `sign_model.tflite` using `SELECT_TF_OPS`, alongside `sinhala_vocab.json` and `sign_vocab.json` for lookup.
5. **Validation** — `test_model.py` provides a standalone OpenCV-based harness for manually verifying model output before deployment.
6. **Serving** — The FastAPI backend loads the TFLite model, resolves predicted video filenames, and streams them to the app; a presentation cache smooths transitions between consecutive videos during playback.

---

## Networking Modes

### Same Wi-Fi (no cable)

```powershell
cd server
.\.venv312\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000
```

Set the app's server host to the laptop's Wi-Fi IPv4, e.g. `192.168.8.177:8000`.

> `0.0.0.0` is only a bind address for starting the server — never enter it into the phone app.

### USB cable with ADB reverse

```powershell
adb reverse tcp:8000 tcp:8000
```

Set the app's server host to `127.0.0.1:8000`.

---

## Troubleshooting

**Phone cannot reach the server**
- Confirm phone and laptop are on the same Wi-Fi network.
- Confirm the server was started with `--host 0.0.0.0`.
- Confirm the app Settings host is the laptop's real IPv4 (not `localhost`/`127.0.0.1` in Wi-Fi mode).
- Confirm Windows Firewall allows TCP port `8000`.

**Videos won't play**
- Confirm the server is running and `sinhala_sign_ai_part/videos` exists.
- Try opening `http://<PC_IP>:8000/sign-videos/you.mp4` directly on the phone's browser.

**Recognition feels slow**
- The server intentionally drops stale frames and processes only the newest one to avoid lag build-up.
- Keep the phone near the router and the laptop plugged in; close other heavy apps.

**Port 8000 already in use**
```powershell
Get-NetTCPConnection -LocalPort 8000
```
Run on a different port if needed, and update the app's Settings to match.

**`.venv` fails to activate**
Use `.venv312` directly instead — it's the working Python 3.12 environment for this project.
