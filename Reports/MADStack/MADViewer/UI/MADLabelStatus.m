//
//  MADLabelStatus.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/28/15.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADLabelStatus.h"
#import <UIKit/NSAttributedString.h>

static NSString * const MADTextReadRecords      = @"\nRead %@ records.";
static NSString * const MADTextFormattingPage   = @"\nFormatting page %@.";
static NSString * const MADTextPageXofY         = @"\nPage %1@ of %2@ pages.";
static NSString * const MADTextNothingToDisplay = @"\nNothing to display.";
static NSString * const MADTextNoCache          = @"No Cache";

static const CGFloat ToolbarFontPointSize       = 8.0;

@interface MADLabelStatus ()

	@property (nonatomic, strong) NSMutableAttributedString *statusMessage1;
	@property (nonatomic, strong) NSMutableAttributedString *statusMessage2;
	@property (nonatomic, strong) NSMutableAttributedString *statusMessage3;
	@property (nonatomic, strong) NSMutableAttributedString *display;

@end

@implementation MADLabelStatus

+ (NSDictionary *)attributesStatusLabelCentered {
	NSMutableParagraphStyle *paragraphStyleCentered = [[NSMutableParagraphStyle alloc] init];
	paragraphStyleCentered.alignment = NSTextAlignmentLeft;
	NSDictionary *result;
	result = [[NSDictionary alloc] initWithObjectsAndKeys: paragraphStyleCentered,
														   NSParagraphStyleAttributeName, nil];
	return result;
}

+ (NSDictionary *)attributesStatusLabelBold {
	UIColor *textColor = [UIColor whiteColor];
	UIFont *fontBold = [UIFont boldSystemFontOfSize:ToolbarFontPointSize];
	NSDictionary *result;
	result = [[NSDictionary alloc] initWithObjectsAndKeys:textColor, NSForegroundColorAttributeName,
														  fontBold, NSFontAttributeName, nil];
	return result;
}

+ (NSDictionary *)attributesStatusLabelLight {
	UIColor *textColor = [UIColor whiteColor];
	UIFont *font = [UIFont systemFontOfSize:ToolbarFontPointSize];
	NSDictionary *result;
	result = [[NSDictionary alloc] initWithObjectsAndKeys:textColor, NSForegroundColorAttributeName,
														  font, NSFontAttributeName, nil];
	return result;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.numberOfLines = 3;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth |
								UIViewAutoresizingFlexibleLeftMargin |
								UIViewAutoresizingFlexibleRightMargin;
		
		NSDictionary *attributes = [MADLabelStatus attributesStatusLabelBold];

		NSMutableAttributedString *statusMessage;
		statusMessage = [[NSMutableAttributedString alloc] initWithString: @" "
															   attributes: attributes];
		self.statusMessage1 = statusMessage;

		attributes = [MADLabelStatus attributesStatusLabelLight];
		
		statusMessage = [[NSMutableAttributedString alloc] initWithString: @" "
															   attributes: attributes];
		self.statusMessage2 = statusMessage;
		
		statusMessage = [[NSMutableAttributedString alloc] initWithString: @" "
															   attributes: attributes];
		self.statusMessage3 = statusMessage;
		
		attributes = [MADLabelStatus attributesStatusLabelCentered];
		statusMessage = [[NSMutableAttributedString alloc] initWithString: @" "
															   attributes: attributes];

		self.display = statusMessage;
		
	}
	return self;
}

- (void)updatePageStatus:(MADReportPosition)reportPosition {
	
	NSString *localizedPageOfPages;
	if (reportPosition.totalPages == 0) {
		localizedPageOfPages = NSLocalizedString(MADTextNothingToDisplay, MADTextNothingToDisplay);
	} else {
		NSString *start, *end;
		NSString *localizedPageOfPagesFormat = NSLocalizedString(MADTextPageXofY,
																 MADTextPageXofY);
		NSNumber *page = @(reportPosition.currentPage + 1), *ofPages = @(reportPosition.totalPages);
		start = [NSNumberFormatter localizedStringFromNumber: page
												 numberStyle: NSNumberFormatterDecimalStyle];
		end = [NSNumberFormatter localizedStringFromNumber: ofPages
											   numberStyle: NSNumberFormatterDecimalStyle];
		localizedPageOfPages = [NSString stringWithFormat:localizedPageOfPagesFormat, start, end];
	}
	
	[self updateStatusWithPageNumber:localizedPageOfPages];
}

- (void)updateRecordsReadStatusWithNumberOfPagesFormatted:(NSNumber *)numberOfRecs {
	NSString *decimalString;
	decimalString = [NSNumberFormatter localizedStringFromNumber: numberOfRecs
													 numberStyle: NSNumberFormatterDecimalStyle];
	NSString *formatString = NSLocalizedString(MADTextFormattingPage, MADTextFormattingPage);
	NSString *readRecords = [NSString stringWithFormat:formatString, decimalString];
	[self updateStatusWithRecordsRead:readRecords];
}

- (void)updateRecordsReadStatusWithNumberOfRecordsRead:(NSNumber *)numberOfRecs {
	NSString *decimalString;
	decimalString = [NSNumberFormatter localizedStringFromNumber: numberOfRecs
													 numberStyle: NSNumberFormatterDecimalStyle];
	NSString *formatString = NSLocalizedString(MADTextReadRecords, MADTextReadRecords);
	NSString *readRecords = [NSString stringWithFormat:formatString, decimalString];
	[self updateStatusWithRecordsRead:readRecords];
}

- (void)displayNoCache {
	[self updateStatusWithTime: NSLocalizedString(MADTextNoCache, MADTextNoCache)];
}

- (void)updateStatusWithTime:(NSString *)message {
	[self.statusMessage1 replaceCharactersInRange: NSMakeRange(0, self.statusMessage1.length)
									   withString: message];
	[self updateDisplay];
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

- (void)updateDisplay {

	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		[self.display replaceCharactersInRange: NSMakeRange(0, self.display.length)
						  withAttributedString: self.statusMessage1];
		if (self.statusMessage2.length > 0) {
			[self.display appendAttributedString:self.statusMessage2];
		}
		
		if (self.statusMessage3.length > 0) {
			[self.display appendAttributedString:self.statusMessage3];
		}
		
		NSAttributedString *display = self.display.copy;
		self.attributedText = display;
	}];
}

@end
