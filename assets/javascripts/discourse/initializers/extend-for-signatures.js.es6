import Post from 'discourse/models/post';
import User from 'discourse/models/user';

export default {
  name: 'extend-for-signatures',
  initialize() {

    Post.reopen({
      showSignatures: Discourse.SiteSettings.signatures_enabled && Discourse.User.currentProp("custom_fields.see_signatures")
    });
  }
};
