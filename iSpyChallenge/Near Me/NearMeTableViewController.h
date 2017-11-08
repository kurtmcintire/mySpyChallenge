//
//  NearMeTableViewController.h
//  iSpyChallenge
//
//  Created by Kurt McIntire on 11/8/17.
//  Copyright © 2017 Blue Owl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataController.h"
#import "PhotoController.h"

@interface NearMeTableViewController : UITableViewController
@property (nonatomic, strong) DataController *dataController;
@property (nonatomic, strong) PhotoController *photoController;

@end
