import { withPluginApi } from "discourse/lib/plugin-api";
import RawHtml from "discourse/widgets/raw-html";

function attachSignature(api, siteSettings) {
  api.includePostAttributes("user_signature");

  api.decorateWidget("post-contents:after-cooked", (dec) => {
    const attrs = dec.attrs;
    if (Ember.isEmpty(attrs.user_signature)) {
      return;
    }

    const currentUser = api.getCurrentUser();
    if (currentUser) {
      const enabled = currentUser.get("custom_fields.see_signatures");
      if (enabled) {
        if (siteSettings.signatures_advanced_mode) {
          return [
            dec.h("hr"),
            dec.h(
              "div",
              new RawHtml({
                html: `<div class='user-signature'>${attrs.user_signature}</div>`,
              })
            ),
          ];
        } else {
          return [
            dec.h("hr"),
            dec.h("img.signature-img", {
              attributes: { src: attrs.user_signature },
            }),
          ];
        }
      }
    }
  });
}

export default {
  name: "extend-for-signatures",
  initialize(container) {
    const siteSettings = container.lookup("site-settings:main");
    if (siteSettings.signatures_enabled) {
      withPluginApi("0.1", (api) => attachSignature(api, siteSettings));
    }
  },
};
