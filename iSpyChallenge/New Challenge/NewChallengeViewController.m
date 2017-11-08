//
//  NewChallengeViewController.m
//  iSpyChallenge
//
//  Created by Kurt McIntire on 11/8/17.
//  Copyright © 2017 Blue Owl. All rights reserved.
//

#import "NewChallengeViewController.h"
#import <MapKit/MapKit.h>
#import "Challenge.h"
#import "LocationManager.h"

@interface NewChallengeViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic, strong) Challenge *currentChallenge;

@end

@implementation NewChallengeViewController


- (IBAction)doneButtonPressed:(id)sender {
    // TODO: Save currentChallenge to CoreData
    // Nil out the currentChallenge object post-save
    // Redirect to the Feed, or present the actionSheet for new Challenge
    self.currentChallenge = nil;
    self.imageView.image = nil;
    self.textView.text = nil;
    [self selectPhoto];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigationBar];
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.currentChallenge == nil) {
        [self selectPhoto];
    }
}

- (void)setupNavigationBar {
    self.title = @"New Challenge";
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
}

- (void)setupView {
    self.textView.text = @"";
}

- (void)takePhoto {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.navigationBar.tintColor = [UIColor colorNamed:@"OwlBlue"];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)selectPhoto {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.navigationBar.tintColor = [UIColor colorNamed:@"OwlBlue"];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    
    if (self.currentChallenge == nil) {
        NSManagedObjectContext *moc = [self.dataController managedObjectContext];
        self.currentChallenge = [[Challenge alloc] initWithContext:moc];
        self.currentChallenge.latitude = @([[LocationManager shared] currentLocation].coordinate.latitude);
        self.currentChallenge.latitude = @([[LocationManager shared] currentLocation].coordinate.longitude);
        
        self.imageView.image = chosenImage;
        
        NSString *sampleHint = @"A sample hint to tell you where you're going";
        self.currentChallenge.hint = sampleHint;
        self.textView.text = sampleHint;
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
