import Component from "@glimmer/component";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import DecoratedHtml from "discourse/components/decorated-html";

let _signatureDecorators = [];

export function addSignatureDecorator(decorator) {
  _signatureDecorators.push(decorator);
}

export function resetSignatureDecorators() {
  _signatureDecorators = [];
}

export default class PostSignature extends Component {
  static shouldRender(args, context) {
    const enabled =
      context.currentUser?.custom_fields?.see_signatures ??
      context.siteSettings.signatures_visible_by_default;

    if (!enabled || !args.post.user_signature) {
      return false;
    }

    if (
      context.siteSettings.signatures_first_post_only &&
      args.post.post_number !== 1
    ) {
      return false;
    }

    const allowedCategories =
      context.siteSettings.signatures_show_in_categories;
    if (allowedCategories) {
      const categoryIds = allowedCategories
        .split("|")
        .map((id) => parseInt(id, 10));
      const postCategoryId = args.post.topic?.category_id;
      if (!categoryIds.includes(postCategoryId)) {
        return false;
      }
    }

    return true;
  }

  @service siteSettings;

  get isAdvancedModeEnabled() {
    return this.siteSettings.signatures_advanced_mode;
  }

  get imageMaxHeight() {
    return `max-height: ${this.siteSettings.signatures_max_image_height}px`;
  }

  decorateSignature = (element, helper) => {
    _signatureDecorators.forEach((decorator) => {
      decorator(element, helper, this.args.post);
    });
  };

  <template>
    <hr />
    {{#if this.isAdvancedModeEnabled}}
      <DecoratedHtml
        @html={{trustHTML @post.user_signature}}
        @decorate={{this.decorateSignature}}
        @className="user-signature"
      />
    {{else}}
      <img
        class="signature-img"
        src={{@post.user_signature}}
        style={{this.imageMaxHeight}}
      />
    {{/if}}
  </template>
}
