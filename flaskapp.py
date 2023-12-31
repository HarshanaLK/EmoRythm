import base64
from flask import Flask, request, jsonify
import cv2
import numpy as np
from keras.models import load_model

app = Flask(__name__)

# Load pre-trained models
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
emotion_model = load_model('C:/Users/ASUS/Desktop/emotion_model.hdf5')

emotion_labels = ['Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise', 'Neutral']

def detect_emotion(frame):
    try:
        # Convert the image to for face detection
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        # Detect faces in the image
        faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))

        if len(faces) == 0:
            return None

        
        (x, y, w, h) = faces[0]

       
        face_roi = gray[y:y + h, x:x + w]
        face_roi = cv2.resize(face_roi, (64, 64), interpolation=cv2.INTER_AREA)
        face_roi = np.expand_dims(np.expand_dims(face_roi, -1), 0) / 255.0

       
        emotion_probabilities = emotion_model.predict(face_roi)
        emotion_index = np.argmax(emotion_probabilities)
        detected_emotion = emotion_labels[emotion_index]

        return detected_emotion

    except Exception as e:
        # checck work is correct
        print('Error in emotion detection:', str(e))
        return None



@app.route('/detect_emotion', methods=['POST'])
def detect_emotion_route():
    try:
        if 'image' not in request.form:
            return jsonify({'error': 'Image data not provided'}), 400


        image_data = request.form['image']
   
        try:
            image_bytes = np.frombuffer(base64.b64decode(image_data), np.uint8)
            image = cv2.imdecode(image_bytes, cv2.IMREAD_COLOR)
            print('Decoded image success')

        except Exception as e:
            print('Error decoding image:', str(e))
            return jsonify({'error': 'Failed to decode the image'}), 400
        

        # Check image is okay
        if image is None:
            raise ValueError('Failed to decode the image')

        detected_emotion = detect_emotion(image)

        if detected_emotion:
            print('Detected emotion:', detected_emotion)
            return jsonify({'emotion': detected_emotion})
        else:
            print('No face detected or failed to detect emotion')
            return jsonify({'error': 'No face detected or failed to detect emotion'}), 400

    except Exception as e:
        # check work it correct
        print('Error in /detect_emotion endpoint:', str(e))
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
