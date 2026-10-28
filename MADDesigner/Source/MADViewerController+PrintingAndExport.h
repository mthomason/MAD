//
//  MADViewerController+PrintingAndExport.h
//  Reports
//
//  Created by Michael Thomason on 3/1/12.
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MAD_MADViewerController_PrintingAndExport_h
#define MAD_MADViewerController_PrintingAndExport_h

#import "MADViewerController_Private.h"

@interface MADViewerController (PrintingAndExport) <MADActivityProtocol, UIDocumentInteractionControllerDelegate, MADPrintingProtocol, MADActivityReportPrintPreviewDelegate, MADActivityItemProviderDelegate>

- (IBAction)activity:(id)sender;
- (void)showPrintDialog;

@end

#endif
