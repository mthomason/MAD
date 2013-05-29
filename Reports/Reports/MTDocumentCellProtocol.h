//
//  MTDocumentCellProtocol.h
//  Reports
//
//  Created by Michael Thomason on 5/29/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MTDocumentCellProtocol <NSObject>

- (void)deleteDocumentRepresentedByCell:(id)cell;
- (void)emailDocumentRepresentedByCell:(id)cell;

@end
