package com.dg.developer.exitplan

import com.ryanheise.audioservice.AudioServiceActivity

/**
 * AudioServiceActivity instead of FlutterActivity: audio_service needs the
 * activity to hand it the right FlutterEngine so the media session can be bound
 * from a cold start.
 */
class MainActivity : AudioServiceActivity()
