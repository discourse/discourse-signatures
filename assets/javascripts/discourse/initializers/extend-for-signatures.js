import { action } from "@ember/object";
import { isEmpty } from "@ember/utils";
import { withSilencedDeprecations } from "discourse/lib/deprecated";
import { withPluginApi } from "discourse/lib/plugin-api";
import RawHtml from "discourse/widgets/raw-html";
import PostSignature from "../components/post-signature";

function customizePost(api, siteSettings) {
  api.addTrackedPostProperties("user_signature");

  api.renderAfterWrapperOutlet("post-content-cooked-html", PostSignature);

  withSilencedDeprecations("discourse.post-stream-widget-overrides", () =>
    customizeWidgetPost(api, siteSettings)
  );
}

function customizeWidgetPost(api, siteSettings) {
  api.decorateWidget("post-contents:after-cooked", (dec) => {
    const attrs = dec.attrs;
    if (isEmpty(attrs.user_signature)) {
      return;
    }

    const currentUser = api.getCurrentUser();
    let enabled;

    if (currentUser) {
      enabled =
        currentUser.get("custom_fields.see_signatures") ??
        siteSettings.signatures_visible_by_default;
    } else {
      enabled = siteSettings.signatures_visible_by_default;
    }
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
  });
}

function addSetting(api) {
  api.modifyClass(
    "controller:preferences/profile",
    (Superclass) =>
      class extends Superclass {
        @action
        save() {
          this.set(
            "model.custom_fields.see_signatures",
            this.get("model.see_signatures")
          );
          this.get("saveAttrNames").push("custom_fields");
          super.save();
        }
      }
  );
}

export default {
  name: "extend-for-signatures",
  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (siteSettings.signatures_enabled) {
      withPluginApi((api) => {
        customizePost(api, siteSettings);
        addSetting(api, siteSettings);
      });
    }
  },
};
