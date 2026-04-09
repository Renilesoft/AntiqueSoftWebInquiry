#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <Firebase.h>
#import <UserNotifications/UserNotifications.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // ✅ Prevent duplicate Firebase init crash
    if ([FIRApp defaultApp] == nil) {
        [FIRApp configure];
    }

    // ✅ Register Flutter plugins
    [GeneratedPluginRegistrant registerWithRegistry:self];

    // ✅ Request notification permission (IMPORTANT for FCM)
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center requestAuthorizationWithOptions:
         (UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
        }];
    }

    // ✅ Register for remote notifications
    [[UIApplication sharedApplication] registerForRemoteNotifications];

    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end