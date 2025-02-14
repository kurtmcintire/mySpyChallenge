//
//  UserTableViewController.h
//  iSpyChallenge
//
//  Created by Bennett Smith on 6/3/16.
//  Copyright © 2016 Blue Owl. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DataController.h"
#import "PhotoController.h"

#import "User.h"
#import "User+CoreDataProperties.h"

@interface UserTableViewController : UITableViewController
@property (nonatomic, strong) DataController *dataController;
@property (nonatomic, strong) PhotoController *photoController;
@property (nonatomic, strong) User *user;
@end
