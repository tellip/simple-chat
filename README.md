# SimpleChat - 极简鸿蒙聊天客户端

一个基于HarmonyOS NEXT开发的极简聊天应用，提供基础的消息收发功能，对接Express后端服务。

## 📱 技术栈

- **运行平台**: HarmonyOS NEXT 6.0.2(22)
- **开发语言**: ArkTS
- **UI框架**: ArkUI
- **网络请求**: NetworkKit
- **构建工具**: Hvigor
- **测试框架**: Hypium + Hamock

## 📂 项目结构

```
SimpleChat/
├── AppScope/                    # 应用全局配置
│   ├── app.json5               # 应用基本信息
│   └── resources/              # 全局资源
├── entry/                       # 主模块
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/   # 入口Ability
│   │   │   ├── entrybackupability/ # 备份能力
│   │   │   └── pages/          # 页面组件
│   │   │       └── Index.ets   # 主聊天页面
│   │   ├── resources/          # 模块资源
│   │   │   ├── base/           # 基础资源
│   │   │   └── dark/           # 深色模式资源
│   │   └── module.json5        # 模块配置
│   ├── src/test/               # 本地单元测试
│   ├── src/ohosTest/           # 设备端测试
│   ├── src/mock/               # 模拟数据配置
│   └── build-profile.json5     # 模块构建配置
├── build-profile.json5         # 应用构建配置
├── oh-package.json5            # 依赖配置
└── code-linter.json5           # 代码检查配置
```

## 🚀 快速开始

### 环境准备

1. 安装 DevEco Studio NEXT 版本
2. 配置 HarmonyOS NEXT 开发环境
3. 准备运行设备（HarmonyOS NEXT 6.0.2 及以上）

### 运行步骤

1. 克隆项目到本地
2. 使用 DevEco Studio 打开项目
3. 修改服务端地址：
    - 打开 `entry/src/main/ets/pages/Index.ets`
    - 将 `SERVER_URL` 改为你的Express服务端地址
   ```typescript
   const SERVER_URL = 'http://你的电脑局域网IP:3000';
   ```
4. 连接设备或启动模拟器
5. 点击运行按钮启动应用

## 📸 应用截图

<!-- 请将你的截图放在项目根目录的screenshots文件夹下，或直接替换下面的src路径 -->
<img src="assets/屏幕截图 2026-06-12 161553.png" alt="极简聊天室界面截图" width="200" style="border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">

## 🔌 服务端对接

本应用需要配合Express后端服务使用，服务端需提供以下接口：

### 1. 获取消息列表
- **接口**: `GET /messages`
- **返回**: 消息数组
```json
[
  {
    "id": 1,
    "content": "消息内容",
    "time": "2026-06-12 12:00:00"
  }
]
```

### 2. 发送消息
- **接口**: `POST /send`
- **请求头**: `Content-Type: application/json`
- **请求体**:
```json
{
  "content": "要发送的消息内容"
}
```
- **返回**: 200 OK 表示发送成功

## ✨ 功能说明

- **消息展示**: 显示所有历史聊天消息，包含内容和时间戳
- **发送消息**: 输入文字后点击"发送"或按回车发送
- **刷新消息**: 点击"刷新"按钮获取最新消息列表
- **自动加载**: 页面打开时自动加载消息列表
- **资源释放**: 页面销毁时自动释放网络请求资源

## 🛠️ 开发说明

### 代码检查

项目已配置严格的代码检查规则，包括：
- TypeScript 推荐规则
- 性能优化规则
- 安全编码规则（禁止不安全的加密算法）

运行检查：
```bash
hvigorw check
```

### 测试

- **本地单元测试**: `entry/src/test/`
- **设备端测试**: `entry/src/ohosTest/`

运行测试：
```bash
hvigorw test
```

### 混淆配置

Release 模式下默认关闭混淆，如需开启：
1. 打开 `entry/build-profile.json5`
2. 将 `obfuscation.enable` 改为 `true`
3. 在 `entry/obfuscation-rules.txt` 中添加自定义规则

## 📄 许可证

本项目采用 MIT 许可证。