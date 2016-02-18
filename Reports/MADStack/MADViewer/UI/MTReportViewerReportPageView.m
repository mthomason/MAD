//
//  MTViewPrintPageRenderReport.m
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MTReportViewerReportPageView.h"
#import <MADDataStructures/MTPair.h>
#import "NSDate+Extras.h"
#import "MADTextPosition.h"

static NSString * const PageNumber = @"Page %@";
static NSString * const MADTextNoCache = @"No Cache";

static const CGFloat PageCounterWidth = 99.0000f;
static const CGFloat PageCounterHeight = 33.0000f;
static const CGFloat PageCounterBuffer = 10.0000f;

@interface MTReportViewerReportPageView ()

    @property (nonatomic, weak) UILabel *timeSinceRefrehLabel;
    @property (nonatomic, strong) UIView *timeSinceRefreshView;
    @property (nonatomic, strong) NSTimer *timerLabelTimeSinceRefreh;
    @property (nonatomic, assign) bool firstTime;
    @property (nonatomic, assign) bool displaysPageCounter;
    @property (nonatomic, assign) bool displaysCacheTimer;

@end

@implementation MTReportViewerReportPageView

- (void)dealloc {
    if (_timerLabelTimeSinceRefreh != nil) {
        if ([_timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
            if ([_timerLabelTimeSinceRefreh isValid]) {
                [_timerLabelTimeSinceRefreh invalidate];
            }
        }
    }
    //_delegate = nil;
    _delegatePage = nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initalize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initalize];
    }
    return self;
}

- (void)layoutSubviews {
    if (self.firstTime) {
        self.firstTime = false;
        if (self.displaysCacheTimer) {
            [self addTimerView];
            [self updateLateRefreshedLabel:self];
        }
        if (self.displaysPageCounter) {
            [self displayPageCounterIndicator];
        }
    }
}

- (void)drawRect:(CGRect)rect {
    if (!self.drawBlankPage) {
        [self.delegatePage drawViewInRect:rect];
    }
}

#pragma mark

- (void)initalize {
    self.displaysCacheTimer = false;
    self.displaysPageCounter = false;
    self.drawBlankPage = false;
    self.firstTime = true;
}

#pragma mark

- (UIView *)displayPageCounterIndicator {

    UIView *numberView = [[UIView alloc] initWithFrame:CGRectMake(CGPointZero.x + self.bounds.size.width - PageCounterWidth - PageCounterBuffer,
                                                                  CGPointZero.y + PageCounterBuffer,
                                                                  PageCounterWidth,
                                                                  PageCounterHeight)];
    UIColor *bgColor = [UIColor colorWithWhite:0.0000f alpha:0.5000f];
    numberView.backgroundColor = bgColor;
    numberView.userInteractionEnabled = NO;
    numberView.alpha = 0.0000f;
    numberView.layer.cornerRadius =  6.0000f;
    
    UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y,
                                                                   PageCounterWidth, PageCounterHeight)];
    labelView.text = [NSString stringWithFormat: @"%lu of %lu",
                                                    (unsigned long)[self.delegatePage pageNumber],
                                                    (unsigned long)[self.delegatePage numberOfPages]];
    labelView.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] + 1.0000f];
    labelView.textColor = [UIColor whiteColor];
    labelView.textAlignment = NSTextAlignmentCenter;
    labelView.userInteractionEnabled = NO;
    labelView.backgroundColor = [UIColor clearColor];
    [numberView addSubview:labelView];
    
    [self addSubview:numberView];

    [UIView animateWithDuration:0.3000f delay:0.0000f
                        options:UIViewAnimationOptionCurveEaseIn animations:^{
                            
                            numberView.alpha = 1.0000f;
                            
                        } completion:^(BOOL finished) {
                            
                            if (finished) {
                                [UIView animateWithDuration:0.30000f delay:1.0000f
                                                    options:UIViewAnimationOptionCurveEaseOut animations:^{
                                                        numberView.alpha = 0.0000f;
                                                    } completion:nil];
                            }
                        }];
    return nil;
}

- (void)addTimerView {
    if (self.timeSinceRefreshView == nil) {
        CGRect viewFrame = CGRectMake(self.frame.size.width - 220.0000f, self.frame.size.height - 23.0000f,
                                      220.0000f, 23.0000f);
        UIView *view = [[UIView alloc] initWithFrame:viewFrame];
        UIColor *bgColor = [UIColor colorWithWhite:0.0000f alpha:0.5000f];
        view.backgroundColor = bgColor;
        view.userInteractionEnabled = NO;
        view.alpha = 0.0000f;
        view.layer.cornerRadius =  6.0000f;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(CGPointZero.x, CGPointZero.y, viewFrame.size.width, viewFrame.size.height)];
        label.font = [UIFont systemFontOfSize:[UIFont systemFontSize] - 2.0000f];
        label.textAlignment = NSTextAlignmentCenter;
        label.userInteractionEnabled = NO;
        UIColor *textColor = [UIColor whiteColor];
        label.textColor = textColor;
        UIColor *backgroundColor = [UIColor clearColor];
        label.backgroundColor = backgroundColor;
        
        [view addSubview:label];
        [self addSubview:view];
        
        __weak UIView *blockView = view;
        [UIView animateWithDuration:0.3000f delay:0.0900f options:UIViewAnimationOptionCurveEaseIn animations:^{
            blockView.alpha = 1.0000f;
        } completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:0.30000f delay:2.0000f
                                    options:UIViewAnimationOptionCurveEaseOut animations:^{
                                        blockView.alpha = 0.0000f;
                                    } completion:nil];
            }
        }];
        
        self.timeSinceRefrehLabel = label;
        self.timeSinceRefreshView = view;
    }
}

- (void)updateLateRefreshedLabel:(id)sender {

    NSDate * _Nullable lastCacheDate = [self.delegatePage lastCacheDate];
    if (lastCacheDate == nil) {
        NSString *noCache = NSLocalizedString(MADTextNoCache, MADTextNoCache);
        self.timeSinceRefrehLabel.text = noCache;
        
    } else {
        MTPair *dateStringAndInterval = [NSDate stringWithTimeIntervalSinceDate:lastCacheDate];
        self.timeSinceRefrehLabel.text = dateStringAndInterval.former;
        MTDateResolution resolution = ((NSNumber *)dateStringAndInterval.latter).integerValue;
        
        NSTimeInterval updateLabelInSeconds = [NSDate timeIntervalForResolution:resolution];
        
        if (self.timerLabelTimeSinceRefreh != nil) {
            if ([self.timerLabelTimeSinceRefreh respondsToSelector:@selector(isValid)]) {
                if ([self.timerLabelTimeSinceRefreh isValid]) {
                    [self.timerLabelTimeSinceRefreh invalidate];
                }
            }
            self.timerLabelTimeSinceRefreh = nil;
        }
        
        NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: updateLabelInSeconds target:self
                                                    selector: @selector(updateLateRefreshedLabel:) userInfo:nil
                                                     repeats: NO];
        self.timerLabelTimeSinceRefreh = t;
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
/* willInsertResult will be NO if the recognition failed. */
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
    NSString *pageNumber = [NSNumberFormatter localizedStringFromNumber: @([self.delegatePage pageNumber])
                                                            numberStyle: NSNumberFormatterSpellOutStyle];
    NSString *formatString = NSLocalizedString(PageNumber, PageNumber);
    return [NSString stringWithFormat:formatString, pageNumber.capitalizedString];
}

@end
