import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  onDocumentCreated,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";

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

async function createInboxNotification(
  userId: string,
  notification: {
    type: string;
    title: string;
    body: string;
    actionPath?: string;
    sourceId?: string;
  },
  stableId?: string,
): Promise<void> {
  const collection = db.collection("users").doc(userId)
    .collection("notifications");
  const reference = stableId ? collection.doc(stableId) : collection.doc();
  await reference.set({
    ...notification,
    isRead: false,
    readAt: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function isDistributorRole(value: unknown): boolean {
  return value === "distributor" ||
    value === "supervisor" ||
    value === "successCreator";
}

async function sendPushNotification(
  token: unknown,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<void> {
  if (typeof token !== "string" || token.length === 0) return;

  try {
    await messaging.send({
      token,
      notification: {title, body},
      data,
      android: {
        priority: "high",
        notification: {
          channelId: "fcm_default_v1",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        headers: {"apns-priority": "10"},
        payload: {aps: {sound: "default"}},
      },
    });
  } catch (error) {
    // Gelen kutusu bildirimi kalıcıdır. Geçersiz/eskimiş bir token rol
    // işlemini veya Firestore tetikleyicisinin yeniden denemesini engellemez.
    console.error("Rol akışı push bildirimi gönderilemedi:", error);
  }
}

// Müşteri distribütörlük başvurusu yaptığında atanmış distribütörü bilgilendirir.
export const onDistributorRequestUpdate = onDocumentUpdated({
  document: "userProfiles/{customerId}",
  region: "europe-west1",
}, async (event) => {
    const change = event.data;
    if (!change) return;

    const before = change.before.data();
    const after = change.after.data();
    if (
      before.distributorRequestStatus === "pending" ||
      after.distributorRequestStatus !== "pending" ||
      after.role !== "customer"
    ) {
      return;
    }

    const customerId = event.params.customerId;
    const distributorId = after.assignedDistributorId;
    if (typeof distributorId !== "string" || distributorId.length === 0) {
      console.warn(`Distribütör başvurusu atlandı: ${customerId} atanmamış.`);
      return;
    }

    const distributorSnapshot = await db
      .collection("userProfiles")
      .doc(distributorId)
      .get();
    const distributor = distributorSnapshot.data();
    if (!distributorSnapshot.exists || !isDistributorRole(distributor?.role)) {
      console.warn(`Distribütör başvurusu atlandı: ${distributorId} yetkili değil.`);
      return;
    }

    const customerName = (readTextField(after, ["name"]) || "Müşteriniz")
      .slice(0, 120);
    const title = "Yeni Distribütörlük Başvurusu";
    const body = `${customerName} distribütör olmak için başvurdu.`;
    await createInboxNotification(distributorId, {
      type: "distributor_request",
      title,
      body,
      actionPath: "/home/customers",
      sourceId: customerId,
    }, `distributor_request_${customerId}`);

    await sendPushNotification(distributor?.fcmToken, title, body, {
      type: "distributor_request",
      customerId,
    });
  });

// Distribütörün onay veya düzeltme komutunu sunucuda tekrar doğrular ve uygular.
// Rol alanı hiçbir zaman mobil istemci tarafından doğrudan değiştirilemez.
export const onRoleChangeActionCreate = onDocumentCreated({
  document: "roleChangeActions/{actionId}",
  region: "europe-west1",
}, async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const actionReference = snapshot.ref;
    const raw = snapshot.data();
    const requestedBy = raw.requestedBy;
    const customerId = raw.customerId;
    const action = raw.action;

    if (
      typeof requestedBy !== "string" || requestedBy.length === 0 ||
      requestedBy.length > 128 ||
      typeof customerId !== "string" || customerId.length === 0 ||
      customerId.length > 128 ||
      (action !== "promote" && action !== "demote")
    ) {
      console.warn(`Geçersiz rol komutu silindi: ${event.params.actionId}`);
      await actionReference.delete();
      return;
    }

    const actorReference = db.collection("userProfiles").doc(requestedBy);
    const targetReference = db.collection("userProfiles").doc(customerId);
    const notificationReference = db.collection("users").doc(customerId)
      .collection("notifications")
      .doc(`role_change_${action}_${customerId}`);

    const result = await db.runTransaction(async (transaction) => {
      const [actionSnapshot, actorSnapshot, targetSnapshot] = await Promise.all([
        transaction.get(actionReference),
        transaction.get(actorReference),
        transaction.get(targetReference),
      ]);

      if (!actionSnapshot.exists) return null;

      const actor = actorSnapshot.data();
      const target = targetSnapshot.data();
      const isAssigned = target?.assignedDistributorId === requestedBy;
      const canPromote = action === "promote" &&
        target?.role === "customer";
      const canDemote = action === "demote" &&
        target?.role === "distributor" &&
        target?.distributorRequestStatus === "approved";

      if (
        !actorSnapshot.exists || !targetSnapshot.exists ||
        !isDistributorRole(actor?.role) || !isAssigned ||
        (!canPromote && !canDemote)
      ) {
        transaction.delete(actionReference);
        return null;
      }

      const targetName = (readTextField(target!, ["name"]) || "Hesabınız")
        .slice(0, 120);
      const title = action === "promote" ?
        "Distribütör Rolünüz Etkinleştirildi" :
        "Hesabınız Müşteri Rolüne Döndürüldü";
      const body = action === "promote" ?
        `${targetName}, distribütörünüz hesabınızı distribütör rolüne geçirdi.` :
        `${targetName}, hesabınız yeniden müşteri rolüne geçirildi.`;

      transaction.update(targetReference, action === "promote" ? {
        role: "distributor",
        distributorRequestStatus: "approved",
      } : {
        role: "customer",
        distributorRequestStatus: "reverted",
      });
      transaction.set(notificationReference, {
        type: "role_change",
        title,
        body,
        actionPath: "/home",
        sourceId: customerId,
        isRead: false,
        readAt: null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      transaction.delete(actionReference);

      return {token: target?.fcmToken, title, body};
    });

    if (result == null) {
      console.warn(`Rol komutu doğrulanamadı: ${event.params.actionId}`);
      return;
    }

    await sendPushNotification(result.token, result.title, result.body, {
      type: "role_change",
      role: action === "promote" ? "distributor" : "customer",
    });
  });

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

        const notificationTitle = "Yeni Programın Hazır!";
        const notificationBody =
          "Distribütörün senin için yeni bir program hazırladı. Hemen incele!";
        await createInboxNotification(userId, {
          type: "program",
          title: notificationTitle,
          body: notificationBody,
          actionPath: "/home",
          sourceId: context.params.programId,
        });

        if (fcmToken) {
          const message = {
            token: fcmToken,
            notification: {
              title: notificationTitle,
              body: notificationBody,
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

      const notificationTitle = "Distribütöründen Mesaj Var!";
      await createInboxNotification(customerId, {
        type: "motivation",
        title: notificationTitle,
        body: textContent,
        actionPath: "/home",
        sourceId: context.params.messageId,
      });

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
          title: notificationTitle,
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

        const notificationTitle = "Müşteri Takip Zamanı!";
        const notificationBody =
          `Müşteriniz ${customerName} için planlanan takip zamanı geldi: ${title}`;
        await createInboxNotification(consultantId, {
          type: "follow_up",
          title: notificationTitle,
          body: notificationBody,
          actionPath: "/home/follow-ups",
          sourceId: doc.id,
        }, `follow_up_${doc.id}`);

        if (fcmToken) {
          const message = {
            token: fcmToken,
            notification: {
                title: notificationTitle,
                body: notificationBody,
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
        }

        // Gelen kutusu kaydı üretildi; aynı takip için tekrar oluşturma.
        await doc.ref.update({
          notificationSent: true,
          notificationSentAt: now,
        });
      }
    } catch (error) {
      console.error("Zamanlanmış takip bildirim hatası:", error);
    }
  });
