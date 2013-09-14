//
//  AppDelegate.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2012 Everyday Apps LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "MAReportDocument.h"
#import "MTViewControllerOpenDocument.h"
#import "UIManagedDocument+FileOperations.h"

NSString * const MTBundleIdDesigner = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdViewer   = @"com.everydayapps.mad.viewer";

@interface AppDelegate()

@end

@implementation AppDelegate

    UIView* _waitingHudView;

void uncaughtExceptionHandler(NSException *exception);
void uncaughtExceptionHandler(NSException *exception) {
    MTLogStatic(@"%@", exception);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil];
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //Log uncaught errors.
    //NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    //Dynamically choose which storyboard to run.
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName: [AppDelegate storyboardName]
                                                         bundle: nil];
    [window setRootViewController:[storyBoard instantiateInitialViewController]];
    [window makeKeyAndVisible];
    [self setWindow: window];
    [window release];

    //Startup strore kit.
    [MTStoreKitController sharedObject];

    //Setup iCloud KVS
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver: self
                      selector: @selector(keyValueStoreDidChange:)
                          name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                        object: nil];
    
    NSUbiquitousKeyValueStore *defaultStore = [NSUbiquitousKeyValueStore defaultStore];
    [defaultStore synchronize];
    
    
    /*
    //Setup iCloud Document Management
    [self checkUserICloudPreferenceAndSetupIfNecessary];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(willBeginFetchingUbiquitousContainer)
                                                 name: UbiquitousContainerFetchingWillBeginNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(didEndFetchingUbiquitousContainer)
                                                 name: UbiquitousContainerFetchingDidEndNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(checkUserICloudPreferenceAndSetupIfNecessary)
                                                 name: NSUbiquityIdentityDidChangeNotification
                                               object: nil];
*/

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {

}

- (void)applicationWillTerminate:(UIApplication *)application {
    MAReportDocument *documentReport = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    [documentReport save:nil];
    [documentReport release];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    NSData *data = [[NSData alloc] initWithContentsOfURL:url];
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithSerializedRepresentation:data];
    NSString *name = [[url lastPathComponent] stringByDeletingPathExtension];
    NSURL *destinationUrl = [[NSURL uniqueUrlForDocumentWithName:name
                                                  withExtension:MTDocumentExtentionMobleApplicationDocumentArchive] retain];
    
    NSFileWrapperWritingOptions writingOptions = NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating;
    NSError* fileWrittingError = nil;
    [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
    if (fileWrittingError) {
        fileWrittingError = nil;
        [fileWrapper writeToURL:destinationUrl options:writingOptions originalContentsURL:url error:&fileWrittingError];
    }
    
    BOOL savedUrl = fileWrittingError == nil;
    if (savedUrl) {
        
        MTViewControllerOpenDocument *openDocumentViewController = (MTViewControllerOpenDocument *)[(UINavigationController *)[[self window] rootViewController] topViewController];
        if (openDocumentViewController != nil) {
            if ([AppDelegate isMadDesigner]) {
                [openDocumentViewController performSegueWithIdentifier:MTSegueShowOpenDocument sender:destinationUrl];
            } else if ([AppDelegate isMadViewer]) {
                [openDocumentViewController performSegueWithIdentifier:MTSegueOpenInViewer sender:destinationUrl];
            }
        }
        
    } else {
        [fileWrittingError presentErrorToUser];
    }
    [data release];
    [fileWrapper release];
    [destinationUrl release];
    return savedUrl;
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return [UIDevice isPad] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark - Key Value Store Notifications

- (void)keyValueStoreDidChange:(NSNotification *)notification {
    MTLog(@"%@", notification);
}

#pragma mark - Actions

+ (NSString *)storyboardName {
    static NSString *_storyboardName;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[AppDelegate bundleId] isEqualToString:MTBundleIdDesigner]) {
            if ([UIDevice isModernOS]) {
                _storyboardName = [UIDevice isPad] ?
                MTStoryboardReportDesignerPad : MTStoryboardReportDesigner;
            } else {
                _storyboardName = [UIDevice isPad] ?
                MTStoryboardReportDesignerPadLagacy : MTStoryboardReportDesignerLagacy;
            }
        } else {
            if ([UIDevice isModernOS]) {
                _storyboardName = [UIDevice isPad] ?
                MTStoryboardReportViewerPad : MTStoryboardReportViewer;
            } else {
                _storyboardName = [UIDevice isPad] ?
                MTStoryboardReportViewerPadLagacy : MTStoryboardReportViewerLagacy;
            }
        }
    });
    
    return _storyboardName;
}

+ (BOOL)isMadViewer {
    static BOOL _isMadViewer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleId = [AppDelegate bundleId];
        _isMadViewer = [bundleId isEqualToString:MTBundleIdMadViewer];
    });
    return _isMadViewer;
}

+ (BOOL)isMadDesigner {
    static BOOL _isMadDesigner;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleId = [AppDelegate bundleId];
        _isMadDesigner = [bundleId isEqualToString:MTBundleIdMadDesigner];
    });
    return _isMadDesigner;
}

