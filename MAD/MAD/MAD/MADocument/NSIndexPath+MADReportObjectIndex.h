//
//  NSIndexPath+MADReportObjectIndex.h
//  MAD
//
//  Created by Michael Thomason on 7/2/16.
//  Copyright © 2017 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MAD_MADDocumentCachedDataReference_h
#define Reports_MAD_MADDocumentCachedDataReference_h

#import <Foundation/NSIndexPath.h>

@interface NSIndexPath (MADReportObjectIndex)

    + (instancetype)newIndexPathWithSection:(NSUInteger)section
                                        row:(NSUInteger)row
                                    andItem:(NSUInteger)item;

@end

#endif
