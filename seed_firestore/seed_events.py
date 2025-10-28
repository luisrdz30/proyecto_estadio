import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timedelta
import uuid
import random

# 🔹 Inicializa Firebase
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# 🔹 IDs de usuarios
user_ids = [
    "N1ZEmHu8FHWkdrCnK3QNDm9VVCt1",
    "PsIuzKrYVAbSGpBRB1BSMU8wGL62",
    "icxXSnaPnRNnq81ZKblrBFH5tBz2",
]

# 🔹 Evento principal (mañana)
manana = datetime.now() + timedelta(days=1)
concierto_mana = {
    "title": "Concierto Maná",
    "image": "https://picsum.photos/400/200?random=1",
    "price": 60,
    "zone": "VIP",
    "time": "20:00",
    "date": f"{manana.day} de {['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'][manana.month-1]} de {manana.year}",
    "eventDateTime": manana.replace(hour=20, minute=0, second=0, microsecond=0),
}

# 🔹 Otros eventos del sistema
otros_eventos = [
    {
        "title": "Urban Fest 2025",
        "image": "https://picsum.photos/400/200?random=6",
        "price": 230,
        "zone": "Zona Front Stage",
        "time": "17:00",
        "date": "6 de diciembre de 2025",
        "eventDateTime": datetime(2025, 12, 6, 17, 0),
    },
    {
        "title": "Fin de Año Fest 2025",
        "image": "https://picsum.photos/400/200?random=10",
        "price": 100,
        "zone": "Palco VIP",
        "time": "20:00",
        "date": "31 de diciembre de 2025",
        "eventDateTime": datetime(2025, 12, 31, 20, 0),
    },
    {
        "title": "RockFest Latino",
        "image": "https://picsum.photos/400/200?random=3",
        "price": 85,
        "zone": "Zona Fan",
        "time": "18:00",
        "date": "30 de noviembre de 2025",
        "eventDateTime": datetime(2025, 11, 30, 18, 0),
    },
    {
        "title": "Noche de Amor",
        "image": "https://images.unsplash.com/photo-1525610553991-2bede1a236e2",
        "price": 150,
        "zone": "Zona Platinum",
        "time": "19:00",
        "date": "30 de octubre de 2025",
        "eventDateTime": datetime(2025, 10, 30, 19, 0),
    },
]

# 🔹 Crea tickets para cada usuario
def crear_tickets_usuario(uid):
    print(f"🎟️ Creando tickets para usuario {uid}...")
    tickets_ref = db.collection("users").document(uid).collection("tickets")

    # Eliminar los anteriores
    for doc in tickets_ref.stream():
        doc.reference.delete()

    # 1️⃣ Ticket del evento Concierto Maná
    all_tickets = [concierto_mana]

    # 2️⃣ Tickets adicionales aleatorios
    adicionales = random.sample(otros_eventos, 2)
    all_tickets.extend(adicionales)

    for ev in all_tickets:
        qr_id = str(uuid.uuid4())
        qr_data = f"{uid}|{ev['title']}|{ev['zone']}|{qr_id}"

        ticket = {
            "count": 1,
            "createdAt": datetime.now(),
            "date": ev["date"],
            "eventDateTime": ev["eventDateTime"],
            "eventTitle": ev["title"],
            "image": ev["image"],
            "price": ev["price"],
            "qrData": qr_data,
            "qrId": qr_id,
            "time": ev["time"],
            "used": False,
            "zone": ev["zone"],
        }

        tickets_ref.add(ticket)
        print(f"✅ Ticket '{ev['title']}' agregado correctamente para {uid}.")

# 🔹 Ejecutar para los tres usuarios
for uid in user_ids:
    crear_tickets_usuario(uid)

print("\n🎉 Cada usuario tiene 3 tickets (incluyendo el Concierto Maná).")
