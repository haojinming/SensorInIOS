//
//  NetworkInfo.h
//  SensorInfo
//
//  Created by utrc on 28/08/2017.
//  Copyright © 2017 utrc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkInfo : NSObject

+(CFDictionaryRef)getWifiNetworkInfo;
-(NSString*)getWifiSSID;
-(NSString*)getWifiBSSID;
-(NSDictionary*)getWifiInfoDictionary;
+(int)getWifiStrength;
@end
