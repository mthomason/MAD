//
//  MADDesignerViewController+ElementSaving.h
//  Reports
//
//  Created by Michael Thomason on 1/4/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADDesignerViewController_ElementSaving_h
#define MAD_MADDesignerViewController_ElementSaving_h

#import "MADDesignerViewController_Private.h"

@interface MADDesignerViewController (ElementSaving) <MADViewControllerStandardProtocol, MADViewControllerBarcodeDelegate, MTViewControllerAggregateDelegate, MADElementPickerProtocol, MADQueryChooseFieldProtocol, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

- (void)saveStaticLabel:(MTDocumentObjectNewStaticLabelViewController *)viewController;
- (void)saveWhiteSpace;
- (void)saveDynamicLabel:(MADQueryChooseFieldController *)viewController;
- (void)saveAggregateLabel:(MTDocumentObjectNewAggregateViewController *)viewController;
- (void)saveBarcodeLabel:(MTViewControllerBarcode *)viewController;
- (void)insertDocumentObjectWithDefination:(NSDictionary *)documentObjectDefination;

@end

#endif
