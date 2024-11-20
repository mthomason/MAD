//
//  RptqDocumentElementLabel.h
//  MAD
//
//  Created by Michael on 1/29/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_RptqDocumentElementLabel_RptqDocumentElement_h
#define MAD_RptqDocumentElementLabel_RptqDocumentElement_h

#import "RptqDocumentElement.h"

NS_ASSUME_NONNULL_BEGIN

@interface RptqDocumentElementLabel : RptqDocumentElement

@end

@interface RptqDocumentElementLabel (CoreDataProperties)

+ (NSFetchRequest<RptqDocumentElementLabel *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *text;

@end

NS_ASSUME_NONNULL_END

#endif
