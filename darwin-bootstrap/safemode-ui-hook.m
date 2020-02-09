#include "substitute.h"
#include <objc/runtime.h>
#include <notify.h>
#include <dispatch/dispatch.h>
#define API_UNAVAILABLE(...)
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <mach-o/dyld.h>

#pragma clang diagnostic ignored "-Weverything"

static Class SpringBoard, SBApplicationController;
static bool g_did_activate_safetydance;
static id g_sb = NULL;

@interface _SBApplicationController
- (id)applicationWithBundleIdentifier:(NSString *)identifier;
+ (instancetype)sharedInstanceIfExists;
@end

@interface _SpringBoard
- (void)relaunchSpringBoard;
@end

@interface _SBApplication
- (void)setFlag:(int64_t)flag forActivationSetting:(unsigned)setting;
- (BOOL)launchApplicationWithIdentifier:(NSString *)iden
        suspended:(BOOL)suspended;
- (BOOL)isRunning;
- (void)activate;
@end

void launchSafety() {
    BOOL res = [g_sb launchApplicationWithIdentifier: @"org.coolstar.SafeMode" suspended:NO];
    if (!res) {
        NSLog(@"substitute safe mode: Safety not yet launched.\n");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            launchSafety();
        });
    } else {
        NSLog(@"substitute safe mode: Safety launched.\n");
    }
}

void (*old_applicationDidFinishLaunching)(id, SEL, id);
static void my_applicationDidFinishLaunching(id self, SEL sel, id app) {
    g_sb = self;
    g_did_activate_safetydance = true;
    old_applicationDidFinishLaunching(self, sel, app);
}

__attribute__((constructor))
static void init() {
    #define GET(clsname) \
        clsname = objc_getClass(#clsname); \
        if (!clsname) { \
            NSLog(@"substitute safe mode failed to find %s", #clsname); \
            return; \
        }

    GET(SpringBoard);
    GET(SBApplicationController);

    int notify_token;
    uint32_t notify_status = notify_register_dispatch(
        "com.ex.substitute.safemode-restart-springboard-plz",
        &notify_token, dispatch_get_main_queue(), ^(int tok) {
            id sb = [UIApplication sharedApplication];
            //[sb relaunchSpringBoard];
        CFDictionaryRef dict = (__bridge CFDictionaryRef)  @{
            (__bridge NSString*) kCFUserNotificationAlertTopMostKey: @1,
            (__bridge NSString*) kCFUserNotificationAlertHeaderKey: @"Title",
            (__bridge NSString*) kCFUserNotificationAlertMessageKey: @"Message"
        };
        SInt32 err = 0;
        CFUserNotificationRef notif = CFUserNotificationCreate(NULL, 0, kCFUserNotificationPlainAlertLevel, &err, dict);
        }
    );

    #define HOOK(cls, sel, selvar) do { \
        int ret = substitute_hook_objc_message(cls, @selector(sel), \
                                               my_##selvar, \
                                               &old_##selvar, NULL); \
        if (ret) { \
            NSLog(@"substitute safe mode '%s' hook failed: %d", #sel, ret); \
            return; \
        } \
    } while(0)

    HOOK(SpringBoard, applicationDidFinishLaunching:,
         applicationDidFinishLaunching);
    launchSafety();
}
