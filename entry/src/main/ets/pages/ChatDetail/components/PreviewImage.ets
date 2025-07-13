import { MessageTypeEnum } from '../../../models/messages'

@CustomDialog
struct PreviewImage {
  controller: CustomDialogController
  url: ResourceStr = ''
  type: MessageTypeEnum = MessageTypeEnum.IMAGE
  build() {
    Column() {
      if (this.type === MessageTypeEnum.IMAGE) {
        Image(this.url)
          .width('100%')
      } else if (this.type === MessageTypeEnum.VIDEO) {
        Video({
          src: this.url
        })
          .loop(true)
          .autoPlay(true)
          .controls(false)
          .width('100%')
          .height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .onClick(() => {
      this.controller.close()
    })
    .justifyContent(FlexAlign.Center)
  }
}

export default PreviewImage