//
//  RptqDocumentElementLabelLink.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_RptqDocumentElementLabelLink_h
#define MAD_RptqDocumentElementLabelLink_h

#import <MAD/RptqDocumentElement.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementLabelLink : RptqDocumentElement

@end

@interface RptqDocumentElementLabelLink (CoreDataProperties)

@property (nullable, nonatomic, copy) NSString *text;
@property (nullable, nonatomic, copy) NSString *url;

@end

NS_ASSUME_NONNULL_END

#endif
