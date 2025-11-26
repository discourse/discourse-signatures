import { action } from "@ember/object";
import { withPluginApi } from "discourse/lib/plugin-api";
import PostSignature from "../components/post-signature";

function customizePost(api) {
  api.addTrackedPostProperties("user_signature");

  api.renderAfterWrapperOutlet("post-content-cooked-html", PostSignature);
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
        customizePost(api);
        addSetting(api);
      });
    }
  },
};
