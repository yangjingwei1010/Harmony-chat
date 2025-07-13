import { preferences } from '@kit.ArkData'
import { MessageInfoModel } from '../models/messages'
import { DefaultUserList } from '../models/users'
import { emitter } from '@kit.BasicServicesKit'
import { promptAction } from '@kit.ArkUI'
import { JSON } from '@kit.ArkTS'

export class StoreClass {
  static context: Context
  static wechat_key: string = 'WECHAT_CHAT'

  static init(context: Context) {
    StoreClass.context = context
  }

  // 获取某个人的聊天仓库
  static getUserStore(userId: string) {
    // 为了不和其他存储冲突，添加一个首选项存储标识wechat_key拼接userId
    return preferences.getPreferencesSync(StoreClass.context, { name: `${StoreClass.wechat_key}_${userId}` })
  }

  // 某个人的仓库添加一条消息
  static async addChatMessage(userId: string, message: MessageInfoModel) {
    const store = StoreClass.getUserStore(userId)
    store.putSync(message.id, JSON.stringify(message))
    await store.flush()
    emitter.emit(StoreClass.wechat_key)
  }

  // 获取某个人的所有信息
  static getChatMessage(userId: string) {
    const store = StoreClass.getUserStore(userId)
    const all = store.getAllSync() as object
    if (all) {
      const list = Object.values(all).map((item: string) => JSON.parse(item) as MessageInfoModel)
      // 聊天列表是时间倒序显示的
      list.sort((a, b) => a.sendTime - b.sendTime)
      return list
    }
    return []
  }

  // 移除某个人的一条消息
  static async removeChatMessage(userId: string, messageId: string) {
    const store = StoreClass.getUserStore(userId)
    store.deleteSync(messageId)
    await store.flush()
    emitter.emit(StoreClass.wechat_key)
  }

  //   删除某个人的所有记录
  static removeChatAllMessage(userId: string) {
    preferences.deletePreferences(StoreClass.context, { name: `${StoreClass.wechat_key}_${userId}` })
    //   线程通信：发布者
    emitter.emit(StoreClass.wechat_key)
  }

  // 获取所有人的最后一条消息
  static getAllChatLastMessage() {
    const lastList: MessageInfoModel[] = []
    DefaultUserList.forEach(user => {
      const chatList = StoreClass.getChatMessage(user.user_id)
      if (chatList.length) {
        lastList.push(chatList[chatList.length - 1])
      }
    })
    lastList.sort((a, b) => b.sendTime - a.sendTime)
    return lastList
  }
}