//
//  AppDelegate.m
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

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

@property (nonatomic, strong) MTApplicationInstance *applicationInstance;

@property (nonatomic, strong) UIFontDescriptor *mainFontDescriptor;
@property (nonatomic, strong) UIFontDescriptor *detailFontDescriptor;

@end

@implementation AppDelegate

void uncaughtExceptionHandler(NSException *exception);
void uncaughtExceptionHandler(NSException *exception) {
    MTLogStatic(@"%@", exception);
}

+ (MTApplicationInstance *)app {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    MTApplicationInstance *result = [appDelegate applicationInstance];
    return result;
}

+ (UIWindow *)window {
    return [[[UIApplication sharedApplication] windows] objectAtIndex:0];
}

+ (MAReportDocument *)activeReportDocument {
    MTApplicationInstance *applicationInstance = [AppDelegate app];
    MAReportDocument *reportDocument = [applicationInstance activeDocument];
    return reportDocument;
}

+ (RptqQuery *)activeRptqQuery {
    MAReportDocument *managedDocument = [AppDelegate activeReportDocument];
    RptqDocument *document = [managedDocument activeDocument];
    NSSet *databaseSchemas = [document hasDatabaseSchemas];
    RptqDatabase *databaseSchema = [databaseSchemas anyObject];
    NSSet *queries = [databaseSchema hasQueries];
    RptqQuery *query = [queries anyObject];
    return query;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:nil];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
    
    MTApplicationInstance *appInstance = [[MTApplicationInstance alloc] init];
    [self setApplicationInstance:appInstance];
    
    UIColor *titleTextColor = [UIColor tintColor2];
    NSDictionary *titleTextAttributes = @{ NSForegroundColorAttributeName : titleTextColor};

    
    [[UITabBarItem appearance] setTitleTextAttributes:titleTextAttributes
                                             forState:UIControlStateNormal];
    
    //Log uncaught errors.
    //NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    [self deleteCoreDataCache];
    
    //Dynamically choose which storyboard to run.
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *storyBoard = [MTApplicationInstance storyboard];
    [window setTintColor:[UIColor tintColor]];
    id initViewController = [storyBoard instantiateInitialViewController];
    [window setRootViewController:initViewController];
    [window makeKeyAndVisible];
    [self setWindow: window];

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
    
    [self registerDefaultsFromSettingsBundle];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application { }

- (void)applicationDidEnterBackground:(UIApplication *)application { }

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (void)applicationDidBecomeActive:(UIApplication *)application { }

- (void)applicationWillTerminate:(UIApplication *)application {
    MAReportDocument *documentReport = [[self applicationInstance] activeDocument];
    [documentReport quickSave];
}

const NSInteger MATagNewDocument = 3838;

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {

    NSString *openDocumentName = [[url lastPathComponent] stringByDeletingPathExtension];
    NSString *openDocumentExt = [url pathExtension];
    NSURL *destinationUrl = [NSURL uniqueUrlForDocumentWithName:openDocumentName withExtension:openDocumentExt];
    NSString *uniqueName = [[destinationUrl lastPathComponent] stringByDeletingPathExtension];
    
    NSError *fileWrittingError = nil;
    [[NSFileManager defaultManager] moveItemAtURL:url toURL:destinationUrl error:&fileWrittingError];
    BOOL result;
    if (fileWrittingError) {
        result = NO;
        [fileWrittingError presentErrorToUser];
    } else {
        result = YES;
        UIAlertView *alertView = [[UIAlertView alloc]  initWithTitle:@"New Document"
                                                             message:[NSString stringWithFormat:@"Added document %@.", uniqueName]
                                                            delegate:nil
                                                   cancelButtonTitle:@"Continue"
                                                   otherButtonTitles:nil];
        [alertView setTag:MATagNewDocument];
        [alertView setDelegate:self];
        [alertView show];
    }
    return result;
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return [UIDevice isPad] ? UIInterfaceOrientationMaskAll : UIInterfaceOrientationMaskAllButUpsideDown;
}

- (void)deleteCoreDataCache {
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(dipatchQueue, ^{
        [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheName];
        [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheTables];
        [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheLinks];
        [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheGroups];
        [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCachePredicates];
    });
}

- (void)registerDefaultsFromSettingsBundle {
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(dipatchQueue, ^{

        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults synchronize];
        
        NSString *pathSettingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
        NSAssert(pathSettingsBundle, @"Could not find Settings.bundle");
        NSString *pathRootPlist = [pathSettingsBundle stringByAppendingPathComponent:@"Root.plist"];
        
        
        NSDictionary *rootPlistSettings = [NSDictionary dictionaryWithContentsOfFile:pathRootPlist];
        NSArray *preferences = [rootPlistSettings objectForKey:@"PreferenceSpecifiers"];
        NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
        
        for (NSDictionary *prefSpecification in preferences)  {
            NSString *key = [prefSpecification objectForKey:@"Key"];
            if (key) {
                
                id currentObject = [standardUserDefaults objectForKey:key];
                if (currentObject == nil) {

                    id objectToSet = [prefSpecification objectForKey:@"DefaultValue"];
                    [defaultsToRegister setObject:objectToSet forKey:key];
                }
            }
        }
        
        [standardUserDefaults registerDefaults:defaultsToRegister];
        [standardUserDefaults synchronize];
    });
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
        UIFontDescriptor *detailFontDescriptor = [detailFont fontDescriptor];
        [self setDetailFontDescriptor:detailFontDescriptor];
        
        UIFont *mainFont = [[cell textLabel] font];
        UIFontDescriptor *mainFontDescriptor = [mainFont fontDescriptor];
        [self setMainFontDescriptor:mainFontDescriptor];
    });
}

@end