+ (NSString *)bundleId {
    static NSString *_bundleId;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _bundleId = [[NSBundle mainBundle] bundleIdentifier];
    });
    return _bundleId;
}

#pragma mark - Document Interaction Controller Delegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return [[self window] rootViewController];
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:[controller URL] error:&error];
}

#pragma mark - iCloud Shit

NSString * const MTICloudUbiquityToken  = @"com.everydayapps.mad.icloud.ubiquityIdentityToken";
NSString * const MTICloudUserEnabled    = @"com.everydayapps.mad.icloud.userenabled";
NSString * const MTICloudUserPrefsSet   = @"com.everydayapps.mad.icloud.userprefsset";

- (void)storeCurrentUbiquityToken:(id)currentToken {
    // Write the ubquity identity token to NSUserDefaults if it exists.
    // Otherwise, remove the key.
    
    if (currentToken) {
        NSData* newTokenData = [NSKeyedArchiver archivedDataWithRootObject:currentToken];
        [[NSUserDefaults standardUserDefaults] setObject:newTokenData forKey:MTICloudUbiquityToken];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:MTICloudUbiquityToken];
    }
}

- (void)checkUserICloudPreferenceAndSetupIfNecessary {
    // Check to see whether the user has previously selected the iCloud storage option.
    // If so, check the iCloud storage state from previous launch.
    // If the user has previously chosen to use iCloud and we're still signed in, setup the CloudManager with cloud storage enabled.
    // If no user choice is recorded, use a UIAlert to fetch the user's preference.
    
    id currentToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL iCloudPrefsSet = [userDefaults boolForKey:MTICloudUserPrefsSet];
    BOOL iCloudEnabled = [userDefaults boolForKey:MTICloudUserEnabled];
    
    if (iCloudEnabled) {
        //Check the Ubiquitous Token from the Previous Launch
        // Fetch a previously stored value for the ubiquity identity token from NSUserDefaults.
        // That value can be compared to the current token to determine if the iCloud login has changed since the last launch of our application
        
        NSData *oldTokenData = [userDefaults objectForKey:MTICloudUbiquityToken];
        id oldToken = oldTokenData ? [NSKeyedUnarchiver unarchiveObjectWithData:oldTokenData] : nil;
        if (oldTokenData && ![oldToken isEqual:currentToken]) {
            // If we had a token, we were signed in before.
            // If the token has change, a signout has occurred - either switching to another account or deleting iCloud entirely.
            NSString *title = NSLocalizedString(@"iCloud Sign-Out", @"iCloud Sign-Out");
            NSString *message = NSLocalizedString(@"You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents", @"You have signed out of the iCloud account previously used to store documents. Sign back in to access those documents");
            NSString *cancel = NSLocalizedString(@"OK", @"OK");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancel otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
    }
    
    if (currentToken) {
        if (iCloudPrefsSet == NO) {
            
            NSString *title = NSLocalizedString(@"Choose Storage Option", @"Choose Storage Option");
            NSString *message = NSLocalizedString(@"Should documents be stored in iCloud or on just this device?", @"Should documents be stored in iCloud or on just this device?");
            NSString *cancel = NSLocalizedString(@"Local only", @"Local only");
            NSString *other = NSLocalizedString(@"iCloud", @"iCloud");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:other, nil];
            [alert show];
            [alert release];
        } else {
            [[MACloudManager sharedManager] setIsCloudEnabled:YES];
        }
    } else {
        [[MACloudManager sharedManager] setIsCloudEnabled:NO];
        
        // Since the user is signed out of iCloud, reset the preference to not use iCloud, so if they sign in again we will prompt them to move data
        [userDefaults removeObjectForKey:MTICloudUserEnabled];
        [userDefaults removeObjectForKey:MTICloudUserPrefsSet];
    }
    
    [self storeCurrentUbiquityToken:currentToken];
}

- (void)alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:MTICloudUserEnabled];
        [[MACloudManager sharedManager] setIsCloudEnabled:YES];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:MTICloudUserEnabled];
        [[MACloudManager sharedManager] setIsCloudEnabled:NO];
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:MTICloudUserPrefsSet];
}

- (void)displayWaitingHud {
    if (!_waitingHudView) {
        _waitingHudView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
        _waitingHudView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        CGRect hudBounds = _waitingHudView.bounds;
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        label.text = NSLocalizedString(@"Waiting for iCloud setup...", @"Waiting for iCloud setup...");
        [label sizeToFit];
        CGSize labelSize = label.frame.size;
        label.frame = CGRectMake((CGRectGetWidth(hudBounds) - labelSize.width) / 2.0, (CGRectGetHeight(hudBounds) - labelSize.height) / 2.0, labelSize.width, labelSize.height);
        [_waitingHudView addSubview:label];
        [[[UIApplication sharedApplication] keyWindow] addSubview:_waitingHudView];
        [label release];
    }
}

- (void)willBeginFetchingUbiquitousContainer {
    [self performSelector:@selector(displayWaitingHud) withObject:nil afterDelay:0.15];
}

- (void)didEndFetchingUbiquitousContainer {
    [[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(displayWaitingHud) object:nil];
    [_waitingHudView removeFromSuperview];
}

@end
