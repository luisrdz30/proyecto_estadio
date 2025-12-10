/**
 * CLOUD FUNCTION para desactivar eventos cuyo endDateTime ya pasó.
 * Corre diariamente a la medianoche (00:00) hora Ecuador.
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

admin.initializeApp();
const db = getFirestore();

exports.desactivarEventosPasados = onSchedule(
  {
    schedule: "every day 00:00",
    timeZone: "America/Guayaquil",
  },
  async () => {

    const ahora = Timestamp.now();

    const snapshot = await db
      .collection("events")
      .where("isActive", "==", true)
      .get();

    const batch = db.batch();

    snapshot.forEach((doc) => {
      const data = doc.data();

      if (!data.endDateTime) return;

      // endDateTime es un Timestamp
      const end = data.endDateTime;

      if (end.toMillis() < Date.now()) {
        batch.update(doc.ref, { isActive: false });
      }
    });

    await batch.commit();

    console.log("Eventos expirados desactivados automáticamente ✔️");
  }
);
