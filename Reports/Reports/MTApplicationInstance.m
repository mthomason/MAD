//
//  MTApplicaitonInstance.m
//  MAD
//
//  Created by Michael Thomason on 2/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTApplicationInstance.h"
#import <CoreData/CoreData.h>
#import "MTQueryBuilderViewController.h"

#import "UIColor+EverydayApps.h"
#import "UIDevice+Hack.h"
#import "MAReportDocument.h"
#import "NSFileManager+Common.h"
#import "UAAppReviewManager.h"

#import "MTUser.h"
#import "MTReportDesigner.h"
#import "MTReportViewer.h"
#import "MTQueryDesigner.h"
#import "MAReportDocument.h"
#import "MTUser.h"
#import "MADocumentState.h"

#import "NSFileManager+Common.h"
#import "NSParagraphStyle+CommonStyles.h"

NSString * const MTApplicationIdMadDesigner                          = @"666001433";
NSString * const MTApplicationIdMadViewer                            = @"666003759";

NSString * const MTBundleIdMadDesigner                              = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdMadViewer                                = @"com.everydayapps.mad.viewer";

NSString * const MTGlobalBundleVersion                              = @"6.0.45";
NSString * const MTGlobalBundleShortVersion                         = @"6.0.45";
NSString * const MTGlobalBundleRev                                  = @"1364";

NSString * const MTStoryboardReportDesigner                         = @"MTStoryboardReportDesigner";
NSString * const MTStoryboardReportDesignerPad                      = @"MTStoryboardReportDesignerPad";
NSString * const MTStoryboardReportDesignerLagacy                   = @"MTStoryboardReportDesignerOS6";
NSString * const MTStoryboardReportDesignerPadLagacy                = @"MTStoryboardReportDesignerPadOS6";

NSString * const MTStoryboardReportViewer                           = @"MTStoryboardReportViewer";
NSString * const MTStoryboardReportViewerPad                        = @"MTStoryboardReportViewerPad";
NSString * const MTStoryboardReportViewerLagacy                     = @"MTStoryboardReportViewerOS6";
NSString * const MTStoryboardReportViewerPadLagacy                  = @"MTStoryboardReportViewerPadOS6";

@interface MTApplicationInstance ()

@property (nonatomic, strong) NSURL *currentDocument;           //To support opening multiple documents
                                                                    //change this url to the url of the open
                                                                    //document.  This url will be key for the
                                                                    //documents array.
@property (nonatomic, strong, readwrite) MTUser *user;
@property (nonatomic, strong, readwrite) MTReportDesigner *reportDesigner;
@property (nonatomic, strong, readwrite) MTReportViewer *reportViewer;
@property (nonatomic, strong, readwrite) MTQueryDesigner *queryDesigner;

@property (nonatomic, strong) NSMutableDictionary *documents;   //MAReportDocument stored by their NSURLS

@end

@implementation MTApplicationInstance

