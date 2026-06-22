import { webSocket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';

const DOMAIN = 0x0001;
// ⚠️ 协议改为 ws://，IP替换为你的PC局域网IP
const SERVER_URL = 'ws://192.168.0.14:3000';

// 正式消息数据接口
interface Message {
  id: number;
  content: string;
  time: string;
}

// 临时宽松接口，用于类型安全校验
interface RawMessage {
  id?: number | string;
  content?: number | string;
  time?: number | string;
}

type RawMessageArray = RawMessage[];

// WebSocket服务端推送消息结构
interface WsHistoryMsg {
  type: 'history';
  data: RawMessageArray;
}

interface WsNewMsg {
  type: 'newMessage';
  data: RawMessage;
}

type WsReceivedMsg = WsHistoryMsg | WsNewMsg;

@Entry
@Component
struct Index {
  @State messageList: Array<Message> = [];
  @State inputText: string = '';
  private ws: webSocket.WebSocket | null = null;
  // 手动维护连接状态，替代浏览器端readyState
  private isConnected: boolean = false;

  // 页面显示时建立WebSocket连接
  onPageShow(): void {
    this.initWebSocket();
  }

  // 页面隐藏时关闭连接，释放资源
  onPageHide(): void {
    this.closeWebSocket();
  }

  /**
   * 初始化WebSocket连接
   */
  private initWebSocket(): void {
    // 先关闭已有连接，避免重复连接
    this.closeWebSocket();

    try {
      this.ws = webSocket.createWebSocket();

      // 连接成功回调
      this.ws.on('open', (err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN, 'Chat', '连接失败: %{public}s', JSON.stringify(err));
          this.isConnected = false;
          return;
        }
        hilog.info(DOMAIN, 'Chat', 'WebSocket连接成功');
        this.isConnected = true;
      });

      // 接收服务端消息：标准双参数回调（错误对象 + 消息数据）
      this.ws.on('message', (err: BusinessError, data: string | ArrayBuffer) => {
        if (err) {
          hilog.error(DOMAIN, 'Chat', '接收消息错误: %{public}s', JSON.stringify(err));
          return;
        }

        // 统一转成字符串
        let rawString: string = '';
        if (typeof data === 'string') {
          rawString = data;
        } else {
          const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
          rawString = decoder.decodeToString(new Uint8Array(data));
        }
        this.handleWebSocketMessage(rawString);
      });

      // 连接错误回调
      this.ws.on('error', (err: BusinessError) => {
        hilog.error(DOMAIN, 'Chat', '连接异常: %{public}s', JSON.stringify(err));
        this.isConnected = false;
      });

      // 连接关闭回调
      this.ws.on('close', (err: BusinessError) => {
        hilog.info(DOMAIN, 'Chat', 'WebSocket连接已关闭');
        this.isConnected = false;
      });

      // 发起连接
      this.ws.connect(SERVER_URL);
    } catch (e) {
      hilog.error(DOMAIN, 'Chat', '创建WebSocket失败: %{public}s', JSON.stringify(e));
    }
  }

  /**
   * 关闭WebSocket连接
   */
  private closeWebSocket(): void {
    if (this.ws) {
      try {
        this.ws.close();
      } catch (e) {
        hilog.error(DOMAIN, 'Chat', '关闭连接异常: %{public}s', JSON.stringify(e));
      }
      this.ws = null;
      this.isConnected = false;
    }
  }

  /**
   * 处理WebSocket收到的消息
   */
  private handleWebSocketMessage(rawString: string): void {
    try {
      // 显式类型断言，消除隐式any
      const msg: WsReceivedMsg = JSON.parse(rawString) as WsReceivedMsg;
      if (msg.type === 'history') {
        // 全量历史消息，替换列表
        this.messageList = this.parseMessageArray(JSON.stringify(msg.data));
      } else if (msg.type === 'newMessage') {
        // 单条新消息，追加到列表
        const rawItem: RawMessage = msg.data;
        const candidate: Message = {
          id: typeof rawItem.id === 'number' ? rawItem.id : 0,
          content: typeof rawItem.content === 'string' ? rawItem.content : '',
          time: typeof rawItem.time === 'string' ? rawItem.time : ''
        };
        if (this.checkMessage(candidate)) {
          this.messageList.push(candidate);
        }
      }
    } catch (e) {
      hilog.error(DOMAIN, 'Chat', '消息解析异常');
    }
  }

  // 类型校验：验证Message结构合法性
  private checkMessage(msg: Message): boolean {
    const hasValidId: boolean = typeof msg.id === 'number';
    const hasValidContent: boolean = typeof msg.content === 'string';
    const hasValidTime: boolean = typeof msg.time === 'string';
    return hasValidId && hasValidContent && hasValidTime;
  }

  // 安全解析消息数组
  private parseMessageArray(rawString: string): Array<Message> {
    let resultArray: Array<Message> = [];
    try {
      const parsed: RawMessageArray = JSON.parse(rawString) as RawMessageArray;
      if (Array.isArray(parsed)) {
        for (let i = 0; i < parsed.length; i++) {
          const rawItem: RawMessage = parsed[i];
          const candidate: Message = {
            id: typeof rawItem.id === 'number' ? rawItem.id : 0,
            content: typeof rawItem.content === 'string' ? rawItem.content : '',
            time: typeof rawItem.time === 'string' ? rawItem.time : ''
          };
          if (this.checkMessage(candidate)) {
            resultArray.push(candidate);
          }
        }
      }
    } catch (e) {
      hilog.error(DOMAIN, 'Chat', '数据解析异常');
    }
    return resultArray;
  }

  /**
   * 发送消息（WebSocket通道）
   */
  private sendMessage(): void {
    if (!this.inputText.trim()) return;
    if (!this.ws || !this.isConnected) {
      hilog.error(DOMAIN, 'Chat', 'WebSocket未连接，发送失败');
      return;
    }

    try {
      const sendData: string = JSON.stringify({
        type: 'send',
        content: this.inputText.trim()
      });
      this.ws.send(sendData);
      this.inputText = '';
    } catch (e) {
      hilog.error(DOMAIN, 'Chat', '发送消息失败: %{public}s', JSON.stringify(e));
    }
  }

  build() {
    Column({ space: 12 }) {
      // 消息列表
      List({ space: 8 }) {
        ForEach(this.messageList, (item: Message) => {
          ListItem() {
            Column({ space: 4 }) {
              Text(item.content)
                .fontSize(16)
                .padding(12)
                .backgroundColor('#E3F2FD')
                .borderRadius(8)
                .alignSelf(ItemAlign.Start);
              Text(item.time)
                .fontSize(12)
                .fontColor('#999999')
                .alignSelf(ItemAlign.Start);
            }
            .width('90%')
          }
        }, (item: Message) => item.id.toString())
      }
      .layoutWeight(1)
      .width('100%')
      .padding(16)

      // 输入框+发送按钮
      Row({ space: 12 }) {
        TextInput({ text: this.inputText, placeholder: '输入消息' })
          .layoutWeight(1)
          .height(48)
          .onChange((value: string) => {
            this.inputText = value;
          })
          .onSubmit(() => {
            this.sendMessage();
          })
        Button('发送')
          .height(48)
          .onClick(() => {
            this.sendMessage();
          })
      }
      .padding(16)
      .width('100%')
    }
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}