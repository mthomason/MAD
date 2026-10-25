//
//  MADDocumentCellProtocol.h
//  Reports
//
//  Created by Michael Thomason on 5/29/13.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef Reports_MADDocumentCellProtocol_h
#define Reports_MADDocumentCellProtocol_h

#import <Foundation/NSObject.h>
#import <UIKit/UICollectionViewCell.h>

@protocol MADDocumentCellProtocol <NSObject>

	- (void)actionEmail:(id)cell;
	- (void)actionRename:(id)sender;
	- (void)actionDuplicate:(id)sender;
	- (void)actionActivateEditMode:(UICollectionViewCell *)sender;

@end

#endif
