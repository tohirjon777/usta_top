package uz.tokhiriy.ustatop

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("f9754681-7a24-46de-b153-16e51d552998")
    }
}
