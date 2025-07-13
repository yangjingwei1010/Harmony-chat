import { MessageInfo, MessageInfoModel, MessageTypeEnum } from '../../../models/messages'
import { PopupItem } from '../../../models/PopupItem'
import { currentUser } from '../../../models/users'
import { AudioRender } from '../../../utils/AudioRender'
import { AVPlayerClass } from '../../../utils/AVPlayerClass'
import { FileOperate } from '../../../utils/FileOperate'
import { StoreClass } from '../../../utils/StoreClass'
import { VoiceTransfer } from '../../../utils/VoiceTransfer'

@Component
@Preview
struct Message {
  item: MessageInfoModel = new MessageInfoModel({} as MessageInfo)
  @State
  showPopup: boolean = false
  @State
  audioState: AnimationStatus = AnimationStatus.Initial
  @State
  transferResult: string = ''
  @State
  popupList: PopupItem[] = [
    {
      title: '听筒播放',
      icon: $r("app.media.ic_public_ears"),
      itemClick: () => {
        if (this.item.messageType === MessageTypeEnum.TEXT) {
          VoiceTransfer.textToVoice(this.item.messageContent)
        }
      }
    },
    {
      title: '收藏',
      icon: $r("app.media.ic_public_cube")
    },
    {
      title: '转文字',
      icon: $r("app.media.ic_public_trans_text"),
      itemClick: () => {
        if (this.item.messageType === MessageTypeEnum.AUDIO) {
          VoiceTransfer.voiceToText(this.item.sourceFilePath, (res) => {
            this.transferResult = res.result
          })
        }
        this.showPopup = false
      }
    },
    {
      title: '删除',
      icon: $r("app.media.ic_public_cancel"),
      itemClick: async () => {
        // 删除语音资源
        if (this.item.sourceFilePath) {
          FileOperate.delFilePath(this.item.sourceFilePath)
        }
        // 删除首选项
        await StoreClass.removeChatMessage(this.item.connectUser.user_id, this.item.id)
        // 删除UI列表
        this.delMessage(this.item.id)
      }
    },
    {
      title: '多选',
      icon: $r("app.media.ic_public_multi_select")
    },
    {
      title: '引用',
      icon: $r("app.media.ic_public_link")
    },
    {
      title: '提醒',
      icon: $r("app.media.ic_public_warin")
    }]

  aboutToAppear(): void {
    AudioRender.callBack = () => {
      this.audioState = AnimationStatus.Stopped
    }
  }

  @Builder
  getContent() {
    GridRow({ columns: 5 }) {
      ForEach(this.popupList, (item: PopupItem) => {
        GridCol() {
          Column({ space: 6 }) {
            Image(item.icon)
              .fillColor($r('app.color.white'))
              .width(18)
              .height(18)
            Text(item.title)
              .fontColor($r('app.color.white'))
              .fontSize(14)
          }
          .height(60)
        }
        .onClick(() => {
          // 如果点击事件存在就触发
          item.itemClick && item.itemClick()
        })
      })
    }
    .width(300)
    .padding({
      top: 15,
      left: 10
    })
  }

  // 删除消息
  delMessage: (messageId: string) => void = () => {
  }

  // 文字消息
  @Builder
  getTextContent() {
    Text(this.item.messageContent)
    // .backgroundColor($r('app.color.white'))
      .backgroundColor(this.item.sendUser.user_id === currentUser.user_id ? $r('app.color.second_primary') :
      $r('app.color.white'))
      .fontColor($r('app.color.text_primary'))
      .padding(10)
      .lineHeight(24)
      .margin({
        left: 10,
        right: 10
      })
      .borderRadius(4)
  }

  getAudioWidth() {
    let minWidth: number = 20
    let maxWidth: number = 90
    let calWidth: number = minWidth + (100 * this.item.sourceDuration / 60)
    if (calWidth > maxWidth) {
      return maxWidth + '%'
    }
    return calWidth + '%'
  }

