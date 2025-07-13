import { MapComponent } from '@hms.core.map.MapComponent'
import { mapCommon, map } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { geoLocationManager } from '@kit.LocationKit';

@Component
struct Location {
  mapController?: map.MapComponentController
  callback?: AsyncCallback<map.MapComponentController>
  @Link
  currentAddress: string
  mapOption: mapCommon.MapOptions = {
    position: {
      target: {
        latitude: 39.9,
        longitude: 116.4
      },
      zoom: 12
    }
  }

  aboutToAppear(): void {
    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController
        // 允许设置我的位置
        this.mapController.setMyLocationEnabled(true)
        // 启用我当前的图层
        this.mapController.setMyLocationControlsEnabled(true)
        this.getLocation()
      }
    }
  }

  // 获取我的位置
  async getLocation() {
    try {
      const result = await geoLocationManager.getCurrentLocation()
      this.mapController?.setMyLocation({
        latitude: result.latitude,
        longitude: result.longitude,
        altitude: 0,
        accuracy: 0,
        speed: 0,
        timeStamp: 0,
        direction: 0,
        timeSinceBoot: 0,
        altitudeAccuracy: 0,
        speedAccuracy: 0,
        directionAccuracy: 0,
        uncertaintyOfTimeSinceBoot: 0,
        sourceType: geoLocationManager.LocationSourceType.GNSS
      })
      // 准备相机
      let cameraUpdate: map.CameraUpdate = map.newCameraPosition({
        target: {
          longitude: result.longitude,
          latitude: result.latitude
        },
        zoom: 16
      })
      this.mapController?.moveCamera(cameraUpdate)
      this.mapController?.addMarker({
        position: {
          longitude: result.longitude,
          latitude: result.latitude
        },
        title: '您当前的位置',
        clickable: true
      })
      this.mapController?.addCircle({
        radius: 500,
        center: {
          longitude: result.longitude,
          latitude: result.latitude
        },
        fillColor: 0XFF00FFFF
      })
      const res = await geoLocationManager.getAddressesFromLocation({
        latitude: result.latitude,
        longitude: result.longitude
      })
      if (res.length) {
        this.currentAddress = res[0].placeName as string
      }
    } catch (err) {
      AlertDialog.show({
        message: err.message
      })
    }
  }

  build() {
    Row() {
      MapComponent({
        mapOptions: this.mapOption,
        mapCallback: this.callback
      }).width('100%')
        .height('100%')
    }
    .height('100%')
  }
}

export default Location