- (id)init {
    self = [super init];
    if (self) {

        MTUser *user = [[MTUser alloc] init];
        [self setUser:user];

        MTReportDesigner *reportDesigner = [[MTReportDesigner alloc] init];
        [self setReportDesigner:reportDesigner];

        MTQueryDesigner *queryDesigner = [[MTQueryDesigner alloc] init];
        [self setQueryDesigner:queryDesigner];
        
        MTReportViewer *reportViewer = [[MTReportViewer alloc] init];
        [self setReportViewer:reportViewer];

        [UAAppReviewManager showPromptWithShouldPromptBlock:^(NSDictionary *trackingInfo) {
            return NO;
        }];
                
        // FIXME: Run these checks on app instance start...
        NSCAssert([MTGlobalBundleShortVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"Whoa! CFBundleShortVersionString, bra.");
        NSCAssert([[MTApplicationInstance bundleId] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]], @"Whoops! check the hard-coded bundle identifier!");
        NSCAssert([MTGlobalBundleRev isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MADRev"]], @"Check the hard-coded MADRev, dog!");
        NSCAssert([[MTApplicationInstance bundleId] isEqualToString:MTBundleIdMadDesigner] || [[MTApplicationInstance bundleId] isEqualToString:MTBundleIdMadViewer], @"Bundle ID is incorrect.");
        NSCAssert([[MTApplicationInstance bundleVersion] isEqualToString:MTGlobalBundleVersion], @"Bundle version is incorrect.");
        NSCAssert([MTGlobalBundleShortVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"Bundle version is incorrect.");
        
        NSMutableDictionary *documents = [[NSMutableDictionary alloc] init];
        [self setDocuments:documents];
        
        [self setupAppReviewManager:self];
    }
    return self;
}

#pragma mark - UAAppReviewManager

- (void)setupAppReviewManager:(id)sender {
    
    NSString *appId = [MTApplicationInstance applicationId];
    NSString *appName = [MTApplicationInstance applicationName];

	[UAAppReviewManager setAppID:appId];
	
    BOOL debug = NO;
    [UAAppReviewManager setDebug:debug];
    [UAAppReviewManager userDidSignificantEvent:NO];    //Launch is significant, but not for display of prompt
    [UAAppReviewManager setAppName:appName];

    NSString *formatString = NSLocalizedString(@"Do you find %@ useful?", @"Do you find %@ useful?");
    NSString *reviewTitle = [NSString stringWithFormat:formatString, appName];
	[UAAppReviewManager setReviewTitle:reviewTitle];
    
	// This overrides the default value, read from the UAAppReviewManager bundle plist
    NSString *plea = NSLocalizedString(@"Continued development relies on this softwares success.  If you find this software useful, then please take the time to show your support. Leaving a review.", @"Continued development relies on this softwares success.  If you find this software useful, then please take the time to show your support. Leaving a review.");
	[UAAppReviewManager setReviewMessage:plea];
    
    NSString *buttonTitleNever = NSLocalizedString(@"Never", @"Never");
    NSString *buttonTitleRate = NSLocalizedString(@"Lets Do It", @"Lets Do It");
    NSString *buttonTitleLater = NSLocalizedString(@"Maybe... later", @"Maybe... later");
	[UAAppReviewManager setCancelButtonTitle:   buttonTitleNever];
	[UAAppReviewManager setRateButtonTitle:     buttonTitleRate];
	[UAAppReviewManager setRemindButtonTitle:   buttonTitleLater];
	[UAAppReviewManager setDaysUntilPrompt:28];
	[UAAppReviewManager setDaysBeforeReminding:13];
	[UAAppReviewManager setShouldPromptIfRated:NO];
	[UAAppReviewManager setSignificantEventsUntilPrompt:20];
	[UAAppReviewManager setUseMainAppBundleForLocalizations:YES];
    [UAAppReviewManager setAffiliateCode:@""];                      // FIXME: Add this affiliate code.
	[UAAppReviewManager setAffiliateCampaignCode:@""];              // FIXME: Add this affiliate code.
	[UAAppReviewManager setOnDeclineToRate:^() {}];
	[UAAppReviewManager setOnDidDisplayAlert:^() {}];
	[UAAppReviewManager setOnDidOptToRate:^() {}];
	[UAAppReviewManager setOnDidOptToRemindLater:^() {}];
	[UAAppReviewManager setKey:@"kSettingsSignificantEventTally" forUAAppReviewManagerKeyType:UAAppReviewManagerKeySignificantEventCount];
    
}

#pragma mark - App settings

+ (NSString *)applicationNamePrefixPart {
    return @"MAD";
}

+ (NSString *)applicationNamePrefixPartFormat {
    return @"MAD %@";
}

+ (NSString *)applicationNameSufixPart {
    return [MTApplicationInstance isMadDesigner] ?
                                                    NSLocalizedString(@"Designer", @"Designer") :
                                                    NSLocalizedString(@"Viewer", @"Viewer");
}

+ (NSString *)applicationId {
    return [MTApplicationInstance isMadDesigner] ?
                                        MTApplicationIdMadDesigner :
                                        MTApplicationIdMadViewer;
}

+ (NSString *)bundleDisplayName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:MTBundleDisplayName];;
}

+ (NSString *)applicationName {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPartFormat];
    NSString *localizedSuffix = [MTApplicationInstance applicationNameSufixPart];
    return [NSString stringWithFormat: localizedPrefix, localizedSuffix];
}

