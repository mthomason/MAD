//
//  MADReportRow.h
//  MAD
//
//  Created by Michael Thomason on 6/25/16.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADReportRow_h
#define MAD_MADReportRow_h

#import <Foundation/NSObject.h>

@class MADPrintPageElement;

@interface MADReportRow : NSObject

@property (nonatomic, readonly, strong, getter=hasDocumentObjects) NSArray <MADPrintPageElement *> *hasDocumentObjects;

@end

#endif
