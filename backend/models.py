from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.dialects.postgresql import UUID
import uuid

db = SQLAlchemy()

class Tourist(db.Model):
    __tablename__ = 'tourists'
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name_hash = db.Column(db.String(256), nullable=False)
    
class Location(db.Model):
    __tablename__ = 'locations'
    id = db.Column(db.Integer, primary_key=True)
    tourist_id = db.Column(UUID(as_uuid=True), db.ForeignKey('tourists.id'), nullable=False)
    latitude = db.Column(db.Float, nullable=False)
    longitude = db.Column(db.Float, nullable=False)
    timestamp = db.Column(db.DateTime, nullable=False, default=db.func.current_timestamp())

class Alert(db.Model):
    __tablename__ = 'alerts'
    id = db.Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tourist_id = db.Column(UUID(as_uuid=True), db.ForeignKey('tourists.id'), nullable=False)
    status = db.Column(db.String(50), nullable=False, default='active')
    timestamp = db.Column(db.DateTime, nullable=False, default=db.func.current_timestamp())

    class Authority(db.Model):
    __tablename__ = 'authorities'
    id = db.Column(db.Integer, primary_key=True)
    # A unique identifier for the authority, e.g., 'dashboard-1'
    authority_id = db.Column(db.String(100), unique=True, nullable=False)
    # This will store the unique token from the browser
    fcm_token = db.Column(db.String(255), nullable=True)