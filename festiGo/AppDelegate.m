//
//  AppDelegate.m
//  ScavengerApp
//
//  Created by Giovanni Maggini on 5/15/13.
//  Copyright (c) 2013 Code for Europe. All rights reserved.
//

#import "AppDelegate.h"
#import "RouteStartViewController.h"
#import "CompassViewController.h"
#import "AFNetworking.h"
#import "SSKeychain.h"
#import <AdSupport/AdSupport.h>
#import "CitySelectionViewController.h"
#import "CannotPlayViewController.h"
#import "CatalogViewController.h"
#import "SIAlertView.h"
#import <HockeySDK/HockeySDK.h>
#import "GAI.h"
#import "GAITrackedViewController.h"

@implementation AppDelegate

- (void)customizeAppearance
{
    // Create resizable images
    UIImage *topNavbarImage = [[UIImage imageNamed:@"navigation-top-background.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 10, 0)];

    // Set the background image for *all* UINavigationBars
    [[UINavigationBar appearance] setBackgroundImage:topNavbarImage
                                       forBarMetrics:UIBarMetricsDefault];
    
    // Customize the title text for *all* UINavigationBars
    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor whiteColor],
      UITextAttributeTextColor,
      //[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8],
      //UITextAttributeTextShadowColor,
      //[NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
      //UITextAttributeTextShadowOffset,
      [UIFont fontWithName:@"AdelleBasic-BoldItalic" size:20.0],
      NSFontAttributeName,
      nil]];
    
    UIImage *backButton = [[UIImage imageNamed:@"back.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 4)];
    
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backButton forState:UIControlStateNormal
                                                    barMetrics:UIBarMetricsDefault];

    //White color for navigation icons
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];

    //Set SIAlertView appearance
    UIColor *color = [Utilities appColor];
    [[SIAlertView appearance] setMessageFont:[UIFont systemFontOfSize:14]];
    [[SIAlertView appearance] setTitleColor:color];
    [[SIAlertView appearance] setMessageColor:color];
    [[SIAlertView appearance] setCornerRadius:12];
    [[SIAlertView appearance] setShadowRadius:20];
    
    if ([self.window respondsToSelector:@selector(setTintColor:)]) {
        [self.window setTintColor:[Utilities appColor]];
    }
    
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
#if DEBUG
    NSLog(@"Received local notification");
#endif
}


// FBSample logic
// If we have a valid session at the time of openURL call, we handle Facebook transitions
// by passing the url argument to handleOpenURL; see the "Just Login" sample application for
// a more detailed discussion of handleOpenURL
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // attempt to extract a token from the url
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                    fallbackHandler:^(FBAppCall *call) {
//                        NSLog(@"In fallback handler");
                    }];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
#if DEBUG
    NSLog(@"Launchoptions: %@", launchOptions);
#endif
    
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:kHockeySDKAPIKey];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];

    
    //Google Analytics
    //Google analytics
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    
    // Optional: set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    
    // Initialize tracker. Replace with your tracking ID.
    [[GAI sharedInstance] trackerWithTrackingId:kGoogleAnaliticsTrackingCode];
    
    //Register preferences default
    [self registerDefaultsFromSettingsBundle];
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"google-analytics"] == NO){
        //Opt Out if user chose so
        [[GAI sharedInstance] setOptOut:YES];
    }
    
    //Customize appearance iOS5
    [self customizeAppearance];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];    
    
    //perform cleanup of previous version's data
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"cleanup_done"])
    {
        [self performCleanupOldVersion];
    }
    
    //Start updating location
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLocationForbidden:) name:kLocationServicesForbidden object:nil];
    [[AppState sharedInstance] startLocationServices];
    

    // Restore game state
    [[AppState sharedInstance] restore];
#if DEBUG
    NSLog(@"Stored checkins count: %d", [[[AppState sharedInstance] checkins] count]);
#endif
    if ([[AppState sharedInstance] playerIsInCompass] == YES) {
        
        // We were in compass view when we quit, we restore the navigation controller and reopen the compass view

        CitySelectionViewController *cityVC = [[CitySelectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
        CatalogViewController *catalogVC = [[CatalogViewController alloc] initWithNibName:@"CatalogViewController" bundle:nil];
        RouteStartViewController *rvc = [[RouteStartViewController alloc] initWithStyle:UITableViewStyleGrouped];
//        rvc.route = [[AppState sharedInstance] currentRoute];
        CompassViewController *cvc = [[CompassViewController alloc] initWithNibName:@"CompassViewController" bundle:nil];
        self.navigationController = [[UINavigationController alloc] initWithRootViewController:cityVC];
        [self.navigationController pushViewController:catalogVC animated:NO];
        [self.navigationController pushViewController:rvc animated:NO];
        [self.navigationController pushViewController:cvc animated:NO];
        
    }
    else{
        // We were not in compass view, so first we have to check if the user has a selected city
        if([[AppState sharedInstance] currentCity] != nil){
            //if the city is not nil, means the player is already in game
            CitySelectionViewController *cityVC = [[CitySelectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
            CatalogViewController *catalogVC = [[CatalogViewController alloc] initWithNibName:@"CatalogViewController" bundle:nil];
            self.navigationController = [[UINavigationController alloc] initWithRootViewController:cityVC];
            [self.navigationController pushViewController:catalogVC animated:NO];

        }
        else{
            //player has to select a city
            CitySelectionViewController *cvc = [[CitySelectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
            self.navigationController = [[UINavigationController alloc] initWithRootViewController:cvc];
        }
    }

    //Tell AFNetworking to use the Network Activity Indicator
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    // Update
//    [self updateContent];
    
    
    //Start app
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    //This method is called also when the user clicks on the "lock" screen on the iPhone
    if([[AppState sharedInstance] playerIsInCompass])
        [[AppState sharedInstance]  startMonitoringForDestination];


}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    if(![[AppState sharedInstance] playerIsInCompass]){
        [[AppState sharedInstance] stopMonitoringForDestination];
        [[AppState sharedInstance] stopLocationServices];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[GoHikeHTTPClient sharedClient] pushCheckins];
    [FBAppCall handleDidBecomeActive];
//    [[AppState sharedInstance] stopMonitoringForDestination];

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    // We already save everywhere in the app, so not using this
    
    [[AppState sharedInstance] stopLocationServices];
    [FBSession.activeSession close];
    
    //If the user closes the app, we don't want to monitor for regions anymore. It's game over!
    [[AppState sharedInstance] stopMonitoringForDestination];
}

- (void)performCleanupOldVersion
{
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [docsPath stringByAppendingPathComponent: @"content.json"];
    __autoreleasing NSError* contentError = nil;
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&contentError];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"cleanup_done"];
    }
}

#pragma mark - Notification Handlers

-(void)handleLocationForbidden:(NSNotification*)notification
{
    NSLog(@"Cannot use LocationServices!");

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLocationServicesForbidden object:nil];
    [[AppState sharedInstance] stopLocationServices];
    
    CannotPlayViewController *cvc = [[CannotPlayViewController alloc] initWithNibName:@"CannotPlayViewController" bundle:nil];
    cvc.messageLabel.text = NSLocalizedString(@"No location available. Please turn on location in Settings", @"No location available. Please turn on location in Settings");
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:cvc];
    self.window.rootViewController = self.navigationController;

}

#pragma mark - Register NSUserDefaults
- (void)registerDefaultsFromSettingsBundle {
    // this function writes default settings as settings
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if(key) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}

@end
