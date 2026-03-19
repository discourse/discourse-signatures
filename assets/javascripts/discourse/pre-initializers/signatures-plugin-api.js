import { withPluginApi } from "discourse/lib/plugin-api";
import {
  addSignatureDecorator,
  resetSignatureDecorators,
} from "discourse/plugins/discourse-signatures/discourse/components/post-signature";

/**
 * Callback used to decorate a signature
 *
 * @callback PluginApi~decorateCookedSignatureCallback
 * @param {HTMLElement} element - The signature DOM element
 * @param {Object} helper - Decorator helper object
 * @param {Object} post - The post model containing the signature
 */

/**
 * Decorate a cooked signature element
 *
 * @memberof PluginApi
 * @instance
 * @function decorateCookedSignature
 * @param {PluginApi~decorateCookedSignatureCallback} decorator
 * @example
 *
 * api.decorateCookedSignature((element, helper, post) => {
 *   element.classList.add('decorated-signature');
 * });
 */

export default {
  name: "signatures-plugin-api",
  after: "inject-discourse-objects",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.signatures_enabled) {
      return;
    }

    withPluginApi((api) => {
      const apiPrototype = Object.getPrototypeOf(api);

      if (!apiPrototype.hasOwnProperty("decorateCookedSignature")) {
        Object.defineProperty(apiPrototype, "decorateCookedSignature", {
          value(decorator) {
            addSignatureDecorator(decorator);
          },
        });
      }
    });
  },

  teardown() {
    resetSignatureDecorators();
  },
};
