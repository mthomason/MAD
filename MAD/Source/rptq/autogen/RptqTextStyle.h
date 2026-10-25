//
//  RptqTextStyle+CoreDataClass.h
//  MAD
//
//  Created by Michael on 5/14/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_RptqTextStyle_h
#define MAD_RptqTextStyle_h

#import <MAD/RptqObject.h>

NS_ASSUME_NONNULL_BEGIN

@class RptqDocumentElement;

@interface RptqTextStyle : RptqObject

@end

@interface RptqTextStyle (CoreDataProperties)

@property (nonatomic) BOOL strikethrough;
@property (nonatomic) BOOL underline;
@property (nonatomic) BOOL italic;
@property (nonatomic) BOOL bold;
@property (nullable, nonatomic, retain) RptqDocumentElement *inElement;

@end

NS_ASSUME_NONNULL_END

#endif
