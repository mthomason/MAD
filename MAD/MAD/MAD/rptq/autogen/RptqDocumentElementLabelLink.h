//
//  RptqDocumentElementLabelLink.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementLabelLink_h
#define MAD_RptqDocumentElementLabelLink_h

#import "RptqDocumentElement.h"

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementLabelLink : RptqDocumentElement

@end

@interface RptqDocumentElementLabelLink (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabelLink *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *text;
@property (nullable, nonatomic, copy) NSString *url;

@end

NS_ASSUME_NONNULL_END

#endif
