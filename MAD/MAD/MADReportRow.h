//
//  MADReportRow.h
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2016 Everyday Apps LLC. All rights reserved.
//

#ifndef MAD_MADReportRow_h
#define MAD_MADReportRow_h

#import <Foundation/NSObject.h>

@class MADDocumentObject;

@interface MADReportRow : NSObject

    @property (nonatomic, readonly, strong, getter=hasDocumentObjects) NSArray <MADDocumentObject *> *hasDocumentObjects;

@end

#endif
