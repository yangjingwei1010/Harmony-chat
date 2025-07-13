import { VoiceRecordEnum } from '../../../models/voice'
import { abilityAccessCtrl, bundleManager, common } from '@kit.AbilityKit'
import { emitter } from '@kit.BasicServicesKit'

@Component
struct VoiceInput {
  @Consume
  voiceState: VoiceRecordEnum
  @State
  list: number[] = []

  @Consume
  transText: string

  aboutToAppear(): void {
    emitter.on('calcVoice', (res: emitter.EventData) => {
      this.calcVoice(res.data!['buffer'] as ArrayBuffer)
    })
  }

  aboutToDisappear(): void {
    emitter.off('calcVoice')
  }

  // 通过buffer计算要展示的播放
  calcVoice(buffer: ArrayBuffer) {
    try {
      // 转为16进制的buffer
      const newBuffer = new Int16Array(buffer)
      // 计算每个均分区间的大小
      const sampleSize = Math.floor(newBuffer.length / 20)
      const amplitudes: number[] = []
      // 遍历缓冲区，计算每个样本的振幅并转换为高度
      // 遍历原始缓冲区，提取每个均分区间的振幅
      for (let i = 0; i < newBuffer.length; i+=sampleSize) {
        let sum = 0
        // 计算当前均分区间内所有振幅的平均值
        for (let j = i; j < i + sampleSize; j++) {
          const sample = newBuffer[j]
          sum += Math.abs(sample)
        }
        const averageAmplitude = 120 * sum / sampleSize / 32767
        amplitudes.push(averageAmplitude < 10 ? 10 : averageAmplitude)
      }
      animateTo({duration: 100}, () => {
        this.list = amplitudes
      })
    } catch (error) {
      AlertDialog.show({
        message: error.message
      })
    }
  }

  @Builder
  getDisplayContent() {
    if(this.voiceState === VoiceRecordEnum.Cancel) {
      Row()
        .height(80)
        .width(100)
        .borderRadius(20)
        .backgroundColor($r('app.color.danger'))
        .margin({
          left: 30
        })
    }
    if(this.voiceState === VoiceRecordEnum.Recording) {
      Row({space: 2}) {
        ForEach(this.list, (v: number) => {
          Row()
            .height(v)
            .width(2)
            .borderRadius(1)
            .backgroundColor($r('app.media.background'))
        })
      }
        .height(80)
        .width(180)
        .borderRadius(20)
        .backgroundColor($r('app.color.chat_primary'))
      .justifyContent(FlexAlign.Center)
    }

    if(this.voiceState === VoiceRecordEnum.Transfer) {
      Row() {
        Text(this.transText)
          .fontSize(20)
          .fontColor($r('app.color.primary'))
      }
      .alignItems(VerticalAlign.Top)
      .padding(10)
        .height(120)
        .width(280)
        .borderRadius(20)
        .backgroundColor($r('app.color.chat_primary'))
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.getDisplayContent()
      }
      .height('100%')
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(this.voiceState === VoiceRecordEnum.Cancel ?  HorizontalAlign.Start : HorizontalAlign.Center)
      Column() {
        // 显示关闭和文本
        Row() {
          Row() {
            Image($r("app.media.ic_public_cancel"))
              .width(30)
              .height(30)
              .fillColor(this.voiceState === VoiceRecordEnum.Cancel? $r('app.color.text_primary') :$r("app.color.voice_round_font_color"))
          }
          .width(70)
          .aspectRatio(1)
          .borderRadius(35)
          .justifyContent(FlexAlign.Center)
          .backgroundColor( this.voiceState === VoiceRecordEnum.Cancel ? $r('app.color.bottom_color') : $r('app.color.voice_round_color'))
          .rotate({
            angle: -10
          })
          .scale({
            x: this.voiceState === VoiceRecordEnum.Cancel ? 1.2 : 1,
            y: this.voiceState === VoiceRecordEnum.Cancel ? 1.2 : 1
          })

          Row() {
            Text("文")
              .fontSize(24)
              .textAlign(TextAlign.Center)
              .fontColor(this.voiceState === VoiceRecordEnum.Transfer ? $r('app.color.text_primary') : $r('app.color.voice_round_font_color'))
          }
          .width(70)
          .aspectRatio(1)
          .borderRadius(35)
          .justifyContent(FlexAlign.Center)
          .backgroundColor( this.voiceState === VoiceRecordEnum.Transfer ? $r('app.color.bottom_color') : $r('app.color.voice_round_color'))
          .rotate({
            angle: 10
          })
          .scale({
            x: this.voiceState === VoiceRecordEnum.Transfer ? 1.2 : 1,
            y: this.voiceState === VoiceRecordEnum.Transfer ? 1.2 : 1
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({
          left: 40,
          right: 40
        })
        .margin({
          bottom: 30
        })

        Stack() {
          Image($r("app.media.ic_public_output"))
            .width('100%')
            .height(120)
            .fillColor(this.voiceState === VoiceRecordEnum.Recording ? $r('app.color.bottom_color') : $r('app.color.voice_round_color'))
            .scale({
              x: 1.2
            })
          Image($r("app.media.ic_public_recorder"))
            .width(30)
            .height(30)
            .fillColor(this.voiceState === VoiceRecordEnum.Recording ? $r('app.color.bottom_voice_color') : $r('app.color.bottom_color'))
        }
        .width('100%')
      }
    }
    .height('100%')
    .backgroundColor($r("app.color.voice_back_color"))

  }
}



export default VoiceInput