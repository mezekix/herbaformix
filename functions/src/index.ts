import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

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
              title: "Yeni Programın Hazır! 🥗",
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
  .onCreate(async (snapshot, context) => {
    const customerId = context.params.customerId;
    const messageData = snapshot.data();

    if (!messageData) return;

    try {
      // Kullanıcı profilini oku
      const profileDoc = await db.collection("userProfiles").doc(customerId).get();
      if (!profileDoc.exists) return;

      const profileData = profileDoc.data();
      const fcmToken = profileData?.fcmToken;
      const settings = profileData?.notificationSettings;

      // Bildirim tercihi kontrolü
      if (settings && settings.dailyMessages === false) {
        console.log(`Kullanıcı ${customerId} motivasyon bildirimlerini kapatmış.`);
        return;
      }

      if (fcmToken) {
        const textContent = messageData.message || messageData.content || "Yeni bir mesajınız var.";

        const message = {
          token: fcmToken,
          notification: {
            title: "Distribütöründen Mesaj Var! 💬",
            body: textContent,
          },
          data: {
            type: "daily_message",
          },
          android: {
            notification: {
              clickAction: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
          apns: {
            payload: {
              aps: {
                category: "DAILY_MESSAGE_CATEGORY",
              },
            },
          },
        };

        await messaging.send(message);
        console.log(`Motivasyon mesajı bildirimi gönderildi: ${customerId}`);
      }
    } catch (error) {
      console.error("Motivasyon bildirim hatası:", error);
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
        if (data.notificationSent === true) continue;

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
              title: "Müşteri Takip Zamanı! ⏰",
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
