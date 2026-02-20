# frozen_string_literal: true

# name: discourse-signatures
# about: Adds signatures to Discourse posts
# meta_topic_id: 42263
# version: 2.2.0
# author: Rafael Silva <xfalcox@gmail.com>
# url: https://github.com/discourse/discourse-signatures

enabled_site_setting :signatures_enabled

DiscoursePluginRegistry.serialized_current_user_fields << "see_signatures"
DiscoursePluginRegistry.serialized_current_user_fields << "signature_url"
DiscoursePluginRegistry.serialized_current_user_fields << "signature_raw"

after_initialize do
  register_user_custom_field_type("see_signatures", :boolean)
  register_user_custom_field_type("signature_url", :string, max_length: 2048)
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

  add_to_serializer(:current_user, :can_have_signature) do
    allowed_groups = SiteSetting.signatures_allowed_groups_map
    allowed_groups.blank? || object.in_any_groups?(allowed_groups)
  end

  register_editable_user_custom_field :see_signatures
  register_editable_user_custom_field :signature_url
  register_editable_user_custom_field :signature_raw

  allow_public_user_custom_field :signature_cooked
  allow_public_user_custom_field :signature_url

  add_to_serializer(:post, :user_signature) do
    return nil unless object.user

    allowed_groups = SiteSetting.signatures_allowed_groups_map
    return nil if allowed_groups.present? && !object.user.in_any_groups?(allowed_groups)

    if SiteSetting.signatures_advanced_mode
      object.user.custom_fields["signature_cooked"]
    else
      object.user.custom_fields["signature_url"]
    end
  end

  on(:user_updated) do |user|
    allowed_groups = SiteSetting.signatures_allowed_groups_map
    if allowed_groups.present? && !user.in_any_groups?(allowed_groups)
      user.custom_fields.delete("signature_url")
      user.custom_fields.delete("signature_raw")
      user.custom_fields.delete("signature_cooked")
      user.save
      next
    end

    if user.custom_fields["signature_url"].present?
      url = user.custom_fields["signature_url"]
      begin
        parsed = URI.parse(url)
        raise URI::InvalidURIError unless parsed.is_a?(URI::HTTP) || parsed.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
        user.custom_fields.delete("signature_url")
        user.save
      end
    end

    if SiteSetting.signatures_advanced_mode && user.custom_fields["signature_raw"]
      raw = user.custom_fields["signature_raw"]
      max_length = SiteSetting.signatures_max_length
      raw = raw[0...max_length] if raw.length > max_length
      user.custom_fields["signature_raw"] = raw

      cooked_sig =
        PrettyText.cook(
          raw,
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
