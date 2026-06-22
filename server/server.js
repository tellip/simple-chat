const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const WebSocket = require('ws');

const app = express();
const PORT = 3000;

// 跨域配置+JSON解析
app.use(cors());
app.use(express.json());

// 定义聊天历史存储文件路径
const HISTORY_FILE = path.join(__dirname, 'messages.json');

// 初始化：从文件加载历史消息
let messageList = [];
try {
  if (fs.existsSync(HISTORY_FILE)) {
    const data = fs.readFileSync(HISTORY_FILE, 'utf8');
    messageList = JSON.parse(data);
    console.log(`✅ 已加载 ${messageList.length} 条历史消息`);
  } else {
    fs.writeFileSync(HISTORY_FILE, '[]', 'utf8');
    console.log('✅ 已创建新的历史记录文件');
  }
} catch (e) {
  console.error('⚠️  加载历史记录失败，将使用空列表:', e.message);
  messageList = [];
}

// 辅助函数：保存消息到文件
function saveHistoryToFile() {
  try {
    fs.writeFileSync(HISTORY_FILE, JSON.stringify(messageList, null, 2), 'utf8');
  } catch (e) {
    console.error('⚠️  保存历史记录失败:', e.message);
  }
}

// 广播消息给所有在线客户端
function broadcast(data) {
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(data));
    }
  });
}

// 启动HTTP服务并挂载WebSocket
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ 服务端启动成功`);
  console.log(`📡 本地地址: http://localhost:${PORT}`);
  console.log(`📡 WebSocket地址: ws://你的PC局域网IP:${PORT}`);
  console.log(`💾 历史记录文件: ${HISTORY_FILE}`);
  console.log(`⚠️  请将鸿蒙端的SERVER_URL改为ws://+局域网地址`);
});

// 创建WebSocket服务器，与HTTP服务共用端口
const wss = new WebSocket.Server({ server });

// WebSocket连接处理
wss.on('connection', (ws) => {
  console.log('✅ 新客户端已连接');

  // 连接建立后立即推送全量历史消息
  ws.send(JSON.stringify({
    type: 'history',
    data: messageList
  }));

  // 接收客户端发送的消息
  ws.on('message', (rawData) => {
    try {
      const msg = JSON.parse(rawData.toString());
      // 处理发送消息请求
      if (msg.type === 'send' && msg.content?.trim()) {
        const newMessage = {
          id: Date.now(),
          content: msg.content.trim(),
          time: new Date().toLocaleTimeString()
        };
        messageList.push(newMessage);
        saveHistoryToFile();
        // 广播新消息给所有在线客户端
        broadcast({
          type: 'newMessage',
          data: newMessage
        });
      }
    } catch (e) {
      console.error('⚠️  解析客户端消息失败:', e.message);
    }
  });

  ws.on('close', () => {
    console.log('❌ 客户端已断开连接');
  });

  ws.on('error', (err) => {
    console.error('⚠️  WebSocket连接错误:', err.message);
  });
});

// 保留原有HTTP接口（可选，用于兼容/调试）
app.post('/send', (req, res) => {
  const { content } = req.body;
  if (!content?.trim()) {
    return res.status(400).json({ success: false, msg: '消息不能为空' });
  }

  const newMessage = {
    id: Date.now(),
    content: content.trim(),
    time: new Date().toLocaleTimeString()
  };
  messageList.push(newMessage);
  saveHistoryToFile();
  broadcast({ type: 'newMessage', data: newMessage });

  res.json({ success: true });
});

app.get('/messages', (req, res) => {
  res.json(messageList);
});