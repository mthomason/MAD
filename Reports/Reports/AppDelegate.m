//
//  AppDelegate.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "MTQueryBuilderViewController.h"
#import "MTApplicationInstance.h"

#import "MTReportDesigner.h"
#import "MTReportViewer.h"
#import "MTQueryDesigner.h"
#import "MAReportDocument.h"

#import "RptqDocument.h"
#import "RptqDatabase.h"
#import "RptqQuery.h"

#import "MTViewControllerOpenDocument.h"
#import "UIManagedDocument+FileOperations.h"
#import "UIApplication+Extras.h"
#import "evp.h"
#import "VerifyStoreReceipt.h"

#import "UIDevice+Hack.h"
#import "MACloudManager.h"
#import "MTStoreKitController.h"
#import "MTLog.h"
#import "NSURL+Document.h"
#import "RptqDocument+Extras.h"

#import "UIColor+EverydayApps.h"

@interface AppDelegate()

@property (nonatomic, retain) MTApplicationInstance *applicationInstance;

@property (nonatomic, retain) UIFontDescriptor *mainFontDescriptor;
@property (nonatomic, retain) UIFontDescriptor *detailFontDescriptor;

@end

@implementation AppDelegate

void uncaughtExceptionHandler(NSException *exception);
void uncaughtExceptionHandler(NSException *exception) {
    MTLogStatic(@"%@", exception);
}

+ (MTApplicationInstance *)app {
    return [[[AppDelegate applicationInstance] retain] autorelease];
}

+ (MTApplicationInstance *)applicationInstance {
    AppDelegate *appDelegate = [[(AppDelegate *)[[UIApplication sharedApplication] delegate] retain] autorelease];
    MTApplicationInstance *result = [[appDelegate applicationInstance] retain];
    return [result autorelease];
}

+ (MAReportDocument *)activeReportDocument {
    MTApplicationInstance *applicationInstance = [AppDelegate applicationInstance];
    MAReportDocument *reportDocument = [[applicationInstance activeDocument] retain];
    return [reportDocument autorelease];
}

+ (RptqDocument *)activeRptqDocument {
    MAReportDocument *managedDocument = [AppDelegate activeReportDocument];
    RptqDocument *document = [[managedDocument activeDocument] retain];
    return [document autorelease];
}

+ (RptqDatabase *)activeRptqDatabase {
    RptqDocument *rptqDocument = [AppDelegate activeRptqDocument];
    NSSet *databaseSchemas = [rptqDocument hasDatabaseSchemas];
    RptqDatabase *databaseSchema = [[databaseSchemas anyObject] retain];
    return [databaseSchema autorelease];
}

+ (RptqQuery *)activeRptqQuery {
    RptqDatabase *rptqDatabase = [AppDelegate activeRptqDatabase];
    NSSet *queries = [rptqDatabase hasQueries];
    RptqQuery *query = [[queries anyObject] retain];
    return [query autorelease];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil];
    [_applicationInstance release];
    [_mainFontDescriptor release];
    [_detailFontDescriptor release];
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    MTApplicationInstance *appInstance = [[MTApplicationInstance alloc] init];
    [self setApplicationInstance:appInstance];
    [appInstance release];
    
    
    UIColor *titleTextColor = [UIColor tintColor2];
    NSDictionary *titleTextAttributes = @{ NSForegroundColorAttributeName : titleTextColor};

    
    [[UITabBarItem appearance] setTitleTextAttributes:titleTextAttributes
                                             forState:UIControlStateNormal];
    
    //Log uncaught errors.
    //NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    
    // FIXME: Have a seperate cache for each app instance, and then for each query even...
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheName];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheTables];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheLinks];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheGroups];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCachePredicates];
    
    //Dynamically choose which storyboard to run.
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *storyBoard = [MTApplicationInstance storyboard];
    [window setTintColor:[UIColor tintColor]];
    id initViewController = [storyBoard instantiateInitialViewController];
    [window setRootViewController:initViewController];
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
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (void)applicationDidBecomeActive:(UIApplication *)application { }

