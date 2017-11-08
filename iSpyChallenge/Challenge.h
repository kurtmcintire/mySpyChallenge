//
//  Challenge.h
//  iSpyChallenge
//
//  Created by Bennett Smith on 6/2/16.
//  Copyright © 2016 Blue Owl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@class User;
@class Match;
@class Rating;

@interface Challenge : NSManagedObject

- (float)averageRating;

@end

NS_ASSUME_NONNULL_END

#import "Challenge+CoreDataProperties.h"
