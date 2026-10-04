//
//  MADLabelStatus.m
//  MAD Designer
//
//  Created by Michael Thomason on 10/28/15.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#import "MADLabelStatus.h"
#import <UIKit/NSAttributedString.h>
#import <os/log.h>

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
	@property (nonatomic, strong) NSDictionary *boldAttributes;
	@property (nonatomic, strong) NSDictionary *lightAttributes;
	@property (nonatomic, strong) NSDictionary *paragraphAttributes;

@end

@implementation MADLabelStatus

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		[self configureInitialState];
	}
	return self;
}

- (void)configureInitialState {
	self.numberOfLines = 3;
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth |
							UIViewAutoresizingFlexibleLeftMargin |
							UIViewAutoresizingFlexibleRightMargin;
	
	// Pre-allocate attributes
	_boldAttributes = @{
		NSForegroundColorAttributeName: [UIColor whiteColor],
		NSFontAttributeName: [UIFont boldSystemFontOfSize:ToolbarFontPointSize]
	};
	
	_lightAttributes = @{
		NSForegroundColorAttributeName: [UIColor whiteColor],
		NSFontAttributeName: [UIFont systemFontOfSize:ToolbarFontPointSize]
	};
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.alignment = NSTextAlignmentLeft;
	_paragraphAttributes = @{NSParagraphStyleAttributeName: paragraphStyle};
	
	// Initialize with empty strings
	_statusMessage1 = [[NSMutableAttributedString alloc] initWithString:@" " attributes:_boldAttributes];
	_statusMessage2 = [[NSMutableAttributedString alloc] initWithString:@" " attributes:_lightAttributes];
	_statusMessage3 = [[NSMutableAttributedString alloc] initWithString:@" " attributes:_lightAttributes];
	_display = [[NSMutableAttributedString alloc] initWithString:@" " attributes:_paragraphAttributes];
}

- (void)updatePageStatus:(MADReportPosition)reportPosition {
	os_log_debug(OS_LOG_DEFAULT, "%s: currentPage=%ld totalPages=%ld thread=%@ label=%p",
				 __PRETTY_FUNCTION__, (long)reportPosition.currentPage,
				 (long)reportPosition.totalPages, NSThread.currentThread.description, self);
	// Perform string formatting off main thread
	NSString *localizedPageOfPages;
	if (reportPosition.totalPages == 0) {
		localizedPageOfPages = NSLocalizedString(MADTextNothingToDisplay, MADTextNothingToDisplay);
	} else {
		NSString *start = [NSNumberFormatter localizedStringFromNumber:@(reportPosition.currentPage + 1) numberStyle:NSNumberFormatterDecimalStyle];
		NSString *end = [NSNumberFormatter localizedStringFromNumber:@(reportPosition.totalPages) numberStyle:NSNumberFormatterDecimalStyle];
		localizedPageOfPages = [NSString stringWithFormat:NSLocalizedString(MADTextPageXofY, MADTextPageXofY), start, end];
	}

	__weak MADLabelStatus *weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[weakSelf updateStatusWithPageNumber:localizedPageOfPages];
	});
}

- (void)updateRecordsReadStatusWithNumberOfPagesFormatted:(NSNumber *)numberOfRecs {
	NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:numberOfRecs numberStyle:NSNumberFormatterDecimalStyle];
	NSString *readRecords = [NSString stringWithFormat:NSLocalizedString(MADTextFormattingPage, MADTextFormattingPage), decimalString];
	
	__weak MADLabelStatus *weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[weakSelf updateStatusWithRecordsRead:readRecords];
	});
}

- (void)updateRecordsReadStatusWithNumberOfRecordsRead:(NSNumber *)numberOfRecs {
	NSString *decimalString = [NSNumberFormatter localizedStringFromNumber:numberOfRecs
																numberStyle:NSNumberFormatterDecimalStyle];
	NSString *readRecords = [NSString stringWithFormat:NSLocalizedString(MADTextReadRecords, MADTextReadRecords), decimalString];
	
	__weak MADLabelStatus *weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[weakSelf updateStatusWithRecordsRead:readRecords];
	});
}

- (void)displayNoCache {
	__weak MADLabelStatus *weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[weakSelf updateStatusWithTime:NSLocalizedString(MADTextNoCache, MADTextNoCache)];
	});
}

- (void)updateStatusWithTime:(NSString *)message {
	[self safelyUpdateAttributedString:self.statusMessage1
						  withNewString:message
							attributes:self.boldAttributes];
}

- (void)updateStatusWithRecordsRead:(NSString *)message {
	[self safelyUpdateAttributedString:self.statusMessage2
						  withNewString:message
							attributes:self.lightAttributes];
}

- (void)updateStatusWithPageNumber:(NSString *)message {
	os_log_debug(OS_LOG_DEFAULT, "%s: message='%@' thread=%@ label=%p",
				 __PRETTY_FUNCTION__, message, NSThread.currentThread.description, self);
	[self safelyUpdateAttributedString:self.statusMessage3
						  withNewString:message
							attributes:self.lightAttributes];
}

- (void)safelyUpdateAttributedString:(NSMutableAttributedString *)target
					   withNewString:(NSString *)newString
						 attributes:(NSDictionary *)attributes {
	// Ensure we're on main thread for all mutations
	if (![NSThread isMainThread]) {
		__weak MADLabelStatus *weakSelf = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			[weakSelf safelyUpdateAttributedString:target
									 withNewString:newString
									   attributes:attributes];
		});
		return;
	}
	
	[target replaceCharactersInRange:NSMakeRange(0, target.length)
						  withString:newString ?: @""];
	[target setAttributes:attributes range:NSMakeRange(0, target.length)];
	
	[self updateDisplay];
}

- (void)updateDisplay {
	// Reuse existing display string
	[self.display replaceCharactersInRange:NSMakeRange(0, self.display.length)
					  withAttributedString:self.statusMessage1];
	
	if (self.statusMessage2.length > 0) {
		[self.display appendAttributedString:self.statusMessage2];
	}
	
	if (self.statusMessage3.length > 0) {
		[self.display appendAttributedString:self.statusMessage3];
	}
	
	// Apply paragraph style once to the entire string
	[self.display addAttributes:self.paragraphAttributes
						  range:NSMakeRange(0, self.display.length)];
	
	self.attributedText = self.display;
}

@end
