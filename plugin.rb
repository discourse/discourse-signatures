# name: discourse-signatures
# about: A plugin to get that nostalgia signatures in Discourse Foruns
# version: 0.0.1
# author: Rafael Silva <xfalcox@gmail.com>
# url: https://github.com/xfalcox/discourse-signatures

enabled_site_setting :signatures_enabled


after_initialize do


  if SiteSetting.signatures_enabled && SiteSetting.signatures_user_signature.present? && SiteSetting.signatures_user_optin.present? then
    add_to_serializer(:post, :user_signature, false) { user_custom_fields["user_field_#{(UserField.find_by name: SiteSetting.signatures_user_signature).id}"] }
    add_to_serializer(:post, :user_show_signatures, false) { user_custom_fields["user_field_#{(UserField.find_by name: SiteSetting.signatures_user_optin).id}"] }
  end
end
