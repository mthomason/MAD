//
//  MADReportPageView.m
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright © 2020 Michael Thomason. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportPageView.h"

#import <setjmp.h>
#import <MAD/miniz.h>

#import <UIKit/UILabel.h>

#import <MAD/MADImageThumbnail.h>

#import <MAD/MADPrintPageRenderer.h>

#import "MADPageStatusView.h"
#import "MADReportPageViewProtocol.h"
#import "MADTextPosition.h"

static const CGFloat PageCounterWidth = 99.0;
static const CGFloat PageCounterHeight = 33.0;
static const CGFloat PageCounterBuffer = 10.0;

@interface MADReportPageView ()

@end

@implementation MADReportPageView {
	BOOL _firstTime;
	BOOL _displaysPageCounter;
}

- (void)dealloc {
	_delegatePage = nil;
}

- (instancetype)init {
	if (self = [super init]) { [self setup]; }
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) { [self setup]; }
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) { [self setup]; }
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	if (_firstTime) {
		_firstTime = NO;
		if (_displaysPageCounter) {
			[self displayPageCounterIndicator];
		}
	}
}

- (void)drawRect:(CGRect)rect {
	[super drawRect: rect];

	if (self.drawBlankPage) return;
	
	@autoreleasepool {
		// Draw Page
		id <MADReportPageViewProtocol> delegatePage = self.delegatePage;
		MADPrintPageRenderer *printPageRenderer = [delegatePage printPageRenderer];
		[printPageRenderer drawPageAtIndex:((NSInteger)delegatePage.pageNumber) - 1 inRect:rect];
		
		if (delegatePage.pageNumber != 1) return;
		
		// Draw Thumbnail
		NSURL *thumbnailURL;
		thumbnailURL = [[delegatePage thumbnailURL] copy];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			UIImage *thumbnail = [MADImageThumbnail newImageThumbnailWithRenderer:printPageRenderer];
			NSData *pngImage = UIImagePNGRepresentation(thumbnail);
			NSError *error = NULL;
			[pngImage writeToURL:thumbnailURL options:NSDataWritingFileProtectionNone error:&error];
			pngImage = nil;
		});
	}

}

#pragma mark

- (void)setup {
	_displaysPageCounter = NO;
	_drawBlankPage = NO;
	_firstTime = YES;
}

#pragma mark -
#pragma mark Page Counter

- (void)displayPageCounterIndicator {

	id <MADReportPageViewProtocol> delegatePage = self.delegatePage;
	if ([delegatePage respondsToSelector:@selector(numberOfPages)]) {
		
		CGRect frame = CGRectMake(CGPointZero.x + self.bounds.size.width - PageCounterWidth - PageCounterBuffer,
								  CGPointZero.y + PageCounterBuffer,
								  PageCounterWidth, PageCounterHeight);
		
		MADPageStatusView *numberView = [[MADPageStatusView alloc] initWithFrame: frame];
		[numberView setPage:[delegatePage pageNumber] ofTotal:[delegatePage numberOfPages]];
		[self addSubview:numberView];
		
		[UIView animateWithDuration: 0.3 delay: 0.0 options: UIViewAnimationOptionCurveEaseIn animations:^{
			
			numberView.alpha = 1.0;
		
		} completion:^(BOOL finished) {
			
			if (finished) {
				
				[UIView animateWithDuration: 0.3 delay: 1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
					numberView.alpha = 0.0;
				} completion:^(BOOL animateFinished) {
					if (animateFinished) {
						[numberView removeFromSuperview];
					}
				}];
			
			}
		}];
	}
}

#pragma mark - UITextInput
#pragma mark Required

/* Methods for manipulating text.
   Reports don't allow text to be manipulated. */
- (nullable NSString *)textInRange:(UITextRange *)range { return nil; }
- (void)replaceRange:(UITextRange *)range withText:(NSString *)text { }

/* Text may have a selection, either zero-length (a caret) or ranged.  Editing operations are
 * always performed on the text from this selection.  nil corresponds to no selection. */

//@property (nullable, readwrite, copy) UITextRange *selectedTextRange;

/* If text can be selected, it can be marked. Marked text represents provisionally
 * inserted text that has yet to be confirmed by the user.  It requires unique visual
 * treatment in its display.  If there is any marked text, the selection, whether a
 * caret or an extended range, always resides witihin.
 *
 * Setting marked text either replaces the existing marked text or, if none is present,
 * inserts it from the current selection. */

//@property (nullable, nonatomic, readonly) UITextRange *markedTextRange; // Nil if no marked text.
//@property (nullable, nonatomic, copy) NSDictionary *markedTextStyle; // Describes how the marked text should be drawn.

- (void)setMarkedText:(nullable NSString *)markedText selectedRange:(NSRange)selectedRange { /* selectedRange is a range within the markedText */ }
- (void)unmarkText {}

/* The end and beginning of the the text document. */
//@property (nonatomic, readonly) UITextPosition *beginningOfDocument;

