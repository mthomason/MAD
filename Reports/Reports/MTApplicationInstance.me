//
//  MTApplicaitonInstance.m
//  MAD
//
//  Created by Michael Thomason on 2/16/14.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#import "MTApplicationInstance.h"
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


NSString *const MTApplicationIdMadDesigner                          = @"666001433";
NSString *const MTApplicationIdMadViewer                            = @"666003759";

NSString * const MTBundleIdMadDesigner                              = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdMadViewer                                = @"com.everydayapps.mad.viewer";
NSString * const MTBundleIdDesigner                                 = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdViewer                                   = @"com.everydayapps.mad.viewer";

NSString * const MTGlobalBundleVersion                              = @"3.0.83";
NSString * const MTGlobalBundleShortVersion                         = @"3.0.83";
NSString * const MTGlobalBundleRev                                  = @"952";

NSString * const MTStoryboardReportDesigner                         = @"MTStoryboardReportDesigner";
NSString * const MTStoryboardReportDesignerPad                      = @"MTStoryboardReportDesignerPad";
NSString * const MTStoryboardReportDesignerLagacy                   = @"MTStoryboardReportDesignerOS6";
NSString * const MTStoryboardReportDesignerPadLagacy                = @"MTStoryboardReportDesignerPadOS6";

NSString * const MTStoryboardReportViewer                           = @"MTStoryboardReportViewer";
NSString * const MTStoryboardReportViewerPad                        = @"MTStoryboardReportViewerPad";
NSString * const MTStoryboardReportViewerLagacy                     = @"MTStoryboardReportViewerOS6";
NSString * const MTStoryboardReportViewerPadLagacy                  = @"MTStoryboardReportViewerPadOS6";

@interface MTApplicationInstance ()

@property (nonatomic, retain) NSURL *currentDocument;           //To support opening multiple documents
                                                                    //change this url to the url of the open
                                                                    //document.  This url will be key for the
                                                                    //documents array.
@property (nonatomic, retain, readwrite) MTUser *user;
@property (nonatomic, retain, readwrite) MTReportDesigner *reportDesigner;
@property (nonatomic, retain, readwrite) MTReportViewer *reportViewer;
@property (nonatomic, retain, readwrite) MTQueryDesigner *queryDesigner;

@property (nonatomic, retain) NSMutableDictionary *documents;   //MAReportDocument stored by their NSURLS

@end

@implementation MTApplicationInstance

