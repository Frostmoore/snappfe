package com.gsv.snapp

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (non FlutterActivity) è richiesto dal plugin local_auth
// per mostrare il prompt biometrico di sistema (BiometricPrompt).
class MainActivity: FlutterFragmentActivity()
