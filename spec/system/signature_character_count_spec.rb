# frozen_string_literal: true

RSpec.describe "Signature character count" do
  fab!(:user)

  before do
    enable_current_plugin
    SiteSetting.signatures_enabled = true
    SiteSetting.signatures_advanced_mode = true
    SiteSetting.signatures_max_length = 500
  end

  it "shows max length when user has no signature" do
    sign_in(user)
    visit "/my/preferences/profile"

    expect(page).to have_css(
      ".signature-char-count",
      text: I18n.t("js.signatures.characters_remaining.other", count: 500),
    )
  end

  it "shows max length when user has a null signature_raw" do
    user.custom_fields["signature_raw"] = nil
    user.save_custom_fields

    sign_in(user)
    visit "/my/preferences/profile"

    expect(page).to have_css(
      ".signature-char-count",
      text: I18n.t("js.signatures.characters_remaining.other", count: 500),
    )
  end

  it "shows correct remaining characters when user has an existing signature" do
    user.custom_fields["signature_raw"] = "Hello world"
    user.save_custom_fields

    sign_in(user)
    visit "/my/preferences/profile"

    expect(page).to have_css(
      ".signature-char-count",
      text: I18n.t("js.signatures.characters_remaining.other", count: 489),
    )
  end

  it "updates remaining characters as user types" do
    sign_in(user)
    visit "/my/preferences/profile"

    expect(page).to have_css(
      ".signature-char-count",
      text: I18n.t("js.signatures.characters_remaining.other", count: 500),
    )

    find(".signature-preferences .d-editor-input").send_keys("Test signature")

    expect(page).to have_css(
      ".signature-char-count",
      text: I18n.t("js.signatures.characters_remaining.other", count: 486),
    )
  end
end
