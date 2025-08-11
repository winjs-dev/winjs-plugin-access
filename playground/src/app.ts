import { useAccess, access as accessApi } from 'winjs';

// 设置默认角色权限
accessApi.setRole('admin');

console.log('access getRole', accessApi.getRole())
// console.log('access hasAccess', access.hasAccess('/'))

export const access = {
  noFoundHandler({ next }) {
    const accessIds = accessApi.getAccess();
    if (!accessIds.includes('/404')) {
      accessApi.setAccess(accessIds.concat(['/404']));
    }
    next('/404');
  },
};
