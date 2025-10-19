//
//  MADHierarchicalGroupingNodeProtocol.h
//  MAD Designer
//
//  Created by Michael on 2/9/17.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef MAD_MADHierarchicalGroupingNodeProtocol_h
#define MAD_MADHierarchicalGroupingNodeProtocol_h

@class UIView;

@protocol MADHierarchicalGroupingNodeProtocol <NSObject>
@property (nonatomic, assign) BOOL root;
- (CGRect)rectForFieldID:(int64_t)managedObjectID inView:(UIView *)containerView;
- (CGRect)frame;
@end

#endif
