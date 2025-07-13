import { http } from '@kit.NetworkKit'
import { JSON } from '@kit.ArkTS'
import { ChatData, ChatResponse } from '../models/chat'
import { promptAction } from '@kit.ArkUI'

const req = http.createHttp()

export async function requestMessage (content: string) {
  try {
    const res = await req.request(`https://api.ownthink.com/bot?appid=xiaosi&userid=user&spoken=${encodeURIComponent(content)}`)
    const message: string = `{"message": "success", "data": {"type": 5000, "info": {"text": "你在干什么啊你在干什么啊你在干什么啊你在干什么啊你在干什么啊你在干什么啊"}}}`
    const result = JSON.parse(message) as ChatResponse
    return result
  } catch (err) {
    
    promptAction.showToast({
      message: err
    })
    return Promise.reject(err)

  }
}