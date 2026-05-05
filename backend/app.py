import firebase_admin
from firebase_admin import credentials, firestore, messaging
from flask import Flask, jsonify, request

# --- Firebase Admin SDK Initialization ---
# This remains the same. It uses your ServiceAccountKey.json for admin access.
try:
    cred = credentials.Certificate("ServiceAccountKey.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("Firebase Admin SDK initialized successfully.")
except Exception as e:
    print(f"Error initializing Firebase Admin SDK: {e}")
    db = None

app = Flask(__name__)

# --- Core Backend Logic: Send Push Notification for an Alert ---
def send_alert_notification(alert_data: dict, alert_id: str):
    """
    Sends a push notification to all registered authority devices based on an alert.
    
    Args:
        alert_data: The dictionary data of the new alert from Firestore.
        alert_id: The document ID of the new alert.
    """
    if not db:
        print("Firestore client not available. Cannot send notification.")
        return

    tourist_id = alert_data.get('touristId', 'N/A')
    location_name = alert_data.get('locationName', 'an unknown location')
    
    # 1. Get all authority device tokens from the 'authorities' collection in Firestore.
    authorities_ref = db.collection('authorities')
    docs = authorities_ref.stream()
    
    registration_tokens = []
    for doc in docs:
        token = doc.to_dict().get('fcm_token')
        if token:
            registration_tokens.append(token)

    if not registration_tokens:
        print("No authority devices are registered to receive notifications.")
        return

    # 2. Construct the push notification message.
    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title='🚨 PANIC ALERT! 🚨',
            body=f'Distress signal from Tourist ID: {tourist_id} near {location_name}. Tap to view on dashboard.',
        ),
        # You can also send data to the app with the notification
        data={
            'alertId': alert_id,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK' # Standard for Flutter
        },
        tokens=registration_tokens,
    )

    # 3. Send the message.
    try:
        response = messaging.send_multicast(message)
        print(f'{response.success_count} notification(s) were sent successfully')
    except Exception as e:
        print(f"Error sending FCM message: {e}")

# --- Cloud Function Trigger (The Ideal Implementation) ---
# In a real production environment, you would deploy this function to Google Cloud.
# It would automatically run every time a new document is created in the 'alerts' collection.
def on_alert_created(data, context):
    """
    Cloud Function Trigger. This is the target function.
    """
    alert_id = context.resource.split('/')[-1]
    alert_data = data['value']['fields'] # The structure might vary slightly
    
    print(f"New alert detected: {alert_id}")
    # Convert Firestore's verbose format to a simple dict if necessary
    # and then call the notification logic.
    # simplified_data = {key: val['stringValue'] for key, val in alert_data.items()}
    # send_alert_notification(simplified_data, alert_id)


# --- API Route for Manual Testing ---
@app.route('/send-notification', methods=['POST'])
def manual_notification_trigger():
    """
    A testing endpoint to manually trigger a notification for a given alert ID.
    """
    data = request.get_json()
    alert_id = data.get('alertId')
    
    if not alert_id:
        return jsonify({"error": "alertId is required"}), 400

    if not db:
        return jsonify({"error": "Firestore not initialized"}), 500

    # Fetch the alert data from Firestore
    alert_doc = db.collection('alerts').document(alert_id).get()
    if not alert_doc.exists:
        return jsonify({"error": "Alert not found in Firestore"}), 404
        
    send_alert_notification(alert_doc.to_dict(), alert_id)
    
    return jsonify({"message": "Notification process triggered for alert " + alert_id}), 200


if __name__ == '__main__':
    # For local development and testing only.
    app.run(host='0.0.0.0', port=5000, debug=True)