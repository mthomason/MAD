//
//  MADLabelStatus.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/28/15.
//  Copyright © 2015 Everyday Apps LLC. All rights reserved.
//

#import "MADLabelStatus.h"
#import <UIKit/NSAttributedString.h>

static NSString * const MADTextReadRecords = @"\nRead %@ records.";
static NSString * const MADTextFormattingPage = @"\nFormatting page %@.";
static NSString * const MADTextPageXofY = @"\nPage %1@ of %2@ pages.";

static const CGFloat ToolbarFontPointSize = 8.0000f;

@interface MADLabelStatus ()

    @property (nonatomic, strong) NSAttributedString *statusMessage1;
    @property (nonatomic, strong) NSAttributedString *statusMessage2;
    @property (nonatomic, strong) NSAttributedString *statusMessage3;
    @property (nonatomic, strong) NSDictionary *attributesStatusLabelBold;
    @property (nonatomic, strong) NSDictionary *attributesStatusLabelLight;

@end

@implementation MADLabelStatus

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.numberOfLines = 3;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        NSDictionary *attributesStatusLabelBold = [MADLabelStatus attributesStatusLabelBold];
        self.attributesStatusLabelBold = attributesStatusLabelBold;
        
        NSDictionary *attributesStatusLabelLight = [MADLabelStatus attributesStatusLabelLight];
        self.attributesStatusLabelLight = attributesStatusLabelLight;
        
        NSAttributedString *statusMessage1 = [NSAttributedString new];
        NSAttributedString *statusMessage2 = [NSAttributedString new];
        NSAttributedString *statusMessage3 = [NSAttributedString new];
        self.statusMessage1 = statusMessage1;
        self.statusMessage2 = statusMessage2;
        self.statusMessage3 = statusMessage3;
    }
    return self;
}

- (void)updatePageStatus:(NSUInteger)numberOfPages currentPageIndex:(NSUInteger)currentPageIndex {
    NSString *localizedPageOfPagesFormat = NSLocalizedString(MADTextPageXofY, MADTextPageXofY);
    NSNumber *numberOfPagesNumber = @(numberOfPages);
    NSNumber *currentPageNumber = @(currentPageIndex + 1);
    NSString *startPage = [NSNumberFormatter localizedStringFromNumber: currentPageNumber numberStyle: NSNumberFormatterDecimalStyle];
    NSString *endPage = [NSNumberFormatter localizedStringFromNumber: numberOfPagesNumber numberStyle: NSNumberFormatterDecimalStyle];
    NSString *localizedPageOfPages = [NSString stringWithFormat:localizedPageOfPagesFormat, startPage, endPage];
    [self updateStatusWithPageNumber:localizedPageOfPages];
}

- (void)updateDisplay {
    [self updateStatusLabel: self.statusMessage1 recordsReadMessage: self.statusMessage2 andNumberOfPagesMessage: self.statusMessage3];
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
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message attributes:self.attributesStatusLabelLight];
    self.statusMessage2 = attributedString;
    [self updateDisplay];
}

- (void)updateStatusWithPageNumber:(NSString *)message {
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message attributes:self.attributesStatusLabelLight];
    self.statusMessage3 = attributedString;
    [self updateDisplay];
}

- (void)updateStatusWithTime:(NSString *)timeMessage {
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:timeMessage attributes:self.attributesStatusLabelBold];
    self.statusMessage1 = attributedString;
    [self updateDisplay];
}

- (void)updateStatusLabel:(NSAttributedString *)timeMessage
       recordsReadMessage:(NSAttributedString *)recordsReadMessage
  andNumberOfPagesMessage:(NSAttributedString *)numberOfPagesMessage {
    
    NSMutableAttributedString *status = [[NSMutableAttributedString alloc] initWithAttributedString:timeMessage];
    if (recordsReadMessage.string.length > 0) {
        [status appendAttributedString:recordsReadMessage];
    }
    
    if (numberOfPagesMessage.string.length > 0) {
        [status appendAttributedString:numberOfPagesMessage];
    }
    
    NSDictionary *attributes = [MADLabelStatus attributesStatusLabelCentered];
    [status addAttributes:attributes range:NSMakeRange(0, status.length)];
    
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
