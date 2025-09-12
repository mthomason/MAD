//
//  MADExplorerController.h
//  Reports
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2017 Michael Thomason. All rights reserved.
//

#ifndef Reports_MADFileExplorerViewController_h
#define Reports_MADFileExplorerViewController_h

#import "MADExplorerControllerProtocol.h"
#import <MADExplorer/MADDocumentCellProtocol.h>
#import <UIKit/UICollectionViewController.h>

@interface MADExplorerController : UICollectionViewController <MADDocumentCellProtocol, MADExplorerControllerProtocol>

+ (instancetype)newExplorerController;
- (void)done:(id)sender;

@end

#endif
