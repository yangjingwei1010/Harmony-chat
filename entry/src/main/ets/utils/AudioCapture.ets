import { audio } from '@kit.AudioKit'
import { JSON } from '@kit.ArkTS'
import { fileIo } from '@kit.CoreFileKit'
import { emitter } from '@kit.BasicServicesKit'

export class AudioCapture {
  static audioCapture: audio.AudioCapturer
  static audioStreamInfo: audio.AudioStreamInfo = {
    samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000,
    channels: audio.AudioChannel.CHANNEL_1,
    sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
    encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
  }
  static audioCaptureInfo: audio.AudioCapturerInfo = {
    // 音源类型
    source: audio.SourceType.SOURCE_TYPE_MIC,
    // 采集器标志
    capturerFlags: 0
  }
  // 是否正在录制
  static recording: boolean = false

  // 初始化录音采集器
  static async init() {
    AudioCapture.audioCapture = await audio.createAudioCapturer({
      streamInfo: AudioCapture.audioStreamInfo,
      capturerInfo: AudioCapture.audioCaptureInfo
    })
  }

  // 开始录制
  static async start(filePath: string) {
    try {
      if (!AudioCapture.audioCapture) return
      let file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
      let fd = file.fd
      let bufferSize: number = fileIo.statSync(fd).size
      //监听录音器读到的数据，不断写入文件中
      AudioCapture.recording = true
      await AudioCapture.audioCapture.start()
      while (AudioCapture.recording) {
        let size = await AudioCapture.audioCapture.getBufferSize()
        let buffer = await AudioCapture.audioCapture.read(size, true)
        if (buffer) {
          // let options: FileOptions = {
          //   offset: bufferSize,
          //   length: buffer.byteLength
          // };
          fileIo.writeSync(fd, buffer, {
            offset: bufferSize,
            length: buffer.byteLength
          })
          // 通知
          emitter.emit('calcVoice', {data: {
            buffer
          }
          })
          bufferSize += buffer.byteLength
        }
      }
    } catch (err) {
      AlertDialog.show({
        message: JSON.stringify('暂不支持录音')
      })
    }
  }

  // 停止
  static async stop() {
    if (AudioCapture.audioCapture) {
      // 只有采集器状态为STATE_RUNNING或STATE_PAUSED的时候才可以停止
      if (AudioCapture.audioCapture.state === audio.AudioState.STATE_RUNNING || AudioCapture.audioCapture.state === audio.AudioState.STATE_PAUSED) {
        AudioCapture.recording = false
        await AudioCapture.audioCapture.stop()
      }
    }
  }

  // 释放资源
  static async release() {
    if (AudioCapture.audioCapture) {
      await AudioCapture.audioCapture.release()
    }
  }
}