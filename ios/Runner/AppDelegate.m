#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <Firebase.h>                 // 🔥 REQUIRED
#import <FirebaseMessaging/FirebaseMessaging.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // 🔥 Initialize Firebase (MANDATORY)
  [FIRApp configure];

  [GeneratedPluginRegistrant registerWithRegistry:self];

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end