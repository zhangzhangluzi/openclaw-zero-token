# 豆包重构总结

## 重构目标

按照 Claude 的模式重构豆包代码，采用浏览器上下文方案，实现与 Claude 一致的架构。

## 核心改进

### 1. 使用浏览器上下文执行请求

**之前（错误）**：
```typescript
// 在 Node.js 中直接 fetch，需要手动拼接 Cookie 和参数
const response = await fetch(url, {
  headers: {
    "Cookie": `sessionid=${sessionid}; ttwid=${ttwid}`,
    // 需要手动添加大量参数
  },
});
```

**现在（正确）**：
```typescript
// 在浏览器上下文中执行，浏览器自动处理一切
const responseData = await page.evaluate(
  async ({ baseUrl, body }) => {
    const res = await fetch(url, {
      method: "POST",
      headers: { ... },
      body: JSON.stringify(body),
    });
    // 浏览器自动：
    // - 携带所有 Cookie
    // - 生成浏览器指纹
    // - 添加动态参数（msToken, a_bogus 等）
    // - 处理 TLS 指纹
    return { ok: true, data: fullText };
  },
  { baseUrl, body }
);
```

### 2. 简化认证参数

**之前**：需要捕获 13 个参数
```typescript
interface DoubaoAuth {
  sessionid: string;
  ttwid?: string;
  userAgent: string;
  msToken?: string;      // ❌ 不再需要
  a_bogus?: string;      // ❌ 不再需要
  fp?: string;           // ❌ 不再需要
  tea_uuid?: string;     // ❌ 不再需要
  device_id?: string;    // ❌ 不再需要
  web_tab_id?: string;   // ❌ 不再需要
  aid?: string;          // ❌ 不再需要
  version_code?: string; // ❌ 不再需要
  pc_version?: string;   // ❌ 不再需要
  region?: string;       // ❌ 不再需要
  language?: string;     // ❌ 不再需要
}
```

**现在**：只需要 4 个参数
```typescript
interface DoubaoAuth {
  sessionid: string;  // ✅ 核心认证 token
  ttwid?: string;     // ✅ 可选辅助 token
  userAgent: string;  // ✅ 用户代理
  cookie?: string;    // ✅ 完整 cookie 字符串
}
```

### 3. 保持浏览器连接

**之前**：
- 登录时启动浏览器
- 捕获 Cookie 后立即关闭浏览器
- 后续请求在 Node.js 中执行

**现在**：
- 登录时启动浏览器
- 保持浏览器连接（不关闭）
- 所有请求都在浏览器中执行

## 修改的文件

### 新增文件
1. `src/providers/doubao-web-client-browser.ts` - 新的浏览器客户端（参考 Claude）

### 修改文件
1. `src/providers/doubao-web-auth.ts` - 简化认证流程
2. `src/agents/doubao-web-stream.ts` - 使用新的浏览器客户端
3. `src/commands/auth-choice.apply.doubao-web.ts` - 简化配置流程
4. `src/commands/auth-choice.apply.ts` - 更新认证选项
5. `src/commands/auth-choice-options.ts` - 更新认证选项
6. `src/commands/onboard-types.ts` - 更新类型定义
7. `src/agents/model-auth.ts` - 更新环境变量处理
8. `src/commands/onboard-auth.config-core.ts` - 更新配置函数
9. `src/agents/models-config.providers.ts` - 更新提供者配置

### 删除文件
无需删除文件，所有功能都整合到浏览器方案中。

## 技术对比

| 特性 | 旧实现 | 新实现 |
|------|--------|--------|
| **请求执行环境** | Node.js | 浏览器上下文 |
| **认证参数数量** | 13 个 | 4 个 |
| **浏览器生命周期** | 登录后关闭 | 保持连接 |
| **动态参数处理** | 手动捕获和维护 | 浏览器自动生成 |
| **反爬虫绕过** | 容易被拦截 | 可以绕过 |
| **代码复杂度** | 高 | 低 |
| **维护成本** | 高（参数可能变化） | 低（浏览器自动处理） |

## 使用方式

### 配置豆包

```bash
pnpm run openclaw onboard
```

选择：
1. Model Provider → **Doubao**
2. Auth Mode → **Automated Login** (推荐) 或 **Manual Paste**

### 自动登录流程

1. 浏览器自动打开豆包网站
2. 用户扫码登录
3. 自动捕获 sessionid 和 ttwid
4. 保存认证信息
5. 浏览器保持连接（不关闭）

### 手动配置流程

1. 在浏览器中登录 https://www.doubao.com/chat/
2. F12 → Application → Cookies
3. 复制 `sessionid` 和 `ttwid`（可选）
4. 粘贴到配置中

## 优势

1. **更简单**：只需要 sessionid，不需要一堆动态参数
2. **更稳定**：浏览器自动处理参数，不会因为豆包 API 变化而失效
3. **更安全**：完整的浏览器环境，不容易被识别为爬虫
4. **更易维护**：代码更简洁，参考 Claude 的成熟实现

## 与 Claude 的一致性

现在豆包的实现完全参考 Claude：

| 方面 | Claude | 豆包（新） |
|------|--------|-----------|
| 浏览器客户端 | `claude-web-client-browser.ts` | `doubao-web-client-browser.ts` |
| 请求方式 | `page.evaluate()` | `page.evaluate()` |
| 认证参数 | sessionKey + cookie | sessionid + ttwid + cookie |
| 浏览器生命周期 | 保持连接 | 保持连接 |
| SSE 解析 | 在流处理中解析 | 在流处理中解析 |

## 测试建议

1. 测试自动登录流程
2. 测试手动配置流程
3. 测试流式响应解析
4. 测试长时间会话（浏览器保持连接）
5. 对比与 Claude 的行为一致性

## 注意事项

1. 需要保持浏览器进程运行
2. 如果浏览器崩溃，需要重新登录
3. sessionid 有效期取决于豆包的会话策略
4. 建议定期检查认证状态

## 后续优化

1. 添加自动重连机制
2. 添加会话过期检测
3. 优化错误处理
4. 添加更详细的日志
