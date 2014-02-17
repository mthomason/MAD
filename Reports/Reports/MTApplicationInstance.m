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

NSString * const MTBundleIdMadDesigner                              = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdMadViewer                                = @"com.everydayapps.mad.viewer";
NSString * const MTBundleIdDesigner                                 = @"com.everydayapps.mad.designer";
NSString * const MTBundleIdViewer                                   = @"com.everydayapps.mad.viewer";
NSInteger  const MTGlobalBundleVersionMajor                         = 2;
NSString * const MTGlobalBundleVersion                              = @"1.0.200";
NSString * const MTGlobalBundleShortVersion                         = @"1.0.200";
NSString * const MTGlobalBundleRev                                  = @"821";

NSString * const MTStoryboardReportDesigner                         = @"MTStoryboardReportDesigner";
NSString * const MTStoryboardReportDesignerPad                      = @"MTStoryboardReportDesignerPad";
NSString * const MTStoryboardReportDesignerLagacy                   = @"MTStoryboardReportDesignerOS6";
NSString * const MTStoryboardReportDesignerPadLagacy                = @"MTStoryboardReportDesignerPadOS6";

NSString * const MTStoryboardReportViewer                           = @"MTStoryboardReportViewer";
NSString * const MTStoryboardReportViewerPad                        = @"MTStoryboardReportViewerPad";
NSString * const MTStoryboardReportViewerLagacy                     = @"MTStoryboardReportViewerOS6";
NSString * const MTStoryboardReportViewerPadLagacy                  = @"MTStoryboardReportViewerPadOS6";

@interface MTApplicationInstance ()

@property (nonatomic, retain) MAReportDocument *document;

@end

@implementation MTApplicationInstance

- (void)dealloc {
    [_document release];
    [super dealloc];
}

- (void)openReport:(NSURL *)url withCompletionHandler:(void (^)(id, BOOL))completionHandler {
     [MAReportDocument openManagedDocumentAtUrl:url withCompletionHandler:^(id managedDocument, BOOL success) {
         [managedDocument retain];
         [self setActiveDocument:managedDocument];
         [self setReportState:MTReportStateOpen];
         completionHandler([managedDocument autorelease], success);
     }];
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

- (void)setActiveDocument:(MAReportDocument *)document {
    @synchronized(self) {
        if (document != [self document]) {
            id activeDocument = [document retain];
            [self setDocument:activeDocument];
            [activeDocument release];
        }
    }
}

- (MAReportDocument *)activeDocument {
    MAReportDocument *result = nil;
    if ([self reportState] == MTReportStateOpen) {
        result = [[[self document] retain] autorelease];
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
    [data writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    if (error) {
        error = nil;
        [data writeToURL:url options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUnlessOpen error:&error];
    }
    
}

@end