- (void)dealloc {
    [_user release];
    [_reportDesigner release];
    [_reportViewer release];
    [_queryDesigner release];
    [_currentDocument release];
    [_documents removeAllObjects];
    [_documents release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {

        MTUser *user = [[MTUser alloc] init];
        [self setUser:user];
        [user release];

        MTReportDesigner *reportDesigner = [[MTReportDesigner alloc] init];
        [self setReportDesigner:reportDesigner];
        [reportDesigner release];

        MTQueryDesigner *queryDesigner = [[MTQueryDesigner alloc] init];
        [self setQueryDesigner:queryDesigner];
        [queryDesigner release];
        
        MTReportViewer *reportViewer = [[MTReportViewer alloc] init];
        [self setReportViewer:reportViewer];
        [reportViewer release];

        [UAAppReviewManager showPromptWithShouldPromptBlock:^(NSDictionary *trackingInfo) {
            // This is the block syntx for showing prompts.
            // It lets you decide if it should be shown now or not based on
            // the UAAppReviewManager trackingInfo or any other factor.
            //NSLog(@"UAAppReviewManager trackingInfo: %@", trackingInfo);
            // Don't show the prompt now, but do it from the buttons in the example app.
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
        [documents release];
        
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
    
	// This overrides the default value of 30, but it doesn't matter here because of Debug mode enabled
	[UAAppReviewManager setDaysUntilPrompt:28];
    
	// This overrides the default value of 1, but it doesn't matter here because of Debug mode enabled
	[UAAppReviewManager setDaysBeforeReminding:13];
    
	// This means that the popup won't show if you have already rated any version of the app, but it doesn't matter here because of Debug mode enabled
	[UAAppReviewManager setShouldPromptIfRated:NO];
    
	// This overrides the default value of 20, but it doesn't matter here because of Debug mode enabled
	[UAAppReviewManager setSignificantEventsUntilPrompt:20];
    
	[UAAppReviewManager setUseMainAppBundleForLocalizations:YES];
    
    [UAAppReviewManager setAffiliateCode:@""];                      // FIXME: Add this affiliate code.
	[UAAppReviewManager setAffiliateCampaignCode:@""];              // FIXME: Add this affiliate code.

    
	// UAAppReviewManager is block based, so setup some blocks on events
	[UAAppReviewManager setOnDeclineToRate:^() {}];
	[UAAppReviewManager setOnDidDisplayAlert:^() {}];
	[UAAppReviewManager setOnDidOptToRate:^() {}];
	[UAAppReviewManager setOnDidOptToRemindLater:^() {}];
	[UAAppReviewManager setKey:@"kSettingsSignificantEventTally" forUAAppReviewManagerKeyType:UAAppReviewManagerKeySignificantEventCount];
    
}

#pragma mark - Open and close mad document

- (void)openReport:(NSURL *)url withCompletionHandler:(void (^)(id, BOOL))completionHandler {
     [MAReportDocument openManagedDocumentAtUrl:url withCompletionHandler:^(id managedDocument, BOOL success) {
         [managedDocument retain];
         [self setCurrentDocument:url];
         [[self documents] setObject:managedDocument forKey:url];
         [self setReportState:MTReportStateOpen];
         [managedDocument setDelegateCacheData:(id<MTDatabaseCacheProtocol>)self];
         completionHandler([managedDocument autorelease], success);
     }];
}

- (void)closeReportWithCompletionHandler:(void (^)(BOOL))completionHandler {
    
    if ([self activeDocument]) {

        __block MTApplicationInstance *blockSelf = self;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            __block MAReportDocument *blockActiveDocument = [blockSelf activeDocument];
            __block MTApplicationInstance *blockSelf2 = blockSelf;
            [blockActiveDocument regenThumbnail];
            [blockActiveDocument closeWithCompletionHandler:^(BOOL success) {
                
                if (success) {
                    
                    [blockActiveDocument setSuspended:YES];
                    [NSFileManager wrapFile:[blockActiveDocument fileURL] withExtention:MTDocumentExtentionMobleApplicationDocument overwrite:YES completion:^(BOOL success, NSURL *resultUrl) {
                        [MADocument deleteFromDiskQuick:blockActiveDocument completion:^(BOOL success) {
                            if (success) {
                                [blockSelf2 setReportState:MTReportStateClosed];
                                [[blockSelf2 documents] removeObjectForKey:[blockSelf2 currentDocument]];
                                dispatch_sync(dispatch_get_main_queue(), ^{
                                    completionHandler(success);
                                });
                            }
                        }];
                        
                    }];
                };
            }];
        });

    } else {
        completionHandler(YES);
    }
 

}

#pragma mark - App settings

+ (NSString *)applicationNamePrefixPart {
    static NSString *localizedPrefix;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localizedPrefix = NSLocalizedString(@"MAD", @"MAD");
        [localizedPrefix retain];
    });
    return localizedPrefix;
}

+ (NSString *)applicationNamePrefixPartFormat {
    static NSString *localizedPrefix;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        localizedPrefix = NSLocalizedString(@"MAD %@", @"MAD %@");
        [localizedPrefix retain];
    });
    return localizedPrefix;
}

+ (NSString *)applicationNameSufixPart {
    static NSString *result;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [MTApplicationInstance isMadDesigner] ?
            NSLocalizedString(@"Designer", @"Designer") :
            NSLocalizedString(@"Viewer", @"Viewer");;
        [result retain];
    });
    return result;
}

