import { initializeNotificationAPI } from "../../../../utils/notification.js";

export default {
  async afterCreate(_event) {
    const { result } = _event;
    const client_message = result.client_message || undefined;
    const phone = result.phone || undefined;
    const email = result.email || undefined;
    const name = result.name || undefined;
    // Constructor del mensaje a enviar
    const msg =
      "Nuevo cliente registrado:\n" + name + "\n" + email ||
      undefined + "\n" + phone + "\nMensaje: " + client_message;

    await initializeNotificationAPI().send({
      type: "new_client",
      to: { number: process.env.ADMIN_PHONE_NUMBER },
      sms: {
        message: msg,
      },
    });
  },
};
