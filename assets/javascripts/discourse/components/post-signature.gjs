import Component from "@glimmer/component";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";

export default class PostSignature extends Component {
  static shouldRender(args, context) {
    const enabled =
      context.currentUser?.custom_fields?.see_signatures ??
      context.siteSettings.signatures_visible_by_default;

    return enabled && args.post.user_signature;
  }

  @service siteSettings;

  get isAdvancedModeEnabled() {
    return this.siteSettings.signatures_advanced_mode;
  }

  <template>
    <hr />
    {{#if this.isAdvancedModeEnabled}}
      <div>
        <div class="user-signature">
          {{htmlSafe @post.user_signature}}
        </div>
      </div>
    {{else}}
      <img class="signature-img" src={{@post.user_signature}} />
    {{/if}}
  </template>
}