+ (NSString *)madDesigner {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPartFormat];
    NSString *localizedSuffix = NSLocalizedString(@"Designer", @"Designer");
    return [NSString stringWithFormat: localizedPrefix, localizedSuffix];
}

+ (NSString *)madViewer {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPartFormat];
    NSString *localizedSuffix = NSLocalizedString(@"Viewer", @"Viewer");
    return [NSString stringWithFormat: localizedPrefix, localizedSuffix];
}

+ (NSString *)madQuery {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPartFormat];
    NSString *localizedSuffix = NSLocalizedString(@"Query", @"Query");
    return [NSString stringWithFormat: localizedPrefix, localizedSuffix];
}

- (MAReportDocument *)currentdocappinst {
    MAReportDocument *result = nil;
    if ([self reportState] == MTReportStateOpen) {
        NSDictionary *documents = [self documents];
        NSURL *currentUrl = [self currentDocument];
        result = [documents objectForKey:currentUrl];
    }
    return result;
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
    if ([MTApplicationInstance isMadDesigner]) {
        _bundleId = MTBundleIdMadDesigner;
    } else if ([MTApplicationInstance isMadViewer]) {
        _bundleId = MTBundleIdMadViewer;
    }
    return _bundleId;
}

+ (NSString *)bundleVersion {
    return MTGlobalBundleVersion;
}

+ (NSAttributedString *)localizedAttributedApplicationNameMadDesigner {
    NSString *title = [MTApplicationInstance madDesigner];
    return [MTApplicationInstance logoForTitle:title];
}

+ (NSAttributedString *)localizedAttributedApplicationNameMadViewer {
    NSString *title = [MTApplicationInstance madViewer];
    return [MTApplicationInstance logoForTitle:title];
}

+ (NSAttributedString *)localizedAttributedApplicationNameMadQuery {
    NSString *title = [MTApplicationInstance madQuery];
    return [MTApplicationInstance logoForTitle:title];
}
            
+ (NSAttributedString *)logoForTitle:(NSString *)title {
    
    
    NSParagraphStyle *paragraphStyle = [NSParagraphStyle titleBarStyle];
    NSMutableAttributedString *attributedStringMadDesigner = [[NSMutableAttributedString alloc] initWithString:title];
    NSInteger length = [[attributedStringMadDesigner string] length];
    
    UIFont *fonta = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0000f];
    UIFont *fontb = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0000f];
    NSRange range = NSMakeRange(0, length);
    UIColor *foregroundColor = [UIColor whiteColor];
    NSArray *components = [title componentsSeparatedByString:@" "];
    NSRange firstRange;
    NSRange secondRange;
    
    if ([components count] == 2) {
        firstRange = [title rangeOfString:[components objectAtIndex:0]];
        secondRange = [title rangeOfString:[components objectAtIndex:1]];
    } else {
        firstRange = range; secondRange = range;
    }
    
    [attributedStringMadDesigner addAttribute:NSFontAttributeName value:fonta range:firstRange];
    [attributedStringMadDesigner addAttribute:NSFontAttributeName value:fontb range:secondRange];
    [attributedStringMadDesigner addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
    [attributedStringMadDesigner addAttribute:NSForegroundColorAttributeName value:foregroundColor range:range];
    
    [attributedStringMadDesigner addAttribute:NSKernAttributeName value:[NSNull null] range:range];
    return attributedStringMadDesigner;
}

