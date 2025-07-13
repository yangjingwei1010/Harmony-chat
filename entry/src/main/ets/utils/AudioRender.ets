import { audio } from '@kit.AudioKit'
import { fileIo } from '@kit.CoreFileKit'

export class AudioRender {
  static renderIng: boolean = false
  static renderModel: audio.AudioRenderer
  static audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
    channels: audio.AudioChannel.CHANNEL_1,
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  }

  static audioRenderInfo: audio.AudioRendererInfo = {
    // 音频渲染器 0 普通  1 低时延 (不支持)
    rendererFlags: 0,
    // 场景
    usage: audio.StreamUsage.STREAM_USAGE_VOICE_ASSISTANT
  }
  // 创建播放器的参数准备好了
  static audioRenderOptions: audio.AudioRendererOptions = {
    streamInfo: AudioRender.audioStreamInfo,
    rendererInfo: AudioRender.audioRenderInfo
  }
  // 读取的size
  static renderSize: number = 0
  // 文件的size
  static maxSize: number = 0
  // 读取的文件
  static renderFile: fileIo.File
  // 播放的回调函数
  static renderCallBack: (() => void) | undefined
  static callBack: (() => void) | undefined
  // 初始化方法
  static async init() {
    if (!AudioRender.renderModel) {
      // 创建实例
      AudioRender.renderModel = await audio.createAudioRenderer(AudioRender.audioRenderOptions)
      // 监听事件
      AudioRender.renderModel.on('writeData', (buffer:ArrayBuffer) => {
        if(AudioRender.renderFile){
          fileIo.readSync(AudioRender.renderFile.fd, buffer, {
            offset: AudioRender.renderSize,
            length: buffer.byteLength
          })
          AudioRender.renderSize+=buffer.byteLength
          // 自动结束
          if(AudioRender.renderSize>=AudioRender.maxSize){
            fileIo.closeSync(AudioRender.renderFile.fd)
            AudioRender.stop()
          }
        }
      })
    }
  }

  static async stop() {
    if (AudioRender.renderModel && AudioRender.renderModel.state === audio.AudioState.STATE_RUNNING) {
      await AudioRender.renderModel.stop()
      AudioRender.renderSize = 0
      AudioRender.maxSize = 0
      AudioRender.callBack && AudioRender.callBack()
    }
  }

  static async start(filePath: string, callBack1?: () => void, callBack2?: () => void) {
    if (AudioRender.renderModel && filePath) {
      await AudioRender.stop()
      AudioRender.renderFile = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
      AudioRender.maxSize = fileIo.statSync(AudioRender.renderFile.fd).size
      AudioRender.renderCallBack && AudioRender.renderCallBack()
      callBack1 && callBack1()
      callBack2 && callBack2()
      await AudioRender.renderModel.start()
    }
  }

  static async release() {
    if (AudioRender.renderModel) {
      await AudioRender.stop()
      await AudioRender.renderModel.release()
    }
  }

}

// todo: 19-05分钟