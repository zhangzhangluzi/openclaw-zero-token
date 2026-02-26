# DeepSeek 与 Claude/豆包实现差异分析

## 执行时间
2025-02-26

## 分析目标
研究 DeepSeek 是否可以采用与 Claude/豆包相同的浏览器方案（在浏览器上下文中执行请求）

---

## 核心差异对比

### 1. 请求执行环境

| 提供商 | 执行环境 | 实现方式 |
|--------|---------|---------|
| **Claude** | 浏览器上下文 | `page.evaluate()` 在浏览器中执行 fetch |
| **豆包** | 浏览器上下文 | `page.evaluate()` 在浏览器中执行 fetch |
| **DeepSeek** | Node.js | 直接在 Node.js 中使用 `fetch()` |

### 2. 浏览器生命周期

| 提供商 | 浏览器管理 | 说明 |
|--------|-----------|------|
| **Claude** | 保持连接 | 浏览器在整个会话期间保持运行 |
| **豆包** | 保持连接 | 浏览器在整个会话期间保持运行 |
| **DeepSeek** | 登录后关闭 | 只在登录时使用浏览器，捕获凭证后关闭 |

### 3. 认证参数

| 提供商 | 需要的参数 | 动态参数处理 |
|--------|-----------|-------------|
| **Claude** | sessionKey, cookie, userAgent | 浏览器自动生成 |
| **豆包** | sessionid, ttwid, cookie, userAgent | 浏览器自动生成（msToken, a_bogus, fp 等） |
| **DeepSeek** | cookie, bearer, userAgent | 无需动态参数 |

### 4. 反爬虫机制

| 提供商 | 反爬虫类型 | 绕过方式 |
|--------|-----------|---------|
| **Claude** | Cloudflare | 在浏览器上下文中执行请求 |
| **豆包** | 字节跳动反爬虫 | 在浏览器上下文中执行请求，浏览器自动生成动态参数 |
| **DeepSeek** | PoW (Proof of Work) | WASM SHA3 计算 + 自定义算法 |

---

## DeepSeek 的特殊性

### PoW 挑战机制

DeepSeek 使用了独特的 **Proof of Work (PoW)** 反爬虫机制：

1. **创建挑战**：调用 `/api/v0/chat/create_pow_challenge` 获取挑战参数
   ```typescript
   {
     algorithm: "sha256" | "DeepSeekHashV1",
     challenge: string,
     difficulty: number,
     salt: string,
     signature: string,
     expire_at?: number
   }
   ```

2. **计算答案**：
   - **SHA256**：使用 Node.js crypto 模块计算
   - **DeepSeekHashV1**：使用嵌入的 WASM 模块计算（自定义算法）

3. **提交答案**：在请求头中添加 `x-ds-pow-response`（Base64 编码的挑战+答案）

### WASM 模块

DeepSeek 使用了一个嵌入的 WASM 模块来计算 PoW：
- 模块大小：约 3KB（Base64 编码）
- 功能：实现 DeepSeekHashV1 算法
- 优势：计算速度快，难以逆向

---

## 是否可以采用浏览器方案？

### 分析结论：**可以，但收益有限**

### 原因分析

#### 1. DeepSeek 的反爬虫机制不同

**Claude/豆包的问题**：
- Cloudflare 检测 TLS 指纹、浏览器指纹
- 需要大量动态参数（msToken, a_bogus 等）
- 在 Node.js 中难以模拟

**DeepSeek 的情况**：
- 使用 PoW 挑战，不依赖浏览器指纹
- 只需要 Cookie 和 Bearer Token
- PoW 计算可以在 Node.js 中完成

#### 2. 当前实现已经很简洁

DeepSeek 当前的实现：
```typescript
// 1. 创建 PoW 挑战
const challenge = await this.createPowChallenge(targetPath);

// 2. 计算答案（Node.js 或 WASM）
const answer = await this.solvePow(challenge);

// 3. 发送请求（Node.js fetch）
const res = await fetch(url, {
  headers: {
    ...headers,
    "x-ds-pow-response": powResponse,
  },
  body: JSON.stringify(body),
});
```

这个流程：
- ✅ 不需要浏览器指纹
- ✅ 不需要动态参数
- ✅ 可以在 Node.js 中完成
- ✅ 性能好（WASM 计算快）

#### 3. 浏览器方案的潜在问题

如果改用浏览器方案：

**优势**：
- 可以绕过可能的 TLS 指纹检测
- 更接近真实浏览器行为

