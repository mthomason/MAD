//
//  MADMacDesignerCanvasView.h
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#ifndef MADMacDesignerCanvasView_h
#define MADMacDesignerCanvasView_h

#import <Cocoa/Cocoa.h>

@class MADMacDocument, RptqDocumentSection, RptqDocumentElement;

NS_ASSUME_NONNULL_BEGIN

@protocol MADMacDesignerCanvasViewDelegate <NSObject>
- (void)canvasViewSelectionDidChange:(id)sender;
- (void)canvasViewDidMutateElements:(id)sender;
@end

@interface MADMacDesignerCanvasView : NSView

@property (nonatomic, weak, nullable) MADMacDocument *document;
@property (nonatomic, weak, nullable) id<MADMacDesignerCanvasViewDelegate> delegate;

@property (nonatomic, assign) CGFloat zoomScale;
@property (nonatomic, strong, nullable) RptqDocumentSection *selectedSection;
@property (nonatomic, strong, readonly) NSMutableSet<NSNumber *> *selectedElementIdentifiers;

- (nullable RptqDocumentElement *)primarySelectedElement;
- (void)selectElement:(nullable RptqDocumentElement *)element inSection:(nullable RptqDocumentSection *)section;
- (void)deleteSelectedElements:(nullable id)sender;
- (void)recalculateCanvasFrame;

@end

NS_ASSUME_NONNULL_END

#endif /* MADMacDesignerCanvasView_h */
