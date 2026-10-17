//
//  MADReportLineStyle.h
//  MAD
//
//  One line's text styling, resolved from its element: the font, its size and traits,
//  and the horizontal alignment.  It is a value, read once per line inside the page
//  walk's read transaction (MADReportPageBuilder) -- an exporter that read the element
//  again afterwards would pay a store read per element, outside that transaction
//  (BUGS.md, "Page draws run one SQLite transaction per cell").
//
//  The six fields are exactly what MADElementStylizedText turns into drawing
//  attributes on Apple: the same font name and size, the same bold/italic/underline/
//  strikethrough, the same horizontal alignment, and the same tail truncation (it sets
//  NSLineBreakByTruncatingTail).  A format that is not Core Graphics maps them to its
//  own spelling -- CSS, for one -- so the two agree about what the line looks like.
//

#ifndef MAD_MADReportLineStyle_h
#define MAD_MADReportLineStyle_h

#import <Foundation/Foundation.h>

#import <MAD/MADAlignment.h>

@class RptqDocumentElement;

NS_ASSUME_NONNULL_BEGIN

@interface MADReportLineStyle : NSObject

/// The element's stored styling.  A missing font name, text style or alignment is
/// read the way the renderer reads it: no name, and the trait and alignment flags off.
+ (instancetype)styleForElement:(RptqDocumentElement *)element;

@property (nullable, nonatomic, copy, readonly) NSString *fontName;
@property (nonatomic, assign, readonly) double fontSize;
@property (nonatomic, assign, readonly) BOOL bold;
@property (nonatomic, assign, readonly) BOOL italic;
@property (nonatomic, assign, readonly) BOOL underline;
@property (nonatomic, assign, readonly) BOOL strikethrough;
@property (nonatomic, assign, readonly) MADHorizontalAlignment horizontalAlignment;

@end

NS_ASSUME_NONNULL_END

#endif
