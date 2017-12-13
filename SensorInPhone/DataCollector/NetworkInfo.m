//
//  NetworkInfo.m
//  SensorInfo
//
//  Created by utrc on 28/08/2017.
//  Copyright © 2017 utrc. All rights reserved.
//

#import "UIKit/UIApplication.h"
#import "NetworkInfo.h"
#import "SystemConfiguration/CaptiveNetwork.h"

@implementation NetworkInfo

+(CFDictionaryRef)getWifiNetworkInfo{
    CFDictionaryRef wifiInterface = NULL;
    CFArrayRef networkInterfaces = CNCopySupportedInterfaces();
    if (networkInterfaces != NULL) {
        if (CFArrayGetCount(networkInterfaces) > 0) {
            CFStringRef wifiRef = CFArrayGetValueAtIndex(networkInterfaces, 0);
            wifiInterface = CNCopyCurrentNetworkInfo(wifiRef);
        }
        CFRelease(networkInterfaces);
    }
    return wifiInterface;
}
-(NSString*)getWifiSSID{
    NSString* result = NULL;
    CFDictionaryRef wifiInterfce = [NetworkInfo getWifiNetworkInfo];
    if(wifiInterfce != NULL){
        if (CFDictionaryGetCount(wifiInterfce) > 0) {
            CFStringRef ssidRef = CFDictionaryGetValue(wifiInterfce, kCNNetworkInfoKeySSID);
            result = (__bridge NSString *)ssidRef;
        }
        CFRelease(wifiInterfce);
    }
    return result;
}
-(NSString*)getWifiBSSID{
    NSString* result  =NULL;
    CFDictionaryRef wifiInterfce = [NetworkInfo getWifiNetworkInfo];
    if(wifiInterfce != NULL){
        if (CFDictionaryGetCount(wifiInterfce) > 0) {
            CFStringRef ssidRef = CFDictionaryGetValue(wifiInterfce, kCNNetworkInfoKeyBSSID);
            result = (__bridge NSString *)ssidRef;
        }
        CFRelease(wifiInterfce);
    }
    return result;
}
-(NSDictionary*)getWifiInfoDictionary{
    NSDictionary* result = NULL;
    CFDictionaryRef wifiInterfce = [NetworkInfo getWifiNetworkInfo];
    result = (__bridge NSDictionary *)wifiInterfce;
    return result;
}
+(int)getWifiStrength{
    int signalStrength = -1;
    UIApplication* app = [UIApplication sharedApplication];
    NSDictionary* statusBar = [app valueForKey:@"statusBar"];
    if(statusBar != nil){
        NSArray* subviews = [[statusBar valueForKey:@"foregroundView"] subviews];
        NSString* dataNetworkItemView = nil;
        Class signalStrengthItemViewClass = [NSClassFromString(@"UIStatusBarDataNetworkItemView") class];
        for (id subview in subviews) {
            if ([subview isKindOfClass:signalStrengthItemViewClass]) {
                dataNetworkItemView = subview;
                break;
            }
        }
        if(dataNetworkItemView != nil){
            signalStrength = [[dataNetworkItemView valueForKey:@"wifiStrengthBars"] intValue];
        }
    }
    
    return signalStrength;
}
@end
