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
#import "UIApplication+Extras.h"
#import "evp.h"

#import "VerifyStoreReceipt.h"

NSString * const MTBundleIdDesigner                                 = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdViewer                                   = @"com.everydayapps.mad.viewer";
NSInteger  const MTGlobalBundleVersionMajor                         = 2;
NSString * const MTGlobalBundleVersion                              = @"1.0.79";
NSString * const MTGlobalBundleShortVersion                         = @"1.0.79";
NSString * const MTGlobalBundleRev                                  = @"700";

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
    
    //List all fonts
    
    //NSArray *fontFamilies = [UIFont familyNames];
    
    //for (NSInteger i = 0; i < [fontFamilies count]; i++) {
    //    NSString *fontFamily = [fontFamilies objectAtIndex:i];
    //    NSArray *fontNames = [UIFont fontNamesForFamilyName:[fontFamilies objectAtIndex:i]];
    //    NSLog (@"%@: %@", fontFamily, fontNames);
    //}
    
    
    //Log uncaught errors.
    //NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheName];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheTables];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheLinks];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheGroups];
    [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCachePredicates];
    
	NSCAssert([MTGlobalBundleShortVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"Whoa! CFBundleShortVersionString, bra.");
	NSCAssert([[AppDelegate bundleId] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]], @"Whoops! check the hard-coded bundle identifier!");
    NSCAssert([MTGlobalBundleRev isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MADRev"]], @"Check the hard-coded MADRev, dog!");
    NSCAssert([[AppDelegate bundleId] isEqualToString:MTBundleIdMadDesigner] || [[AppDelegate bundleId] isEqualToString:MTBundleIdMadViewer], @"Bundle ID is incorrect.");
    NSCAssert([[AppDelegate bundleVersion] isEqualToString:MTGlobalBundleVersion], @"Bundle version is incorrect.");
    NSCAssert([MTGlobalBundleShortVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"Bundle version is incorrect.");

    //Dynamically choose which storyboard to run.
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName: [AppDelegate storyboardName]
                                                         bundle: nil];
    [window setTintColor:[UIColor tintColor]];
    [window setRootViewController:[storyBoard instantiateInitialViewController]];
    [window makeKeyAndVisible];
    [self setWindow: window];
    [window release];

    //UIFont *font = [UIFont fontWithName:@"DestructoBeamBB" size:18.0000f];
    //[[UINavigationBar appearance] setTitleTextAttributes:@{
    //                                                       UITextAttributeFont            : font
    //                                                       }];
    
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

- (void)applicationDidBecomeActive:(UIApplication *)application {

}

- (void)applicationWillTerminate:(UIApplication *)application {
    MAReportDocument *documentReport = [[[MTActiveDocument sharedDocument] activeDocument] retain];
    [documentReport save:nil];
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
            if ([AppDelegate isMadDesigner]) {
                [openDocumentViewController performSegueWithIdentifier:MTSegueShowOpenDocument sender:destinationUrl];
            } else if ([AppDelegate isMadViewer]) {
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
    MTLog(@"%@", notification);
}

#pragma mark - Actions

+ (NSAttributedString *)attributedStringMadDesigner {

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    NSString *title = @"MAD Designer";
    NSMutableAttributedString *attributedStringMadDesigner = [[NSMutableAttributedString alloc] initWithString:title];
    NSInteger length = [[attributedStringMadDesigner string] length];
    [attributedStringMadDesigner addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Futura-CondensedMedium" size:18.0000f] range:NSMakeRange(0, 3)];
    [attributedStringMadDesigner addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Futura-CondensedExtraBold" size:18.0000f] range:NSMakeRange(4, length - 4)];
    [attributedStringMadDesigner addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, length)];
    [paragraphStyle release];
    return [attributedStringMadDesigner autorelease];

}

+ (NSAttributedString *)attributedStringMadViewer {

    NSMutableAttributedString *attributedStringMadDesigner = [[NSMutableAttributedString alloc] initWithString:@"MAD Viewer"];
    NSInteger length = [[attributedStringMadDesigner string] length];
    UIFont *fonta = [UIFont fontWithName:@"Futura-CondensedMedium" size:18.0000f];
    UIFont *fontb = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:18.0000f];
    [attributedStringMadDesigner addAttribute:NSFontAttributeName value:fonta range:NSMakeRange(0, 3)];
    [attributedStringMadDesigner addAttribute:NSFontAttributeName value:fontb range:NSMakeRange(4, length - 4)];
    return [attributedStringMadDesigner autorelease];

}

+ (NSAttributedString *)attributedStringMadQuery {

    NSMutableAttributedString *attributedStringMadDesigner = [[NSMutableAttributedString alloc] initWithString:@"MAD Query"];
    NSInteger length = [[attributedStringMadDesigner string] length];
    UIFont *fonta = [UIFont fontWithName:@"Futura-CondensedMedium" size:18.0000f];
    UIFont *fontb = [UIFont fontWithName:@"Futura-CondensedExtraBold" size:18.0000f];
    [attributedStringMadDesigner addAttribute:NSFontAttributeName value:fonta range:NSMakeRange(0, 3)];
    [attributedStringMadDesigner addAttribute:NSFontAttributeName value:fontb range:NSMakeRange(4, length - 4)];
    return [attributedStringMadDesigner autorelease];

}

+ (NSString *)storyboardName {
    static NSString *_storyboardName;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([AppDelegate isMadDesigner]) {
            if ([UIDevice isModernOS]) {
                _storyboardName = [UIDevice isPad] ?
                MTStoryboardReportDesignerPad : MTStoryboardReportDesigner;
            } else {
                _storyboardName = [UIDevice isPad] ?
                MTStoryboardReportDesignerPadLagacy : MTStoryboardReportDesigner;
            }
        } else if ([AppDelegate isMadViewer]) {
            if ([UIDevice isModernOS]) {
                _storyboardName = [UIDevice isPad] ?
                MTStoryboardReportViewerPad : MTStoryboardReportViewer;
            } else {
                _storyboardName = [UIDevice isPad] ?
                MTStoryboardReportViewerPadLagacy : MTStoryboardReportViewer;
            }
        }
    });
    
    return _storyboardName;
}

+ (BOOL)isMadViewer {
    static BOOL _isMadViewer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        _isMadViewer = [bundleId isEqualToString:MTBundleIdMadViewer];
    });
    return _isMadViewer;
}

+ (BOOL)isMadDesigner {
    static BOOL _isMadDesigner;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        _isMadDesigner = [bundleId isEqualToString:MTBundleIdMadDesigner];
    });
    return _isMadDesigner;
}

+ (NSString *)bundleId {
    static NSString *_bundleId;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([AppDelegate isMadDesigner]) {
            _bundleId = MTBundleIdMadDesigner;
        } else if ([AppDelegate isMadViewer]) {
            _bundleId = MTBundleIdMadViewer;
        }
    });
    return _bundleId;
}

+ (NSString *)bundleVersion {
    static NSString *_bundleVersion;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _bundleVersion = MTGlobalBundleVersion;
    });
    return _bundleVersion;
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

@end
