import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { Mustache } from '@winner-fed/utils';
import type { IApi } from '@winner-fed/winjs';

// 获取当前模块的目录路径，兼容 ES 模块和 CommonJS
const getCurrentDir = () => {
  if (typeof __dirname !== 'undefined') {
    // CommonJS 环境
    return __dirname;
  }
  // ES 模块环境
  return dirname(fileURLToPath(import.meta.url));
};

const ACCESS_TEMPLATES_DIR = join(getCurrentDir(), '../templates');
const DIR_NAME = 'plugin-access';

export default (api: IApi) => {
  api.describe({
    key: 'access',
    config: {
      schema({ zod }) {
        return zod
          .object({
            roles: zod
              .record(zod.string(), zod.array(zod.string()))
              .describe(
                '角色与权限映射配置。键为角色名称（如 admin、user、guest），值为该角色拥有的权限路径数组。支持通配符模式（如 /users/* 匹配所有用户子路径）。权限路径用于路由和组件级别的访问控制。',
              )
              .default({}),
          })
          .describe(
            'WinJS 权限控制插件配置。提供基于角色的权限管理系统（RBAC），支持路由级和组件级的访问控制，包含同步异步权限检查、路径模式匹配等功能。',
          )
          .required();
      },
    },
    enableBy: api.EnableBy.config,
  });

  api.onGenerateFiles(() => {
    const { roles = {} } = api.config.access || {};
    const accessTpl = readFileSync(
      join(ACCESS_TEMPLATES_DIR, 'core.tpl'),
      'utf-8',
    );

    api.writeTmpFile({
      path: join(DIR_NAME, 'index.ts'),
      noPluginDir: true,
      content: Mustache.render(accessTpl, {
        roles: JSON.stringify(roles),
      }),
      context: {},
    });

    api.writeTmpFile({
      path: join(DIR_NAME, 'runtime.ts'),
      noPluginDir: true,
      content: readFileSync(join(ACCESS_TEMPLATES_DIR, 'runtime.tpl'), 'utf-8'),
    });

    api.writeTmpFile({
      path: join(DIR_NAME, 'createComponent.ts'),
      noPluginDir: true,
      content: readFileSync(
        join(ACCESS_TEMPLATES_DIR, 'createComponent.tpl'),
        'utf-8',
      ),
    });

    api.writeTmpFile({
      path: join(DIR_NAME, 'createDirective.ts'),
      noPluginDir: true,
      content: readFileSync(
        join(ACCESS_TEMPLATES_DIR, 'createDirective.tpl'),
        'utf-8',
      ),
    });

    api.writeTmpFile({
      path: join(DIR_NAME, 'types.d.ts'),
      noPluginDir: true,
      content: readFileSync(join(ACCESS_TEMPLATES_DIR, 'types.d.ts'), 'utf-8'),
    });
  });

  api.addRuntimePluginKey(() => ['access']);

  api.addRuntimePlugin(() => {
    return [`${api.paths.absTmpPath}/${DIR_NAME}/runtime.ts`];
  });
};
