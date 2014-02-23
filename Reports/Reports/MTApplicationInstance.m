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

NSString * const MTBundleIdMadDesigner                              = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdMadViewer                                = @"com.everydayapps.mad.viewer";
NSString * const MTBundleIdDesigner                                 = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdViewer                                   = @"com.everydayapps.mad.viewer";
NSInteger  const MTGlobalBundleVersionMajor                         = 2;
NSString * const MTGlobalBundleVersion                              = @"1.0.218";
NSString * const MTGlobalBundleShortVersion                         = @"1.0.218";
NSString * const MTGlobalBundleRev                                  = @"839";

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
@property (nonatomic, retain) NSMutableDictionary *documents;   //MAReportDocument stored by their NSURLS

@end

@implementation MTApplicationInstance

- (void)dealloc {
    [_currentDocument release];
    [_documents removeAllObjects];
    [_documents release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        
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
    }
    return self;
}

- (void)openReport:(NSURL *)url withCompletionHandler:(void (^)(id, BOOL))completionHandler {
    __block MTApplicationInstance *blockSelf = self;
     [MAReportDocument openManagedDocumentAtUrl:url withCompletionHandler:^(id managedDocument, BOOL success) {
         [managedDocument retain];
         [self setCurrentDocument:url];
         [[self documents] setObject:managedDocument forKey:url];
         [self setReportState:MTReportStateOpen];
         [blockSelf retain];
         [managedDocument setDelegateCacheData:(id<MTDatabaseCacheProtocol>)blockSelf];
         [blockSelf release];
         completionHandler([managedDocument autorelease], success);
     }];
}

- (void)closeReportWithCompletionHandler:(void (^)(BOOL))completionHandler {
    
 
    __block MTApplicationInstance *blockSelf = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        MAReportDocument *activeDocument = [[blockSelf activeDocument] retain];
        [activeDocument regenThumbnail];
        [activeDocument closeWithCompletionHandler:^(BOOL success) {
            
            if (success) {
                MAReportDocument *activeDocument = [blockSelf activeDocument];
                [activeDocument setSuspended:YES];
                [NSFileManager wrapFile:[activeDocument fileURL] withExtention:MTDocumentExtentionMobleApplicationDocument overwrite:YES completion:^(BOOL success, NSURL *resultUrl) {
                    [MADocument deleteFromDiskQuick:activeDocument completion:^(BOOL success) {
                        if (success) {
                            [blockSelf setReportState:MTReportStateClosed];
                            [[blockSelf documents] removeObjectForKey:[blockSelf currentDocument]];
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                completionHandler(success);
                            });
                        }
                    }];
                    
                }];
            };
        }];
        [activeDocument release];
    });

}

+ (NSString *)applicationNamePrefixPart {
    NSString *localizedPrefix = NSLocalizedString(@"MAD %@", @"MAD %@");
    return [[localizedPrefix retain] autorelease];
}

+ (NSString *)applicationName {

    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPart];
    NSString *localizedSuffix = [MTApplicationInstance isMadDesigner] ?
                                NSLocalizedString(@"Designer", @"Designer") :
                                NSLocalizedString(@"Viewer", @"Viewer");
    return [[[NSString stringWithFormat: localizedPrefix, localizedSuffix] retain] autorelease];

}

+ (NSString *)madDesigner {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPart];
    NSString *localizedSuffix = NSLocalizedString(@"Designer", @"Designer");
    return [[[NSString stringWithFormat: localizedPrefix, localizedSuffix] retain] autorelease];
}

+ (NSString *)madViewer {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPart];
    NSString *localizedSuffix = NSLocalizedString(@"Viewer", @"Viewer");
    return [[[NSString stringWithFormat: localizedPrefix, localizedSuffix] retain] autorelease];
}

+ (NSString *)madQuery {
    NSString *localizedPrefix = [MTApplicationInstance applicationNamePrefixPart];
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
    UIColor *foregroundColor = [UIColor tintColor2];
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

+ (NSArray *)reportUrls {
    NSArray *madFiles = [NSFileManager contentsOfDocumentsDirectoryWithPathExtension: MTDocumentExtentionMobleApplicationDocument];
    SEL selectorPath = @selector(path);
    SEL selectorSort = @selector(caseInsensitiveCompare:);
    NSString *key = NSStringFromSelector(selectorPath);
    NSSortDescriptor *sortByFileName = [NSSortDescriptor sortDescriptorWithKey:key ascending:YES selector:selectorSort];
    NSArray *sortDescriptors = @[sortByFileName];
    NSArray *results = [[madFiles sortedArrayUsingDescriptors:sortDescriptors] retain];
    return [results autorelease];
}

@end
