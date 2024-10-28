# frozen_string_literal: true

# name: discourse-signatures
# about: Adds signatures to Discourse posts
# meta_topic_id: 42263
# version: 2.1.0
# author: Rafael Silva <xfalcox@gmail.com>
# url: https://github.com/discourse/discourse-signatures

enabled_site_setting :signatures_enabled

DiscoursePluginRegistry.serialized_current_user_fields << "see_signatures"
DiscoursePluginRegistry.serialized_current_user_fields << "signature_url"
DiscoursePluginRegistry.serialized_current_user_fields << "signature_raw"

after_initialize do
  register_user_custom_field_type("see_signatures", :boolean)
  register_user_custom_field_type("signature_url", :string, max_length: 32_000)
  register_user_custom_field_type("signature_raw", :string, max_length: 10_000)

  # add to class and serializer to allow for default value for the setting
  add_to_class(:user, :see_signatures) do
    if custom_fields["see_signatures"] != nil
      custom_fields["see_signatures"]
    else
      SiteSetting.signatures_visible_by_default
    end
  end

  add_to_serializer(:user, :see_signatures) { object.see_signatures }

  register_editable_user_custom_field %i[see_signatures signature_url signature_raw]

  allow_public_user_custom_field :signature_cooked
  allow_public_user_custom_field :signature_url

  add_to_serializer(:post, :user_signature) do
    if SiteSetting.signatures_advanced_mode
      object.user.custom_fields["signature_cooked"] if object.user
    else
      object.user.custom_fields["signature_url"] if object.user
    end
  end

  # This is the code responsible for cooking a new advanced mode sig on user update
  on(:user_updated) do |user|
    if SiteSetting.signatures_advanced_mode && user.custom_fields["signature_raw"]
      cooked_sig =
        PrettyText.cook(
          user.custom_fields["signature_raw"],
          omit_nofollow: user.has_trust_level?(TrustLevel[3]) && !SiteSetting.tl3_links_no_follow,
        )
      # avoid infinite recursion
      if cooked_sig != user.custom_fields["signature_cooked"]
        user.custom_fields["signature_cooked"] = cooked_sig
        user.save
      end
    end
  end
end

register_asset "stylesheets/common/signatures.scss"