**劣势**：
- ❌ 需要保持浏览器连接（资源消耗）
- ❌ PoW 计算仍然需要 WASM（浏览器中也要加载）
- ❌ 增加复杂度，但收益不明显
- ❌ 当前实现已经稳定工作

---

## 推荐方案

### 保持当前实现，原因如下：

1. **DeepSeek 的反爬虫机制不依赖浏览器环境**
   - PoW 挑战可以在 Node.js 中完成
   - 不需要浏览器指纹或动态参数

2. **当前实现已经稳定**
   - 登录时使用浏览器捕获凭证
   - 后续请求在 Node.js 中执行
   - 性能好，资源消耗低

3. **浏览器方案收益有限**
   - 不会显著提高成功率
   - 反而增加复杂度和资源消耗

### 如果未来 DeepSeek 加强反爬虫

如果 DeepSeek 未来添加了类似 Cloudflare 的检测，可以考虑：

1. **混合方案**：
   - 登录和 PoW 挑战：在浏览器中执行
   - PoW 计算：在 Node.js 中执行（WASM）
   - 发送请求：在浏览器中执行

2. **完全浏览器方案**：
   - 所有请求都在浏览器中执行
   - 参考 Claude/豆包的实现

---

## 代码对比示例

### 当前 DeepSeek 实现（Node.js）

```typescript
async chatCompletions(params) {
  // 1. 创建 PoW 挑战（Node.js fetch）
  const challenge = await this.createPowChallenge(targetPath);
  
  // 2. 计算答案（Node.js WASM）
  const answer = await this.solvePow(challenge);
  
  // 3. 发送请求（Node.js fetch）
  const res = await fetch(url, {
    headers: {
      ...await this.fetchHeaders(),
      "x-ds-pow-response": powResponse,
    },
    body: JSON.stringify(body),
  });
  
  return res.body;
}
```

### 如果改用浏览器方案

```typescript
async chatCompletions(params) {
  const { page } = await this.ensureBrowser();
  
  // 在浏览器上下文中执行所有操作
  const responseData = await page.evaluate(
    async ({ url, body, headers, wasmModule }) => {
      // 1. 创建 PoW 挑战（浏览器 fetch）
      const challengeRes = await fetch(challengeUrl, { ... });
      const challenge = await challengeRes.json();
      
      // 2. 计算答案（浏览器 WASM）
      const answer = await solvePoW(challenge, wasmModule);
      
      // 3. 发送请求（浏览器 fetch）
      const res = await fetch(url, {
        headers: {
          ...headers,
          "x-ds-pow-response": btoa(JSON.stringify({ ...challenge, answer })),
        },
        body: JSON.stringify(body),
      });
      
      // 读取流式响应
      const reader = res.body.getReader();
      let fullText = "";
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        fullText += new TextDecoder().decode(value);
      }
      
      return { ok: true, data: fullText };
    },
    { url, body, headers, wasmModule: SHA3_WASM_B64 }
  );
  
  // 转换为 ReadableStream
  const encoder = new TextEncoder();
  return new ReadableStream({
    start(controller) {
      controller.enqueue(encoder.encode(responseData.data));
      controller.close();
    },
  });
}
```

**对比**：
- 浏览器方案更复杂
- 需要在浏览器中加载 WASM 模块
- 需要保持浏览器连接
- 但功能上没有明显优势

---

## 总结

### DeepSeek 与 Claude/豆包的核心差异

1. **反爬虫机制不同**：
   - Claude/豆包：依赖浏览器指纹和动态参数
   - DeepSeek：使用 PoW 挑战，不依赖浏览器环境

2. **当前实现已经足够好**：
   - DeepSeek 的 Node.js 实现简洁、稳定、高效
   - 不需要保持浏览器连接
   - PoW 计算在 Node.js 中完成

3. **建议**：
   - **保持当前实现**，不需要改用浏览器方案
   - 如果未来遇到问题，再考虑混合或完全浏览器方案

### 关键洞察

**为什么 Claude/豆包需要浏览器方案？**
- Cloudflare 和字节跳动的反爬虫检测浏览器指纹
- 需要大量动态参数，只有浏览器能自动生成

**为什么 DeepSeek 不需要？**
- PoW 挑战是计算密集型，不依赖浏览器环境
- 只需要 Cookie 和 Bearer Token
- WASM 计算可以在 Node.js 中高效完成

---

## 参考

- Claude 实现：`src/providers/claude-web-client-browser.ts`
- 豆包实现：`src/providers/doubao-web-client-browser.ts`
- DeepSeek 实现：`src/providers/deepseek-web-client.ts`
- DeepSeek 认证：`src/providers/deepseek-web-auth.ts`