+ (NSString *)storyboardName {
    NSString *_storyboardName;
    if ([MTApplicationInstance isMadDesigner]) {
        if ([UIDevice isModernOS]) {
            _storyboardName = [UIDevice isPad] ? MTStoryboardReportDesignerPad : MTStoryboardReportDesigner;
        } else {
            _storyboardName = [UIDevice isPad] ? MTStoryboardReportDesignerPadLagacy : MTStoryboardReportDesigner;
        }
    } else if ([MTApplicationInstance isMadViewer]) {
        if ([UIDevice isModernOS]) {
            _storyboardName = [UIDevice isPad] ? MTStoryboardReportViewerPad : MTStoryboardReportViewer;
        } else {
            _storyboardName = [UIDevice isPad] ? MTStoryboardReportViewerPadLagacy : MTStoryboardReportViewer;
        }
    }
    return _storyboardName;
}

+ (UIStoryboard *)storyboard {
    NSString *storyboardName = [MTApplicationInstance storyboardName];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    return storyboard;
}

+ (NSAttributedString *)waterMarkStringMad {
    NSString *displayStringText = [MTApplicationInstance applicationNamePrefixPart];
    UIColor *foregroundColor = [UIColor lightTextColor];
    CGFloat fontSize = [MTApplicationInstance isMadDesigner] ? 100.0000f : 78.0000f;
    UIFont *customFont = [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:fontSize];
    NSDictionary *attributes = @{
                                 NSForegroundColorAttributeName : foregroundColor,
                                 NSFontAttributeName : customFont
                                 };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: displayStringText
                                                                           attributes: attributes];
    return attributedString;
}

+ (NSAttributedString *)waterMarkStringDesigner {
    NSString *displayStringText = [[MTApplicationInstance applicationNameSufixPart] uppercaseString];
    UIColor *foregroundColor = [UIColor lightTextColor];
    CGFloat fontSize =  [MTApplicationInstance isMadDesigner] ? 44.5000f : 46.0000f;
    UIFont *customFont = [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:fontSize];
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    NSDictionary *attributes = @{
                                 NSForegroundColorAttributeName : foregroundColor,
                                 NSFontAttributeName : customFont,
                                 NSParagraphStyleAttributeName : paragraphStyle
                                 };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString: displayStringText attributes:attributes];
    return attributedString;
}

