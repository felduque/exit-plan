# R8 rules for the release build.
#
# The TikTok Business SDK ships a single artifact containing every feature it
# offers, including ones this app does not use. R8 traces those code paths,
# finds they reference libraries that are not on the classpath, and fails the
# build over classes that can never actually be reached at runtime.

# There is deliberately no -dontwarn for com.android.billingclient here.
#
# There used to be: TikTok's SDK references Play Billing for purchase tracking,
# the app sold nothing, and the classes were absent, so R8 failed the build over
# code that could never run. Now in_app_purchase ships Play Billing as a real
# dependency with its own consumer rules, so the classes are present and the
# warning is gone on its own. Restoring the suppression would only serve to hide
# a genuine missing-class problem in the library the app takes money through.

# Note: com.android.installreferrer is NOT suppressed here. It is a real
# dependency in build.gradle.kts, because the Play install referrer is how
# TikTok attributes an install to the ad that produced it — the entire reason
# the SDK is in this app. Silencing it instead would have produced a green
# build that quietly attributes nothing.

# The Google Mobile Ads SDK pulls in WorkManager, which keeps its queue in a
# Room database. Room resolves a database to its generated implementation by
# reflection — Class.forName("<Database>_Impl") — and R8 cannot see an edge
# expressed as a string. Under minification it renames WorkDatabase_Impl,
# WorkManager's androidx.startup initializer throws while the process is still
# binding, and the app dies before a single line of Dart runs.
#
# The symptom is maximally misleading: "Unable to get provider
# androidx.startup.InitializationProvider", which names neither Room, nor
# WorkManager, nor ads. It only appears in release builds, so a debug run looks
# perfectly healthy.
#
# Keeping the no-arg constructor also keeps the class name, which is the half
# that actually matters here.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-dontwarn androidx.room.paging.**
