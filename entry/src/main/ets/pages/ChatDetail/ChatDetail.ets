import { router } from '@kit.ArkUI'
import { it } from '@ohos/hypium'
import { MessageInfo, MessageInfoModel, MessageTypeEnum } from '../../models/messages'
import { currentUser, UserInfo } from '../../models/users'
import { AudioRender } from '../../utils/AudioRender'
import { AVPlayerClass } from '../../utils/AVPlayerClass'
import { requestMessage } from '../../utils/request'
import { StoreClass } from '../../utils/StoreClass'
import BottomInput from './components/BottomInput'
import Message from './components/Message'
import PreviewImage from './components/PreviewImage'

@Entry
@Component
struct ChatDetail {
  @State
  talker: UserInfo = {} as UserInfo
  @State
  messageList: MessageInfoModel[] = []
  @State
  talkerInputIng: boolean = false
  // 滚动条对象
  scroller: Scroller = new Scroller()
  previewType: MessageTypeEnum = MessageTypeEnum.IMAGE
  // 预览图片
  previewUrl: ResourceStr = ''
  previewController: CustomDialogController = new CustomDialogController({
    builder: PreviewImage({
      url: this.previewUrl,
      type: this.previewType
    }),
    autoCancel: false,
    customStyle: true
  })

  async sendTextMessage(content: string) {
    const message = new MessageInfoModel({
      sendUser: currentUser,
      connectUser: this.talker,
      messageContent: content,
    } as MessageInfo)
    this.messageList.push(message)
    await StoreClass.addChatMessage(this.talker.user_id, message)
    this.scroller.scrollEdge(Edge.Bottom)
    AVPlayerClass.play('send')
    this.getResponseMessage(content)
  }

  async sendVoiceMessage(message: MessageInfoModel) {
    this.messageList.push(message)
    this.scroller.scrollEdge(Edge.Bottom)
    StoreClass.addChatMessage(this.talker.user_id, message)
    AVPlayerClass.play('send')
    await this.getResponseMessage(message.messageContent)
  }

  async sendImageMessage(messageList: MessageInfoModel[]) {
    this.messageList.push(...messageList)
    this.scroller.scrollEdge(Edge.Bottom)
    messageList.forEach(item => {
      StoreClass.addChatMessage(this.talker.user_id, item)
    })
    AVPlayerClass.play('send')
  }

  async getResponseMessage(content: string) {
    // 对方正在输入
    this.talkerInputIng = true
    const result = await requestMessage(content)
    const message = new MessageInfoModel({
      sendUser: this.talker,
      connectUser: this.talker,
      messageContent: result.data.info.text
    } as MessageInfo)
    AVPlayerClass.play('information')
    this.messageList.push(message)
    await StoreClass.addChatMessage(this.talker.user_id, message)
    this.scroller.scrollEdge(Edge.Bottom)
    // 输入完成
    this.talkerInputIng = false

  }

  delMessage(messageId: string) {
    let index = this.messageList.findIndex(message => message.id === messageId)
    this.messageList.splice(index, 1)
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom)
    }, 100)
  }

  aboutToAppear(): void {
    this.talker = router.getParams() as UserInfo
    this.messageList = StoreClass.getChatMessage(this.talker.user_id)
    // 初始化播放器
    AudioRender.init()
  }

  aboutToDisappear(): void {
    AudioRender.release()
  }

  build() {
    Column() {
      Row() {
        Stack({ alignContent: Alignment.Start }) {
          Text(this.talkerInputIng ? '对方正在输入' : this.talker.username)
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
          Image($r('app.media.ic_public_arrow_left'))
            .width(30)
            .height(30)
            .onClick(() => {
              this.getUIContext().getRouter().back()
            })
        }
        .height(50)
      }
      .padding({
        left: 10,
        right: 10
      })

      // 聊天内容
      List({ space: 20, scroller: this.scroller }) {
        ForEach(this.messageList, (item: MessageInfoModel) => {
          ListItem() {
            Message({
              item: item,
              delMessage: (message) => {
                this.delMessage(message)
              },
              previewImage: () => {
                this.previewUrl = 'file://' + item.sourceFilePath
                this.previewType = item.messageType
                this.previewController.open()
              }
            })
          }
        })
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor($r('app.color.back_color'))
      .padding({
        top: 20,
        bottom: 60
      })

      BottomInput({
        talker: this.talker,
        sendTextMessage: (content) => {
          this.sendTextMessage(content)
        },
        sendVoiceMessage: (message) => {
          this.sendVoiceMessage(message)
        },
        sendImageList: (messageList) => {
          this.sendImageMessage(messageList)
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}

