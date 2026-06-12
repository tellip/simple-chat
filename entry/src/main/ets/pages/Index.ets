/*
 * 极简鸿蒙聊天客户端
 * 对接提供的Express服务端接口
 */
// 👇 修正：移除 HttpResponse，仅保留 http
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 👇 必须修改：改为你电脑的局域网IP+3000端口，示例：http://192.168.3.10:3000
const SERVER_URL = 'http://10.253.1.162:3000';

interface GeneratedTypeLiteralInterface_1 {
  id: number;
  content: string;
  time: string;
}

@Entry
@Component
struct Index {
  // 消息列表，存储服务端返回的所有聊天消息
  @State messageList: Array<GeneratedTypeLiteralInterface_1> = [];
  // 输入框的内容
  @State inputContent: string = '';
  // 网络请求实例（官方案例同款用法）
  private httpRequest = http.createHttp();

  aboutToAppear() {
    // 页面加载时，自动获取一次消息列表
    this.getMessageList();
  }

  aboutToDisappear() {
    // 页面销毁时，销毁请求实例，释放资源
    this.httpRequest.destroy();
  }

  /**
   * 核心方法1：获取所有聊天消息
   * 对接服务端 GET /messages 接口
   */
  async getMessageList() {
    try {
      // 官方案例同款request方法调用，不指定泛型，使用自动推断
      let response = await this.httpRequest.request(
        `${SERVER_URL}/messages`,
        {
          method: http.RequestMethod.GET,
          connectTimeout: 5000,
          readTimeout: 5000
        }
      );

      // 处理响应结果
      if (response.responseCode === 200) {
        this.messageList = JSON.parse(response.result as string);
      }
    } catch (err) {
      let error = err as BusinessError;
      console.error('获取消息失败：', error.message);
    }
  }

  /**
   * 核心方法2：发送聊天消息
   * 对接服务端 POST /send 接口
   */
  async sendMessage() {
    // 非空校验，和服务端逻辑保持一致
    if (!this.inputContent.trim()) {
      return;
    }

    try {
      // 官方案例同款POST请求配置
      let response = await this.httpRequest.request(
        `${SERVER_URL}/send`,
        {
          method: http.RequestMethod.POST,
          // 和服务端express.json()解析对应，必须设置json格式头
          header: {
            'Content-Type': 'application/json'
          },
          // 请求体，和服务端接口要求的字段一致
          extraData: {
            content: this.inputContent.trim()
          },
          connectTimeout: 5000,
          readTimeout: 5000
        }
      );

      // 发送成功处理
      if (response.responseCode === 200) {
        this.inputContent = ''; // 清空输入框
        this.getMessageList(); // 刷新消息列表
      }
    } catch (err) {
      let error = err as BusinessError;
      console.error('发送消息失败：', error.message);
    }
  }

  build() {
    Column() {
      // 顶部：标题栏
      Text('极简聊天室')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10, bottom: 10 })

      // 中间：消息列表区域
      List({ space: 8 }) {
        ForEach(this.messageList, (item: GeneratedTypeLiteralInterface_1) => {
          ListItem() {
            Column() {
              Text(item.content)
                .fontSize(16)
                .width('100%')
                .textAlign(TextAlign.Start)
              Text(item.time)
                .fontSize(12)
                .fontColor('#999999')
                .width('100%')
                .textAlign(TextAlign.End)
                .margin({ top: 4 })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
          }
        }, (item: GeneratedTypeLiteralInterface_1) => item.id.toString())
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 10 })

      // 底部：输入框+操作按钮区域
      Row() {
        TextInput({ text: this.inputContent, placeholder: '请输入聊天内容' })
          .layoutWeight(1)
          .height(40)
          .onChange((value) => {
            this.inputContent = value;
          })
          .onSubmit(() => {
            this.sendMessage();
          })

        Button('发送')
          .width(80)
          .height(40)
          .margin({ left: 8 })
          .onClick(() => {
            this.sendMessage();
          })

        Button('刷新')
          .width(80)
          .height(40)
          .margin({ left: 8 })
          .onClick(() => {
            this.getMessageList();
          })
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        bottom: 20,
        top: 10
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}