# frozen_string_literal: true

RSpec.describe "Discourse Signatures" do
  before do
    enable_current_plugin
    SiteSetting.signatures_enabled = true
  end

  describe "group-based restriction" do
    fab!(:user)
    fab!(:group)
    fab!(:topic)

    before do
      SiteSetting.signatures_advanced_mode = false
      user.custom_fields["signature_url"] = "https://example.com/sig.png"
      user.save_custom_fields
    end

    context "when signatures_allowed_groups is empty" do
      before { SiteSetting.signatures_allowed_groups = "" }

      it "includes user_signature in the post serializer" do
        post = Fabricate(:post, topic:, user:)
        json = PostSerializer.new(post, scope: Guardian.new(user), root: false).as_json
        expect(json[:user_signature]).to eq("https://example.com/sig.png")
      end

      it "sets can_have_signature to true for current user" do
        json = CurrentUserSerializer.new(user, scope: Guardian.new(user), root: false).as_json
        expect(json[:can_have_signature]).to eq(true)
      end
    end

    context "when user is in the allowed group" do
      before do
        SiteSetting.signatures_allowed_groups = group.id.to_s
        group.add(user)
      end

      it "includes user_signature in the post serializer" do
        post = Fabricate(:post, topic:, user:)
        json = PostSerializer.new(post, scope: Guardian.new(user), root: false).as_json
        expect(json[:user_signature]).to eq("https://example.com/sig.png")
      end

      it "sets can_have_signature to true" do
        json = CurrentUserSerializer.new(user, scope: Guardian.new(user), root: false).as_json
        expect(json[:can_have_signature]).to eq(true)
      end
    end

    context "when user is not in the allowed group" do
      before { SiteSetting.signatures_allowed_groups = group.id.to_s }

      it "returns nil for user_signature in the post serializer" do
        post = Fabricate(:post, topic:, user:)
        json = PostSerializer.new(post, scope: Guardian.new(user), root: false).as_json
        expect(json[:user_signature]).to be_nil
      end

      it "sets can_have_signature to false" do
        json = CurrentUserSerializer.new(user, scope: Guardian.new(user), root: false).as_json
        expect(json[:can_have_signature]).to eq(false)
      end
    end
  end

  describe "signature length enforcement" do
    fab!(:user)

    before do
      SiteSetting.signatures_advanced_mode = true
      SiteSetting.signatures_max_length = 100
    end

    it "truncates signature_raw to max_length on user update" do
      user.custom_fields["signature_raw"] = "a" * 200
      user.save_custom_fields

      DiscourseEvent.trigger(:user_updated, user)
      user.reload

      expect(user.custom_fields["signature_raw"].length).to eq(100)
    end

    it "does not truncate signatures within the limit" do
      user.custom_fields["signature_raw"] = "short signature"
      user.save_custom_fields

      DiscourseEvent.trigger(:user_updated, user)
      user.reload

      expect(user.custom_fields["signature_raw"]).to eq("short signature")
    end
  end

  describe "URL validation" do
    fab!(:user)

    before { SiteSetting.signatures_advanced_mode = false }

    it "removes invalid URLs on user update" do
      user.custom_fields["signature_url"] = "not a valid url %%"
      user.save_custom_fields

      DiscourseEvent.trigger(:user_updated, user)
      user.reload

      expect(user.custom_fields["signature_url"]).to be_nil
    end

    it "keeps valid URLs on user update" do
      user.custom_fields["signature_url"] = "https://example.com/sig.png"
      user.save_custom_fields

      DiscourseEvent.trigger(:user_updated, user)
      user.reload

      expect(user.custom_fields["signature_url"]).to eq("https://example.com/sig.png")
    end

    it "removes URLs with non-HTTP schemes on user update" do
      user.custom_fields["signature_url"] = "javascript:alert(1)"
      user.save_custom_fields

      DiscourseEvent.trigger(:user_updated, user)
      user.reload

      expect(user.custom_fields["signature_url"]).to be_nil
    end
  end

  describe "group restriction on user update" do
    fab!(:user)
    fab!(:group)

    before do
      SiteSetting.signatures_advanced_mode = false
      user.custom_fields["signature_url"] = "https://example.com/sig.png"
      user.save_custom_fields
    end

    it "clears signature data when user is not in the allowed group" do
      SiteSetting.signatures_allowed_groups = group.id.to_s

      DiscourseEvent.trigger(:user_updated, user)
      user.reload

      expect(user.custom_fields["signature_url"]).to be_nil
    end

    it "keeps signature data when user is in the allowed group" do
      SiteSetting.signatures_allowed_groups = group.id.to_s
      group.add(user)

      DiscourseEvent.trigger(:user_updated, user)
      user.reload

      expect(user.custom_fields["signature_url"]).to eq("https://example.com/sig.png")
    end
  end
end
