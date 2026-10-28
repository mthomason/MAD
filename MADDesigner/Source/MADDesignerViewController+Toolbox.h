//
//  MADDesignerViewController+Toolbox.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADDesignerViewController_Toolbox_h
#define MAD_MADDesignerViewController_Toolbox_h

#import "MADDesignerViewController_Private.h"

@interface MADDesignerViewController (Toolbox) <UIPopoverPresentationControllerDelegate, MADDesignerSectionLayoutDelegate>

- (void)adjustContextOffsetForToolboxWithToolboxType:(MTToolboxType)toolboxType;
- (void)adjustContentOffsetForSelectedElements;
- (void)adjustContentOffsetForLastSelectedSectionControlPanel;
- (void)adjustContextOffsetForOpenPopover;
- (void)adjustPassthroughViews;
- (void)dismissSectionPresentationIfOpen;
- (void)dismissToolboxPresentationIfOpen;
- (void)adjustSettingsLocation;
- (void)adjustToolboxLocation;

- (IBAction)actionDone:(id)sender;
- (IBAction)actionAdd:(id)sender;
- (IBAction)actionCancel:(id)sender;
- (IBAction)actionDismiss;
- (IBAction)actionShowToolbox;
- (IBAction)actionShowSectionSettingsFromLabel:(UILabel *)label;

- (BOOL)padLike;
- (NSSet <__kindof UIView *> *)passthroughViews;
- (UIView *)getSectionControlViewForDocumentSection:(RptqDocumentSection *)section;

@end

#endif
