//
//  CitySelectionViewController.m
//  GoHikeAmsterdam
//
//  Created by Giovanni on 8/21/13.
//  Copyright (c) 2013 Code for Europe. All rights reserved.
//

#import "CitySelectionViewController.h"
#import "CatalogViewController.h"
#import "SVProgressHUD.h"
#import "AFNetworking.h"
#import "CitiesOverlayView.h"
#import "SettingsViewController.h"

#define base_url @"http://api.festigo.es/"

@interface CitySelectionViewController ()

@end

@implementation CitySelectionViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)fixUIForiOS7
{
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Fix UI for iOS7
    [self fixUIForiOS7];

    self.title = NSLocalizedString(@"Where are you?", @"Where are you?");
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
//    UIBarButtonItem *settingsBarButton =
    UIButton *settingsBtn = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [settingsBtn setImage:[UIImage imageNamed:@"19-gear"] forState:UIControlStateNormal];
    [settingsBtn addTarget:self action:@selector(settingsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *settingsBarButton = [[UIBarButtonItem alloc] initWithCustomView:settingsBtn];
//    [settingsButton addt]
//    [settingsButton setTarget:self];
//    [settingsButton setAction:@selector(settingsButtonTapped:)];
    self.navigationItem.leftBarButtonItem = settingsBarButton;
    
    //Tableview background
    UIView *tablebgView = [[[NSBundle mainBundle] loadNibNamed:@"TableBackground" owner:self options:nil] objectAtIndex:0];
    [self.tableView setBackgroundView:tablebgView];


    //register the UITableViewCell
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
            
    //add RefreshControl to TableView
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    [refreshControl addTarget:self action:@selector(loadCities) forControlEvents:UIControlEventValueChanged];
    refreshControl.tintColor = [UIColor grayColor];
    self.refreshControl = refreshControl;
    
    //festiGo Styling
    [self.tableView setSeparatorColor:[UIColor clearColor]];
}

- (void)viewWillAppear:(BOOL)animated
{
    //Get the location, then load the cities
    [self getLocation];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)settingsButtonTapped:(id)sender
{
    SettingsViewController *settingsVC = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *settingsNavController = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    [self.navigationController presentViewController:settingsNavController animated:YES completion:^{    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    GHCities *cities = [[AppState sharedInstance] cities];
    switch (section) {
        case 0:
            return [[cities GHwithin] count];
            break;
        case 1:
            return  [[cities GHother] count];
            break;
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    GHCities *cities = [[AppState sharedInstance] cities];

    switch (indexPath.section) {
        case 0:
        {
            //cities within
            cell.textLabel.text =  [[[cities GHwithin] objectAtIndex:indexPath.row] GHname];
        }
            break;
        case 1:
        {
            //cities other
            cell.textLabel.text = [[[cities GHother] objectAtIndex:indexPath.row] GHname];
        }
            break;
        default:
            break;
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"AdelleBasic-BoldItalic" size:16.0];
    
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return NSLocalizedString(@"Nearby cities", @"Section title for cities the player is within");
            break;
        case 1:
            return NSLocalizedString(@"All playable cities", @"Section title for other cities outside of player range");
            break;
        default:
            break;
    }
    return nil;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    GHCity *city;
    GHCities *cities = [[AppState sharedInstance] cities];

    switch (indexPath.section) {
        case 0:
        {
            //within
            city = [[cities GHwithin] objectAtIndex:indexPath.row];
    
        }
            break;
        case 1:
        {
            //others
            city = [[cities GHother] objectAtIndex:indexPath.row];
        }
            break;
        default:
            break;
    }

    [[AppState sharedInstance] setCurrentCity:city];
    [[AppState sharedInstance] save];
    [self pushNewControllerAnimated:YES];
}

#pragma mark - Actions

- (void)getLocation
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLocationUpdate:) name:kLocationServicesGotBestAccuracyLocation object:nil];
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Locating you", @"Locating you") maskType:SVProgressHUDMaskTypeBlack];
    [[AppState sharedInstance] startLocationServicesLowPrecision];
}

- (void)loadCities
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLoadCitiesCompleted:) name:kFinishedLoadingCities object:nil];
    //Hide the refresh control
    [self.refreshControl endRefreshing];
    
    AFNetworkReachabilityStatus status = [[GoHikeHTTPClient sharedClient] networkReachabilityStatus];
    if(status == AFNetworkReachabilityStatusNotReachable)
    {
        [SVProgressHUD dismiss];
        NSLog(@"Not reachable, not loading cities");
        return;
    }
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Updating cities", @"Updating cities") maskType:SVProgressHUDMaskTypeBlack];
    
    [[GoHikeHTTPClient sharedClient] locate];
}

#pragma mark - Notification handlers

- (void)handleLocationUpdate:(NSNotification*)notification
{
    [[AppState sharedInstance] stopLocationServices];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationServicesGotBestAccuracyLocation object:nil];

    if ([[notification userInfo] objectForKey:@"error"]) {
        NSLog(@"Error in updating location: %@", [[[notification userInfo] objectForKey:@"error"] description]);
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Could not get location at this time", @"Could not get location at this time")];
    }
    else{
        [self loadCities];
    }
}

- (void)pushNewControllerAnimated:(BOOL)animated
{
    CatalogViewController *cvc = [[CatalogViewController alloc] initWithNibName:@"CatalogViewController" bundle:nil];
    [self.navigationController pushViewController:cvc animated:animated];
}

- (void)handleLoadCitiesCompleted:(NSNotification*)notification
{
    if([[notification userInfo] objectForKey:@"error"])
    {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Error loading cities", @"Error loading cities")];
    }
    else{
        [SVProgressHUD showSuccessWithStatus:nil];
        [self.tableView reloadData];
        
        if ([[AppState sharedInstance] currentCity] == nil) { //means it's first time user starts app
            GHCity *city = [[[[AppState sharedInstance] cities] GHwithin] lastObject];
            if (city != nil) {
                [[AppState sharedInstance] setCurrentCity:city];
                [[AppState sharedInstance] save];
                [self pushNewControllerAnimated:NO];
                return;
            }
        }
        
        //How to play screen
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"howtoplay_cities_displayed"] == nil) {
            
            [self displayWelcomeScreen];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"howtoplay_cities_displayed"];
        }

        
    }
}

- (void)displayWelcomeScreen
{
    CitiesOverlayView *citiesOverlayView = [[[NSBundle mainBundle] loadNibNamed:@"CitiesOverlayView" owner:self options:nil] objectAtIndex:0];
    citiesOverlayView.textView.text = NSLocalizedString(@"WelcomeText", @"Welcome text to the app");
    [citiesOverlayView.playButton setTitle:NSLocalizedString(@"Let's play!", @"Button to play") forState:UIControlStateNormal];
    CGRect frame = self.tableView.bounds;
    [citiesOverlayView setFrame:frame];
    [self.tableView.superview insertSubview:citiesOverlayView aboveSubview:self.tableView];

}

@end
