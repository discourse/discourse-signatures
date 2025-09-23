# frozen_string_literal: true

RSpec.describe "Image signatures", type: :system do
  fab!(:user)
  fab!(:topic) { Fabricate(:topic, category: Fabricate(:category)) }
  fab!(:post) { Fabricate(:post, topic:) }
  let(:signature_image_url) { "https://example.com/signature.png" }

  context "when signatures plugin is enabled" do
    before do
      enable_current_plugin
      SiteSetting.signatures_enabled = true
      SiteSetting.signatures_advanced_mode = false
    end

    context "when signatures are visible by default" do
      before { SiteSetting.signatures_visible_by_default = true }

      fab!(:post) { Fabricate(:post, topic:, user:, raw: "This is a test post with signature") }

      it "allows user to set an image signature and displays it below posts" do
        sign_in(user)

        visit "/my/preferences/profile"

        expect(page).to have_content(I18n.t("js.signatures.enable_signatures"))
        expect(page).to have_content(I18n.t("js.signatures.my_signature"))
        expect(page).to have_field(placeholder: I18n.t("js.signatures.signature_placeholder"))

        check I18n.t("js.signatures.show_signatures")
        fill_in placeholder: I18n.t("js.signatures.signature_placeholder"),
                with: signature_image_url

        click_button I18n.t("js.save")
        expect(page).to have_content(I18n.t("js.saved"))

        visit post.url

        expect(page).to have_css("img.signature-img[src='#{signature_image_url}']")
      end

      it "does not show signatures when user has disabled them" do
        sign_in(user)

        user.custom_fields["signature_url"] = signature_image_url
        user.custom_fields["see_signatures"] = false
        user.save_custom_fields

        post = Fabricate(:post, topic:, user:)

        visit topic.url

        expect(page).to have_no_css("img.signature-img")
      end

      it "shows signatures to other users when signatures_visible_by_default is true" do
        user.custom_fields["signature_url"] = signature_image_url
        user.save_custom_fields

        post = Fabricate(:post, topic:, user:)

        sign_in Fabricate(:user)

        visit topic.url

        expect(page).to have_css("img.signature-img[src='#{signature_image_url}']")
      end
    end

    context "when signatures are not visible by default" do
      before { SiteSetting.signatures_visible_by_default = false }

      it "does not show signatures when user hasn't opted in" do
        user.custom_fields["signature_url"] = signature_image_url
        user.save_custom_fields

        post = Fabricate(:post, topic:, user:)

        sign_in Fabricate(:user)

        visit topic.url

        expect(page).to have_no_css("img.signature-img")
      end

      it "allows users to opt into seeing signatures" do
        user.custom_fields["signature_url"] = signature_image_url
        user.save_custom_fields

        post = Fabricate(:post, topic:, user:)

        sign_in Fabricate(:user)

        visit "/my/preferences/profile"

        check I18n.t("js.signatures.show_signatures")
        click_button I18n.t("js.save")

        visit topic.url

        expect(page).to have_css("img.signature-img[src='#{signature_image_url}']")
      end
    end
  end

  context "when signatures plugin is disabled" do
    before { SiteSetting.signatures_enabled = false }

    it "does not show signatures or preferences" do
      user.custom_fields["signature_url"] = signature_image_url
      user.save_custom_fields

      post = Fabricate(:post, topic:, user:)

      sign_in(user)

      visit topic.url

      expect(page).to have_no_css("img.signature-img")

      visit "/my/preferences/profile"

      expect(page).to have_no_content(I18n.t("js.signatures.enable_signatures"))
    end
  end
end
