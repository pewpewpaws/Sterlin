# Keep AppWidget Provider and Service classes from R8 obfuscation / shrinking in release APK
-keep class com.pewpewpaws.sterlin.widgets.TimetableWidgetProvider { *; }
-keep class com.pewpewpaws.sterlin.widgets.TimetableWidgetService { *; }
-keep class com.pewpewpaws.sterlin.widgets.TimetableViewsFactory { *; }
-keep class com.pewpewpaws.sterlin.** { *; }
-keep class es.chemaaguilar.homewidget.** { *; }
