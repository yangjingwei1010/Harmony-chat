import { media } from '@kit.MediaKit'

export enum PlayType {
  Message,
  Video,
  Notice
}

export class AVPlayerClass {
  static player: media.AVPlayer
  static context: Context
  // 1.初始化：创建播放器  -> 状态idle
  static async init(context: Context) {
    AVPlayerClass.player = await media.createAVPlayer()
    AVPlayerClass.context = context
    AVPlayerClass.player.on('stateChange', async (state) => {
      if (state === 'initialized') {
        // 3.prepare() -> 状态 prepared
        await AVPlayerClass.player.prepare()
      } else if (state === 'prepared') {
        // 4.play() -> 状态 playing
        await AVPlayerClass.player.play()
      } else if (state === 'completed') {
        // 5.播放完成要先回到initialized，才能切换播放源
        await AVPlayerClass.player.reset()
      }
    })
  }

  static async play(type: 'camera' | 'information' | 'send') {
    // 6.再次播放也需要先回到initialized
    AVPlayerClass.player.reset()
    // 2.1准备播放地址
    let fileDescriptor = await AVPlayerClass.context.resourceManager.getRawFd(type + '.wav')
    // 2.2设置播放源 ->  状态:initialized
    AVPlayerClass.player.fdSrc = fileDescriptor
  }
}