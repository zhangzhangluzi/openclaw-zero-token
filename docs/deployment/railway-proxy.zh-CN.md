# 作为在线 API 中转服务部署（Railway）

> 目标：把 OpenClaw Zero Token 当作 OpenAI 兼容 API 网关使用，而不是本地助手 UI。

## 1) 推荐网关配置（对外服务）

建议配置：
- `gateway.bind = "lan"`
- `gateway.auth.mode = "token"`
- `gateway.controlUi.enabled = false`
- 通过反向代理/平台域名启用 HTTPS

示例：

```json
{
  "gateway": {
    "mode": "local",
    "port": 3001,
    "bind": "lan",
    "controlUi": { "enabled": false },
    "auth": {
      "mode": "token",
      "token": "replace-with-a-long-random-token"
    },
    "trustedProxies": ["127.0.0.1", "::1"]
  }
}
```

## 2) Railway 最小化部署

1. 新建 Railway Project 并连接仓库
2. 配置变量：

```bash
OPENCLAW_PROFILE=prod
OPENCLAW_GATEWAY_TOKEN=<一段长随机串>
OPENCLAW_STATE_DIR=/data/openclaw-state
```

3. 挂载 Volume（例如挂载到 `/data`）用于会话持久化
4. Start Command：

```bash
node openclaw.mjs gateway --allow-unconfigured --bind lan --port $PORT --auth token --token $OPENCLAW_GATEWAY_TOKEN
```

5. 用公网域名验证：

```bash
curl https://<your-railway-domain>/v1/chat/completions \
  -H "Authorization: Bearer <OPENCLAW_GATEWAY_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-web/deepseek-chat",
    "messages": [{"role": "user", "content": "ping"}],
    "stream": false
  }'
```

## 3) Railway 没有浏览器，无法 Web 登录怎么办？

Railway 无 GUI 浏览器是常见限制，推荐以下方案：

1. **本地先登录，Railway 只跑网关（推荐）**
   - 本地执行 `node openclaw.mjs onboard`
   - 生成认证状态后，同步到 Railway Volume
   - Railway 只执行 `gateway` 启动命令

2. **使用非在线浏览器依赖的链路**
   - 如 `doubao-proxy`：本地浏览器获取 `sessionid`，服务端仅做 API 转发

3. **登录刷新与在线服务分离**
   - 在可打开浏览器的环境刷新凭据
   - 再同步到 Railway 运行目录

## 4) 常见问题排查

- **重启后失效**：通常是 Volume 或 `OPENCLAW_STATE_DIR` 配置错误。
- **401/会话过期**：上游 Web 会话过期，需在可浏览器环境重新登录刷新。
- **启动要求 onboarding**：生产启动命令不要触发登录流程，只运行 `gateway`。

## 5) 构建报错：`cannot copy to non-directory: ... /app/**`

这个报错通常不是代码问题，而是 Railway 构建配置里把 **Dockerfile Path / Build Context** 误设成了带 `**` 的值。

处理方式：

1. 在 Railway 服务设置里改用 **Nixpacks**（不要强制 Dockerfile 构建）
2. 清空 Dockerfile 相关自定义路径（尤其是 `**`、`./**` 这类通配）
3. 保持仓库根目录作为构建上下文（`/`）
4. 推送后重新 Deploy（本仓库已提供 `railway.toml`）

如果你必须用 Dockerfile：
- 请提供明确存在的 Dockerfile 路径（例如 `./Dockerfile`）
- 不要在 Dockerfile 的 `COPY` 目标路径里写 `/app/**`

> 注意：Railway 控制台里的构建配置通常优先于仓库默认配置。若你已在 UI 里设置 Dockerfile 路径，可能会覆盖 `railway.toml`。
