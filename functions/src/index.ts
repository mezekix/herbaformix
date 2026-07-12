import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

function readTextField(
  data: admin.firestore.DocumentData,
  fields: string[],
): string {
  for (const field of fields) {
    const value = data[field];
    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }
  }
  return "";
}

function wasAlreadyNotifiedForDueDate(
  data: admin.firestore.DocumentData,
): boolean {
  if (data.notificationSent !== true) return false;

  const sentAt = data.notificationSentAt;
  const dueDate = data.dueDate;
  if (
    sentAt instanceof admin.firestore.Timestamp &&
    dueDate instanceof admin.firestore.Timestamp
  ) {
    return sentAt.toMillis() >= dueDate.toMillis();
  }

  return true;
}

async function recordNotificationAttempt(
  userId: string,
  data: admin.firestore.DocumentData,
): Promise<void> {
  await db.collection("notification_debug").doc(userId).set({
    ...data,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
}

// 1. Program Bildirimi (users/{userId}/program/{programId} active olunca tetiklenir)
export const onProgramCreateOrUpdate = functions.firestore
  .document("users/{userId}/program/{programId}")
  .onWrite(async (change, context) => {
    const userId = context.params.userId;
    const afterData = change.after.data();
    const beforeData = change.before.data();

    // Sadece aktif program durumunda veya yeni aktif edildiğinde bildirim gönder
    const wasActive = beforeData?.isActive === true;
    const isActive = afterData?.isActive === true;

    if (isActive && !wasActive) {
      try {
        // Kullanıcı profilini oku
        const profileDoc = await db.collection("userProfiles").doc(userId).get();
        if (!profileDoc.exists) return;

        const profileData = profileDoc.data();
        const fcmToken = profileData?.fcmToken;
        const settings = profileData?.notificationSettings;

        // Bildirim tercihi kontrolü
        if (settings && settings.newProgram === false) {
          console.log(`Kullanıcı ${userId} yeni program bildirimlerini kapatmış.`);
          return;
        }

        if (fcmToken) {
          const message = {
            token: fcmToken,
            notification: {
              title: "Yeni Programın Hazır!",
              body: "Distribütörün senin için yeni bir program hazırladı. Hemen incele!",
            },
            data: {
              type: "new_program",
            },
            android: {
              notification: {
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
              },
            },
            apns: {
              payload: {
                aps: {
                  category: "NEW_PROGRAM_CATEGORY",
                },
              },
            },
          };

          await messaging.send(message);
          console.log(`Yeni program bildirimi gönderildi: ${userId}`);
        }
      } catch (error) {
        console.error("Program bildirim hatası:", error);
      }
    }
  });

// 2. Motivasyon Mesajı Bildirimi (daily_messages/{messageId} eklenince tetiklenir)
export const onMotivationMessageCreate = functions.firestore
  .document("motivations/{customerId}/daily_messages/{messageId}")
  .onWrite(async (change, context) => {
    const customerId = context.params.customerId;
    const messageData = change.after.data();

    if (!messageData) return;

    const textContent = readTextField(messageData, [
      "distributor_mesaji",
      "message",
      "content",
    ]);
    if (!textContent) return;

    const previousMessageData = change.before.data();
    const previousTextContent = previousMessageData
      ? readTextField(previousMessageData, [
        "distributor_mesaji",
        "message",
        "content",
      ])
      : "";


    if (previousTextContent === textContent) return;

    try {
      const profileDoc = await db.collection("userProfiles").doc(customerId).get();
      if (!profileDoc.exists) {
        await recordNotificationAttempt(customerId, {
          type: "daily_message",
          status: "skipped_profile_missing",
        });
        console.warn(`Motivasyon bildirimi atlandi: ${customerId} profili yok.`);
        return;
      }

      const profileData = profileDoc.data();
      const fcmToken = profileData?.fcmToken;
      const settings = profileData?.notificationSettings;

      if (settings && settings.dailyMessages === false) {
        await recordNotificationAttempt(customerId, {
          type: "daily_message",
          status: "skipped_disabled",
        });
        console.log(`Motivasyon bildirimi kapali: ${customerId}.`);
        return;
      }

      if (!fcmToken) {
        await recordNotificationAttempt(customerId, {
          type: "daily_message",
          status: "skipped_missing_token",
        });
        console.warn(`Motivasyon bildirimi atlandi: ${customerId} icin fcmToken yok.`);
        return;
      }

      const message = {
        token: fcmToken,
        notification: {
          title: "Distribütöründen Mesaj Var!",
          body: textContent,
        },
        data: {
          type: "daily_message",
        },
        android: {
          priority: "high" as const,
          notification: {
            channelId: "fcm_default_v1",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              category: "DAILY_MESSAGE_CATEGORY",
              sound: "default",
            },
          },
        },
      };

      await messaging.send(message);
      await recordNotificationAttempt(customerId, {
        type: "daily_message",
        status: "sent",
        hasToken: true,
        tokenSuffix: String(fcmToken).slice(-8),
      });
      console.log(`Motivasyon mesaji bildirimi gonderildi: ${customerId}`);
    } catch (error) {
      await recordNotificationAttempt(customerId, {
        type: "daily_message",
        status: "send_error",
        errorCode: (error as {code?: string}).code ?? "unknown",
        errorMessage: (error as Error).message ?? String(error),
      });
      console.error("Motivasyon bildirim hatasi:", error);
    }
  });
// 3. Takip Hatırlatıcısı (Zamanlanmış cron job)
export const checkFollowUpsScheduled = functions.pubsub
  .schedule("every 1 hours")
  .timeZone("Europe/Istanbul")
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    try {
      // isCompleted == false ve ve vadesi geçmiş takip görevlerini bul
      const followUpsSnapshot = await db
        .collection("scheduled_follow_ups")
        .where("isCompleted", "==", false)
        .where("dueDate", "<=", now)
        .get();

      if (followUpsSnapshot.empty) {
        console.log("Gönderilecek takip bildirimi yok.");
        return;
      }

      for (const doc of followUpsSnapshot.docs) {
        const data = doc.data();

        // Eğer bildirim zaten gönderildiyse atla
        if (wasAlreadyNotifiedForDueDate(data)) continue;

        const consultantId = data.consultantId;
        const customerName = `${data.customerFirstName || ""} ${data.customerLastName || ""}`.trim();
        const title = data.title || "Müşteri Takip Zamanı";

        // Danışman profilinden FCM Token oku
        const consultantDoc = await db.collection("userProfiles").doc(consultantId).get();
        if (!consultantDoc.exists) continue;

        const consultantData = consultantDoc.data();
        const fcmToken = consultantData?.fcmToken;
        const settings = consultantData?.notificationSettings;

        // Bildirim tercihi kontrolü
        if (settings && settings.followUps === false) {
          console.log(`Danışman ${consultantId} takip bildirimlerini kapatmış.`);
          continue;
        }

        if (fcmToken) {
          const message = {
            token: fcmToken,
            notification: {
              title: "Müşteri Takip Zamanı!",
              body: `Müşteriniz ${customerName} için planlanan takip zamanı geldi: ${title}`,
            },
            data: {
              type: "follow_up",
              followUpId: doc.id,
            },
            android: {
              notification: {
                clickAction: "FLUTTER_NOTIFICATION_CLICK",
              },
            },
            apns: {
              payload: {
                aps: {
                  category: "FOLLOW_UP_CATEGORY",
                },
              },
            },
          };

          await messaging.send(message);
          console.log(`Takip hatırlatması gönderildi. Danışman: ${consultantId}, Müşteri: ${customerName}`);

          // Bildirim gönderildi olarak işaretle
          await doc.ref.update({
            notificationSent: true,
            notificationSentAt: now,
          });
        }
      }
    } catch (error) {
      console.error("Zamanlanmış takip bildirim hatası:", error);
    }
  });
