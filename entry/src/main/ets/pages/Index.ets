import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0001;
// ⚠️ 这里必须改为你的PC局域网IP+端口
const SERVER_URL = 'http://192.168.0.14:3000';

// 1. 显式定义正式消息数据接口
interface Message {
  id: number;
  content: string;
  time: string;
}

// 2. 显式定义临时宽松接口（仅用于承接JSON.parse结果，后续会严格过滤）
interface RawMessage {
  id?: number | string;
  content?: number | string;
  time?: number | string;
}

// 3. 显式定义临时宽松数组接口
type RawMessageArray = RawMessage[];

@Entry
@Component
struct Index {
  @State messageList: Array<Message> = [];
  @State inputText: string = '';
  private pollTimer: number | null = null;

  // 页面显示时启动消息轮询
  onPageShow(): void {
    this.fetchMessages();
    this.pollTimer = setInterval(() => this.fetchMessages(), 1000);
  }

  // 页面隐藏时停止轮询
  onPageHide(): void {
    if (this.pollTimer !== null) {
      clearInterval(this.pollTimer);
      this.pollTimer = null;
    }
  }

  // 安全的类型检查：验证正式Message结构
  private checkMessage(msg: Message): boolean {
    const hasValidId: boolean = typeof msg.id === 'number';
    const hasValidContent: boolean = typeof msg.content === 'string';
    const hasValidTime: boolean = typeof msg.time === 'string';
    return hasValidId && hasValidContent && hasValidTime;
  }

  // 安全的消息数组解析：全程使用显式类型
  private parseMessageArray(rawString: string): Array<Message> {
    let resultArray: Array<Message> = [];

    try {
      // 4. 关键修复：JSON.parse后立即转成显式的RawMessageArray
      const parsed: RawMessageArray = JSON.parse(rawString) as RawMessageArray;

      // 检查是否为数组（虽然RawMessageArray本身是数组，但JSON.parse可能返回非数组）
      if (Array.isArray(parsed)) {
        // 遍历并验证每一项
        for (let i = 0; i < parsed.length; i++) {
          const rawItem: RawMessage = parsed[i];
          // 先转成Message再检查（因为我们只关心这三个字段）
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

  // 拉取最新消息
  private fetchMessages(): void {
    const httpRequest = http.createHttp();
    httpRequest.request(`${SERVER_URL}/messages`, {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING // 始终以字符串形式获取
    }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err && data.responseCode === 200) {
        const rawData: string = data.result as string;
        this.messageList = this.parseMessageArray(rawData);
      } else {
        hilog.error(DOMAIN, 'Chat', '拉取消息失败: %{public}s', JSON.stringify(err));
      }
      httpRequest.destroy();
    });
  }

  // 发送消息
  private sendMessage(): void {
    if (this.inputText.trim().length === 0) {
      return;
    }

    const httpRequest = http.createHttp();
    httpRequest.request(`${SERVER_URL}/send`, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: JSON.stringify({ content: this.inputText }),
      expectDataType: http.HttpDataType.STRING
    }, (err: BusinessError, data: http.HttpResponse) => {
      if (!err && data.responseCode === 200) {
        this.inputText = '';
      } else {
        hilog.error(DOMAIN, 'Chat', '发送消息失败: %{public}s', JSON.stringify(err));
      }
      httpRequest.destroy();
    });
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