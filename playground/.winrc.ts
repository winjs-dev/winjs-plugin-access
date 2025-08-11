import { defineConfig } from 'win';

export default defineConfig({
  plugins: ['@winner-fed/plugin-access'],
  routes: [{
    path: '/',
    name: 'Home',
    component: 'index',
    routes: [
      {
        path: 'admin',
        name: 'Admin',
        component: '@/components/admin'
      },
      {
        path: 'normal',
        name: 'Normal',
        component: '@/components/normal'
      }
    ]
  }],
  access: {
    roles: {
      admin: ['/', '/admin'],
      normal: ['/normal']
    }
  }
});
