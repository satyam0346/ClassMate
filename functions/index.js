const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendAnnouncementNotification = onDocumentCreated(
  "announcements/{docId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const title = data.title || "New Announcement";
    let message = data.message || "A new announcement has been posted.";
    if (message.length > 100) {
      message = message.substring(0, 100) + "…";
    }

    const payload = {
      notification: {
        title: `📢 ${title}`,
        body: message,
      },
      data: {
        announcementId: event.params.docId,
      },
      android: {
        notification: {
          channelId: "classmate_channel",
        },
      },
      topic: "class_announcements",
    };

    try {
      await admin.messaging().send(payload);
      console.log("Successfully sent announcement notification");
      // Update fcmSent flag
      await snap.ref.update({ fcmSent: true });
    } catch (error) {
      console.error("Error sending announcement notification:", error);
    }
  }
);

exports.sendMaterialNotification = onDocumentCreated(
  "materials/{docId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const title = data.title || "New Material";
    const subject = data.subject || "a subject";
    // Assuming fileType is "link" for links
    const fileType = data.fileType || "file";
    
    let bodyText = `A new ${fileType} file has been uploaded for ${subject}.`;
    if (fileType === "link") {
      bodyText = `A new link has been shared for ${subject}.`;
    }

    const payload = {
      notification: {
        title: `📚 ${title}`,
        body: bodyText,
      },
      data: {
        materialId: event.params.docId,
      },
      android: {
        notification: {
          channelId: "classmate_channel",
        },
      },
      topic: "class_materials",
    };

    try {
      await admin.messaging().send(payload);
      console.log("Successfully sent material notification");
    } catch (error) {
      console.error("Error sending material notification:", error);
    }
  }
);