- (void)applicationWillTerminate:(UIApplication *)application {
    MAReportDocument *documentReport = [[[self applicationInstance] activeDocument] retain];
    [documentReport quickSave];
    [documentReport release];
}

const NSInteger MATagNewDocument = 3838;

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    NSString *openDocumentName = [[[url lastPathComponent] stringByDeletingPathExtension] retain];
    NSString *openDocumentExt = [[url pathExtension] retain];
    NSURL *destinationUrl = [[NSURL uniqueUrlForDocumentWithName:openDocumentName withExtension:openDocumentExt] retain];
    NSString *uniqueName = [[[destinationUrl lastPathComponent] stringByDeletingPathExtension] retain];
    
    NSError *fileWrittingError = nil;
    [[NSFileManager defaultManager] moveItemAtURL:url toURL:destinationUrl error:&fileWrittingError];
    BOOL result;
    if (fileWrittingError) {
        result = NO;
        [fileWrittingError presentErrorToUser];
    } else {
        result = YES;
        /*
        MTViewControllerOpenDocument *openDocumentViewController = (MTViewControllerOpenDocument *)[(UINavigationController *)[[self window] rootViewController] topViewController];
        if (openDocumentViewController != nil) {
            if ([MTApplicaitonInstance isMadDesigner]) {
                [openDocumentViewController performSegueWithIdentifier:MTSegueShowOpenDocument sender:destinationUrl];
            } else if ([MTApplicaitonInstance isMadViewer]) {
                [openDocumentViewController performSegueWithIdentifier:MTSegueOpenInViewer sender:destinationUrl];
            }
        }
         */
        UIAlertView *alertView = [[UIAlertView alloc]  initWithTitle:@"New Document"
                                                             message:[NSString stringWithFormat:@"Added document %@.", uniqueName]
                                                            delegate:nil
                                                   cancelButtonTitle:@"Continue"
                                                   otherButtonTitles:nil];
        [alertView setTag:MATagNewDocument];
        [alertView setDelegate:self];
        [alertView show];
        [alertView release];
    }
    
    [uniqueName release];
    [openDocumentName release];
    [openDocumentExt release];
    [destinationUrl release];
    return result;
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return [UIDevice isPad] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
}

#pragma mark - Key Value Store Notifications

- (void)keyValueStoreDidChange:(NSNotification *)notification {
    //MTLog(@"%@", notification);
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

- (void)alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView tag] == MATagNewDocument) {
        MTViewControllerOpenDocument *openDocumentViewController = (MTViewControllerOpenDocument *)[(UINavigationController *)[[self window] rootViewController] visibleViewController];
        if (openDocumentViewController != nil &&
            [openDocumentViewController respondsToSelector:@selector(updateFileList:)]) {
            [openDocumentViewController updateFileList:self];
        }
    }
}

#pragma mark - Sigh...

- (UIFont *)mainFont {
    [self initFonts];
    return [UIFont fontWithDescriptor:[self mainFontDescriptor] size:18.0000f];
}

- (UIFont *)detailFont {
    [self initFonts];
    return [UIFont fontWithDescriptor:[self detailFontDescriptor] size:12.0000f];
}

- (void)initFonts {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MTCellSkinner"];
        
        UIFont *detailFont = [[cell detailTextLabel] font];
        UIFontDescriptor *detailFontDescriptor = [[detailFont fontDescriptor] retain];
        [self setDetailFontDescriptor:detailFontDescriptor];
        
        UIFont *mainFont = [[cell textLabel] font];
        UIFontDescriptor *mainFontDescriptor = [[mainFont fontDescriptor] retain];
        [self setMainFontDescriptor:mainFontDescriptor];
        [mainFontDescriptor release];
        [detailFontDescriptor release];
        [cell release];
    });
}

@end
