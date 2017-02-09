//
//  RptqDocumentElement.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElement_NSManagedObject_h
#define MAD_RptqDocumentElement_NSManagedObject_h

#import <CoreData/NSManagedObject.h>
#import <CoreData/NSFetchRequest.h>

@class RptqDocumentSectionRows, MADAlignment, MADBorderStyle, MADCurrencyFormatter,
       MADMargin, MADPadding, MADTextStyle, UIColor;

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElement : NSManagedObject

@end

extern NSString * const MTNullIdentifier;

@interface RptqDocumentElement (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElement *> *)fetchRequest;

@property (nonatomic) int64_t identifier;
@property (nonatomic) int16_t type;
@property (nonatomic) int64_t dropIndex;
@property (nonatomic) double fontsize;
@property (nullable, nonatomic, copy) NSString *fontname;
@property (nullable, nonatomic, retain) NSValue *origin;
@property (nullable, nonatomic, retain) NSValue *dropPoint;
@property (nullable, nonatomic, retain) MADMargin *margin;
@property (nullable, nonatomic, retain) MADPadding *padding;
@property (nullable, nonatomic, retain) MADBorderStyle *border;
@property (nullable, nonatomic, retain) MADAlignment *alignment;
@property (nullable, nonatomic, retain) NSValue *size;
@property (nullable, nonatomic, retain) MADTextStyle *style;
@property (nullable, nonatomic, retain) UIColor *backgroundColor;
@property (nullable, nonatomic, retain) UIColor *foregroundColor;
@property (nullable, nonatomic, retain) MADCurrencyFormatter *numericFormat;
@property (nullable, nonatomic, retain) RptqDocumentSectionRows *inSectionRow;

@end

NS_ASSUME_NONNULL_END

#endif
