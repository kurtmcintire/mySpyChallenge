//
//  ChallengeFeedCell.h
//  iSpyChallenge
//
//  Created by Kurt McIntire on 11/8/17.
//  Copyright © 2017 Blue Owl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChallengeFeedCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *winsLabel;
@property (weak, nonatomic) IBOutlet UILabel *starsLabel;
@property (weak, nonatomic) IBOutlet UILabel *hintLabel;
@property (weak, nonatomic) IBOutlet UILabel *createdByLabel;

@end
