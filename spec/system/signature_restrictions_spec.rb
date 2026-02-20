# frozen_string_literal: true

RSpec.describe "Signature restrictions" do
  fab!(:user)
  fab!(:category)
  fab!(:topic) { Fabricate(:topic, category:) }
  let(:signature_image_url) { "data:abcdef," }

  before do
    enable_current_plugin
    SiteSetting.signatures_enabled = true
    SiteSetting.signatures_advanced_mode = false
    SiteSetting.signatures_visible_by_default = true
  end

  describe "group-based restriction" do
    fab!(:group)
    fab!(:post_with_sig) { Fabricate(:post, topic:, user:) }

    before do
      user.custom_fields["signature_url"] = signature_image_url
      user.save_custom_fields
    end

    context "when signatures_allowed_groups is empty" do
      before { SiteSetting.signatures_allowed_groups = "" }

      it "shows signatures for all users" do
        sign_in(user)
        visit topic.url
        expect(page).to have_css("img.signature-img")
      end
    end

    context "when user is in an allowed group" do
      before do
        SiteSetting.signatures_allowed_groups = group.id.to_s
        group.add(user)
      end

      it "shows the signature below their post" do
        sign_in(user)
        visit topic.url
        expect(page).to have_css("img.signature-img[src='#{signature_image_url}']")
      end

      it "shows the signature editing UI in preferences" do
        sign_in(user)
        visit "/my/preferences/profile"
        expect(page).to have_content(I18n.t("js.signatures.my_signature"))
        expect(page).to have_no_content(I18n.t("js.signatures.not_allowed"))
      end
    end

    context "when user is not in an allowed group" do
      before { SiteSetting.signatures_allowed_groups = group.id.to_s }

      it "does not show the signature below their post" do
        sign_in(Fabricate(:user))
        visit topic.url
        expect(page).to have_no_css("img.signature-img")
      end

      it "shows the restriction message in preferences" do
        sign_in(user)
        visit "/my/preferences/profile"
        expect(page).to have_content(I18n.t("js.signatures.not_allowed"))
        expect(page).to have_no_field(placeholder: I18n.t("js.signatures.signature_placeholder"))
      end
    end
  end

  describe "category-based display" do
    fab!(:other_category, :category)
    fab!(:other_topic) { Fabricate(:topic, category: other_category) }

    before do
      user.custom_fields["signature_url"] = signature_image_url
      user.save_custom_fields
    end

    context "when signatures_show_in_categories is empty" do
      before { SiteSetting.signatures_show_in_categories = "" }

      it "shows signatures in all categories" do
        Fabricate(:post, topic:, user:)
        sign_in(user)
        visit topic.url
        expect(page).to have_css("img.signature-img")
      end
    end

    context "when signatures_show_in_categories is set" do
      before { SiteSetting.signatures_show_in_categories = category.id.to_s }

      it "shows signatures in the allowed category" do
        Fabricate(:post, topic:, user:)
        sign_in(user)
        visit topic.url
        expect(page).to have_css("img.signature-img")
      end

      it "does not show signatures in other categories" do
        Fabricate(:post, topic: other_topic, user:)
        sign_in(user)
        visit other_topic.url
        expect(page).to have_no_css("img.signature-img")
      end
    end
  end

  describe "first-post-only display" do
    before do
      user.custom_fields["signature_url"] = signature_image_url
      user.save_custom_fields
    end

    context "when signatures_first_post_only is false" do
      before { SiteSetting.signatures_first_post_only = false }

      it "shows signatures on all posts" do
        Fabricate(:post, topic:, user:)
        Fabricate(:post, topic:, user:)
        sign_in(user)
        visit topic.url
        expect(page).to have_css("img.signature-img", count: 2)
      end
    end

    context "when signatures_first_post_only is true" do
      before { SiteSetting.signatures_first_post_only = true }

      it "shows signature only on the first post" do
        Fabricate(:post, topic:, user:)
        Fabricate(:post, topic:, user:)
        sign_in(user)
        visit topic.url
        expect(page).to have_css("img.signature-img", count: 1)
      end
    end
  end
end
