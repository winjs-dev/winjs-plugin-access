import type { NavigationGuard, NavigationGuardNext, RouteLocationNormalized, Router } from 'vue-router';

interface CustomNavigationGuardOption {
  router: Router;
  to: RouteLocationNormalized;
  from: RouteLocationNormalized;
  next: NavigationGuardNext;
}

interface CustomNavigationGuard {
  (option: CustomNavigationGuardOption): ReturnType<NavigationGuard>;
}

export interface AccessPluginRuntimeConfig {
  access?: {
    noFoundHandler?: CustomNavigationGuard;
    unAccessHandler?: CustomNavigationGuard;
    ignoreAccess?: string[];
  };
}
