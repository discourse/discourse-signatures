import Post from 'discourse/models/post';
import { withPluginApi } from 'discourse/lib/plugin-api';

function oldPluginCode() {
  Post.reopen({
    showSignatures: function() {
      return Discourse.User.currentProp("custom_fields.see_signatures");
    }.property()
  });
}

function attachSignature(api) {
  api.includePostAttributes('user_signature_url');

  api.decorateWidget('post-contents:after', dec => {

    const attrs = dec.attrs;
    if (Ember.isEmpty(attrs.user_signature_url)) { return; }

    const currentUser = api.getCurrentUser();
    if (currentUser) {
      const enabled = currentUser.get('custom_fields.see_signatures');
      if (enabled) {
        return [dec.h('hr'), dec.h('img.signature-img', { attributes: { src: attrs.user_signature_url } } )];
      }
    }
  });
}

export default {
  name: 'extend-for-signatures',
  initialize(container) {
    const siteSettings = container.lookup('site-settings:main');
    if (siteSettings.signatures_enabled) {
      withPluginApi('0.1', attachSignature, { noApi: oldPluginCode });
    }
  }
};
