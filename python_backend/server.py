from flask import Flask, request, jsonify
from deepface import DeepFace
import os

app = Flask(__name__)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route("/verify-face", methods=["POST"])
def verify_face():
    try:
        if "file1" not in request.files or "file2" not in request.files:
            return jsonify({"error": "Please upload two images"}), 400

        file1 = request.files["file1"]
        file2 = request.files["file2"]

        path1 = os.path.join(UPLOAD_FOLDER, file1.filename)
        path2 = os.path.join(UPLOAD_FOLDER, file2.filename)
        file1.save(path1)
        file2.save(path2)

        # DeepFace verification
        result = DeepFace.verify(img1_path=path1, img2_path=path2)

        return jsonify({
            "verified": result["verified"],
            "distance": result["distance"]
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(port=5000, debug=True)
