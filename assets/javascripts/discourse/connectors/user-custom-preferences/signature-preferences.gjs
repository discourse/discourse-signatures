import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DEditor from "discourse/components/d-editor";
import withEventValue from "discourse/helpers/with-event-value";
import { i18n } from "discourse-i18n";

export default class SignaturePreferences extends Component {
  @service currentUser;
  @service siteSettings;

  @tracked _signatureRaw = this.args.model.custom_fields?.signature_raw || "";

  get canHaveSignature() {
    return this.currentUser?.can_have_signature !== false;
  }

  get maxLength() {
    return this.siteSettings.signatures_max_length;
  }

  get charactersRemaining() {
    return this.maxLength - this._signatureRaw.length;
  }

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

  @action
  updateRawSignature(value) {
    this._signatureRaw = value;
    this.args.model.set("custom_fields.signature_raw", value);
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
        {{#if this.canHaveSignature}}
          <div class="control-group signatures">
            <label class="control-label">{{i18n
                "signatures.my_signature"
              }}</label>
            <div class="controls input-xxlarge">
              {{#if this.siteSettings.signatures_advanced_mode}}
                <DEditor
                  @value={{@model.custom_fields.signature_raw}}
                  @change={{withEventValue this.updateRawSignature}}
                />
                <span class="signature-char-count">
                  {{i18n
                    "signatures.characters_remaining"
                    count=this.charactersRemaining
                  }}
                </span>
              {{else}}
                <input
                  type="url"
                  maxlength="2048"
                  placeholder={{i18n "signatures.signature_placeholder"}}
                  value={{@model.custom_fields.signature_url}}
                  {{on "input" this.updateSignatureUrl}}
                />
              {{/if}}
            </div>
          </div>
        {{else}}
          <div class="control-group signatures">
            <p class="signature-not-allowed">{{i18n
                "signatures.not_allowed"
              }}</p>
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
