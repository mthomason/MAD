//
//  MADReportPageView.m
//  Reports
//
//  Created by Michael Thomason on 2/8/13.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning Compile this file with ARC using the -fobjc-arc flag.
#endif

#import "MADReportPageView.h"

#import <setjmp.h>
#import <MAD/miniz.h>

#import <UIKit/UILabel.h>

#import <QuartzCore/CALayer.h>

#import <MADBarcodes/png.h>
#import <MAD/MADImageThumbnail.h>

#import <MAD/MADPrintPageRenderer.h>

#import "MADPageStatusView.h"
#import "MADReportPageViewProtocol.h"
#import "MADTextPosition.h"

#import "MADLabelTimer.h"

static NSString * const PageNumber = @"Page %@";
static NSString * const MADTextNoCache = @"No Cache";

static const CGFloat PageCounterWidth = 99.0000f;
static const CGFloat PageCounterHeight = 33.0000f;
static const CGFloat PageCounterBuffer = 10.0000f;

struct iodata_stream_t {
    unsigned int  i;
    char         *m;
};
typedef struct iodata_stream_t iodata_stream_t;

static void png_error_func(png_structp, png_const_charp);
static void png_warn_func(png_structp, png_const_charp);
static void mad_png_read_fn(png_structp ps, png_bytep obuffer, png_size_t z);

static void mad_png_read_fn(png_structp ps, png_bytep obuffer, png_size_t z) {
    png_voidp io_ptr = png_get_io_ptr(ps);
    memcpy(obuffer, (((iodata_stream_t *)io_ptr)->m) + (((iodata_stream_t*)io_ptr)->i), z);
    ((iodata_stream_t *)io_ptr)->i += (unsigned int)z;
}

static void png_error_func(png_structp png_ptr, png_const_charp message) {
    NSLog(@"%s", message);
    longjmp(png_jmpbuf(png_ptr), 1);
}

static void png_warn_func(png_structp png_ptr, png_const_charp message) {
    NSLog(@"%s", message);
}

@interface MADReportPageView ()

    @property (nonatomic, weak) MADLabelTimer *timerLabel;

@end

@implementation MADReportPageView {
    BOOL _firstTime;
    BOOL _displaysPageCounter;
    BOOL _displaysCacheTimer;
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
        if (_displaysCacheTimer) {
            [self addTimerView];
            [self updateTimeSinceLastRefresh:self];
        }
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
        UIImage *thumbnail = [MADImageThumbnail newImageThumbnailWithRenderer:printPageRenderer];
        NSData *pngImage = UIImagePNGRepresentation(thumbnail);
        size_t newImageSize = 0;
        
        const int kPngSignatureLength = 8;
        //int BYTE_SIZE = sizeof(float);
        
        png_const_bytep pngSignature = malloc(kPngSignatureLength * BYTE_SIZE);
        [pngImage getBytes:(void *)pngSignature range:NSMakeRange(0, kPngSignatureLength)];
        
        FILE *fp = NULL;
        void *compressedPNG = NULL;
        
        if (!png_check_sig(pngSignature, 8)) goto RegenThumbnailShortCircuit;
        
        iodata_stream_t dstream;
        
        png_structp p = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, png_error_func, png_warn_func);
        png_infop info =  png_create_info_struct(p);
        
        if (info == NULL) {
            png_destroy_read_struct(&p, NULL, NULL);
        } else {
            
            dstream.i = 0;
            dstream.m = (char *)pngImage.bytes;
            png_set_read_fn(p, &dstream, mad_png_read_fn);
            png_set_sig_bytes((png_structp)pngSignature, kPngSignatureLength);
        }
        png_byte numberOfChannels = png_get_channels(p, info);
        png_uint_32 imageWidth = png_get_image_width(p, info);
        png_sig_cmp(pngImage.bytes+kPngSignatureLength, (png_size_t)0, numberOfChannels*imageWidth);
        
        png_read_png(p, info, PNG_TRANSFORM_IDENTITY, NULL);
        png_uint_32 imageHeight = png_get_image_height(p, info);
        compressedPNG = tdefl_write_image_to_png_file_in_memory_ex(p,
                                                                   (int)imageWidth,
                                                                   (int)imageHeight,
                                                                   (int)numberOfChannels,
                                                                   &newImageSize,
                                                                   MZ_UBER_COMPRESSION, 0);
        png_destroy_read_struct(&p, (png_infopp)NULL, NULL);
        p = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, png_error_func, png_warn_func);
        thumbnailURL = [delegatePage thumbnailURL];
        const char *thumbnailPath = thumbnailURL.path.UTF8String;
        fp = fopen(thumbnailPath, "wb");
        png_init_io(p, fp);
        png_write_png(p, info, PNG_TRANSFORM_IDENTITY, compressedPNG);
        png_destroy_write_struct(&p, &info);
    RegenThumbnailShortCircuit:;
        free(compressedPNG);
        free((void *)pngSignature);
        fclose(fp);
        thumbnail = nil;
    }

}

