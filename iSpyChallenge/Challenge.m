//
//  Challenge.m
//  iSpyChallenge
//
//  Created by Bennett Smith on 6/2/16.
//  Copyright © 2016 Blue Owl. All rights reserved.
//

#import "Challenge.h"
#import "Rating.h"

@implementation Challenge

- (float)averageRating {
    NSMutableArray *starsArray = [NSMutableArray new];
    for (Rating *rating in self.ratings) {
        [starsArray addObject:rating.stars];
    }
    
    NSNumber *average = [starsArray valueForKeyPath:@"@avg.self"];
    return average.floatValue;
}

@end
