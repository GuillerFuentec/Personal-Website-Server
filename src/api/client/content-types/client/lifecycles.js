import { initializeNotificationAPI } from "../../../../utils/notification.js";

const parseContactInfo = (contactInfo) => {
  if (!contactInfo) {
    return {};
  }

  if (typeof contactInfo === "string") {
    try {
      return JSON.parse(contactInfo);
    } catch (error) {
      strapi.log.warn(
        "[client afterCreate] No se pudo parsear contact_info como JSON",
        error
      );
      return {};
    }
  }

  return contactInfo;
};

export default {
  async afterCreate(event) {
    const { result } = event;
    const { name = "Nuevo cliente", contact_info } = result;
    const { email, phone, message } = parseContactInfo(contact_info);
    const adminPhone = process.env.ADMIN_PHONE_NUMBER;

    if (!adminPhone) {
      strapi.log.error(
        "[client afterCreate] ADMIN_PHONE_NUMBER is not defined. Skipping notification dispatch."
      );
      return;
    }

    const msgParts = [
      `Nuevo cliente registrado: ${name}`,
      email ? `Email: ${email}` : null,
      phone ? `Telefono: ${phone}` : null,
      message ? `Mensaje: ${message}` : null,
    ].filter(Boolean);

    const msg = msgParts.join("\n");

    await initializeNotificationAPI().send({
      type: "new_client",
      to: { number: adminPhone },
      sms: {
        message: msg,
      },
    });
  },
};
