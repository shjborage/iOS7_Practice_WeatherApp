//
//  WXManager.m
//  SimpleWeather
//
//  Created by shihaijie on 5/15/14.
//  Copyright (c) 2014 Saick. All rights reserved.
//

#import "WXManager.h"
#import "WXClient.h"
#import <TSMessages/TSMessage.h>

@interface WXManager ()

// 1
@property (nonatomic, strong, readwrite) WXCondition *currentCondition;
@property (nonatomic, strong, readwrite) CLLocation *currentLocation;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;

// 2
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) WXClient *client;

@end

@implementation WXManager

+ (instancetype)sharedManager
{
  static id _shareManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _shareManager = [[self alloc] init];
  });
  
  return _shareManager;
}

- (id)init
{
  if (self = [super init]) {
    _locationManager = [CLLocationManager new];
    _locationManager.delegate = self;
    
    _client = [WXClient new];
    
    [[[[RACObserve(self, currentLocation)
        ignore:nil]
       flattenMap:^(CLLocation *newLocation) {
         return [RACSignal merge:@[
                                   [self updateCurrentConditions],
                                   [self updateDailyForecast],
                                   [self updateHourlyForecast]
                                   ]];
       }] deliverOn:RACScheduler.mainThreadScheduler]
     subscribeError:^(NSError *error) {
       [TSMessage showNotificationWithTitle:@"Error"
                                   subtitle:@"There was a problem fetching the latest weather."
                                       type:TSMessageNotificationTypeError];
     }];
  }
  return self;
}

- (RACSignal *)updateCurrentConditions
{
  return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate] doNext:^(WXCondition *condition) {
    self.currentCondition = condition;
  }];
}

- (RACSignal *)updateHourlyForecast
{
  return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
    self.hourlyForecast = conditions;
  }];
}

- (RACSignal *)updateDailyForecast
{
  return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
    self.dailyForecast = conditions;
  }];
}

#pragma mark - Finding your location

- (void)findCurrentLocation
{
  self.isFirstUpdate = YES;
  [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
  // Always ignore the first location update because it is almost always cached.
  if (self.isFirstUpdate) {
    self.isFirstUpdate = NO;
    return;
  }
  
  CLLocation *location = [locations lastObject];
  
  // Once you have a location with the proper accuracy, stop further updates.
  if (location.horizontalAccuracy > 0) {
    self.currentLocation = location;
    [self.locationManager stopUpdatingLocation];
  }
}

@end
