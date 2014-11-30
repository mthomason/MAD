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

#import "MADQueryViewController.h"

#import "MADocument.h"

#import "MTUser.h"
#import "MTReportDesigner.h"

#import "UIColor+EverydayApps.h"
#import "UIDevice+Hack.h"
#import "NSFileManager+Common.h"
#import "NSParagraphStyle+CommonStyles.h"
#import "NSURL+Document.h"

#import "MADFileManager.h"

#import "MTNavigationController.h"
#import "MTNavigationControllerHideBottomBarUnlicensed.h"
#import "MADNavigationControllerSplitParentViewController.h"
#import "MACloudManager.h"

NSString * const MTApplicationIdMadDesigner                          = @"666001433";
NSString * const MTApplicationIdMadViewer                            = @"666003759";

NSString * const MTBundleIdMadDesigner                              = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdMadViewer                                = @"com.everydayapps.mad.viewer";

NSString * const MTGlobalBundleVersion                              = @"7.0.276";
NSString * const MTGlobalBundleShortVersion                         = @"7.0.276";
NSString * const MTGlobalBundleRev                                  = @"1651";

NSString * const MADHandleStoryboardDesigner                        = @"MADDesigner";
NSString * const MADHandleStoryboardViewer                          = @"MADViewer";

NSString * const MTBundleDisplayName                                = @"CFBundleDisplayName";

@interface MTApplicationInstance ()
    <NSCoding>

@property (nonatomic, strong) NSURL *currentDocument;           //To support opening multiple documents
                                                                    //change this url to the url of the open
                                                                    //document.  This url will be key for the
                                                                    //documents array.
@property (nonatomic, strong, readwrite) MTUser *user;
@property (nonatomic, strong, readwrite) MTReportDesigner *reportDesigner;
@property (nonatomic, strong, readwrite) MTReportViewer *reportViewer;
@property (nonatomic, strong, readwrite) MTQueryDesigner *queryDesigner;

@property (nonatomic, strong) NSMutableDictionary *documents;   //MADocument stored by their NSURLS
@property (nonatomic, strong, readwrite) MADFileManager *openFiles;


@end

@implementation MTApplicationInstance

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        //NSNumber *reportState = [aDecoder decodeObjectForKey:@"reportState"];
        //self.reportState = reportState.unsignedIntegerValue;
        //self.openFiles = [aDecoder decodeObjectForKey:@"openFiles"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    //NSNumber *reportState = @(self.reportState);
    //[aCoder encodeObject:reportState forKey:@"reportState"];
    //[aCoder encodeObject:self.openFiles forKey:@"openFiles"];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        MADFileManager *openFiles = [MADFileManager new];
        self.openFiles = openFiles;

        MTUser *user = [[MTUser alloc] init];
        self.user = user;

        MTReportDesigner *reportDesigner = [[MTReportDesigner alloc] init];
        self.reportDesigner = reportDesigner;
        
        // FIXME: Run these checks on app instance start...
        NSCAssert([MTGlobalBundleShortVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"Whoa! CFBundleShortVersionString, bra.");
        NSCAssert([[MTApplicationInstance bundleId] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]], @"Whoops! check the hard-coded bundle identifier!");
        NSCAssert([MTGlobalBundleRev isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"MADRev"]], @"Check the hard-coded MADRev, dog!");
        NSCAssert([[MTApplicationInstance bundleId] isEqualToString:MTBundleIdMadDesigner] || [[MTApplicationInstance bundleId] isEqualToString:MTBundleIdMadViewer], @"Bundle ID is incorrect.");
        NSCAssert([[MTApplicationInstance bundleVersion] isEqualToString:MTGlobalBundleVersion], @"Bundle version is incorrect.");
        NSCAssert([MTGlobalBundleShortVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"Bundle version is incorrect.");
        
        NSMutableDictionary *documents = [[NSMutableDictionary alloc] init];
        self.documents = documents;
        
    }
    return self;
}

#pragma mark - App settings

