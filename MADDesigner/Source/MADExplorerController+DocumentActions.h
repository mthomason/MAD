//
//  MADExplorerController+DocumentActions.h
//  MAD Designer
//
//  Created by Michael Thomason on 1/2/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADExplorerController_DocumentActions_h
#define MAD_MADExplorerController_DocumentActions_h

#import "MADExplorerController_Private.h"

@interface MADExplorerController (DocumentActions) <MADDocumentCellProtocol, MADViewControllerStandardProtocol, MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate, UITextFieldDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate>

+ (UIAlertController *)alertNotConfiguredForEmail;
+ (UIAlertController *)alertNotifyCloudSignOut:(void (^)(UIAlertAction *action))handler;
+ (UIAlertController *)alertRenameDocument:(void (^)(UITextField *textField))textFieldConfig
								   confirm:(void (^)(UIAlertAction *action, NSString *text))handlerConfirm
									cancel:(void (^)(UIAlertAction *action))handlerCancel;

- (IBAction)actionAddDocument:(id)sender;
- (IBAction)actionInformation:(id)sender;
- (IBAction)actionAbout:(id)sender;
- (IBAction)actionDocumentInformation:(id)sender;
- (IBAction)actionStore:(id)sender;
- (IBAction)actionCancel:(id)sender;
- (IBAction)actionSearch:(id)sender;
- (IBAction)actionEdit:(id)sender;
- (IBAction)actionDone:(id)sender;
- (IBAction)actionDownload:(id)sender;
- (IBAction)actionCut:(id)sender;
- (IBAction)actionCopy:(id)sender;
- (IBAction)actionPaste:(id)sender;
- (IBAction)actionActivity:(id)sender;
- (IBAction)actionDelete:(id)sender;
- (IBAction)actionDuplicate:(id)sender;
- (IBAction)actionRename:(id)sender;
- (IBAction)actionEmail:(MADCollectionViewCellDocument *)cell;
- (void)actionActivateEditMode:(UICollectionViewCell *)sender;

@end

#endif
