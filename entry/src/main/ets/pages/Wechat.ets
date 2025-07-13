import { MessageInfoModel } from '../models/messages'
import { StoreClass } from '../utils/StoreClass'
import { promptAction, router } from '@kit.ArkUI'
import { emitter } from '@kit.BasicServicesKit'
import { FileOperate } from '../utils/FileOperate'
import { PopupItem } from '../models/PopupItem'
import { scanBarcode, scanCore } from '@kit.ScanKit'

@Component
struct WeChat {
  @State
  list: MessageInfoModel[] = []
  @State
  showDropDown: boolean = false // 显示底部浮层

  @State
  popList: PopupItem[] = [
    {
      title: '发起群聊',
      icon: $r('app.media.ic_public_message')
    },
    {
      title: '添加朋友',
      icon: $r('app.media.ic_public_add_friend')
    },
    {
      title: '扫一扫',
      icon: $r('app.media.ic_public_scan'),
      itemClick: () => {
        this.scan()// 扫码
      }
    },
    {
      title: '收付款',
      icon: $r('app.media.ic_public_receive'),
      itemClick: () => {
        this.getUIContext().getRouter().pushUrl({
          url: 'pages/PayQrCode/PayQrCode'
        })
      }
    }
  ]

  async scan() {
    let options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: true
    }
    try {
      const result = scanBarcode.startScanForResult(this.getUIContext().getHostContext(), options)
      this.showDropDown = false
    } catch (error) {
      this.getUIContext().getPromptAction().showToast({
        message: error.message
      })
    }
  }

  @Builder
  getDropDown() {
    Column() {
      ForEach(this.popList, (item: PopupItem) => {
        Row({ space: 5 }) {
          Image(item.icon)
            .fillColor($r('app.color.white'))
            .width(20)
            .height(20)
          Text(item.title)
            .fontColor(Color.White)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(48)
        .justifyContent(FlexAlign.Center)
        .padding({
          left: 10,
          right: 10
        }).onClick(() => {
          item.itemClick && item.itemClick()
        })

      })
    }
    .width(120)
  }

  @Builder
  getListEnd(userId: string) {
    Row() {
      Text('删除')
        .fontColor($r('app.color.white'))
        .width(100)
        .textAlign(TextAlign.Center)
    }
    .height(70)
    .padding({
      left: 20,
      right: 20
    })
    .backgroundColor($r('app.color.danger'))
    .onClick(async () => {
      await FileOperate.delUserPath(userId)
      StoreClass.removeChatAllMessage(userId)
    })
  }

  aboutToAppear(): void {
    this.list = StoreClass.getAllChatLastMessage()
    emitter.on(StoreClass.wechat_key, () => {
      this.list = StoreClass.getAllChatLastMessage()
    })
  }

  transTime(time: number) {
    const dateObj = new Date(time)
    const year = dateObj.getFullYear()
    const month = dateObj.getMonth()
    const date = dateObj.getDate()
    const hours = dateObj.getHours()
    const minutes = dateObj.getMinutes()
    if (year === new Date().getFullYear()) {
      if (month === new Date().getMonth()) {
        if (date === new Date().getDate()) {
          // 当天消息
          return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`
        } else {
          return `${new Date().getDate()-date}天前}`
        }
      } else {
        return `${(month + 1).toString()}月${date}日`
      }
    } else {
      return `${year}年${(month + 1).toString()}月${date}日`
    }

  }

  build() {
    Column() {
      Row() {
        Text(`微信(${this.list.length})`)
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
        Image($r('app.media.ic_public_add_norm'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.text_primary'))
          .position({
            x: '100%'
          })
          .translate({
            x: -40,
            y: 15
          })
          .bindPopup(this.showDropDown, {
            builder: this.getDropDown,
            placement: Placement.Bottom,
            onStateChange: (event) => {
              this.showDropDown = event.isVisible
            },
            popupColor: $r("app.color.popup_back"),
            backgroundBlurStyle: BlurStyle.NONE
          })
          .onClick(() => {
            this.showDropDown = true
          })

      }.width('100%')
      .justifyContent(FlexAlign.Center)
      .height(50)

      List() {
        ForEach(this.list, (item: MessageInfoModel) => {
          ListItem() {
            Row({ space: 10 }) {
              Image(item.connectUser.avatar)
                .width(50)
                .height(50)
                .borderRadius(4)

              Column({ space: 10 }) {
                Row() {
                  Text(item.connectUser.username)
                    .fontColor($r('app.color.text_primary'))
                    .fontSize(16)
                  Text(this.transTime(item.sendTime))
                    .fontSize(12)
                    .fontColor($r('app.color.text_second'))
                    .margin({
                      top: 10
                    })
                }
                .justifyContent(FlexAlign.SpaceBetween)
                .width('100%')

                Text(item.messageContent)
                  .fontColor($r('app.color.text_second'))
                  .fontSize(14)
                  .maxLines(1)
                  .textOverflow({
                    overflow: TextOverflow.Ellipsis
                  })
              }
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(HorizontalAlign.Start)
              .height(50)
              .layoutWeight(1)
              .padding({
                top: 3,
                bottom: 3
              })
            }
            .onClick(() => {
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/ChatDetail/ChatDetail',
                params: item.connectUser
              })
            })
            .stateStyles({
              normal: {
                .backgroundColor($r('app.color.white'))
              },
              pressed: {
                .backgroundColor($r('app.color.back_color'))
              }
            })
          }
          .padding({
            top: 10,
            bottom: 10
          })
          .swipeAction({
            end: this.getListEnd(item.id)
          })
        })
      }
      .divider({
        strokeWidth: 1,
        color: $r('app.color.border_color')
      })
      .padding({
        left: 10,
        right: 20
      })
    }
    .height('100%')
  }
}

export default WeChat