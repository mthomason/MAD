//
//  AppDelegate.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate()

@end

@implementation AppDelegate

void uncaughtExceptionHandler(NSException *exception);
void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"%@", exception);
}

- (void)dealloc {
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    //[self checkUserICloudPreferenceAndSetupIfNecessary];
    
    dispatch_queue_t queuePriorityBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queuePriorityBackground, ^{
        UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle: NSLocalizedString(@"Email", @"Email")
                                                          action: @selector(email:)];
        UIMenuController *menu = [UIMenuController sharedMenuController];
        [menu setMenuItems:@[menuItem]];
        [menuItem release];
        dispatch_async(dispatch_get_main_queue(), ^{
        });
    });

    return YES;
}
			
- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application { }

- (void)applicationDidBecomeActive:(UIApplication *)application { }

- (void)applicationWillTerminate:(UIApplication *)application {
    MTReportDocument *documentReport = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    [documentReport save:nil];
    [documentReport release];
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    static NSNumber *isPad;
    if (!isPad) {
        isPad = @([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    }
    return   [isPad boolValue] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark - Actions

+ (NSString *)storyboardName {
    NSString *storyboardName = [UIDevice isPad] ? MTStoryboardReportDesignerPad : MTStoryboardReportDesigner;
    return storyboardName;
}

#pragma mark - iCloud

- (void)checkUbiquitousTokenFromPreviousLaunch:(id)currentToken
{
    // Fetch a previously stored value for the ubiquity identity token from NSUserDefaults.
    // That value can be compared to the current token to determine if the iCloud login has changed since the last launch of our application
    
    NSData* oldTokenData = [[NSUserDefaults standardUserDefaults] objectForKey:@"com.apple.CloudNotes.UbiquityIdentityToken"];
    id oldToken = oldTokenData ? [NSKeyedUnarchiver unarchiveObjectWithData:oldTokenData] : nil;
    if (oldTokenData && ![oldToken isEqual:currentToken]) {
        // If we had a token, we were signed in before.
        // If the token has change, a signout has occurred - either switching to another account or deleting iCloud entirely.
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"iCloud Sign-Out" message:@"You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)storeCurrentUbiquityToken:(id)currentToken
{
    // Write the ubquity identity token to NSUserDefaults if it exists.
    // Otherwise, remove the key.
    
    if (currentToken) {
        NSData* newTokenData = [NSKeyedArchiver archivedDataWithRootObject:currentToken];
        [[NSUserDefaults standardUserDefaults] setObject:newTokenData forKey:@"com.apple.CloudNotes.UbiquityIdentityToken"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"com.apple.CloudNotes.UbiquityIdentityToken"];
    }
}

- (void)checkUserICloudPreferenceAndSetupIfNecessary
{
    // Check to see whether the user has previously selected the iCloud storage option.
    // If so, check the iCloud storage state from previous launch.
    // If the user has previously chosen to use iCloud and we're still signed in, setup the CloudManager with cloud storage enabled.
    // If no user choice is recorded, use a UIAlert to fetch the user's preference.
    
    id currentToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* userICloudChoice = [userDefaults stringForKey:@"com.apple.CloudNotes.UseICloudStorage"];
    
    if ([userICloudChoice isEqualToString:@"YES"]) {
        [self checkUbiquitousTokenFromPreviousLaunch:currentToken];
    }
    
    if (currentToken) {
        if ([userICloudChoice length] == 0) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Choose Storage Option" message:@"Should documents be stored in iCloud or on just this device?" delegate:self cancelButtonTitle:@"Local only" otherButtonTitles:@"iCloud", nil];
            [alert show];
        }
        else if ([userICloudChoice isEqualToString:@"YES"]) {
            [[CloudManager sharedManager] setIsCloudEnabled:YES];
        }
    }
    else {
        [[CloudManager sharedManager] setIsCloudEnabled:NO];
        
        // Since the user is signed out of iCloud, reset the preference to not use iCloud, so if they sign in again we will prompt them to move data
        [userDefaults removeObjectForKey:@"com.apple.CloudNotes.UseICloudStorage"];
    }
    
    [self storeCurrentUbiquityToken:currentToken];
}

@end
