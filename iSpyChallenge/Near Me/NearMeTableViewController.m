//
//  NearMeTableViewController.m
//  iSpyChallenge
//
//  Created by Kurt McIntire on 11/8/17.
//  Copyright © 2017 Blue Owl. All rights reserved.
//

#import "NearMeTableViewController.h"
#import "Challenge.h"
#import "Challenge+CoreDataProperties.h"
#import "ChallengeFeedCell.h"
#import "LocationManager.h"

#import <CoreData/CoreData.h>

@interface NearMeTableViewController () <NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@end

@implementation NearMeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigationBar];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)setupNavigationBar {
    self.title = @"Near Me";
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)injectPropertiesInController:(UIViewController *)controller {
    if ([controller respondsToSelector:@selector(setDataController:)]) {
        [controller performSelector:@selector(setDataController:) withObject:self.dataController];
    }
    if ([controller respondsToSelector:@selector(setPhotoController:)]) {
        [controller performSelector:@selector(setPhotoController:) withObject:self.photoController];
    }
    if ([controller respondsToSelector:@selector(setChallenge:)]) {
        Challenge *challenge = (Challenge *)[self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
        [controller performSelector:@selector(setChallenge:) withObject:challenge];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // TODO: Segue
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[[self fetchedResultsController] sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetchedResultsController] sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChallengeFeedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChallengeFeedCell"];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    /*
    [self performSegueWithIdentifier:@"showChallenge" sender:self];
    */
}

#pragma mark - Fetched Results Controller

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Challenge"];
    [fetchRequest setFetchBatchSize:20];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"hint" ascending:YES]]];
    
    NSManagedObjectContext *moc = [self.dataController managedObjectContext];
    [self setFetchedResultsController:[[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:moc sectionNameKeyPath:nil cacheName:@"DataBrowserChallenge"]];
    [[self fetchedResultsController] setDelegate:self];
    
    NSError *error = nil;
    if ([[self fetchedResultsController] performFetch:&error] == NO) {
        NSLog(@"Unresolved error %@\n%@", [error localizedDescription], [error userInfo]);
    }
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self tableView] beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
        [[self tableView] insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        break;
        case NSFetchedResultsChangeDelete:
        [[self tableView] deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        break;
        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
        break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeInsert:
        [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        break;
        
        case NSFetchedResultsChangeDelete:
        [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        break;
        
        case NSFetchedResultsChangeUpdate:
        [self configureCell:[[self tableView] cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
        break;
        
        case NSFetchedResultsChangeMove:
        [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
        break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[self tableView] endUpdates];
}

- (void)configureCell:(ChallengeFeedCell *)cell
          atIndexPath:(NSIndexPath *)indexPath {
    
    Challenge *challenge = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    NSString *createdBy = [NSString stringWithFormat:@"Created by: %@", challenge.creator.username];
    NSString *stars = [NSString stringWithFormat:@"%.01f / 5", challenge.averageRating];
    NSString *wins = @"";
    
    if (challenge.matches.count > 1) {
        wins = [NSString stringWithFormat:@"%lu wins", challenge.matches.count];
    } else if (challenge.matches.count == 1) {
        wins = [NSString stringWithFormat:@"%lu win", challenge.matches.count];
    } else {
        wins = @"No wins";
    }
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:challenge.latitude.floatValue longitude:challenge.longitude.floatValue];
    CLLocationDistance distance = [location distanceFromLocation:[LocationManager shared].currentLocation];
    NSString *distanceString = @"";
    
    if (distance < 1000) {
        distanceString = [NSString stringWithFormat:@"%.00f m", distance];
    } else {
        distanceString = [NSString stringWithFormat:@"%.00f km", distance / 1000];
    }
    
    cell.distanceLabel.text = distanceString;
    cell.createdByLabel.text = createdBy;
    cell.hintLabel.text = challenge.hint;
    cell.starsLabel.text = stars;
    cell.winsLabel.text = wins;
    
    /*
    [[cell textLabel] setText:challenge.hint];
    [[cell detailTextLabel] setText:latlon];

    UIImage *photo = [self.photoController photoWithName:challenge.photoHref];
    [[cell imageView] setImage:photo];
    */
}

@end