  // 获取语音显示
  @Builder
  getAudioContent() {
    Column() {
      Row({ space: 5 }) {
        Text(`${this.item.sourceDuration}'`)
          .textAlign(TextAlign.Center)
        ImageAnimator()
          .images([
            {
              src: $r('app.media.ic_public_voice3')
            },
            {
              src: $r('app.media.ic_public_voice1')
            },
            {
              src: $r('app.media.ic_public_voice2')
            },
            {
              src: $r('app.media.ic_public_voice3')
            }
          ])
          .iterations(-1)
          .state(this.audioState)
          .fillMode(FillMode.None)
          .duration(300)
          .width(20)
          .height(20)
          .rotate({
            angle: currentUser.user_id === this.item.sendUser.user_id ? 180 : 0
          })
      }
      .width(this.getAudioWidth())
      .backgroundColor(currentUser.user_id === this.item.sendUser.user_id ? $r('app.color.chat_primary') :
      $r('app.color.white'))
      .justifyContent(currentUser.user_id === this.item.sendUser.user_id ? FlexAlign.End : FlexAlign.Start)
      .height(40)
      .padding({
        left: 10,
        right: 10
      })
      .margin({
        left: 10,
        right: 10
      })
      .borderRadius(4)
      .direction(currentUser.user_id === this.item.sendUser.user_id ? Direction.Ltr : Direction.Rtl)
      .onClick(() => {
        AudioRender.start(this.item.sourceFilePath, () => {
          this.audioState = AnimationStatus.Running
        })
      })

      if (this.transferResult) {
        Text(this.transferResult)
      }
    }
    .alignItems(currentUser.user_id === this.item.sendUser.user_id ? HorizontalAlign.End : HorizontalAlign.Start)
  }

  previewImage: () => void = () => {}

  @Builder
  getImageContent() {
    Column() {
      Image('file://' + this.item.sourceFilePath)
        .width('100%')
        .borderRadius(4)
        .enabled(false)
    }
    .width('40%')
    .margin({
      left: 10,
      right: 10
    })
    .onClick(() => {
      this.previewImage()
    })
  }

  videoController: VideoController = new VideoController()

  @Builder
  getVideoContent() {
    Column() {
      Stack() {
        Video({
          src: 'file://' + this.item.sourceFilePath,
          controller: this.videoController
        })
          .controls(false)
          .width(100)
          .height(150)
          .borderRadius(4)
          .id(this.item.id)
          .onPrepared(() => {
            this.videoController.setCurrentTime(0.1)
          })
        Image($r('app.media.ic_public_play'))
          .width(30)
          .aspectRatio(1)
          .fillColor($r('app.color.back_color'))
      }
    }
    .margin({
      left: 10,
      right: 10
    })
    .onClick(() => {
      this.previewImage()
    })
  }

  build() {
    Row() {
      Image(this.item.sendUser.avatar)
        .width(40)
        .aspectRatio(1)
        .borderRadius(6)
      Row() {
        Column() {
          if (this.item.messageType === MessageTypeEnum.TEXT) {
            this.getTextContent()
          } else if (this.item.messageType === MessageTypeEnum.AUDIO) {
            this.getAudioContent()
          } else if (this.item.messageType === MessageTypeEnum.IMAGE) {
            this.getImageContent()
          } else if (this.item.messageType === MessageTypeEnum.VIDEO) {
            this.getVideoContent()
          }
        }
        .bindPopup(this.showPopup, {
          builder: this.getContent(),
          popupColor: $r('app.color.popup_back'),
          backgroundBlurStyle: BlurStyle.NONE,
          onStateChange: (event) => {
            // 当手指点击了其他位置，关闭状态
            this.showPopup = event.isVisible
          }
        })
      }
      .layoutWeight(6)
      // .justifyContent(FlexAlign.Start)
      .justifyContent(this.item.sendUser.user_id === currentUser.user_id ? FlexAlign.End : FlexAlign.Start)

      Text().layoutWeight(1)
    }
    .width('100%')
    .padding({
      left: 20,
      right: 20
    })
    .gesture(
      LongPressGesture()
        .onAction(() => {
          this.showPopup = true
        })
    )
    .alignItems(VerticalAlign.Top)
    // .direction(Direction.Ltr)
    .direction(this.item.sendUser.user_id === currentUser.user_id ? Direction.Rtl : Direction.Ltr)
  }
}

export default Message