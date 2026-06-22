const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = 3000;

// 跨域配置+JSON解析
app.use(cors());
app.use(express.json());

// 定义聊天历史存储文件路径（当前目录下的 messages.json）
const HISTORY_FILE = path.join(__dirname, 'messages.json');

// 初始化：从文件加载历史消息（如果文件不存在则创建空数组）
let messageList = [];
try {
  if (fs.existsSync(HISTORY_FILE)) {
    const data = fs.readFileSync(HISTORY_FILE, 'utf8');
    messageList = JSON.parse(data);
    console.log(`✅ 已加载 ${messageList.length} 条历史消息`);
  } else {
    // 文件不存在，创建空文件
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

// 1. 发送消息接口
app.post('/send', (req, res) => {
  const { content } = req.body;
  if (!content?.trim()) {
    return res.status(400).json({ success: false, msg: '消息不能为空' });
  }

  messageList.push({
    id: Date.now(),
    content: content.trim(),
    time: new Date().toLocaleTimeString()
  });

  // 保存到文件
  saveHistoryToFile();

  res.json({ success: true });
});

// 2. 获取所有消息接口（包含历史）
app.get('/messages', (req, res) => {
  res.json(messageList);
});

// 监听所有网卡（允许局域网访问）
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ 服务端启动成功`);
  console.log(`📡 本地地址: http://localhost:${PORT}`);
  console.log(`📡 局域网地址: http://你的PC局域网IP:${PORT}`);
  console.log(`💾 历史记录文件: ${HISTORY_FILE}`);
  console.log(`⚠️  请将鸿蒙端的SERVER_URL改为上面的局域网地址`);
});