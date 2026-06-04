import { registerPlugin } from '@capacitor/core';
import type { FlybuyPlugin, Instance } from './definitions';

export * from './definitions';

const FlybuyNative = registerPlugin<FlybuyPlugin>('Flybuy', {
  web: () => import('./web').then((m) => new m.FlybuyWeb()),
});

/**
 * Returns a scoped accessor for a FlyBuy instance.
 * Pass null (or omit) for the primary instance, or an appAuthId string for a secondary project.
 *
 * Usage:
 *   const core = getInstance();          // primary instance
 *   const core = getInstance('139');     // secondary project
 *
 *   const { customer } = await core.customer.getCurrent();
 *   const { sites } = await core.sites.fetchByRegion({ latitude, longitude, radiusMeters });
 */
export function getInstance(appAuthId: string | null = null): Instance {
  return {
    customer: {
      getCurrent: () =>
        FlybuyNative.getCurrentCustomer({ appAuthId }),
      create: (options) =>
        FlybuyNative.createCustomer({ ...options, appAuthId }),
      login: (options) =>
        FlybuyNative.login({ ...options, appAuthId }),
      loginWithToken: (options) =>
        FlybuyNative.loginWithToken({ ...options, appAuthId }),
      logout: () =>
        FlybuyNative.logout({ appAuthId }),
      update: (options) =>
        FlybuyNative.updateCustomer({ ...options, appAuthId }),
      signUp: (options) =>
        FlybuyNative.signUp({ ...options, appAuthId }),
    },
    sites: {
      fetchByRegion: (options) =>
        FlybuyNative.fetchSitesByRegion({ ...options, appAuthId }),
      fetchByPartnerIdentifier: (options) =>
        FlybuyNative.fetchSiteByPartnerIdentifier({ ...options, appAuthId }),
      fetchNearPlace: (options) =>
        FlybuyNative.fetchSitesNearPlace({ ...options, appAuthId }),
    },
    places: {
      suggest: (options) =>
        FlybuyNative.placesSuggest({ ...options, appAuthId }),
      retrieve: (options) =>
        FlybuyNative.placesRetrieve({ ...options, appAuthId }),
    },
    parseLink: (options) =>
      FlybuyNative.parseLink(options),
  };
}