//
//  LocationManager.h
//  iSpyChallenge
//
//  Created by Kurt McIntire on 11/8/17.
//  Copyright © 2017 Blue Owl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationManager : NSObject <CLLocationManagerDelegate>

+ (LocationManager *)shared;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) CLLocation *currentLocation;

- (void)startUpdatingLocation;

@end