+ (NSString *)applicationId {
    static NSString *result;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        result = [MTApplicationInstance isMadDesigner] ?
                    MTApplicationIdMadDesigner :
                    MTApplicationIdMadViewer;
        [result retain];
    });
    return result;
}

+ (NSString *)bundleDisplayName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:MTBundleDisplayName];;
}

+ (NSString *)applicationName {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPartFormat];
    NSString *localizedSuffix = [MTApplicationInstance applicationNameSufixPart];
    return [[[NSString stringWithFormat: localizedPrefix, localizedSuffix] retain] autorelease];
}

+ (NSString *)madDesigner {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPartFormat];
    NSString *localizedSuffix = NSLocalizedString(@"Designer", @"Designer");
    return [[[NSString stringWithFormat: localizedPrefix, localizedSuffix] retain] autorelease];
}

+ (NSString *)madViewer {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPartFormat];
    NSString *localizedSuffix = NSLocalizedString(@"Viewer", @"Viewer");
    return [[[NSString stringWithFormat: localizedPrefix, localizedSuffix] retain] autorelease];
}

+ (NSString *)madQuery {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPartFormat];
    NSString *localizedSuffix = NSLocalizedString(@"Query", @"Query");
    return [[[NSString stringWithFormat: localizedPrefix, localizedSuffix] retain] autorelease];
}

- (MAReportDocument *)activeDocument {
    MAReportDocument *result = nil;
    if ([self reportState] == MTReportStateOpen) {
        NSDictionary *documents = [self documents];
        NSURL *currentUrl = [self currentDocument];
        result = [documents objectForKey:currentUrl];
    }
    return [[result retain] autorelease];
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
        if ([MTApplicationInstance isMadDesigner]) {
            _bundleId = MTBundleIdMadDesigner;
        } else if ([MTApplicationInstance isMadViewer]) {
            _bundleId = MTBundleIdMadViewer;
        }
        [_bundleId retain];
    });
    return _bundleId;
}

+ (NSString *)bundleVersion {
    static NSString *_bundleVersion;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _bundleVersion = [MTGlobalBundleVersion retain];
    });
    return _bundleVersion;
}

+ (NSParagraphStyle *)paragraphStyleTitleBar {
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
    [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
    [paragraphStyle setAlignment:NSTextAlignmentCenter];
    return [paragraphStyle autorelease];
}

+ (NSAttributedString *)localizedAttributedApplicationNameMadDesigner {
    NSString *title = [MTApplicationInstance madDesigner];
    return [[[MTApplicationInstance logoForTitle:title] retain] autorelease];
}

+ (NSAttributedString *)localizedAttributedApplicationNameMadViewer {
    NSString *title = [MTApplicationInstance madViewer];
    return [[[MTApplicationInstance logoForTitle:title] retain] autorelease];
}

+ (NSAttributedString *)localizedAttributedApplicationNameMadQuery {
    NSString *title = [MTApplicationInstance madQuery];
    return [[[MTApplicationInstance logoForTitle:title] retain] autorelease];
}
            
+ (NSAttributedString *)logoForTitle:(NSString *)title {
    
    
    NSParagraphStyle *paragraphStyle = [[MTApplicationInstance paragraphStyleTitleBar] retain];
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
    [paragraphStyle release];
    return [attributedStringMadDesigner autorelease];
    
}

+ (NSString *)storyboardName {
    static NSString *_storyboardName;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([MTApplicationInstance isMadDesigner]) {
            if ([UIDevice isModernOS]) {
                _storyboardName = [UIDevice isPad] ?
                MTStoryboardReportDesignerPad : MTStoryboardReportDesigner;
            } else {
                _storyboardName = [UIDevice isPad] ?
                MTStoryboardReportDesignerPadLagacy : MTStoryboardReportDesigner;
            }
        } else if ([MTApplicationInstance isMadViewer]) {
            if ([UIDevice isModernOS]) {
                _storyboardName = [UIDevice isPad] ?
                MTStoryboardReportViewerPad : MTStoryboardReportViewer;
            } else {
                _storyboardName = [UIDevice isPad] ?
                MTStoryboardReportViewerPadLagacy : MTStoryboardReportViewer;
            }
        }
        [_storyboardName retain];
    });
    return _storyboardName;
}

