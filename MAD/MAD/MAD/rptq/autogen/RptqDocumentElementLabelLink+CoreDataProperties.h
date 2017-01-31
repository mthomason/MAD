//
//  RptqDocumentElementLabelLink+CoreDataProperties.h
//  MAD
//
//  Created by Michael on 1/31/17.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_RptqDocumentElementLabelLink_CoreDataProperties_h
#define MAD_RptqDocumentElementLabelLink_CoreDataProperties_h

#import "RptqDocumentElementLabelLink.h"
#import <CoreData/NSFetchRequest.h>

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementLabelLink (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabelLink *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *text;
@property (nullable, nonatomic, copy) NSString *url;

@end

NS_ASSUME_NONNULL_END

#endif
