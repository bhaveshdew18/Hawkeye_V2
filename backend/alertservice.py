import firebase_admin
from firebase_admin import credentials, messaging
import smtplib

try:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    print("✅ Firebase initialized.")
except Exception as e:
    print(f"🔥 Firebase initialization failed: {e}")

def send_push_notification(device_token, title, body):
    message = messaging.Message(
        notification=messaging.Notification(title=title, body=body),
        token=device_token,
    )
    try:
        response = messaging.send(message)
        print("Successfully sent push notification:", response)
    except Exception as e:
        print("Error sending push notification:", e)

def send_email_alert(recipient_email, subject, body):
    sender_email = "your-email@example.com"
    password = "your-email-password"
    message = f"Subject: {subject}\n\n{body}"
    try:
        server = smtplib.SMTP("smtp.example.com", 587)
        server.starttls()
        server.login(sender_email, password)
        server.sendmail(sender_email, recipient_email, message)
        server.quit()
        print(f"Successfully sent email to {recipient_email}")
    except Exception as e:
        print(f"Failed to send email: {e}")

def trigger_alert(tourist_info):
    authority_device_token = "placeholder_device_token_from_db"
    authority_email = "authority@example.gov"
    title = "🚨 PANIC ALERT 🚨"
    body = f"Distress signal from tourist: {tourist_info.get('name')}. Last known location: {tourist_info.get('location')}."
    send_push_notification(authority_device_token, title, body)
    send_email_alert(authority_email, title, body)