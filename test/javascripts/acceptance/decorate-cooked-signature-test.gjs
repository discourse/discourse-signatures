import { visit } from "@ember/test-helpers";
import { test } from "qunit";
import { withPluginApi } from "discourse/lib/plugin-api";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { resetSignatureDecorators } from "discourse/plugins/discourse-signatures/discourse/components/post-signature";

acceptance("Acceptance | decorateCookedSignature", function (needs) {
  needs.user();
  needs.settings({
    signatures_enabled: true,
    signatures_advanced_mode: true,
    signatures_visible_by_default: true,
  });

  needs.hooks.afterEach(() => {
    resetSignatureDecorators();
  });

  needs.pretender((server, helper) => {
    server.get("/t/999.json", () => {
      return helper.response({
        post_stream: {
          posts: [
            {
              id: 1,
              username: "signature_user",
              avatar_template:
                "/letter_avatar_proxy/v4/letter/s/8edcca/{size}.png",
              created_at: "2024-01-01T12:00:00.000Z",
              cooked: "<p>This is a post with a signature</p>",
              post_number: 1,
              post_type: 1,
              updated_at: "2024-01-01T12:00:00.000Z",
              reply_count: 0,
              reply_to_post_number: null,
              quote_count: 0,
              incoming_link_count: 0,
              reads: 1,
              readers_count: 0,
              score: 0,
              yours: false,
              topic_id: 999,
              topic_slug: "topic-with-signature",
              display_username: "Signature User",
              primary_group_name: null,
              flair_url: null,
              flair_bg_color: null,
              flair_color: null,
              version: 1,
              can_edit: false,
              can_delete: false,
              can_recover: false,
              can_wiki: false,
              read: true,
              user_title: null,
              bookmarked: false,
              bookmarks: [],
              actions_summary: [],
              moderator: false,
              admin: false,
              staff: false,
              user_id: 2,
              hidden: false,
              trust_level: 1,
              deleted_at: null,
              user_deleted: false,
              edit_reason: null,
              can_view_edit_history: true,
              wiki: false,
              user_signature: "<p>My <strong>awesome</strong> signature</p>",
            },
          ],
          stream: [1],
        },
        timeline_lookup: [[1, 0]],
        id: 999,
        title: "Topic with signature",
        fancy_title: "Topic with signature",
        posts_count: 1,
        created_at: "2024-01-01T12:00:00.000Z",
        views: 1,
        reply_count: 0,
        like_count: 0,
        last_posted_at: "2024-01-01T12:00:00.000Z",
        visible: true,
        closed: false,
        archived: false,
        has_summary: false,
        archetype: "regular",
        slug: "topic-with-signature",
        category_id: 1,
        word_count: 10,
        deleted_at: null,
        user_id: 2,
        featured_link: null,
        pinned_globally: false,
        pinned_at: null,
        pinned_until: null,
        image_url: null,
        draft: null,
        draft_key: "topic_999",
        draft_sequence: 0,
        posted: false,
        unpinned: null,
        pinned: false,
        current_post_number: 1,
        highest_post_number: 1,
        deleted_by: null,
        has_deleted: false,
        actions_summary: [],
        chunk_size: 20,
        bookmarked: false,
        bookmarks: [],
        topic_timer: null,
        message_bus_last_id: 0,
        participant_count: 1,
        show_read_indicator: false,
        thumbnails: null,
        details: {
          can_create_post: true,
          participants: [
            {
              id: 2,
              username: "signature_user",
              avatar_template:
                "/letter_avatar_proxy/v4/letter/s/8edcca/{size}.png",
              post_count: 1,
            },
          ],
        },
      });
    });
  });

  test("decorateCookedSignature applies decorators to signature content", async function (assert) {
    let decoratorCalled = false;
    let receivedElement = null;
    let receivedPost = null;

    withPluginApi((api) => {
      api.decorateCookedSignature((element, helper, post) => {
        decoratorCalled = true;
        receivedElement = element;
        receivedPost = post;
        element.classList.add("decorated-test-signature");
      });
    });

    await visit("/t/topic-with-signature/999");

    assert.true(decoratorCalled, "decorator was called");

    assert.notStrictEqual(
      receivedElement,
      null,
      "element was passed to decorator"
    );

    assert.strictEqual(
      receivedPost.topic_slug,
      "topic-with-signature",
      "correct post was passed to decorator"
    );

    assert.strictEqual(
      receivedPost.user_signature,
      "<p>My <strong>awesome</strong> signature</p>",
      "post contains user_signature"
    );
    assert.dom(".user-signature.decorated-test-signature").exists();
    assert.dom(".user-signature strong").hasText("awesome");
  });

  test("multiple decorators are applied in order", async function (assert) {
    const callOrder = [];

    withPluginApi((api) => {
      api.decorateCookedSignature((element) => {
        callOrder.push("first");
        element.dataset.firstDecorator = "applied";
      });

      api.decorateCookedSignature((element) => {
        callOrder.push("second");
        element.dataset.secondDecorator = "applied";
      });
    });

    await visit("/t/topic-with-signature/999");

    assert.deepEqual(
      callOrder,
      ["first", "second"],
      "decorators called in registration order"
    );
    assert.dom(".user-signature[data-first-decorator='applied']").exists();
    assert.dom(".user-signature[data-second-decorator='applied']").exists();
  });
});
