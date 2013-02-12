//
//  MTPrintingProtocol.h
//  Reports
//
//  Created by Michael Thomason on 2/12/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MTPrintingProtocol <NSObject>

@required

@optional

- (void)drawView:(id)sender inRect:(CGRect)rect;
- (void)drawPageAtIndex:(NSUInteger)pageIndex inRect:(CGRect)printableRect;

@end