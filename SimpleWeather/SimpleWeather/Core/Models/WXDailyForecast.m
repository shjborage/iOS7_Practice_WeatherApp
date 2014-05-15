//
//  WXDailyForecast.m
//  SimpleWeather
//
//  Created by shihaijie on 5/15/14.
//  Copyright (c) 2014 Saick. All rights reserved.
//

#import "WXDailyForecast.h"

@implementation WXDailyForecast

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
  // 1
  NSMutableDictionary *paths = [[super JSONKeyPathsByPropertyKey] mutableCopy];
  // 2
  paths[@"tempHigh"] = @"temp.max";
  paths[@"tempLow"] = @"temp.min";
  // 3
  return paths;
}

@end
