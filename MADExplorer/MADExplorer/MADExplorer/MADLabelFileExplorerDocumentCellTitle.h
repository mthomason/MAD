//
//  MADLabelFileExplorerDocumentCellTitle.h
//  MADExplorer
//
//  Created by Michael Thomason on 6/21/16.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADLabelFileExplorerDocumentCellTitle_h
#define Reports_MADLabelFileExplorerDocumentCellTitle_h

#import <UIKit/UILabel.h>

@interface MADLabelFileExplorerDocumentCellTitle : UILabel

@property (nonatomic, assign, getter=isSelected) BOOL selected;
@property (nonatomic, copy) void (^handleTap)(id sender);

- (UIColor *)disabledTextColor;
- (UIColor *)enabledTextColor;

@end

#endif
