# Keep AppWidget Provider and Service classes from R8 obfuscation / shrinking in release APK
-keep class com.example.planner.TimetableWidgetProvider { *; }
-keep class com.example.planner.TimetableWidgetService { *; }
-keep class com.example.planner.TimetableViewsFactory { *; }
-keep class es.chemaaguilar.homewidget.** { *; }
