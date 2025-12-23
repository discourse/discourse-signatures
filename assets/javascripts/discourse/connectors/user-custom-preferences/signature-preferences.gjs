import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DEditor from "discourse/components/d-editor";
import { i18n } from "discourse-i18n";

export default class SignaturePreferences extends Component {
  @service siteSettings;

  @action
  updateSeeSignatures(event) {
    const model = this.args.model;
    model.set("see_signatures", event.target.checked);
    model.set("custom_fields.see_signatures", event.target.checked);
  }

  @action
  updateSignatureUrl(event) {
    this.args.model.set("custom_fields.signature_url", event.target.value);
  }

  <template>
    {{#if this.siteSettings.signatures_enabled}}
      <div class="user-custom-preferences-outlet signature-preferences">
        <div class="control-group signatures">
          <label class="control-label">{{i18n
              "signatures.enable_signatures"
            }}</label>
          <div class="controls">
            <label class="checkbox-label">
              <input
                type="checkbox"
                checked={{@model.see_signatures}}
                {{on "change" this.updateSeeSignatures}}
              />
              {{i18n "signatures.show_signatures"}}
            </label>
          </div>
        </div>
        <div class="control-group signatures">
          <label class="control-label">{{i18n
              "signatures.my_signature"
            }}</label>
          <div class="controls input-xxlarge">
            {{#if this.siteSettings.signatures_advanced_mode}}
              <DEditor @value={{@model.custom_fields.signature_raw}} />
            {{else}}
              <input
                type="text"
                placeholder={{i18n "signatures.signature_placeholder"}}
                value={{@model.custom_fields.signature_url}}
                {{on "input" this.updateSignatureUrl}}
              />
            {{/if}}
          </div>
        </div>
      </div>
    {{/if}}
  </template>
}
