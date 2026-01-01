# pip install firebase-admin

import firebase_admin
from firebase_admin import credentials, firestore

COLLECTION = "shops/meamore/services_list"  

EN_DOC = {
    "items": [
        {"key": "Shower and dry", "value": 1},
        {"key": "Haircut", "value": 1},
        {"key": "Dematting", "value": 1},
        {"key": "Thinning", "value": 1},
        {"key": "Stripping", "value": 1},
        {"key": "Restoration", "value": 1},
    ]
}

HE_DOC = {
    "items": [
        {"key": "מקלחת וייבוש", "value": 1},
        {"key": "תספורת", "value": 1},
        {"key": "פתיחת קשרים", "value": 1},
        {"key": "דילול", "value": 1},
        {"key": "מריטה", "value": 1},
        {"key": "שיקום", "value": 1},
    ]
}

def main():
    # Download from Firebase Console -> Project settings -> Service accounts -> Generate new private key
    cred = credentials.Certificate("c:\\Users\\slava\\Downloads\\me-amore-employees-firebase-adminsdk-fbsvc-4d453b0e9d.json")
    firebase_admin.initialize_app(cred)

    db = firestore.client()

    # Two docs in the SAME collection: "en" and "he"
    db.collection(COLLECTION).document("en").set(EN_DOC)
    db.collection(COLLECTION).document("he").set(HE_DOC)

    print(f"Done. Wrote {COLLECTION}/en and {COLLECTION}/he")

if __name__ == "__main__":
    main()
