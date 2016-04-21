//
//  RptqDocumentObjectImage.h
//  MAD
//
//  Created by Michael Thomason on 11/16/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_AutoGen_RptqDocumentObjectImage_h
#define MAD_AutoGen_RptqDocumentObjectImage_h

#import <CoreData/NSManagedObject.h>

@class RptqDocumentObject;

@interface RptqDocumentObjectImage : NSManagedObject

    @property (nonatomic, strong) NSNumber * identifier;
    @property (nonatomic, strong) id image;
    @property (nonatomic, strong) RptqDocumentObject *parentObject;

@end

#endif