+ (void)drawMadWatermarkInRect:(CGRect)rect {

    NSAttributedString *displayString = [MTApplicationInstance waterMarkStringMad];
    NSAttributedString *displayString2 = [MTApplicationInstance waterMarkStringDesigner];

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    NSInteger rowCounter = 0, columnCounter = 0;
    CGSize logoSize = [displayString size];
    CGSize logoSize2 = [displayString2 size];
    CGSize logoMargin = CGSizeMake(45.0000f, 66.0000f);
    CGRect logoRect, logoRect2;
    
    CGFloat xHalfSize = logoMargin.width / 2.0000f - logoSize.width / 2.0000f;
    CGFloat xOffset = xHalfSize - 66.0000f;
    CGFloat yOffset = logoMargin.height / 2.0000f - logoSize.height / 2.0000f - 150.0000f;
    
    do {
        columnCounter = 0;
        
        do {
            @autoreleasepool {

                BOOL moveLeft = rowCounter % 2 == 0;
                CGFloat x = ((columnCounter * 2) + 1) * logoMargin.width + columnCounter * logoSize.width + xOffset;
                CGFloat xQuarterSize = xOffset / 2;
                if (moveLeft) {
                    x -= xQuarterSize;
                } else {
                    x += xQuarterSize;
                }
                CGFloat y = ((rowCounter * 2) + 1) * logoMargin.height + rowCounter * logoSize.height + logoSize2.height + yOffset;
                logoRect = CGRectMake(x, y, logoSize.width, logoSize.height);
                CGFloat y2 = y + logoSize.height;
                logoRect2 = CGRectMake(x, y2, logoSize2.width, logoSize2.height);
                
                CGContextSaveGState(ctx);
                
                {
                    CGFloat yResolved = columnCounter % 2 == 0 ? y : y + ((logoRect.size.height + (logoMargin.height * 2)) / 2.0000f);
                    CGFloat yt = logoRect.size.height - 24.0000f;
                    CGFloat firstT = yResolved + yt;
                    x += 2.000f;
                    CGContextTranslateCTM(ctx, x, firstT);
                    
                    CGFloat rect2Offset = 0.0000f;
                    
                    CGRect rect2 = CGRectMake(rect2Offset, 0.0000f, logoRect2.size.width, logoRect2.size.height);
                    [displayString2 drawInRect:rect2];
                    CGContextTranslateCTM(ctx, -2.0000f, -yt);
                    CGRect rect1 = CGRectMake(0.0000f, 0.0000f, logoRect.size.width, logoRect.size.height);
                    [displayString drawInRect:rect1];
                }
                CGContextRestoreGState(ctx);

            }
            columnCounter++;
        } while (logoRect.origin.x + logoRect.size.width < rect.size.width);
        rowCounter++;
    } while (logoRect.origin.y + logoRect.size.height < rect.size.height);
    
}

- (void)initalizeAppearance {
    UIColor *tintColorWhite = [UIColor tintColorWhite];
    UIColor *edaGreen = [UIColor tintColorAnalogous4];
    UIColor *tintColor = [UIColor tintColorBlue];
    
    NSDictionary *titleTextAttributes = @{ NSForegroundColorAttributeName : tintColorWhite};
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationController class], nil]            setTintColor: tintColorWhite];
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]                   setTintColor: tintColorWhite];
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil]                         setTintColor: tintColorWhite];
    [[UINavigationBar appearanceWhenContainedIn:[UINavigationController class], nil]            setTintColor: tintColorWhite];

    [[UIToolbar appearanceWhenContainedIn:[UINavigationController class], nil]            setBarTintColor: tintColor];
    [[UIToolbar appearanceWhenContainedIn:[UINavigationBar class], nil]                   setBarTintColor: tintColor];
//    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil]                         setTintColor: tintColorWhite];
    [[UINavigationBar appearanceWhenContainedIn:[UINavigationController class], nil]            setBarTintColor: tintColor];
    
    [[UIActivityIndicatorView appearanceWhenContainedIn:[UIToolbar class], nil]                 setColor: edaGreen];
    [[UIActivityIndicatorView appearanceWhenContainedIn:[UINavigationController class], nil]    setColor: edaGreen];
    
    [[UITabBarItem appearance] setTitleTextAttributes: titleTextAttributes                      forState: UIControlStateNormal];

}

- (id)mainWindow {
    //Dynamically choose which storyboard to run.
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIStoryboard *storyBoard = [MTApplicationInstance storyboard];
    id initViewController = [storyBoard instantiateInitialViewController];
    [window setRootViewController:initViewController];
    [window makeKeyAndVisible];
    return window;
}

- (void)deleteCoreDataCache {
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(dipatchQueue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            dispatch_queue_t dipatchQueueBg = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            dispatch_async(dipatchQueueBg, ^{
                
                [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheName];
                [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheTables];
                [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheLinks];
                [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCacheGroups];
                [NSFetchedResultsController deleteCacheWithName: NSFetchedResultsCachePredicates];
            });
        });
    });
}

- (void)registerDefaultsFromSettingsBundle {
    dispatch_queue_t dipatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(dipatchQueue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            dispatch_queue_t dipatchQueueBg = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            dispatch_async(dipatchQueueBg, ^{
                
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
        });
    });
}

@end
