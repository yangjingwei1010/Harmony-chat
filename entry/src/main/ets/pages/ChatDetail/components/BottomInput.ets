import { VoiceRecordEnum } from '../../../models/voice'
import VoiceInput from './VoiceInput'
import { display, promptAction } from '@kit.ArkUI'
import { abilityAccessCtrl, bundleManager, common } from '@kit.AbilityKit'
import { AudioCapture } from '../../../utils/AudioCapture'
import { FileOperate } from '../../../utils/FileOperate'
import { currentUser, UserInfo } from '../../../models/users'
import { MessageInfo, MessageInfoModel, MessageTypeEnum } from '../../../models/messages'
import { PopupItem } from '../../../models/PopupItem'
import { fileIo, picker } from '@kit.CoreFileKit'
import { camera, cameraPicker } from '@kit.CameraKit'
import Location from './Location'
import { VoiceTransfer } from '../../../utils/VoiceTransfer'
import { JSON } from '@kit.ArkTS'


@Component
@Preview
struct BottomInput {
  @State
  showVoice: boolean = false
  @State
  content: string = ''
  @State
  showVoiceComp: boolean = false
  // 录音状态, 默认录制中
  @Provide
  voiceState: VoiceRecordEnum = VoiceRecordEnum.Recording
  screenWidth: number = 0
  screenHeight: number = 0
  tempAudioPath: string = ''
  timer: number | null = null
  isStartTimer: boolean = false
  duration: number = 0
  // 是否展示地图
  @State
  showLocation: boolean = false
  @State
  bottomList: PopupItem[] = [
    {
      icon: $r('app.media.ic_public_photo'),
      title: '照片',
      itemClick: () => {
        this.sendPhoto()
      }
    },
    {
      icon: $r('app.media.ic_public_carema'),
      title: '拍摄',
      itemClick: () => {
        this.openCamera()
      }

    },
    {
      icon: $r('app.media.ic_statusbar_gps'),
      title: '位置',
      itemClick: () => {
        this.showLocation = true
      }
    },
    {
      icon: $r('app.media.ic_public_voice'),
      title: '语音输入',

    },
    {
      icon: $r("app.media.ic_public_collect"),
      title: '收藏',

    },
    {
      icon: $r("app.media.ic_public_contacts_filled"),
      title: '个人名片',

    },
    {
      icon: $r("app.media.ic_public_folder_filled"),
      title: '文件',

    },
    {
      icon: $r("app.media.ic_public_music_filled"),
      title: '音乐',
    }
  ]
  @State
  showBottomCard: boolean = false // 显示底部
  @State
  currentAddress: string = ''
  @Provide
  transText: string = ''
  // 属性，可以接收传值 文字消息
  sendTextMessage: (content: string) => void = () => {
  }
  // 发送语音消息
  sendVoiceMessage: (message: MessageInfoModel) => void = () => {
  }
  // 发送图片
  sendImageList: (messageList: MessageInfoModel[]) => void = () => {
  }

