//
//  MADLabelStatus.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/28/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADLabelStatus.h"
#import <UIKit/NSAttributedString.h>

static NSString * const MADTextReadRecords      = @"\nRead %@ records.";
static NSString * const MADTextFormattingPage   = @"\nFormatting page %@.";
static NSString * const MADTextPageXofY         = @"\nPage %1@ of %2@ pages.";

static const CGFloat ToolbarFontPointSize       = 8.0000f;

@interface MADLabelStatus ()

    @property (nonatomic, strong) NSMutableAttributedString *statusMessage1;
    @property (nonatomic, strong) NSMutableAttributedString *statusMessage2;
    @property (nonatomic, strong) NSMutableAttributedString *statusMessage3;

@end

@implementation MADLabelStatus

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.numberOfLines = 3;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        NSDictionary *attributes = [MADLabelStatus attributesStatusLabelBold];

        NSMutableAttributedString *statusMessage = [[NSMutableAttributedString alloc] initWithString: @"M"
                                                                                          attributes: attributes];
        self.statusMessage1 = statusMessage;

        attributes = [MADLabelStatus attributesStatusLabelLight];
        
        statusMessage = [[NSMutableAttributedString alloc] initWithString: @"A"
                                                               attributes: attributes];
        self.statusMessage2 = statusMessage;
        
        statusMessage = [[NSMutableAttributedString alloc] initWithString: @"D"
                                                               attributes: attributes];
        self.statusMessage3 = statusMessage;
        
    }
    return self;
}

- (void)updatePageStatus:(NSUInteger)numberOfPages currentPageIndex:(NSUInteger)currentPageIndex {
    NSString *localizedPageOfPagesFormat = NSLocalizedString(MADTextPageXofY, MADTextPageXofY);
    NSNumber *numberOfPagesNumber = @(numberOfPages);
    NSNumber *currentPageNumber = @(currentPageIndex + 1);
    NSString *start = [NSNumberFormatter localizedStringFromNumber: currentPageNumber
                                                       numberStyle: NSNumberFormatterDecimalStyle];
    NSString *end = [NSNumberFormatter localizedStringFromNumber: numberOfPagesNumber
                                                     numberStyle: NSNumberFormatterDecimalStyle];
    NSString *localizedPageOfPages = [NSString stringWithFormat:localizedPageOfPagesFormat, start, end];
    [self updateStatusWithPageNumber:localizedPageOfPages];
}

- (void)updateDisplay {
    [self updateStatusLabel: self.statusMessage1 recordsReadMessage: self.statusMessage2
                                            andNumberOfPagesMessage: self.statusMessage3];
}

- (void)updateRecordsReadStatusWithNumberOfPagesFormatted:(NSNumber *)numberOfRecs {
    NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:numberOfRecs numberStyle:NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(MADTextFormattingPage, MADTextFormattingPage);
    NSString *readRecords = [NSString stringWithFormat:formatString, decimalString];
    [self updateStatusWithRecordsRead:readRecords];
}

- (void)updateRecordsReadStatusWithNumberOfRecordsRead:(NSNumber *)numberOfRecs {
    NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:numberOfRecs numberStyle:NSNumberFormatterDecimalStyle];
    NSString *formatString = NSLocalizedString(MADTextReadRecords, MADTextReadRecords);
    NSString *readRecords = [NSString stringWithFormat:formatString, decimalString];
    [self updateStatusWithRecordsRead:readRecords];
}

- (void)updateStatusWithRecordsRead:(NSString *)message {
    [self.statusMessage2 replaceCharactersInRange: NSMakeRange(0, self.statusMessage2.length)
                                       withString: message];
    [self updateDisplay];
}

- (void)updateStatusWithPageNumber:(NSString *)message {
    [self.statusMessage3 replaceCharactersInRange: NSMakeRange(0, self.statusMessage3.length)
                                       withString: message];
    [self updateDisplay];
}

- (void)updateStatusWithTime:(NSString *)message {
    [self.statusMessage1 replaceCharactersInRange: NSMakeRange(0, self.statusMessage1.length)
                                       withString: message];
    [self updateDisplay];
}

- (void)updateStatusLabel:(NSAttributedString *)timeMessage
       recordsReadMessage:(NSAttributedString *)recordsReadMessage
  andNumberOfPagesMessage:(NSAttributedString *)numberOfPagesMessage {
    
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] initWithAttributedString: timeMessage];
    if (recordsReadMessage.string.length > 0) {
        [status appendAttributedString:recordsReadMessage];
    }
    
    if (numberOfPagesMessage.string.length > 0) {
        [status appendAttributedString:numberOfPagesMessage];
    }
    
    NSDictionary *attributes = [MADLabelStatus attributesStatusLabelCentered];
    [status addAttributes: attributes range: NSMakeRange(0, status.length)];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        self.attributedText = status;
    }];
}

+ (NSDictionary *)attributesStatusLabelCentered {
    NSMutableParagraphStyle *paragraphStyleCentered = [[NSMutableParagraphStyle alloc] init];
    paragraphStyleCentered.alignment = NSTextAlignmentLeft;
    NSDictionary * __autoreleasing attributesStatusLabelCentered = [[NSDictionary alloc] initWithObjectsAndKeys:paragraphStyleCentered, NSParagraphStyleAttributeName, nil];
    return attributesStatusLabelCentered;
}

+ (NSDictionary *)attributesStatusLabelBold {
    UIColor *textColor = [UIColor whiteColor];
    UIFont *fontBold = [UIFont boldSystemFontOfSize:ToolbarFontPointSize];
    NSDictionary * __autoreleasing attributesStatusLabelBold = [[NSDictionary alloc] initWithObjectsAndKeys:textColor, NSForegroundColorAttributeName,
                                                                                                            fontBold, NSFontAttributeName, nil];
    return attributesStatusLabelBold;
}

+ (NSDictionary *)attributesStatusLabelLight {
    UIColor *textColor = [UIColor whiteColor];
    UIFont *font = [UIFont systemFontOfSize:ToolbarFontPointSize];
    NSDictionary * __autoreleasing attributesStatusLabelLight = [[NSDictionary alloc] initWithObjectsAndKeys:textColor, NSForegroundColorAttributeName,
                                                                font, NSFontAttributeName, nil];
    return attributesStatusLabelLight;
}

@end
