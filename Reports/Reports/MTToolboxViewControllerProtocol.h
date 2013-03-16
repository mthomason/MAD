//
//  MTToolboxViewControllerProtocol.h
//  Reports
//
//  Created by Michael Thomason on 3/16/13.
//  Copyright (c) 2013 Everyday Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MTToolboxViewControllerProtocol <NSObject>

@required

- (void)setSelectedDocumentObjects:(NSSet *)objectIds;

@end
