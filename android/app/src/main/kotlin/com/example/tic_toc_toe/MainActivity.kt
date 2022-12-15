package com.example.tic_toc_toe

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PersistableBundle
import android.util.Log
import com.google.gson.JsonElement
import com.pubnub.api.PNConfiguration
import com.pubnub.api.PubNub
import com.pubnub.api.callbacks.SubscribeCallback
import com.pubnub.api.models.consumer.PNStatus
import com.pubnub.api.models.consumer.objects_api.channel.PNChannelMetadataResult
import com.pubnub.api.models.consumer.objects_api.membership.PNMembershipResult
import com.pubnub.api.models.consumer.objects_api.uuid.PNUUIDMetadataResult
import com.pubnub.api.models.consumer.pubsub.PNMessageResult
import com.pubnub.api.models.consumer.pubsub.PNPresenceEventResult
import com.pubnub.api.models.consumer.pubsub.PNSignalResult
import com.pubnub.api.models.consumer.pubsub.files.PNFileEventResult
import com.pubnub.api.models.consumer.pubsub.message_actions.PNMessageActionResult
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity: FlutterActivity() {

    private val METHOD_CHANNEL = "game/exchange"

    private var pubNub : PubNub? = null
    private var channel_pubnub: String? = null
    private var handler : Handler? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        handler = (Handler(Looper.getMainLooper()))

        val pnConfigurations = PNConfiguration("MyUniqueUUID")
        pnConfigurations.subscribeKey = "sub-c-8086d344-d761-4b93-83fb-0b8543c0a5ac"
        pnConfigurations.publishKey = "pub-c-89f6b446-9747-494b-8d2a-aa2bae239647"

        pubNub = PubNub(pnConfigurations)

        pubNub.let { it ->
            it?.addListener(object : SubscribeCallback(){
                override fun status(pubnub: PubNub, pnStatus: PNStatus) {}
                override fun presence(pubnub: PubNub, pnPresenceEventResult: PNPresenceEventResult) {}
                override fun signal(pubnub: PubNub, pnSignalResult: PNSignalResult) {}
                override fun uuid(pubnub: PubNub, pnUUIDMetadataResult: PNUUIDMetadataResult) {}
                override fun channel(pubnub: PubNub, pnChannelMetadataResult: PNChannelMetadataResult) {}
                override fun membership(pubnub: PubNub, pnMembershipResult: PNMembershipResult) {}
                override fun messageAction(pubnub: PubNub, pnMessageActionResult: PNMessageActionResult) {}
                override fun file(pubnub: PubNub, pnFileEventResult: PNFileEventResult) {}

                override fun message(pubnub: PubNub, pnMessageResult: PNMessageResult) {
                    Log.d("Pubnub Listener", "Received message: ${pnMessageResult.message.toString()}")
                    var receivedObject : JsonElement? = null
                    var actionReceived = "sendAction"

                    if(pnMessageResult.message.asJsonObject["tap"] !== null){
                        receivedObject = pnMessageResult.message.asJsonObject["tap"]
                    }

                    handler?.let {
                        it.post {
                            val methodChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, METHOD_CHANNEL)
                            methodChannel.invokeMethod(actionReceived, receivedObject.toString())
                        }
                    }
                }
            })
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->

            if(call.method == "sendAction"){
                pubNub!!.publish()
                    .message(call.arguments)
                    .channel(channel_pubnub)
                    .async { _, status -> Log.d("pubnhub", "teve erro? ${status.isError}")  }
                result.success(true)
            }
            else if(call.method == "subscribe"){
                subscribeChannel(call.argument<String>("channel"))
                result.success(true)
            }
        }
    }

    private fun subscribeChannel(channelName: String?){
        channel_pubnub = channelName
        channelName.let {
            pubNub?.subscribe()?.channels(Arrays.asList(channelName))?.execute()
        }
    }
}
