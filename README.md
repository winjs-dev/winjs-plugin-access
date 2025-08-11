# @winner-fed/plugin-access

适配 access（权限）的 WinJS 插件，适用于 Vue3。

<p>
  <a href="https://npmjs.com/package/@winner-fed/plugin-access">
   <img src="https://img.shields.io/npm/v/@winner-fed/plugin-access?style=flat-square&colorA=564341&colorB=EDED91" alt="npm version" />
  </a>
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square&colorA=564341&colorB=EDED91" alt="license" />
  <a href="https://npmcharts.com/compare/@winner-fed/plugin-access?minimal=true"><img src="https://img.shields.io/npm/dm/@winner-fed/plugin-access.svg?style=flat-square&colorA=564341&colorB=EDED91" alt="downloads" /></a>
</p>

## 功能特性

- 🔐 基于角色的权限管理系统 (RBAC)
- 🚀 支持动态设置角色和权限
- 🛡️ 提供路由级别的权限控制
- 🎯 提供组件级别的权限控制（指令和组件）
- ⚡ 支持同步和异步权限检查
- 🔍 支持路径模式匹配（支持通配符）
- 📦 开箱即用，零配置启动
- 🔧 可配置的权限控制处理器

## 安装

```bash
npm install @winner-fed/plugin-access
```

## 基本配置

在 `.winrc.ts` 中配置插件：

```typescript
import { defineConfig } from 'win';

export default defineConfig({
  plugins: [require.resolve('@winner-fed/plugin-access')],
  access: {
    roles: {
      admin: ['/', '/admin', '/users/*'],
      normal: ['/normal', '/profile'],
      guest: ['/login', '/register']
    }
  }
});
```

## 使用方法

### 1. 路由配置

```typescript
// src/app.ts
import { access as accessApi } from 'winjs';

// 设置默认角色
accessApi.setRole('admin');

export const access = {
  noFoundHandler({ next }) {
    // 处理404页面
    const accessIds = accessApi.getAccess();
    if (!accessIds.includes('/404')) {
      accessApi.setAccess(accessIds.concat(['/404']));
    }
    next('/404');
  },
  unAccessHandler({ next }) {
    // 处理无权限访问
    next('/403');
  },
  ignoreAccess: ['/login', '/register'] // 忽略权限检查的路由
};
```

### 2. 组件中使用

#### 使用 v-access 指令

```vue
<template>
  <div>
    <!-- 只有有权限的用户才能看到 -->
    <div v-access="'/admin'">管理员内容</div>
    
    <!-- 支持动态权限 -->
    <div v-access="dynamicPath">动态内容</div>
    
    <!-- 支持通配符 -->
    <div v-access="'/users/*'">用户管理</div>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const dynamicPath = ref('/profile');
</script>
```

#### 使用 Access 组件

```vue
<template>
  <div>
    <Access id="/admin">
      <template #default>
        <div>管理员专用功能</div>
      </template>
    </Access>
  </div>
</template>
```

#### 使用 useAccess Hook

```vue
<template>
  <div>
    <div v-if="hasAdminAccess">管理员功能</div>
    <div v-if="hasUserAccess">用户功能</div>
  </div>
</template>

<script setup>
import { useAccess } from 'winjs';

const hasAdminAccess = useAccess('/admin');
const hasUserAccess = useAccess('/users/*');
</script>
```

### 3. 编程式权限控制

```typescript
import { access } from 'winjs';

// 设置角色
access.setRole('admin');

// 设置权限
access.setAccess(['/admin', '/users']);

// 检查权限（异步）
const hasAccess = await access.hasAccess('/admin');

// 检查权限（同步）
const hasAccessSync = access.hasAccessSync('/admin');

// 获取当前角色
const currentRole = access.getRole();

// 获取当前权限列表
const currentAccess = access.getAccess();

// 路径匹配
const isMatch = access.match('/users/profile', ['/users/*']);

// 设置预设权限
access.setPresetAccess(['/public', '/common']);
```

## API 文档

### 配置项

#### access.roles
- 类型：`Record<string, string[]>`
- 描述：角色与权限的映射关系

#### access.noFoundHandler
- 类型：`(params: { router, to, from, next }) => void`
- 描述：404页面处理函数

#### access.unAccessHandler
- 类型：`(params: { router, to, from, next }) => void`
- 描述：无权限访问处理函数

#### access.ignoreAccess
- 类型：`string[]`
- 描述：忽略权限检查的路由列表

### Access 对象方法

#### setRole(roleId: string | Promise<string>)
设置当前用户角色。

#### getRole(): string
获取当前用户角色。

#### setAccess(accessIds: string[] | Promise<string[]>)
设置当前用户权限列表。

#### getAccess(): string[]
获取当前用户权限列表。

#### hasAccess(path: string): Promise<boolean>
异步检查是否有指定路径的权限。

#### hasAccessSync(path: string): boolean
同步检查是否有指定路径的权限。

#### match(path: string, accessIds: string[]): boolean
检查路径是否匹配权限列表。

#### setPresetAccess(accessIds: string | string[])
设置预设权限。

#### isDataReady(): boolean
检查权限数据是否准备就绪。

### useAccess Hook

```typescript
const hasAccess = useAccess(path: string | Ref<string>): Ref<boolean>
```

返回一个响应式的权限状态。

## 高级用法

### 1. 异步权限设置

```typescript
import { access } from 'winjs';

// 异步设置角色
access.setRole(fetch('/api/user/role').then(res => res.json()));

// 异步设置权限
access.setAccess(fetch('/api/user/permissions').then(res => res.json()));
```

### 2. 动态权限更新

```typescript
import { access } from 'winjs';

// 用户登录后更新权限
function onLogin(userInfo) {
  access.setRole(userInfo.role);
  access.setAccess(userInfo.permissions);
}

// 用户登出后清空权限
function onLogout() {
  access.setRole('guest');
  access.setAccess([]);
}
```

### 3. 权限通配符

支持以下通配符模式：
- `/users/*` - 匹配 `/users/` 下的所有路径
- `/admin/*/edit` - 匹配 `/admin/任意内容/edit` 格式的路径

### 4. 权限组合

```typescript
// 预设权限 + 角色权限 + 动态权限
access.setPresetAccess(['/public', '/common']);
access.setRole('admin'); // 自动获取 admin 对应的权限
access.setAccess(['/special']); // 额外的动态权限
```

## 许可证

[MIT](./LICENSE).
