import Preferences from 'discourse/controllers/preferences';
import { withPluginApi } from 'discourse/lib/plugin-api';
import RawHtml from 'discourse/widgets/raw-html';
import { cook } from 'discourse/lib/text';

function attachSignature(api) {
  api.includePostAttributes('user_signature');

  api.decorateWidget('post-contents:after', dec => {

    const attrs = dec.attrs;
    if (Ember.isEmpty(attrs.user_signature)) { return; }

    const currentUser = api.getCurrentUser();
    const siteSettings = Discourse.SiteSettings; // TODO: change way to get the sitesettings
    if (currentUser) {
      const enabled = currentUser.get('custom_fields.see_signatures');
      if (enabled) {
        if (siteSettings.signatures_advanced_mode) {
          return [dec.h('hr'), dec.h('div', new RawHtml({html: `<div class='user-signature'>${cook(attrs.user_signature)}</div>`}))];
        } else {
          return [dec.h('hr'), dec.h('img.signature-img', {attributes: {src: attrs.user_signature}})];
        }
      }
    }
  });
}

export default {
  name: 'extend-for-signatures',
  initialize(container) {
    const siteSettings = container.lookup('site-settings:main');
    if (siteSettings.signatures_enabled) {
      withPluginApi('0.1', attachSignature);

      Preferences.reopen({
        signaturesEnabled: function() {
          return Discourse.SiteSettings.signatures_enabled;
        }.property(),
        signaturesAdvancedMode: function() {
          return Discourse.SiteSettings.signatures_advanced_mode;
        }.property()
      });
    }
  }
};
