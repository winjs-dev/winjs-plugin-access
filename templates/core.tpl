import { computed, reactive, unref } from 'vue';
import type { Ref } from 'vue';
import createComponent from './createComponent';
import createDirective from './createDirective';

export interface Access {
  hasAccess: (accessId: string | number) => Promise<boolean>;
  hasAccessSync: (accessId: string | number) => boolean;
  isDataReady: () => boolean;
  setRole: (roleId: string | Promise<string>) => void;
  getRole: () => string;
  setAccess: (accessIds: Array<string | number> | Promise<Array<string | number>>) => void;
  getAccess: () => string[];
  match: (path: string, accessIds: string[]) => boolean;
  setPresetAccess: (accessId: string | string[]) => void;
}

/**
 * Checks if a given value is a plain object.
 *
 * @param {object} object - The value to check.
 * @returns {boolean} - True if the value is a plain object, otherwise false.
 *
 * @example
 * console.log(isPlainObject({})); // true
 * console.log(isPlainObject([])); // false
 * console.log(isPlainObject(null)); // false
 * console.log(isPlainObject(Object.create(null))); // true
 * console.log(Buffer.from('hello, world')); // false
 */
function isPlainObject(object: object): boolean {
  if (typeof object !== 'object') {
    return false;
  }

  if (object == null) {
    return false;
  }

  if (Object.getPrototypeOf(object) === null) {
    return true;
  }

  if (object.toString() !== '[object Object]') {
    return false;
  }

  let proto = object;

  while (Object.getPrototypeOf(proto) !== null) {
    proto = Object.getPrototypeOf(proto);
  }

  return Object.getPrototypeOf(object) === proto;
}

function isPromise(obj) {
  return (
    !!obj &&
    (typeof obj === 'object' || typeof obj === 'function') &&
    typeof obj.then === 'function'
  );
}

const state = reactive({
  roles: {{{ roles }}},
  currentRoleId: "",
  currentAccessIds: []
});
const rolePromiseList: Promise<any>[] = [];
const accessPromiseList: Promise<any>[] = [];

// 预设的 accessId
const presetAccessIds = [];
const setPresetAccess = (access) => {
  const accessIds = Array.isArray(access) ? access : [access];

  presetAccessIds.push(...accessIds.filter(id => !presetAccessIds.includes(id)));
};

const getAllowAccessIds = () => {
  const result = [...presetAccessIds, ...state.currentAccessIds];

  const roleAccessIds = state.roles[state.currentRoleId];
  if (Array.isArray(roleAccessIds) && roleAccessIds.length > 0) {
    result.push(...roleAccessIds);
  }

  return result;
};

const _syncSetAccessIds = (promise) => {
  accessPromiseList.push(promise);
  promise
    .then((accessIds) => {
      setAccess(accessIds);
    })
    .catch((e) => {
      console.error(e);
    })
    .then(() => {
      const index = accessPromiseList.indexOf(promise);
      if (index !== -1) {
        accessPromiseList.splice(index, 1);
      }
    });
};

const setAccess = (accessIds) => {
  if (isPromise(accessIds)) {
    return _syncSetAccessIds(accessIds);
  }
  if (isPlainObject(accessIds)) {
    if (accessIds.accessIds) {
      setAccess(accessIds.accessIds);
    }
    if (accessIds.roleId) {
      setRole(accessIds.roleId);
    }
    return;
  }
  if (!Array.isArray(accessIds)) {
    throw new Error('[plugin-access]: argument to the setAccess() must be array or promise or object');
  }
  state.currentAccessIds = accessIds;
};

const _syncSetRoleId = (promise) => {
  rolePromiseList.push(promise);
  promise
    .then((roleId) => {
      setRole(roleId);
    })
    .catch((e) => {
      console.error(e);
    })
    .then(() => {
      const index = rolePromiseList.indexOf(promise);
      if (index !== -1) {
        rolePromiseList.splice(index, 1);
      }
    });
};

const setRole = async (roleId) => {
  if (isPromise(roleId)) {
    return _syncSetRoleId(roleId);
  }
  if (typeof roleId !== 'string') {
    throw new Error('[plugin-access]: argument to the setRole() must be string or promise');
  }
  state.currentRoleId = roleId;
};

const match = (path, accessIds) => {
  if (path === null || path === undefined) {
    return false;
  }
  if (!Array.isArray(accessIds) || accessIds.length === 0) {
    return false;
  }
  path = path.split('?')[0];
  // 进入"/"路由时，此时path为“”
  if (path === '') {
    path = '/';
  }
  const len = accessIds.length;
  for (let i = 0; i < len; i++) {
    if (path === accessIds[i]) {
      return true;
    }
    // 支持*匹配
    const reg = new RegExp(`^${accessIds[i].replace('*', '.+')}$`);
    if (reg.test(path)) {
      return true;
    }
  }
  return false;
};

const isDataReady = () => {
  return rolePromiseList.length || accessPromiseList.length;
};

const hasAccess = async (path) => {
  if (!isDataReady()) {
    return match(path, getAllowAccessIds());
  }
  await Promise.all(rolePromiseList.concat(accessPromiseList));
  return match(path, getAllowAccessIds());
};

export const install = (app) => {
  app.directive('access', createDirective(useAccess));
  app.component('Access', createComponent(useAccess));
};

export const hasAccessSync = (path) => {
  return match(unref(path), getAllowAccessIds());
};

export const access: Access = {
  hasAccess,
  hasAccessSync,
  isDataReady,
  setRole,
  getRole: () => {
    return state.currentRoleId;
  },
  setAccess,
  match,
  getAccess: getAllowAccessIds,
  setPresetAccess
};

type UseAccessFunction = (accessId: string | number) => Ref<boolean>;

export const useAccess: UseAccessFunction = (path) => {
  const allowPageIds = computed(getAllowAccessIds);
  const result = computed(() => {
    return match(unref(path), allowPageIds.value);
  });
  return result;
};