  // 打开相机
  async openCamera() {
    try {
      let pickerProfile: cameraPicker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      }
      let pickerResult: cameraPicker.PickerResult = await cameraPicker.pick(getContext(),
        [cameraPicker.PickerMediaType.PHOTO, cameraPicker.PickerMediaType.VIDEO], pickerProfile
      )
      // promptAction.showDialog({
      //   message: JSON.stringify(pickerResult)
      // })
      if (pickerResult.resultUri !== '' && pickerResult.mediaType === 'photo') {
        const newFileName = getContext().filesDir + '/' + Date.now() + '.jpg'
        const file = fileIo.openSync(pickerResult.resultUri, fileIo.OpenMode.READ_ONLY)
        fileIo.copyFileSync(file.fd, newFileName)
        const newMessage = new MessageInfoModel({
          connectUser: this.talker,
          sendUser: currentUser,
          messageContent: '[图片]',
          messageType: MessageTypeEnum.IMAGE,
          sourceFilePath: newFileName
        } as MessageInfo)
        this.sendImageList([newMessage])
      } else if (pickerResult.resultUri !== '' && pickerResult.mediaType === 'video') {
        const videoPath = getContext().filesDir + '/' + Date.now() + '.mp4'
        const file = fileIo.openSync(pickerResult.resultUri, fileIo.OpenMode.READ_ONLY)
        fileIo.copyFileSync(file.fd, videoPath) // 拷贝文件
        const newMessage = new MessageInfoModel({
          connectUser: this.talker,
          sendUser: currentUser,
          messageContent: '[视频]',
          messageType: MessageTypeEnum.VIDEO,
          sourceFilePath: videoPath
        } as MessageInfo)
        this.sendImageList([newMessage])
      }
    } catch (err) {
      promptAction.showDialog({
        message: '相机打开失败'
      })
    }
  }

  // 发送照片
  async sendPhoto() {
    const photo = new picker.PhotoViewPicker()
    const result = await photo.select({
      maxSelectNumber: 9,
      MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE
    })
    if (result.photoUris.length) {
      let imageList: MessageInfoModel[] = []
      result.photoUris.forEach(item => {
        const file = fileIo.openSync(item, fileIo.OpenMode.READ_ONLY)
        let newFileName = getContext().filesDir + '/' + Date.now() + '.jpg'
        fileIo.copyFileSync(file.fd, newFileName)
        const newMess = new MessageInfoModel({
          connectUser: this.talker,
          sendUser: currentUser,
          messageContent: '[图片]',
          messageType: MessageTypeEnum.IMAGE,
          sourceFilePath: newFileName
        } as MessageInfo)
        imageList.push(newMess)
        fileIo.closeSync(file.fd)
      })
      // 调用父组件的方法加入消息列表
      this.sendImageList(imageList)
      animateTo({ duration: 150 }, () => {
        this.showBottomCard = false
      })
    }
  }

  async checkPermission() {
    try {
      const manager = abilityAccessCtrl.createAtManager() // 创建程序控制管理器
      // 获取应用信息
      const buildInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      const status = manager.checkAccessTokenSync(buildInfo.appInfo?.accessTokenId, "ohos.permission.MICROPHONE")
      if (status === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        // 不被允许，跳转应用设置
        const context = getContext() as common.UIAbilityContext
        context.startAbility({
          bundleName: 'com.huawei.hmos.settings',
          abilityName: 'com.huawei.hmos.settings.MainAbility',
          uri: "application_info_entry",
          parameters: {
            pushParams: buildInfo.name
          }
        })
      } else {
        this.showVoiceComp = true
        //   开始录音
        this.beginCollectVoice()
      }
    } catch (error) {
      // AlertDialog.show({
      //   message: '打开系统录音失败'
      // })
      this.showVoiceComp = true
      //   开始录音
      this.beginCollectVoice()
    }
  }

  @Prop
  talker: UserInfo

  // 开启录音
  beginCollectVoice() {
    this.startTimer()
    this.tempAudioPath = FileOperate.createAudioFile(this.talker.user_id)
    AudioCapture.start(this.tempAudioPath)
  }

  // 结束录音
  stopCollectVoice() {
    this.endTimer()
    AudioCapture.stop()
  }

  // 开始计时
  startTimer() {
    if (this.isStartTimer === true) {
      return
    }
    this.timer = setInterval(() => {
      this.duration++
      promptAction.showToast({
        message: `当前语音：${this.duration}秒`
      })
    }, 1000)
    this.isStartTimer = true
  }

  // 结束计时
  endTimer() {
    clearInterval(this.timer)
    this.timer = null
    this.isStartTimer = false
  }

  releaseFinger() {
    this.showVoiceComp = false
    this.stopCollectVoice()
    if (this.voiceState === VoiceRecordEnum.Cancel) {
      // 取消录音
      FileOperate.delFilePath(this.tempAudioPath)
      this.duration = 0
    } else if (this.voiceState === VoiceRecordEnum.Transfer) {
      if (this.transText) {
        this.sendTextMessage(this.transText)
        this.duration = 0
        this.transText = ''
      }
    } else if (this.voiceState === VoiceRecordEnum.Recording) {
      if (this.duration < 1) {
        promptAction.showToast({
          message: '时间太短'
        })
        FileOperate.delFilePath(this.tempAudioPath)
        return
      }
      // 正常录音
      const message = new MessageInfoModel({
        sourceDuration: this.duration,
        messageContent: `[语音]${this.duration}"`,
        connectUser: this.talker,
        sendUser: currentUser,
        messageType: MessageTypeEnum.AUDIO,
        sourceFilePath: this.tempAudioPath
      } as MessageInfo)
      this.sendVoiceMessage(message)
      this.tempAudioPath = ''
      this.duration = 0
    }
    // 恢复录音状态
    this.voiceState = VoiceRecordEnum.Recording
  }

  @Builder
  getLocationContent() {
    Stack({ alignContent: Alignment.Top }) {
      Location({ currentAddress: $currentAddress })
      Row() {
        Text('取消')
          .fontColor($r('app.color.text_second'))
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.showLocation = false
          })
        Button('发送')
          .type(ButtonType.Normal)
          .borderRadius(4)
          .backgroundColor($r('app.color.pay_back'))
          .fontColor($r('app.color.white'))
          .width(60)
          .height(30)
          .onClick(() => {
            if (this.currentAddress) {
              this.sendTextMessage(this.currentAddress)
            }
            this.currentAddress = ''
            this.showLocation = false
          })
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({
        left: 20,
        right: 20
      })
      .width('100%')
      .height(60)
      .margin({
        top: 50
      })
    }
    .width('100%')
  }

  @Builder
  voiceBuilder() {
    // builder内部不能直接放置自定义组件，需要先
    Column() {
      VoiceInput()
    }
  }

  @Builder
  getBottomCard(item: PopupItem) {
    Column() {
      Column() {
        Image(item.icon)
          .width(30)
          .height(30)
          .fillColor("#4c4c4c")
      }
      .backgroundColor(Color.White)
      .width(56)
      .aspectRatio(1)
      .borderRadius(10)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Text(item.title)
        .fontSize(12)
        .fontColor($r('app.color.text_second'))
        .margin({
          top: 10
        })
    }.layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      item.itemClick && item.itemClick()
    })
  }

  aboutToAppear(): void {
    this.screenWidth = px2vp(display.getDefaultDisplaySync().width)
    this.screenHeight = px2vp(display.getDefaultDisplaySync().height)
    AudioCapture.init()
  }

  aboutToDisappear(): void {
    AudioCapture.release()
  }

  build() {
    Column() {
      Row({ space: 10 }) {
        Image(this.showVoice ? $r('app.media.ic_public_keyboard') : $r('app.media.ic_public_sound'))
          .width(25)
          .aspectRatio(1)
          .onClick(() => {
            this.showVoice = !this.showVoice
            if (!this.showVoice) {
              animateTo({ duration: 150 }, () => {
                this.showBottomCard = false
              })
            }
          })
        if (!this.showVoice) {
          TextInput({ text: $$this.content })
            .height(35)
            .layoutWeight(1)
            .borderRadius(2)
            .backgroundColor($r('app.color.white'))
            .id('input')
            .focusable(!this.showBottomCard)
            .defaultFocus(true)
            .onSubmit(() => {
              this.sendTextMessage(this.content)
              this.content = ''
              focusControl.requestFocus('input')
            })
            .onClick(() => {
              animateTo({ duration: 150 }, () => {
                this.showBottomCard = false
              })
            })
        } else {
          Button('按住 说话')
            .type(ButtonType.Normal)
            .backgroundColor($r('app.color.white'))
            .borderRadius(2)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .gesture(
              GestureGroup(GestureMode.Parallel,
                LongPressGesture()
                  .onAction(() => {
                    this.checkPermission()
                  })
                  .onActionEnd(() => {
                    // this.showVoiceComp = false
                    // this.voiceState = VoiceRecordEnum.Recording
                    this.releaseFinger()
                  }),
                PanGesture()
                  .onActionUpdate((event) => {
                    if (event.fingerList[0].globalY > this.screenHeight - 120) {
                      this.voiceState = VoiceRecordEnum.Recording
                    } else {
                      if (event.fingerList[0].globalX < this.screenWidth / 2) {
                        // 录制
                        this.voiceState = VoiceRecordEnum.Cancel
                      } else {
                        // 转文字
                        this.voiceState = VoiceRecordEnum.Transfer
                        // 文本转换
                        VoiceTransfer.voiceToText(this.tempAudioPath, (text) => {
                          this.transText = text.result
                        })
                      }
                    }
                  })
                  .onActionEnd(() => {
                    this.voiceState = VoiceRecordEnum.Recording
                  })
              )
            )
        }
        Image($r('app.media.ic_public_add_norm'))
          .width(25)
          .aspectRatio(1)
          .onClick(() => {
            animateTo({ duration: 150 }, () => {
              this.showBottomCard = !this.showBottomCard
            })
          })
      }
      .width('100%')
      .height(60)
      .padding({
        left: 10,
        right: 10
      })
      .bindContentCover($$this.showLocation, this.getLocationContent())

      if (this.showBottomCard) {
        // 底部结构
        GridRow({ columns: 4 }) {
          ForEach(this.bottomList, (item: PopupItem) => {
            GridCol() {
              this.getBottomCard(item)
            }.height(100)
          })
        }
        .width('100%')

      }
    }
    .backgroundColor($r('app.color.second_back_color'))
    .bindContentCover($$this.showVoiceComp, this.voiceBuilder, {
      modalTransition: ModalTransition.NONE
    })
  }
}

export default BottomInput