+ (UIStoryboard *)storyboard {
    NSString *storyboardName = [MTApplicationInstance storyboardName];
    UIStoryboard *storyboard = [[UIStoryboard storyboardWithName:storyboardName bundle:nil] retain];
    return [storyboard autorelease];
}

- (void)cacheQueryResult:(id)queryResult {
    NSError *error = nil;
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:queryResult format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
    NSURL *url = [[self activeDocument] cachedDataUrl];
    if (url) {
        [data writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
        if (error) {
            error = nil;
            [data writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
        }
    }
}

+ (NSAttributedString *)waterMarkStringMad {
    static NSAttributedString *attributedString;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *displayStringText = [MTApplicationInstance applicationNamePrefixPart];
        UIColor *foregroundColor = [UIColor lightTextColor];
        CGFloat fontSize = [MTApplicationInstance isMadDesigner] ? 100.0000f : 78.0000f;
        UIFont *customFont = [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:fontSize];
        NSDictionary *attributes = @{
                                     NSForegroundColorAttributeName : foregroundColor,
                                     NSFontAttributeName : customFont
                                     };
        attributedString = [[NSAttributedString alloc] initWithString: displayStringText attributes:attributes];
        [attributedString retain];
    });
    return attributedString;
}

+ (NSAttributedString *)waterMarkStringDesigner {
    static NSAttributedString *attributedString;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
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
        attributedString = [[NSAttributedString alloc] initWithString: displayStringText attributes:attributes];
        [attributedString retain];
        [paragraphStyle release];
    });
    return attributedString;
}

+ (void)drawMadWatermarkInRect:(CGRect)rect {

    NSAttributedString *displayString = [MTApplicationInstance waterMarkStringMad];
    NSAttributedString *displayString2 = [MTApplicationInstance waterMarkStringDesigner];

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    NSStringDrawingContext *sctx = [[NSStringDrawingContext alloc] init];
    
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
            
            //if (logoRect.size.width > logoRect2.size.width) {
            //    logoRect2.origin.x = logoRect2.origin.x + ((logoRect.size.width - logoRect2.size.width) / 2.0000f);
            //}
            
            CGContextSaveGState(ctx);
            
            {
                CGFloat yResolved = columnCounter % 2 == 0 ? y : y + ((logoRect.size.height + (logoMargin.height * 2)) / 2.0000f);
                CGFloat yt = logoRect.size.height - 24.0000f;
                CGFloat firstT = yResolved + yt;
                x += 2.000f;
                CGContextTranslateCTM(ctx, x, firstT);
                
                CGFloat rect2Offset = 0.0000f;
                //if (logoRect.size.width > logoRect2.size.width) {
                //    rect2Offset = (logoRect.size.width - logoRect2.size.width) / 2.0000f;
                //}
                
                CGRect rect2 = CGRectMake(rect2Offset, 0.0000f, logoRect2.size.width, logoRect2.size.height);
                [displayString2 drawInRect:rect2];
                CGContextTranslateCTM(ctx, -2.0000f, -yt);
                CGRect rect1 = CGRectMake(0.0000f, 0.0000f, logoRect.size.width, logoRect.size.height);
                [displayString drawInRect:rect1];
            }
            CGContextRestoreGState(ctx);
            columnCounter++;
        } while (logoRect.origin.x + logoRect.size.width < rect.size.width);
        rowCounter++;
    } while (logoRect.origin.y + logoRect.size.height < rect.size.height);
    [sctx release];
}

@end