#pragma mark

- (void)setup {
    _displaysCacheTimer = YES;
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
                                  PageCounterWidth,
                                  PageCounterHeight);
        MADPageStatusView *numberView = [[MADPageStatusView alloc] initWithFrame: frame];
        [numberView setPage:[delegatePage pageNumber] ofTotal:[delegatePage numberOfPages]];
        [self addSubview:numberView];
        
        [UIView animateWithDuration:0.3000f delay:0.0000f
                            options:UIViewAnimationOptionCurveEaseIn animations:^{
                                
                                numberView.alpha = 1.0000f;
                                
                            } completion:^(BOOL finished) {
                                
                                if (finished) {
                                    [UIView animateWithDuration:0.30000f delay:1.0000f
                                                        options:UIViewAnimationOptionCurveEaseOut
                                                     animations:^{
                                                            numberView.alpha = 0.0000f;
                                                        } completion:^(BOOL animateFinished) {
                                                            if (animateFinished) {
                                                                [numberView removeFromSuperview];
                                                            }
                                                        }];
                                }
                            }];
    }
}

#pragma mark -
#pragma mark Timer

- (void)addTimerView {
    if (self.timerLabel == nil) {
        CGRect viewFrame = CGRectMake(self.frame.size.width - 220.0000f,
                                      self.frame.size.height - 23.0000f,
                                      220.0000f, 23.0000f);
        MADLabelTimer *view = [[MADLabelTimer alloc] initWithFrame:viewFrame];
        [self addSubview:view];
        
        UIView * __weak blockView = view;
        [UIView animateWithDuration:0.3000f
                              delay:0.0900f options:UIViewAnimationOptionCurveEaseIn animations:^{
            blockView.alpha = 1.0000f;
        } completion:^(BOOL finished) {
            if (finished) {
                [UIView animateWithDuration:0.30000f delay:2.0000f
                                    options:UIViewAnimationOptionCurveEaseOut animations:^{
                                        blockView.alpha = 0.0000f;
                                    } completion:nil];
            }
        }];
        self.timerLabel = view;
    }
}

- (void)updateTimeSinceLastRefresh:(id)sender {
    NSDate *date = [self.delegatePage lastCacheDate];
    [self.timerLabel updateWithDate: date];
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
    NSString *pageNumberString, *formatString, *pageNumberStringCaps, *result;
    
    pageNumberValue = [self.delegatePage pageNumber];
    pageNumberWrapper = [[NSNumber alloc] initWithUnsignedInteger:pageNumberValue];
    
    pageNumberString = [NSNumberFormatter localizedStringFromNumber: pageNumberWrapper
                                                            numberStyle: NSNumberFormatterSpellOutStyle];
    formatString = NSLocalizedString(pageNumberString, pageNumberString);
    pageNumberStringCaps = pageNumberString.capitalizedString;
    result = [[NSString alloc] initWithFormat:formatString, pageNumberStringCaps];
    return result;
}

@end
