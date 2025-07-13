// 消息类型
import { UserInfo } from './users'
import { util } from '@kit.ArkTS'

export enum MessageTypeEnum {
  TEXT,// 文本
  AUDIO,// 音频
  VIDEO,//视频
  IMAGE,//图片
  LOCATION,// 定位
  LINK,// 链接

}

// 消息数据结构
export interface MessageInfo {
  id: string // 标识
  sendUser: UserInfo // 这条消息的发送者
  connectUser: UserInfo // 这条消息的归属者
  messageContent: string // 消息内容  文本消息  [图片] [7"语音]
  sendTime: number // 发送时间
  // 消息类型
  messageType: MessageTypeEnum // 消息类型
  sourceFilePath: string // 音频地址 图片地址 视频地址
  sourceDuration: number // 音频或者视频的长度 单位s
}
export class MessageInfoModel implements MessageInfo {
  id: string = ''
  sendUser: UserInfo = {} as UserInfo
  connectUser: UserInfo = {} as UserInfo
  messageContent: string = ''
  sendTime: number = 0
  messageType: MessageTypeEnum = MessageTypeEnum.TEXT
  sourceFilePath: string = ''
  sourceDuration: number = 0

  constructor(model: MessageInfo) {
    this.id = model.id || util.generateRandomUUID()
    this.sendUser = model.sendUser
    this.connectUser = model.connectUser
    this.messageContent = model.messageContent
    this.sendTime = model.sendTime || Date.now()
    this.messageType = model.messageType || MessageTypeEnum.TEXT
    this.sourceFilePath = model.sourceFilePath
    this.sourceDuration = model.sourceDuration
  }
}