+ (NSString *)applicationNamePrefixPart {
    return MTDocumentExtentionMobleApplicationDocument;
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

- (MADocument *)currentdocappinst {
    MADocument *result = nil;
    if ([self reportState] == MTReportStateOpen) {
        NSDictionary *documents = [self documents];
        NSURL *currentUrl = [self currentDocument];
        result = documents[currentUrl];
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
    
    if (components.count == 2) {
        firstRange = [title rangeOfString:components[0]];
        secondRange = [title rangeOfString:components[1]];
    } else {
        firstRange = range; secondRange = range;
    }
    
    [attributedStringMadDesigner addAttribute: NSFontAttributeName
                                        value: fonta
                                        range: firstRange];
    
    [attributedStringMadDesigner addAttribute: NSFontAttributeName
                                        value: fontb
                                        range: secondRange];
    
    [attributedStringMadDesigner addAttribute: NSParagraphStyleAttributeName
                                        value: paragraphStyle
                                        range: range];
    
    [attributedStringMadDesigner addAttribute: NSForegroundColorAttributeName
                                        value: foregroundColor
                                        range: range];
    
    [attributedStringMadDesigner addAttribute:NSKernAttributeName value:[NSNull null] range:range];
    return attributedStringMadDesigner;
}

+ (NSString *)storyboardName {
    return MADHandleStoryboardDesigner;
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
    //UIColor *edaGreen = [UIColor tintColorAnalogous4];
    //UIColor *tintColor = [UIColor tintColorBlue];
    
    NSDictionary *titleTextAttributes = @{ NSForegroundColorAttributeName : tintColorWhite};
    [[UITabBarItem appearance] setTitleTextAttributes: titleTextAttributes forState: UIControlStateNormal];    //Make tab bar buttons white
    [[UINavigationBar appearanceWhenContainedIn:[UINavigationController class], nil]            setTintColor: tintColorWhite];
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil]                         setTintColor: tintColorWhite];
    [UIToolbar appearance].barTintColor = [UIColor tintColorBlue];
    [UILabel appearanceWhenContainedIn:[UITableViewCell class], nil].highlightedTextColor = [UIColor edaOrange];
    [UILabel appearanceWhenContainedIn:[UICollectionViewCell class], nil].highlightedTextColor = [UIColor edaOrange];
    
    [UISegmentedControl appearanceWhenContainedIn:[UINavigationBar class], nil].tintColor = tintColorWhite;
/*
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationController class], nil]            setTintColor: tintColorWhite];
    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]                   setTintColor: tintColorWhite];
    [[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil]                         setTintColor: tintColorWhite];
    [[UINavigationBar appearanceWhenContainedIn:[UITabBarController class], nil]            setTintColor: tintColorWhite];
    [[UINavigationBar appearanceWhenContainedIn:[UIViewController class], nil]            setTintColor: tintColorWhite];
    [[UINavigationBar appearanceWhenContainedIn:[MTNavigationController class], nil]            setTintColor: tintColorWhite];
    [[UINavigationBar appearanceWhenContainedIn:[MADNavigationControllerSplitParentViewController class], nil]            setTintColor: tintColorWhite];

    //[[UINavigationBar appearance] setTitleTextAttributes:
    // @{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    
    [[UIToolbar appearanceWhenContainedIn:[UINavigationController class], nil]                  setBarTintColor: tintColor];
    [[UIToolbar appearanceWhenContainedIn:[UINavigationBar class], nil]                         setBarTintColor: tintColor];
    [[UINavigationBar appearanceWhenContainedIn:[UINavigationController class], nil]            setBarTintColor: tintColor];
    
    [[UIActivityIndicatorView appearanceWhenContainedIn:[UIToolbar class], nil]                 setColor: edaGreen];
    [[UIActivityIndicatorView appearanceWhenContainedIn:[UINavigationController class], nil]    setColor: edaGreen];
      
    [[UINavigationBar appearance] setTitleTextAttributes: titleTextAttributes             ];*/
    [[UITabBarItem appearance] setTitleTextAttributes: titleTextAttributes forState: UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes: titleTextAttributes forState: UIControlStateNormal];

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
                NSArray *preferences = rootPlistSettings[@"PreferenceSpecifiers"];
                NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
                
                for (NSDictionary *prefSpecification in preferences)  {
                    NSString *key = prefSpecification[@"Key"];
                    if (key) {
                        
                        id currentObject = [standardUserDefaults objectForKey:key];
                        if (currentObject == nil) {
                            
                            id objectToSet = prefSpecification[@"DefaultValue"];
                            defaultsToRegister[key] = objectToSet;
                        }
                    }
                }
                
                [standardUserDefaults registerDefaults:defaultsToRegister];
                [standardUserDefaults synchronize];
                
            });
        });
    });
    
}

#pragma mark - Document Operations

- (void)closeReportWithCompletionHandler:(void (^)(BOOL))completionHandler {
    
    __weak MADocument *activeDocument = [self openDocument];
    if (activeDocument) {
        
        if (activeDocument.documentState != UIDocumentStateClosed) {
            __weak MTApplicationInstance *weakself = self;
            [activeDocument saveToURL: activeDocument.fileURL forSaveOperation: UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                if (success) {
                    [activeDocument closeWithCompletionHandler:^(BOOL success) {
                        if (success) {
                            weakself.reportState = MTReportStateClosed;
                            [weakself.openFiles removeDocumentWithUrl:weakself.openFiles.openUrl];
                        }
                        completionHandler(success);
                    }];
                    
                }
            }];
        }
    }
}

- (MADocument *)openDocument {
    MADocument *result = nil;
    if ([self reportState] == MTReportStateOpen) {
        result = (MADocument *)self.openFiles.openDocument;
    }
    return result;
}

@end
