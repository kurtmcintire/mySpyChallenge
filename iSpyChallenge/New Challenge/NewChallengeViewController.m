//
//  NewChallengeViewController.m
//  iSpyChallenge
//
//  Created by Kurt McIntire on 11/8/17.
//  Copyright © 2017 Blue Owl. All rights reserved.
//

#import "NewChallengeViewController.h"

@interface NewChallengeViewController ()

@end

@implementation NewChallengeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigationBar];
}

- (void)setupNavigationBar {
    self.title = @"New Challenge";
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
}

@end
