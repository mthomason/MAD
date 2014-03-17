//
//  MTDocumentCellProtocol.h
//  Reports
//
//  Created by Michael Thomason on 5/29/13.
//  Copyright (c) 2014 Everyday Apps LLC. All rights reserved.
//

#ifndef Reports_MTDocumentCellProtocol_h
#define Reports_MTDocumentCellProtocol_h

#import <Foundation/Foundation.h>

@protocol MTDocumentCellProtocol <NSObject>

- (void)deleteDocumentRepresentedByCell:(id)cell;
- (void)email:(id)cell;
- (void)rename:(id)sender;

@end

#endif
