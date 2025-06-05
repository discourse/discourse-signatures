import Component, { Input } from "@ember/component";
import { classNames, tagName } from "@ember-decorators/component";
import DEditor from "discourse/components/d-editor";
import { i18n } from "discourse-i18n";

@tagName("div")
@classNames("user-custom-preferences-outlet", "signature-preferences")
export default class SignaturePreferences extends Component {
  <template>
    {{#if this.siteSettings.signatures_enabled}}
      <div class="control-group signatures">
        <label class="control-label">{{i18n
            "signatures.enable_signatures"
          }}</label>
        <div class="controls">
          <label class="checkbox-label">
            <Input @type="checkbox" @checked={{this.model.see_signatures}} />
            {{i18n "signatures.show_signatures"}}
          </label>
        </div>
      </div>
      <div class="control-group signatures">
        <label class="control-label">{{i18n "signatures.my_signature"}}</label>
        {{#if this.siteSettings.signatures_advanced_mode}}
          <DEditor
            @value={{this.model.custom_fields.signature_raw}}
            @showUploadModal="showUploadModal"
          />
        {{else}}
          <Input
            @type="text"
            class="input-xxlarge"
            placeholder={{i18n "signatures.signature_placeholder"}}
            @value={{this.model.custom_fields.signature_url}}
          />
        {{/if}}
      </div>
    {{/if}}
  </template>
}