- (UITextPosition *)beginningOfDocument {
	MADTextPosition *beginningOfDocument = [MADTextPosition BeginningOfDocument];
	return beginningOfDocument;
}
//@property (nonatomic, readonly) UITextPosition *endOfDocument;

- (UITextPosition *)endOfDocument {
	
}

/* Methods for creating ranges and positions. */
- (nullable UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition {

	
	
}
- (nullable UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset {}
- (nullable UITextPosition *)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset {}

/* Simple evaluation of positions */
- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)other {}
- (NSInteger)offsetFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition {}

/* A system-provied input delegate is assigned when the system is interested in input changes. */
//@property (nullable, nonatomic, weak) id <UITextInputDelegate> inputDelegate;

/* A tokenizer must be provided to inform the text input system about text units of varying granularity. */
//@property (nonatomic, readonly) id <UITextInputTokenizer> tokenizer;

/* Layout questions. */
- (nullable UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction {}
- (nullable UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction {}

/* Writing direction */
- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction {}
- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range {}

/* Geometry used to provide, for example, a correction rect. */
- (CGRect)firstRectForRange:(UITextRange *)range {}
- (CGRect)caretRectForPosition:(UITextPosition *)position {}
- (NSArray *)selectionRectsForRange:(UITextRange *)range {}       // Returns an array of UITextSelectionRects

/* Hit testing. */
- (nullable UITextPosition *)closestPositionToPoint:(CGPoint)point {}
- (nullable UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range {}
- (nullable UITextRange *)characterRangeAtPoint:(CGPoint)point {}

#pragma mark Optional

- (BOOL)shouldChangeTextInRange:(UITextRange *)range replacementText:(NSString *)text {   /* return NO to not change text */ }

/* Text styling information can affect, for example, the appearance of a correction rect.
 * Returns a dictionary containing NSAttributedString keys. */
- (nullable NSDictionary<NSString *,id> *)textStylingAtPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction {
	
}

/* To be implemented if there is not a one-to-one correspondence between text positions within range and character offsets into the associated string. */
- (nullable UITextPosition *)positionWithinRange:(UITextRange *)range atCharacterOffset:(NSInteger)offset {
	
}

- (NSInteger)characterOffsetOfPosition:(UITextPosition *)position withinRange:(UITextRange *)range {
	
}

/* An affiliated view that provides a coordinate system for all geometric values in this protocol.
 * If unimplmeented, the first view in the responder chain will be selected. */
//@property (nonatomic, readonly) __kindof UIView *textInputView;

/* Selection affinity determines whether, for example, the insertion point appears after the last
 * character on a line or before the first character on the following line in cases where text
 * wraps across line boundaries. */
//@property (nonatomic) UITextStorageDirection selectionAffinity;

/* This is an optional method for clients that wish to support dictation phrase alternatives. If
 * they do not implement this method, dictation will just insert the most likely interpretation
 * of what was spoken via -insertText:.
 * dictationResult is an array of UIDictationPhrases. */
- (void)insertDictationResult:(NSArray<UIDictationPhrase *> *)dictationResult {
	
}

/* These are optional methods for clients that wish to know when there are pending dictation results. */
- (void)dictationRecordingDidEnd {
	
}
- (void)dictationRecognitionFailed {
	
}

/* The following three optional methods are for clients that wish to support a placeholder for
 * pending dictation results. -insertDictationPlaceholder must return a reference to the
 * placeholder. This reference will be used to identify the placeholder by the other methods
 * (there may be more than one placeholder). */
- (id)insertDictationResultPlaceholder {
	
}

- (CGRect)frameForDictationResultPlaceholder:(id)placeholder {
	
}

/* InsertResult will be NO if the recognition failed. */
- (void)removeDictationResultPlaceholder:(id)placeholder willInsertResult:(BOOL)willInsertResult {}

/* The following three optional methods are for clients that wish to display a floating cursor to
 * guide user manipulation of the selected text range via the system-provided keyboard. If a client
 * does not implement these methods, user feedback will be limited to the outcome after setting the
 * selected text range using positions resulting from hit testing. */
- (void)beginFloatingCursorAtPoint:(CGPoint)point { }
- (void)updateFloatingCursorAtPoint:(CGPoint)point { }
- (void)endFloatingCursor { }


#pragma mark - Accessibility

- (BOOL)isAccessibilityElement {
	return YES;
}

- (NSString *)accessibilityLabel {
	NSUInteger pageNumberValue;
	NSNumber *pageNumberWrapper;
	NSString *pageNumberString, *formatString, *pageNumberStringCaps;
	
	pageNumberValue = [self.delegatePage pageNumber];
	pageNumberWrapper = [[NSNumber alloc] initWithUnsignedInteger:pageNumberValue];
	
	pageNumberString = [NSNumberFormatter localizedStringFromNumber: pageNumberWrapper
															numberStyle: NSNumberFormatterSpellOutStyle];
	formatString = NSLocalizedString(pageNumberString, pageNumberString);
	pageNumberStringCaps = pageNumberString.capitalizedString;
	return [NSString stringWithFormat:formatString, pageNumberStringCaps];
}

@end
