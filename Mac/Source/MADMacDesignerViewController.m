//
//  MADMacDesignerViewController.m
//  MAD Designer (macOS Native)
//

#import "MADMacDesignerViewController.h"
#import "MADMacDesignerCanvasView.h"
#import "MADMacDocument.h"

#import <MAD/MAD.h>
#import <MADBarcodes/MADBarcodes.h>

static const CGFloat kDefaultLeftSidebarWidth = 220.0;
static const CGFloat kMinLeftSidebarWidth = 180.0;
static const CGFloat kMaxLeftSidebarWidth = 340.0;

static const CGFloat kDefaultRightInspectorWidth = 260.0;
static const CGFloat kMinRightInspectorWidth = 220.0;
static const CGFloat kMaxRightInspectorWidth = 380.0;

typedef NS_ENUM(NSInteger, MADMacPaletteElementKind) {
	MADMacPaletteElementKindLabel = 1,
	MADMacPaletteElementKindDataField = 2,
	MADMacPaletteElementKindAggregate = 3,
	MADMacPaletteElementKindBarcode = 4,
	MADMacPaletteElementKindImage = 5,
	MADMacPaletteElementKindLineRule = 6
};

#pragma mark - Helper Views

@interface MADMacFlippedInspectorView : NSView
@end

@implementation MADMacFlippedInspectorView
- (BOOL)isFlipped { return YES; }
@end

/// Toolbar button that can be clicked to insert into the selected section OR dragged onto any canvas section.
@interface MADMacDraggablePaletteButton : NSButton <NSDraggingSource>
@property (nonatomic, assign) MADMacPaletteElementKind paletteElementKind;
@property (nonatomic, assign) NSPoint mouseDownPoint;
@end

@implementation MADMacDraggablePaletteButton

- (NSDragOperation)draggingSession:(__unused NSDraggingSession *)session
	sourceOperationMaskForDraggingContext:(__unused NSDraggingContext)context {
	return NSDragOperationCopy;
}

- (void)mouseDown:(NSEvent *)event {
	_mouseDownPoint = [self convertPoint:event.locationInWindow fromView:nil];
	[super mouseDown:event];
}

- (void)mouseDragged:(NSEvent *)event {
	NSPoint cur = [self convertPoint:event.locationInWindow fromView:nil];
	if (hypot(cur.x - _mouseDownPoint.x, cur.y - _mouseDownPoint.y) < 4.0) {
		return;
	}
	NSPasteboardItem *pbItem = [[NSPasteboardItem alloc] init];
	[pbItem setString:[NSString stringWithFormat:@"%ld", (long)_paletteElementKind]
			  forType:MADMacDesignerPasteboardTypeElementKind];
	NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
	NSRect bounds = self.bounds;
	NSImage *dragImg = [[NSImage alloc] initWithSize:bounds.size];
	[dragImg lockFocus];
	[[[NSColor controlAccentColor] colorWithAlphaComponent:0.15] setFill];
	[[NSBezierPath bezierPathWithRoundedRect:bounds xRadius:4.0 yRadius:4.0] fill];
	[[NSColor controlAccentColor] setStroke];
	[[NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 0.5, 0.5) xRadius:4.0 yRadius:4.0] stroke];
	NSDictionary *attrs = @{
		NSFontAttributeName: [NSFont systemFontOfSize:11.0 weight:NSFontWeightMedium],
		NSForegroundColorAttributeName: [NSColor labelColor]
	};
	[self.title drawInRect:NSInsetRect(bounds, 6.0, 3.0) withAttributes:attrs];
	[dragImg unlockFocus];
	[dragItem setDraggingFrame:bounds contents:dragImg];
	[self beginDraggingSessionWithItems:@[dragItem] event:event source:self];
}

@end

#pragma mark - MADMacDesignerViewController

@interface MADMacDesignerViewController () <
	NSSplitViewDelegate,
	NSTableViewDataSource,
	NSTableViewDelegate,
	NSSearchFieldDelegate,
	MADMacDesignerCanvasViewDelegate
>

@property (nonatomic, weak, readwrite, nullable) MADMacDocument *madDocument;
@property (nonatomic, assign) BOOL isResizingMainSplitProgrammatically;
@property (nonatomic, assign, readwrite) CGFloat leftSidebarWidth;
@property (nonatomic, assign, readwrite) CGFloat rightInspectorWidth;

// Main layout views
@property (nonatomic, strong) NSView *topWorkspaceBar;
@property (nonatomic, strong) NSSplitView *mainSplitView;
@property (nonatomic, strong) NSView *leftSidebarView;
@property (nonatomic, strong) NSView *centerCanvasContainerView;
@property (nonatomic, strong) NSView *rightInspectorContainerView;

// Left sidebar controls
@property (nonatomic, strong, readwrite) MADMacDesignerMinimapView *minimapView;
@property (nonatomic, strong) NSTableView *sectionsTableView;
@property (nonatomic, strong) NSSearchField *queryFieldsSearchField;
@property (nonatomic, strong) NSTableView *queryFieldsTableView;
@property (nonatomic, strong) NSArray<RptqQueryField *> *filteredQueryFields;

// Center canvas controls
@property (nonatomic, strong, readwrite) MADMacDesignerCanvasView *canvasView;
@property (nonatomic, strong) NSScrollView *canvasScrollView;
@property (nonatomic, strong) NSSlider *zoomSlider;
@property (nonatomic, strong) NSButton *zoomPercentButton;
@property (nonatomic, strong) NSButton *gridToggleBtn;
@property (nonatomic, strong) NSButton *snapToggleBtn;
@property (nonatomic, strong) NSButton *rulersToggleBtn;

// Right inspector: Page & Selected Section controls
@property (nonatomic, strong) NSScrollView *inspectorScrollView;
@property (nonatomic, strong) NSPopUpButton *paperSizePopup;
@property (nonatomic, strong) NSTextField *selectedSectionBadgeLabel;
@property (nonatomic, strong) NSTextField *sectionHeightField;
@property (nonatomic, strong) NSButton *sectionVisibleCheck;
@property (nonatomic, strong) NSButton *sectionPageBreakCheck;

// Right inspector: Selected Element controls
@property (nonatomic, strong) NSTextField *noElementSelectedHintLabel;
@property (nonatomic, strong) NSStackView *elementInspectorCardsStack;
@property (nonatomic, strong) NSTextField *elementTypeBadgeLabel;
@property (nonatomic, strong) NSPopUpButton *elementSectionPopup;

// Element Content & Data Binding card
@property (nonatomic, strong) NSBox *contentBindingCard;
@property (nonatomic, strong) NSView *staticTextRow;
@property (nonatomic, strong) NSTextField *elementTextField;
@property (nonatomic, strong) NSView *queryFieldRow;
@property (nonatomic, strong) NSPopUpButton *queryFieldPopup;
@property (nonatomic, strong) NSView *aggregateFunctionRow;
@property (nonatomic, strong) NSPopUpButton *aggregateTypePopup;
@property (nonatomic, strong) NSView *aggregateScopeRow;
@property (nonatomic, strong) NSPopUpButton *aggregateScopePopup;
@property (nonatomic, strong) NSView *numericFormatRow;
@property (nonatomic, strong) NSButton *numericFormatCheck;
@property (nonatomic, strong) NSTextField *decimalsField;
@property (nonatomic, strong) NSView *barcodeSymbologyRow;
@property (nonatomic, strong) NSPopUpButton *barcodeSymbologyPopup;
@property (nonatomic, strong) NSView *barcodeOptionsRow;
@property (nonatomic, strong) NSButton *barcodeHumanReadableCheck;
@property (nonatomic, strong) NSPopUpButton *barcodeBorderPopup;
@property (nonatomic, strong) NSView *imagePickerRow;
@property (nonatomic, strong) NSButton *chooseImageButton;

// Typography & Appearance card
@property (nonatomic, strong) NSPopUpButton *fontFamilyPopup;
@property (nonatomic, strong) NSTextField *fontSizeField;
@property (nonatomic, strong) NSButton *boldCheck;
@property (nonatomic, strong) NSButton *italicCheck;
@property (nonatomic, strong) NSButton *underlineCheck;
@property (nonatomic, strong) NSButton *strikethroughCheck;
@property (nonatomic, strong) NSSegmentedControl *hAlignControl;
@property (nonatomic, strong) NSSegmentedControl *vAlignControl;
@property (nonatomic, strong) NSColorWell *fgColorWell;
@property (nonatomic, strong) NSButton *hasBgColorCheck;
@property (nonatomic, strong) NSColorWell *bgColorWell;

// Geometry & Box Model card
@property (nonatomic, strong) NSTextField *posXField;
@property (nonatomic, strong) NSTextField *posYField;
@property (nonatomic, strong) NSTextField *widthField;
@property (nonatomic, strong) NSTextField *heightField;
@property (nonatomic, strong) NSTextField *borderTopField;
@property (nonatomic, strong) NSTextField *borderBottomField;
@property (nonatomic, strong) NSTextField *borderLeftField;
@property (nonatomic, strong) NSTextField *borderRightField;
@property (nonatomic, strong) NSTextField *paddingAllField;
@property (nonatomic, strong) NSTextField *marginAllField;

@property (nonatomic, assign) BOOL isUpdatingInspector;

@end

@implementation MADMacDesignerViewController

- (instancetype)initWithDocument:(MADMacDocument *)document {
	self = [super initWithNibName:nil bundle:nil];
	if (self) {
		_madDocument = document;
		_leftSidebarWidth = kDefaultLeftSidebarWidth;
		_rightInspectorWidth = kDefaultRightInspectorWidth;
		_filteredQueryFields = @[];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Construction

- (void)loadView {
	NSView *rootView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1220, 760)];
	rootView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	// 1. Top Workspace Bar (38pt height)
	_topWorkspaceBar = [self buildTopWorkspaceBar];
	_topWorkspaceBar.translatesAutoresizingMaskIntoConstraints = NO;
	[rootView addSubview:_topWorkspaceBar];

	// 2. Main 3-Pane Split View
	_mainSplitView = [[NSSplitView alloc] initWithFrame:NSMakeRect(0, 0, 1220, 722)];
	_mainSplitView.vertical = YES;
	_mainSplitView.dividerStyle = NSSplitViewDividerStyleThin;
	_mainSplitView.delegate = self;
	_mainSplitView.translatesAutoresizingMaskIntoConstraints = NO;

	_leftSidebarView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, _leftSidebarWidth, 722)];
	[self populateLeftSidebar:_leftSidebarView];

	_centerCanvasContainerView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 740, 722)];
	[self populateCenterCanvas:_centerCanvasContainerView];

	_rightInspectorContainerView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, _rightInspectorWidth, 722)];
	[self populateRightInspector:_rightInspectorContainerView];

	[_mainSplitView addSubview:_leftSidebarView];
	[_mainSplitView addSubview:_centerCanvasContainerView];
	[_mainSplitView addSubview:_rightInspectorContainerView];
	[_mainSplitView setHoldingPriority:NSLayoutPriorityDefaultHigh forSubviewAtIndex:0];
	[_mainSplitView setHoldingPriority:NSLayoutPriorityDefaultLow forSubviewAtIndex:1];
	[_mainSplitView setHoldingPriority:NSLayoutPriorityDefaultHigh forSubviewAtIndex:2];

	[rootView addSubview:_mainSplitView];

	[NSLayoutConstraint activateConstraints:@[
		[_topWorkspaceBar.topAnchor constraintEqualToAnchor:rootView.topAnchor],
		[_topWorkspaceBar.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
		[_topWorkspaceBar.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
		[_topWorkspaceBar.heightAnchor constraintEqualToConstant:38.0],

		[_mainSplitView.topAnchor constraintEqualToAnchor:_topWorkspaceBar.bottomAnchor],
		[_mainSplitView.leadingAnchor constraintEqualToAnchor:rootView.leadingAnchor],
		[_mainSplitView.trailingAnchor constraintEqualToAnchor:rootView.trailingAnchor],
		[_mainSplitView.bottomAnchor constraintEqualToAnchor:rootView.bottomAnchor]
	]];

	self.view = rootView;
}

- (MADMacDraggablePaletteButton *)makePaletteButtonWithTitle:(NSString *)title
												  symbolName:(NSString *)symbolName
														kind:(MADMacPaletteElementKind)kind
													  action:(SEL)action
													 toolTip:(NSString *)toolTip {
	MADMacDraggablePaletteButton *btn = [[MADMacDraggablePaletteButton alloc] initWithFrame:NSZeroRect];
	btn.title = title;
	btn.bezelStyle = NSBezelStyleTexturedRounded;
	btn.controlSize = NSControlSizeSmall;
	btn.font = [NSFont systemFontOfSize:11.0 weight:NSFontWeightMedium];
	btn.target = self;
	btn.action = action;
	btn.paletteElementKind = kind;
	btn.toolTip = toolTip;
	if (@available(macOS 11.0, *)) {
		NSImage *img = [NSImage imageWithSystemSymbolName:symbolName accessibilityDescription:title];
		if (img) {
			btn.image = img;
			btn.imagePosition = NSImageLeft;
		}
	}
	return btn;
}

- (NSView *)buildTopWorkspaceBar {
	NSView *bar = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1220, 38)];
	bar.wantsLayer = YES;
	bar.layer.backgroundColor = [NSColor windowBackgroundColor].CGColor;

	NSTextField *insertLbl = [NSTextField labelWithString:@"Insert:"];
	insertLbl.font = [NSFont systemFontOfSize:11.0 weight:NSFontWeightSemibold];
	insertLbl.textColor = [NSColor secondaryLabelColor];

	MADMacDraggablePaletteButton *lblBtn = [self makePaletteButtonWithTitle:@"Label"
																 symbolName:@"textformat"
																	   kind:MADMacPaletteElementKindLabel
																	 action:@selector(addStaticLabelAction:)
																	toolTip:@"Click to insert or drag onto any section to place a Static Label"];
	MADMacDraggablePaletteButton *dataBtn = [self makePaletteButtonWithTitle:@"Data Field"
																  symbolName:@"tablecells"
																		kind:MADMacPaletteElementKindDataField
																	  action:@selector(addDataFieldAction:)
																	 toolTip:@"Click to insert or drag onto any section to place a bound Data Field"];
	MADMacDraggablePaletteButton *aggBtn = [self makePaletteButtonWithTitle:@"Aggregate"
																 symbolName:@"sum"
																	   kind:MADMacPaletteElementKindAggregate
																	 action:@selector(addAggregateAction:)
																	toolTip:@"Click to insert or drag onto any section to place a Summary Aggregate"];
	MADMacDraggablePaletteButton *bcBtn = [self makePaletteButtonWithTitle:@"Barcode"
																symbolName:@"barcode"
																	  kind:MADMacPaletteElementKindBarcode
																	action:@selector(addBarcodeAction:)
																   toolTip:@"Click to insert or drag onto any section to place a Barcode"];
	MADMacDraggablePaletteButton *imgBtn = [self makePaletteButtonWithTitle:@"Image"
																 symbolName:@"photo"
																	   kind:MADMacPaletteElementKindImage
																	 action:@selector(addImageAction:)
																	toolTip:@"Click to insert or drag onto any section to place an Image"];
	MADMacDraggablePaletteButton *lineBtn = [self makePaletteButtonWithTitle:@"Line"
																  symbolName:@"minus"
																		kind:MADMacPaletteElementKindLineRule
																	  action:@selector(addLineRuleAction:)
																	 toolTip:@"Click to insert or drag onto any section to place a horizontal rule"];

	NSBox *sep1 = [[NSBox alloc] init];
	sep1.boxType = NSBoxSeparator;
	[sep1.widthAnchor constraintEqualToConstant:1.0].active = YES;
	[sep1.heightAnchor constraintEqualToConstant:18.0].active = YES;

	NSSegmentedControl *alignBtns = [NSSegmentedControl segmentedControlWithLabels:@[@"⫷", @"⫼", @"⫸", @"⊤", @"⫿", @"⊥"]
																	  trackingMode:NSSegmentSwitchTrackingMomentary
																			target:self
																			action:@selector(quickAlignToolbarAction:)];
	alignBtns.controlSize = NSControlSizeSmall;
	alignBtns.toolTip = @"Align Selected Elements (Left, Center, Right, Top, Middle, Bottom)";

	NSButton *fitBtn = [NSButton buttonWithTitle:@"Size to Fit" target:self action:@selector(sizeSelectedElementsToFitAction:)];
	fitBtn.bezelStyle = NSBezelStyleTexturedRounded;
	fitBtn.controlSize = NSControlSizeSmall;
	fitBtn.font = [NSFont systemFontOfSize:11.0];
	fitBtn.toolTip = @"Resize selected element(s) to fit their text content";

	NSStackView *leftStack = [NSStackView stackViewWithViews:@[
		insertLbl, lblBtn, dataBtn, aggBtn, bcBtn, imgBtn, lineBtn, sep1, alignBtns, fitBtn
	]];
	leftStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	leftStack.spacing = 5.0;
	leftStack.alignment = NSLayoutAttributeCenterY;
	leftStack.translatesAutoresizingMaskIntoConstraints = NO;
	[bar addSubview:leftStack];

	_gridToggleBtn = [NSButton checkboxWithTitle:@"Grid" target:self action:@selector(toggleGridAction:)];
	_gridToggleBtn.controlSize = NSControlSizeSmall;
	_gridToggleBtn.font = [NSFont systemFontOfSize:11.0];
	_gridToggleBtn.state = NSControlStateValueOn;

	_snapToggleBtn = [NSButton checkboxWithTitle:@"Snap" target:self action:@selector(toggleSnapAction:)];
	_snapToggleBtn.controlSize = NSControlSizeSmall;
	_snapToggleBtn.font = [NSFont systemFontOfSize:11.0];
	_snapToggleBtn.state = NSControlStateValueOn;

	_rulersToggleBtn = [NSButton checkboxWithTitle:@"Rulers" target:self action:@selector(toggleRulersAction:)];
	_rulersToggleBtn.controlSize = NSControlSizeSmall;
	_rulersToggleBtn.font = [NSFont systemFontOfSize:11.0];
	_rulersToggleBtn.state = NSControlStateValueOn;

	_zoomSlider = [NSSlider sliderWithValue:1.0 minValue:0.5 maxValue:2.0 target:self action:@selector(zoomSliderChanged:)];
	_zoomSlider.controlSize = NSControlSizeSmall;
	[_zoomSlider.widthAnchor constraintEqualToConstant:84.0].active = YES;

	_zoomPercentButton = [NSButton buttonWithTitle:@"100%" target:self action:@selector(resetZoomAction:)];
	_zoomPercentButton.bezelStyle = NSBezelStyleRecessed;
	_zoomPercentButton.showsBorderOnlyWhileMouseInside = YES;
	_zoomPercentButton.controlSize = NSControlSizeSmall;
	_zoomPercentButton.font = [NSFont monospacedDigitSystemFontOfSize:11.0 weight:NSFontWeightMedium];
	_zoomPercentButton.toolTip = @"Click to reset zoom to 100%";

	NSStackView *rightStack = [NSStackView stackViewWithViews:@[
		_gridToggleBtn, _snapToggleBtn, _rulersToggleBtn, _zoomSlider, _zoomPercentButton
	]];
	rightStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	rightStack.spacing = 8.0;
	rightStack.alignment = NSLayoutAttributeCenterY;
	rightStack.translatesAutoresizingMaskIntoConstraints = NO;
	[bar addSubview:rightStack];

	NSBox *bottomLine = [[NSBox alloc] init];
	bottomLine.boxType = NSBoxSeparator;
	bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
	[bar addSubview:bottomLine];

	[NSLayoutConstraint activateConstraints:@[
		[leftStack.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor constant:10.0],
		[leftStack.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
		[rightStack.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor constant:-10.0],
		[rightStack.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
		[bottomLine.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor],
		[bottomLine.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor],
		[bottomLine.bottomAnchor constraintEqualToAnchor:bar.bottomAnchor]
	]];

	return bar;
}

- (void)populateLeftSidebar:(NSView *)container {
	NSTextField *minimapHeader = [NSTextField labelWithString:@"PAGE & SECTION MINIMAP"];
	minimapHeader.font = [NSFont systemFontOfSize:10.0 weight:NSFontWeightBold];
	minimapHeader.textColor = [NSColor secondaryLabelColor];
	minimapHeader.translatesAutoresizingMaskIntoConstraints = NO;

	NSTextField *minimapSub = [NSTextField labelWithString:@"Click a band to jump & select"];
	minimapSub.font = [NSFont systemFontOfSize:9.5];
	minimapSub.textColor = [NSColor tertiaryLabelColor];
	minimapSub.translatesAutoresizingMaskIntoConstraints = NO;

	_minimapView = [[MADMacDesignerMinimapView alloc] initWithFrame:NSMakeRect(0, 0, 200, 128)];
	_minimapView.translatesAutoresizingMaskIntoConstraints = NO;
	_minimapView.wantsLayer = YES;
	_minimapView.layer.cornerRadius = 5.0;
	_minimapView.layer.masksToBounds = YES;

	NSTextField *sectionsHeader = [NSTextField labelWithString:@"REPORT BANDS"];
	sectionsHeader.font = [NSFont systemFontOfSize:10.0 weight:NSFontWeightBold];
	sectionsHeader.textColor = [NSColor secondaryLabelColor];
	sectionsHeader.translatesAutoresizingMaskIntoConstraints = NO;

	_sectionsTableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 200, 165)];
	_sectionsTableView.headerView = nil;
	_sectionsTableView.rowHeight = 24.0;
	_sectionsTableView.allowsEmptySelection = NO;
	_sectionsTableView.dataSource = self;
	_sectionsTableView.delegate = self;
	_sectionsTableView.doubleAction = @selector(sectionsTableDoubleClicked:);
	_sectionsTableView.target = self;

	NSTableColumn *secNameCol = [[NSTableColumn alloc] initWithIdentifier:@"SectionName"];
	secNameCol.title = @"Section";
	secNameCol.width = 128.0;
	[_sectionsTableView addTableColumn:secNameCol];

	NSTableColumn *secMetaCol = [[NSTableColumn alloc] initWithIdentifier:@"SectionMeta"];
	secMetaCol.title = @"Info";
	secMetaCol.width = 68.0;
	[_sectionsTableView addTableColumn:secMetaCol];

	NSScrollView *sectionsScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 200, 165)];
	sectionsScroll.documentView = _sectionsTableView;
	sectionsScroll.hasVerticalScroller = YES;
	sectionsScroll.borderType = NSBezelBorder;
	sectionsScroll.translatesAutoresizingMaskIntoConstraints = NO;

	NSTextField *fieldsHeader = [NSTextField labelWithString:@"QUERY FIELDS (DRAG TO CANVAS)"];
	fieldsHeader.font = [NSFont systemFontOfSize:10.0 weight:NSFontWeightBold];
	fieldsHeader.textColor = [NSColor secondaryLabelColor];
	fieldsHeader.translatesAutoresizingMaskIntoConstraints = NO;

	_queryFieldsSearchField = [[NSSearchField alloc] initWithFrame:NSZeroRect];
	_queryFieldsSearchField.placeholderString = @"Filter query fields…";
	_queryFieldsSearchField.controlSize = NSControlSizeSmall;
	_queryFieldsSearchField.font = [NSFont systemFontOfSize:11.0];
	_queryFieldsSearchField.delegate = self;
	_queryFieldsSearchField.target = self;
	_queryFieldsSearchField.action = @selector(queryFieldsSearchChanged:);
	_queryFieldsSearchField.translatesAutoresizingMaskIntoConstraints = NO;

	_queryFieldsTableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 200, 220)];
	_queryFieldsTableView.headerView = nil;
	_queryFieldsTableView.rowHeight = 23.0;
	_queryFieldsTableView.dataSource = self;
	_queryFieldsTableView.delegate = self;
	_queryFieldsTableView.target = self;
	_queryFieldsTableView.doubleAction = @selector(queryFieldsTableDoubleClicked:);
	[_queryFieldsTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:YES];

	NSTableColumn *fieldCol = [[NSTableColumn alloc] initWithIdentifier:@"QueryFieldName"];
	fieldCol.title = @"Field";
	fieldCol.width = 190.0;
	[_queryFieldsTableView addTableColumn:fieldCol];

	NSScrollView *fieldsScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 200, 220)];
	fieldsScroll.documentView = _queryFieldsTableView;
	fieldsScroll.hasVerticalScroller = YES;
	fieldsScroll.borderType = NSBezelBorder;
	fieldsScroll.translatesAutoresizingMaskIntoConstraints = NO;

	NSTextField *fieldsHint = [NSTextField labelWithString:@"Drag onto any band or double-click to insert"];
	fieldsHint.font = [NSFont systemFontOfSize:9.5];
	fieldsHint.textColor = [NSColor tertiaryLabelColor];
	fieldsHint.lineBreakMode = NSLineBreakByTruncatingTail;
	fieldsHint.translatesAutoresizingMaskIntoConstraints = NO;

	[container addSubview:minimapHeader];
	[container addSubview:minimapSub];
	[container addSubview:_minimapView];
	[container addSubview:sectionsHeader];
	[container addSubview:sectionsScroll];
	[container addSubview:fieldsHeader];
	[container addSubview:_queryFieldsSearchField];
	[container addSubview:fieldsScroll];
	[container addSubview:fieldsHint];

	[NSLayoutConstraint activateConstraints:@[
		[minimapHeader.topAnchor constraintEqualToAnchor:container.topAnchor constant:10.0],
		[minimapHeader.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10.0],
		[minimapHeader.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10.0],

		[minimapSub.topAnchor constraintEqualToAnchor:minimapHeader.bottomAnchor constant:1.0],
		[minimapSub.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10.0],
		[minimapSub.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10.0],

		[_minimapView.topAnchor constraintEqualToAnchor:minimapSub.bottomAnchor constant:5.0],
		[_minimapView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10.0],
		[_minimapView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10.0],
		[_minimapView.heightAnchor constraintEqualToConstant:124.0],

		[sectionsHeader.topAnchor constraintEqualToAnchor:_minimapView.bottomAnchor constant:10.0],
		[sectionsHeader.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10.0],
		[sectionsHeader.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10.0],

		[sectionsScroll.topAnchor constraintEqualToAnchor:sectionsHeader.bottomAnchor constant:4.0],
		[sectionsScroll.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10.0],
		[sectionsScroll.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10.0],
		[sectionsScroll.heightAnchor constraintEqualToConstant:168.0],

		[fieldsHeader.topAnchor constraintEqualToAnchor:sectionsScroll.bottomAnchor constant:12.0],
		[fieldsHeader.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10.0],
		[fieldsHeader.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10.0],

		[_queryFieldsSearchField.topAnchor constraintEqualToAnchor:fieldsHeader.bottomAnchor constant:4.0],
		[_queryFieldsSearchField.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10.0],
		[_queryFieldsSearchField.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10.0],

		[fieldsScroll.topAnchor constraintEqualToAnchor:_queryFieldsSearchField.bottomAnchor constant:4.0],
		[fieldsScroll.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10.0],
		[fieldsScroll.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10.0],
		[fieldsScroll.bottomAnchor constraintEqualToAnchor:fieldsHint.topAnchor constant:-4.0],

		[fieldsHint.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10.0],
		[fieldsHint.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10.0],
		[fieldsHint.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-8.0]
	]];
}

- (void)populateCenterCanvas:(NSView *)container {
	_canvasView = [[MADMacDesignerCanvasView alloc] initWithFrame:NSMakeRect(0, 0, 740, 680)];
	_canvasView.document = self.madDocument;
	_canvasView.delegate = self;
	_minimapView.canvasView = _canvasView;

	_canvasScrollView = [[NSScrollView alloc] initWithFrame:container.bounds];
	_canvasScrollView.documentView = _canvasView;
	_canvasScrollView.hasVerticalScroller = YES;
	_canvasScrollView.hasHorizontalScroller = YES;
	_canvasScrollView.backgroundColor = [NSColor underPageBackgroundColor];
	_canvasScrollView.drawsBackground = YES;
	_canvasScrollView.translatesAutoresizingMaskIntoConstraints = NO;
	[container addSubview:_canvasScrollView];

	_canvasScrollView.contentView.postsBoundsChangedNotifications = YES;
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(canvasClipViewBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:_canvasScrollView.contentView];

	[NSLayoutConstraint activateConstraints:@[
		[_canvasScrollView.topAnchor constraintEqualToAnchor:container.topAnchor],
		[_canvasScrollView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
		[_canvasScrollView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
		[_canvasScrollView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor]
	]];
}

- (void)canvasClipViewBoundsDidChange:(__unused NSNotification *)note {
	[_minimapView setNeedsDisplay:YES];
}
#pragma mark - Right Inspector Construction (Clearly Divided Cards in ScrollView)

- (NSBox *)makeInspectorCardBoxWithTitle:(NSString *)title stackOut:(NSStackView * _Nonnull * _Nonnull)outStack {
	NSBox *box = [[NSBox alloc] initWithFrame:NSZeroRect];
	box.boxType = NSBoxCustom;
	box.borderWidth = 1.0;
	box.cornerRadius = 6.0;
	box.borderColor = [NSColor separatorColor];
	box.fillColor = [[NSColor controlBackgroundColor] colorWithAlphaComponent:0.65];
	box.contentViewMargins = NSMakeSize(8.0, 8.0);
	box.translatesAutoresizingMaskIntoConstraints = NO;

	NSStackView *cardStack = [[NSStackView alloc] initWithFrame:NSZeroRect];
	cardStack.orientation = NSUserInterfaceLayoutOrientationVertical;
	cardStack.alignment = NSLayoutAttributeLeading;
	cardStack.spacing = 6.0;
	cardStack.translatesAutoresizingMaskIntoConstraints = NO;

	if (title.length > 0) {
		NSTextField *hdr = [NSTextField labelWithString:title];
		hdr.font = [NSFont systemFontOfSize:10.0 weight:NSFontWeightBold];
		hdr.textColor = [NSColor secondaryLabelColor];
		[cardStack addArrangedSubview:hdr];
	}

	[box.contentView addSubview:cardStack];
	[NSLayoutConstraint activateConstraints:@[
		[cardStack.topAnchor constraintEqualToAnchor:box.contentView.topAnchor],
		[cardStack.leadingAnchor constraintEqualToAnchor:box.contentView.leadingAnchor],
		[cardStack.trailingAnchor constraintEqualToAnchor:box.contentView.trailingAnchor],
		[cardStack.bottomAnchor constraintEqualToAnchor:box.contentView.bottomAnchor]
	]];

	if (outStack) *outStack = cardStack;
	return box;
}

- (NSView *)makeInspectorRowWithLabel:(NSString *)labelText control:(NSView *)control {
	NSTextField *lbl = [NSTextField labelWithString:labelText];
	lbl.font = [NSFont systemFontOfSize:11.0];
	lbl.textColor = [NSColor secondaryLabelColor];
	lbl.lineBreakMode = NSLineBreakByTruncatingTail;
	[lbl.widthAnchor constraintEqualToConstant:66.0].active = YES;

	[control setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
									  forOrientation:NSLayoutConstraintOrientationHorizontal];
	if ([control isKindOfClass:[NSControl class]]) {
		((NSControl *)control).controlSize = NSControlSizeSmall;
		((NSControl *)control).font = [NSFont systemFontOfSize:11.0];
	}
	if ([control isKindOfClass:[NSPopUpButton class]]) {
		((NSPopUpButton *)control).cell.lineBreakMode = NSLineBreakByTruncatingTail;
	}

	NSStackView *row = [NSStackView stackViewWithViews:@[lbl, control]];
	row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	row.spacing = 6.0;
	row.alignment = NSLayoutAttributeCenterY;
	row.translatesAutoresizingMaskIntoConstraints = NO;
	return row;
}

- (NSTextField *)makeNumericInputFieldWithAction:(SEL)action {
	NSTextField *tf = [[NSTextField alloc] initWithFrame:NSZeroRect];
	tf.controlSize = NSControlSizeSmall;
	tf.font = [NSFont monospacedDigitSystemFontOfSize:11.0 weight:NSFontWeightRegular];
	tf.target = self;
	tf.action = action;
	[tf setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow
								 forOrientation:NSLayoutConstraintOrientationHorizontal];
	return tf;
}

- (void)populateRightInspector:(NSView *)container {
	_inspectorScrollView = [[NSScrollView alloc] initWithFrame:container.bounds];
	_inspectorScrollView.hasVerticalScroller = YES;
	_inspectorScrollView.hasHorizontalScroller = NO;
	_inspectorScrollView.drawsBackground = NO;
	_inspectorScrollView.borderType = NSNoBorder;
	_inspectorScrollView.translatesAutoresizingMaskIntoConstraints = NO;
	[container addSubview:_inspectorScrollView];

	MADMacFlippedInspectorView *docView = [[MADMacFlippedInspectorView alloc] initWithFrame:NSMakeRect(0, 0, kDefaultRightInspectorWidth, 920)];
	docView.translatesAutoresizingMaskIntoConstraints = NO;
	_inspectorScrollView.documentView = docView;

	NSStackView *rootStack = [[NSStackView alloc] initWithFrame:NSZeroRect];
	rootStack.orientation = NSUserInterfaceLayoutOrientationVertical;
	rootStack.alignment = NSLayoutAttributeLeading;
	rootStack.spacing = 10.0;
	rootStack.edgeInsets = NSEdgeInsetsMake(10.0, 10.0, 16.0, 10.0);
	rootStack.translatesAutoresizingMaskIntoConstraints = NO;
	[docView addSubview:rootStack];

	// =========================================================================
	// SECTION 1: DOCUMENT PAGE & SELECTED SECTION INSPECTOR
	// =========================================================================
	NSStackView *sectionCardStack = nil;
	NSBox *sectionCard = [self makeInspectorCardBoxWithTitle:@"1 · PAGE & SELECTED SECTION" stackOut:&sectionCardStack];

	_paperSizePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	[_paperSizePopup addItemsWithTitles:@[
		@"US Letter (8.5 × 11 in)",
		@"US Legal (8.5 × 14 in)",
		@"A4 (210 × 297 mm)"
	]];
	_paperSizePopup.target = self;
	_paperSizePopup.action = @selector(paperSizeChanged:);
	[sectionCardStack addArrangedSubview:[self makeInspectorRowWithLabel:@"Paper" control:_paperSizePopup]];

	NSBox *secInnerSep = [[NSBox alloc] init];
	secInnerSep.boxType = NSBoxSeparator;
	[sectionCardStack addArrangedSubview:secInnerSep];
	[secInnerSep.widthAnchor constraintEqualToAnchor:sectionCardStack.widthAnchor].active = YES;

	_selectedSectionBadgeLabel = [NSTextField labelWithString:@"Band: Report Detail"];
	_selectedSectionBadgeLabel.font = [NSFont systemFontOfSize:11.5 weight:NSFontWeightSemibold];
	_selectedSectionBadgeLabel.textColor = [NSColor controlAccentColor];
	_selectedSectionBadgeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	[sectionCardStack addArrangedSubview:_selectedSectionBadgeLabel];

	_sectionHeightField = [self makeNumericInputFieldWithAction:@selector(sectionHeightFieldEdited:)];
	NSButton *autoFitSecBtn = [NSButton buttonWithTitle:@"Fit Height"
												 target:self
												 action:@selector(autoFitSelectedSectionHeightAction:)];
	autoFitSecBtn.bezelStyle = NSBezelStyleRounded;
	autoFitSecBtn.controlSize = NSControlSizeSmall;
	autoFitSecBtn.font = [NSFont systemFontOfSize:10.5];
	autoFitSecBtn.toolTip = @"Shrink or expand section height to snugly fit its elements";

	NSStackView *secHeightControls = [NSStackView stackViewWithViews:@[_sectionHeightField, autoFitSecBtn]];
	secHeightControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	secHeightControls.spacing = 4.0;
	[sectionCardStack addArrangedSubview:[self makeInspectorRowWithLabel:@"Height (pt)" control:secHeightControls]];

	_sectionVisibleCheck = [NSButton checkboxWithTitle:@"Section Visible"
												target:self
												action:@selector(sectionVisibleChanged:)];
	_sectionVisibleCheck.controlSize = NSControlSizeSmall;
	_sectionVisibleCheck.font = [NSFont systemFontOfSize:11.0];

	_sectionPageBreakCheck = [NSButton checkboxWithTitle:@"Page Break After"
												  target:self
												  action:@selector(sectionPageBreakChanged:)];
	_sectionPageBreakCheck.controlSize = NSControlSizeSmall;
	_sectionPageBreakCheck.font = [NSFont systemFontOfSize:11.0];

	NSStackView *secFlagsRow = [NSStackView stackViewWithViews:@[_sectionVisibleCheck, _sectionPageBreakCheck]];
	secFlagsRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	secFlagsRow.spacing = 10.0;
	[sectionCardStack addArrangedSubview:secFlagsRow];

	[rootStack addArrangedSubview:sectionCard];
	[sectionCard.widthAnchor constraintEqualToAnchor:rootStack.widthAnchor constant:-20.0].active = YES;

	// =========================================================================
	// PROMINENT VISUAL DIVIDER BETWEEN SECTION & ELEMENT INSPECTORS
	// =========================================================================
	NSBox *majorDivider = [[NSBox alloc] init];
	majorDivider.boxType = NSBoxSeparator;
	[rootStack addArrangedSubview:majorDivider];
	[majorDivider.widthAnchor constraintEqualToAnchor:rootStack.widthAnchor constant:-20.0].active = YES;

	NSTextField *elemMajorHeader = [NSTextField labelWithString:@"2 · SELECTED ELEMENT INSPECTOR"];
	elemMajorHeader.font = [NSFont systemFontOfSize:10.5 weight:NSFontWeightBold];
	elemMajorHeader.textColor = [NSColor labelColor];
	[rootStack addArrangedSubview:elemMajorHeader];

	_noElementSelectedHintLabel = [NSTextField wrappingLabelWithString:
		@"No element selected.\n\nClick an element on the canvas to inspect and style it, or drag a Query Field from the left sidebar onto any report band."];
	_noElementSelectedHintLabel.font = [NSFont systemFontOfSize:11.0];
	_noElementSelectedHintLabel.textColor = [NSColor secondaryLabelColor];
	[rootStack addArrangedSubview:_noElementSelectedHintLabel];
	[_noElementSelectedHintLabel.widthAnchor constraintEqualToAnchor:rootStack.widthAnchor constant:-20.0].active = YES;

	_elementInspectorCardsStack = [[NSStackView alloc] initWithFrame:NSZeroRect];
	_elementInspectorCardsStack.orientation = NSUserInterfaceLayoutOrientationVertical;
	_elementInspectorCardsStack.alignment = NSLayoutAttributeLeading;
	_elementInspectorCardsStack.spacing = 10.0;
	_elementInspectorCardsStack.translatesAutoresizingMaskIntoConstraints = NO;
	[rootStack addArrangedSubview:_elementInspectorCardsStack];
	[_elementInspectorCardsStack.widthAnchor constraintEqualToAnchor:rootStack.widthAnchor constant:-20.0].active = YES;

	// -------------------------------------------------------------------------
	// CARD 2A: ELEMENT IDENTITY & SECTION ASSIGNMENT
	// -------------------------------------------------------------------------
	NSStackView *idCardStack = nil;
	NSBox *idCard = [self makeInspectorCardBoxWithTitle:@"ELEMENT & BAND ASSIGNMENT" stackOut:&idCardStack];

	_elementTypeBadgeLabel = [NSTextField labelWithString:@"Static Label"];
	_elementTypeBadgeLabel.font = [NSFont systemFontOfSize:11.5 weight:NSFontWeightSemibold];
	_elementTypeBadgeLabel.textColor = [NSColor controlAccentColor];
	_elementTypeBadgeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	[idCardStack addArrangedSubview:_elementTypeBadgeLabel];

	_elementSectionPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	_elementSectionPopup.target = self;
	_elementSectionPopup.action = @selector(elementSectionAssignmentChanged:);
	_elementSectionPopup.toolTip = @"Move the selected element(s) to another report section";
	[idCardStack addArrangedSubview:[self makeInspectorRowWithLabel:@"Band" control:_elementSectionPopup]];

	NSButton *dupBtn = [NSButton buttonWithTitle:@"Duplicate" target:self action:@selector(duplicateSelectedElementsAction:)];
	dupBtn.bezelStyle = NSBezelStyleRounded;
	dupBtn.controlSize = NSControlSizeSmall;
	dupBtn.font = [NSFont systemFontOfSize:11.0];

	NSButton *delBtn = [NSButton buttonWithTitle:@"Delete" target:self action:@selector(deleteSelectedElementsAction:)];
	delBtn.bezelStyle = NSBezelStyleRounded;
	delBtn.controlSize = NSControlSizeSmall;
	delBtn.font = [NSFont systemFontOfSize:11.0];
	if (@available(macOS 11.0, *)) {
		delBtn.hasDestructiveAction = YES;
	}

	NSStackView *idActionsRow = [NSStackView stackViewWithViews:@[dupBtn, delBtn]];
	idActionsRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	idActionsRow.spacing = 6.0;
	[idCardStack addArrangedSubview:idActionsRow];

	[_elementInspectorCardsStack addArrangedSubview:idCard];
	[idCard.widthAnchor constraintEqualToAnchor:_elementInspectorCardsStack.widthAnchor].active = YES;

	// -------------------------------------------------------------------------
	// CARD 2B: CONTENT & DATA BINDING (Contextual to Element Type)
	// -------------------------------------------------------------------------
	NSStackView *bindingStack = nil;
	_contentBindingCard = [self makeInspectorCardBoxWithTitle:@"CONTENT & DATA BINDING" stackOut:&bindingStack];

	_elementTextField = [[NSTextField alloc] initWithFrame:NSZeroRect];
	_elementTextField.placeholderString = @"Label or barcode text…";
	_elementTextField.target = self;
	_elementTextField.action = @selector(elementTextEdited:);
	_staticTextRow = [self makeInspectorRowWithLabel:@"Text" control:_elementTextField];
	[bindingStack addArrangedSubview:_staticTextRow];

	_queryFieldPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	_queryFieldPopup.target = self;
	_queryFieldPopup.action = @selector(queryFieldChanged:);
	_queryFieldRow = [self makeInspectorRowWithLabel:@"Field" control:_queryFieldPopup];
	[bindingStack addArrangedSubview:_queryFieldRow];

	_aggregateTypePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	[_aggregateTypePopup addItemsWithTitles:@[@"SUM", @"MEAN (AVG)", @"COUNT", @"FIRST", @"LAST", @"MIN", @"MAX"]];
	_aggregateTypePopup.target = self;
	_aggregateTypePopup.action = @selector(aggregateTypeChanged:);
	_aggregateFunctionRow = [self makeInspectorRowWithLabel:@"Function" control:_aggregateTypePopup];
	[bindingStack addArrangedSubview:_aggregateFunctionRow];

	_aggregateScopePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	_aggregateScopePopup.target = self;
	_aggregateScopePopup.action = @selector(aggregateScopeChanged:);
	_aggregateScopeRow = [self makeInspectorRowWithLabel:@"Scope" control:_aggregateScopePopup];
	[bindingStack addArrangedSubview:_aggregateScopeRow];

	_numericFormatCheck = [NSButton checkboxWithTitle:@"Numeric" target:self action:@selector(numericFormatChanged:)];
	_numericFormatCheck.controlSize = NSControlSizeSmall;
	_numericFormatCheck.font = [NSFont systemFontOfSize:11.0];

	NSTextField *decLbl = [NSTextField labelWithString:@"Dec:"];
	decLbl.font = [NSFont systemFontOfSize:11.0];
	decLbl.textColor = [NSColor secondaryLabelColor];
	_decimalsField = [self makeNumericInputFieldWithAction:@selector(numericFormatChanged:)];
	[_decimalsField.widthAnchor constraintEqualToConstant:34.0].active = YES;

	NSStackView *numFormatControls = [NSStackView stackViewWithViews:@[_numericFormatCheck, decLbl, _decimalsField]];
	numFormatControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	numFormatControls.spacing = 4.0;
	_numericFormatRow = [self makeInspectorRowWithLabel:@"Format" control:numFormatControls];
	[bindingStack addArrangedSubview:_numericFormatRow];

	_barcodeSymbologyPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	NSDictionary *symDict = [MADBarcode newDictionaryNames] ?: @{};
	NSArray<NSNumber *> *sortedKeys = [[symDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
	for (NSNumber *symNum in sortedKeys) {
		NSString *name = symDict[symNum];
		if (name.length > 0) {
			[_barcodeSymbologyPopup addItemWithTitle:name];
			_barcodeSymbologyPopup.lastItem.tag = symNum.integerValue;
		}
	}
	_barcodeSymbologyPopup.target = self;
	_barcodeSymbologyPopup.action = @selector(barcodeSymbologyChanged:);
	_barcodeSymbologyRow = [self makeInspectorRowWithLabel:@"Symbology" control:_barcodeSymbologyPopup];
	[bindingStack addArrangedSubview:_barcodeSymbologyRow];

	_barcodeHumanReadableCheck = [NSButton checkboxWithTitle:@"Show Text" target:self action:@selector(barcodeOptionsChanged:)];
	_barcodeHumanReadableCheck.controlSize = NSControlSizeSmall;
	_barcodeHumanReadableCheck.font = [NSFont systemFontOfSize:11.0];
	_barcodeBorderPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	[_barcodeBorderPopup addItemsWithTitles:@[@"No Border", @"Bind Bars", @"Box Frame"]];
	_barcodeBorderPopup.target = self;
	_barcodeBorderPopup.action = @selector(barcodeOptionsChanged:);
	NSStackView *bcOptControls = [NSStackView stackViewWithViews:@[_barcodeHumanReadableCheck, _barcodeBorderPopup]];
	bcOptControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	bcOptControls.spacing = 6.0;
	_barcodeOptionsRow = [self makeInspectorRowWithLabel:@"Options" control:bcOptControls];
	[bindingStack addArrangedSubview:_barcodeOptionsRow];

	_chooseImageButton = [NSButton buttonWithTitle:@"Choose Image…" target:self action:@selector(chooseImageFileAction:)];
	_chooseImageButton.bezelStyle = NSBezelStyleRounded;
	_imagePickerRow = [self makeInspectorRowWithLabel:@"Image" control:_chooseImageButton];
	[bindingStack addArrangedSubview:_imagePickerRow];

	[_elementInspectorCardsStack addArrangedSubview:_contentBindingCard];
	[_contentBindingCard.widthAnchor constraintEqualToAnchor:_elementInspectorCardsStack.widthAnchor].active = YES;

	// -------------------------------------------------------------------------
	// CARD 2C: TYPOGRAPHY, ALIGNMENT & COLORS
	// -------------------------------------------------------------------------
	NSStackView *typoStack = nil;
	NSBox *typoCard = [self makeInspectorCardBoxWithTitle:@"TYPOGRAPHY & APPEARANCE" stackOut:&typoStack];

	_fontFamilyPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	[_fontFamilyPopup addItemsWithTitles:@[
		@"Helvetica", @"HelveticaNeue", @"ArialMT", @"Courier",
		@"TimesNewRomanPSMT", @"Avenir-Book", @"Menlo-Regular", @"Georgia"
	]];
	_fontFamilyPopup.target = self;
	_fontFamilyPopup.action = @selector(typographyChanged:);
	[typoStack addArrangedSubview:[self makeInspectorRowWithLabel:@"Font" control:_fontFamilyPopup]];

	_fontSizeField = [self makeNumericInputFieldWithAction:@selector(typographyChanged:)];
	[typoStack addArrangedSubview:[self makeInspectorRowWithLabel:@"Size (pt)" control:_fontSizeField]];

	_boldCheck = [NSButton checkboxWithTitle:@"B" target:self action:@selector(typographyChanged:)];
	_boldCheck.font = [NSFont boldSystemFontOfSize:11.0];
	_boldCheck.controlSize = NSControlSizeSmall;
	_italicCheck = [NSButton checkboxWithTitle:@"I" target:self action:@selector(typographyChanged:)];
	_italicCheck.font = [NSFontManager.sharedFontManager convertFont:[NSFont systemFontOfSize:11.0] toHaveTrait:NSItalicFontMask];
	_italicCheck.controlSize = NSControlSizeSmall;
	_underlineCheck = [NSButton checkboxWithTitle:@"U" target:self action:@selector(typographyChanged:)];
	_underlineCheck.font = [NSFont systemFontOfSize:11.0];
	_underlineCheck.controlSize = NSControlSizeSmall;
	_strikethroughCheck = [NSButton checkboxWithTitle:@"S" target:self action:@selector(typographyChanged:)];
	_strikethroughCheck.font = [NSFont systemFontOfSize:11.0];
	_strikethroughCheck.controlSize = NSControlSizeSmall;

	NSStackView *styleChecks = [NSStackView stackViewWithViews:@[_boldCheck, _italicCheck, _underlineCheck, _strikethroughCheck]];
	styleChecks.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	styleChecks.spacing = 8.0;
	[typoStack addArrangedSubview:[self makeInspectorRowWithLabel:@"Style" control:styleChecks]];

	_hAlignControl = [NSSegmentedControl segmentedControlWithLabels:@[@"Left", @"Center", @"Right"]
													   trackingMode:NSSegmentSwitchTrackingSelectOne
															 target:self
															 action:@selector(alignmentChanged:)];
	[typoStack addArrangedSubview:[self makeInspectorRowWithLabel:@"H-Align" control:_hAlignControl]];

	_vAlignControl = [NSSegmentedControl segmentedControlWithLabels:@[@"Top", @"Middle", @"Bottom"]
													   trackingMode:NSSegmentSwitchTrackingSelectOne
															 target:self
															 action:@selector(alignmentChanged:)];
	[typoStack addArrangedSubview:[self makeInspectorRowWithLabel:@"V-Align" control:_vAlignControl]];

	_fgColorWell = [[NSColorWell alloc] initWithFrame:NSMakeRect(0, 0, 38, 22)];
	_fgColorWell.target = self;
	_fgColorWell.action = @selector(colorChanged:);
	[_fgColorWell.widthAnchor constraintEqualToConstant:40.0].active = YES;
	[_fgColorWell.heightAnchor constraintEqualToConstant:22.0].active = YES;

	_hasBgColorCheck = [NSButton checkboxWithTitle:@"Fill" target:self action:@selector(colorChanged:)];
	_hasBgColorCheck.controlSize = NSControlSizeSmall;
	_hasBgColorCheck.font = [NSFont systemFontOfSize:11.0];

	_bgColorWell = [[NSColorWell alloc] initWithFrame:NSMakeRect(0, 0, 38, 22)];
	_bgColorWell.target = self;
	_bgColorWell.action = @selector(colorChanged:);
	[_bgColorWell.widthAnchor constraintEqualToConstant:40.0].active = YES;
	[_bgColorWell.heightAnchor constraintEqualToConstant:22.0].active = YES;

	NSStackView *colorRowControls = [NSStackView stackViewWithViews:@[_fgColorWell, _hasBgColorCheck, _bgColorWell]];
	colorRowControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	colorRowControls.spacing = 6.0;
	[typoStack addArrangedSubview:[self makeInspectorRowWithLabel:@"Colors" control:colorRowControls]];

	[_elementInspectorCardsStack addArrangedSubview:typoCard];
	[typoCard.widthAnchor constraintEqualToAnchor:_elementInspectorCardsStack.widthAnchor].active = YES;

	// -------------------------------------------------------------------------
	// CARD 2D: POSITION, SIZE & BOX MODEL (Borders, Padding, Margin)
	// -------------------------------------------------------------------------
	NSStackView *geomStack = nil;
	NSBox *geomCard = [self makeInspectorCardBoxWithTitle:@"POSITION, SIZE & BOX MODEL" stackOut:&geomStack];

	_posXField = [self makeNumericInputFieldWithAction:@selector(elementGeometryEdited:)];
	_posYField = [self makeNumericInputFieldWithAction:@selector(elementGeometryEdited:)];
	_widthField = [self makeNumericInputFieldWithAction:@selector(elementGeometryEdited:)];
	_heightField = [self makeNumericInputFieldWithAction:@selector(elementGeometryEdited:)];

	NSTextField *yLbl = [NSTextField labelWithString:@"Y:"];
	yLbl.font = [NSFont systemFontOfSize:11.0];
	yLbl.textColor = [NSColor secondaryLabelColor];
	NSStackView *xyRow = [NSStackView stackViewWithViews:@[_posXField, yLbl, _posYField]];
	xyRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	xyRow.spacing = 4.0;
	xyRow.distribution = NSStackViewDistributionFillProportionally;
	[geomStack addArrangedSubview:[self makeInspectorRowWithLabel:@"X / Y (pt)" control:xyRow]];

	NSTextField *hLbl = [NSTextField labelWithString:@"H:"];
	hLbl.font = [NSFont systemFontOfSize:11.0];
	hLbl.textColor = [NSColor secondaryLabelColor];
	NSStackView *whRow = [NSStackView stackViewWithViews:@[_widthField, hLbl, _heightField]];
	whRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	whRow.spacing = 4.0;
	whRow.distribution = NSStackViewDistributionFillProportionally;
	[geomStack addArrangedSubview:[self makeInspectorRowWithLabel:@"W / H (pt)" control:whRow]];

	_borderTopField = [self makeNumericInputFieldWithAction:@selector(elementBoxModelEdited:)];
	_borderTopField.toolTip = @"Top Border (pt)";
	_borderBottomField = [self makeNumericInputFieldWithAction:@selector(elementBoxModelEdited:)];
	_borderBottomField.toolTip = @"Bottom Border (pt)";
	_borderLeftField = [self makeNumericInputFieldWithAction:@selector(elementBoxModelEdited:)];
	_borderLeftField.toolTip = @"Left Border (pt)";
	_borderRightField = [self makeNumericInputFieldWithAction:@selector(elementBoxModelEdited:)];
	_borderRightField.toolTip = @"Right Border (pt)";

	NSStackView *bordersGrid = [NSStackView stackViewWithViews:@[
		_borderTopField, _borderBottomField, _borderLeftField, _borderRightField
	]];
	bordersGrid.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	bordersGrid.spacing = 3.0;
	bordersGrid.distribution = NSStackViewDistributionFillEqually;
	[geomStack addArrangedSubview:[self makeInspectorRowWithLabel:@"Border T/B/L/R" control:bordersGrid]];

	_paddingAllField = [self makeNumericInputFieldWithAction:@selector(elementBoxModelEdited:)];
	_marginAllField = [self makeNumericInputFieldWithAction:@selector(elementBoxModelEdited:)];
	NSTextField *mLbl = [NSTextField labelWithString:@"M:"];
	mLbl.font = [NSFont systemFontOfSize:11.0];
	mLbl.textColor = [NSColor secondaryLabelColor];
	NSStackView *padMarRow = [NSStackView stackViewWithViews:@[_paddingAllField, mLbl, _marginAllField]];
	padMarRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	padMarRow.spacing = 4.0;
	padMarRow.distribution = NSStackViewDistributionFillProportionally;
	[geomStack addArrangedSubview:[self makeInspectorRowWithLabel:@"Pad / Margin" control:padMarRow]];

	[_elementInspectorCardsStack addArrangedSubview:geomCard];
	[geomCard.widthAnchor constraintEqualToAnchor:_elementInspectorCardsStack.widthAnchor].active = YES;

	NSClipView *clipView = _inspectorScrollView.contentView;
	[NSLayoutConstraint activateConstraints:@[
		[_inspectorScrollView.topAnchor constraintEqualToAnchor:container.topAnchor],
		[_inspectorScrollView.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
		[_inspectorScrollView.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
		[_inspectorScrollView.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],

		[docView.topAnchor constraintEqualToAnchor:clipView.topAnchor],
		[docView.leadingAnchor constraintEqualToAnchor:clipView.leadingAnchor],
		[docView.trailingAnchor constraintEqualToAnchor:clipView.trailingAnchor],

		[rootStack.topAnchor constraintEqualToAnchor:docView.topAnchor],
		[rootStack.leadingAnchor constraintEqualToAnchor:docView.leadingAnchor],
		[rootStack.trailingAnchor constraintEqualToAnchor:docView.trailingAnchor],
		[rootStack.bottomAnchor constraintEqualToAnchor:docView.bottomAnchor]
	]];
}

#pragma mark - NSSplitViewDelegate (Resizable Left Sidebar & Right Inspector)

- (CGFloat)splitView:(__unused NSSplitView *)splitView
	constrainMinCoordinate:(CGFloat)proposedMinimumPosition
			   ofSubviewAt:(NSInteger)dividerIndex {
	if (dividerIndex == 0) {
		return MAX(proposedMinimumPosition, kMinLeftSidebarWidth);
	}
	if (dividerIndex == 1) {
		CGFloat totalW = NSWidth(splitView.bounds);
		return MAX(_leftSidebarWidth + 280.0, totalW - kMaxRightInspectorWidth);
	}
	return proposedMinimumPosition;
}

- (CGFloat)splitView:(__unused NSSplitView *)splitView
	constrainMaxCoordinate:(CGFloat)proposedMaximumPosition
			   ofSubviewAt:(NSInteger)dividerIndex {
	if (dividerIndex == 0) {
		return MIN(proposedMaximumPosition, kMaxLeftSidebarWidth);
	}
	if (dividerIndex == 1) {
		CGFloat totalW = NSWidth(splitView.bounds);
		return MIN(proposedMaximumPosition, totalW - kMinRightInspectorWidth);
	}
	return proposedMaximumPosition;
}

- (BOOL)splitView:(__unused NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view {
	if (view == _leftSidebarView || view == _rightInspectorContainerView) {
		return NO;
	}
	return YES;
}

- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(__unused NSSize)oldSize {
	if (splitView != _mainSplitView || splitView.subviews.count < 3) {
		[splitView adjustSubviews];
		return;
	}
	_isResizingMainSplitProgrammatically = YES;
	NSRect bounds = splitView.bounds;
	CGFloat dividerThickness = splitView.dividerThickness;

	CGFloat leftW = MIN(kMaxLeftSidebarWidth, MAX(kMinLeftSidebarWidth, _leftSidebarWidth));
	CGFloat rightW = MIN(kMaxRightInspectorWidth, MAX(kMinRightInspectorWidth, _rightInspectorWidth));
	CGFloat centerW = MAX(240.0, bounds.size.width - leftW - rightW - dividerThickness * 2.0);

	if (leftW + rightW + centerW + dividerThickness * 2.0 > bounds.size.width) {
		centerW = MAX(180.0, bounds.size.width - leftW - rightW - dividerThickness * 2.0);
	}

	_leftSidebarView.frame = NSMakeRect(0.0, 0.0, leftW, bounds.size.height);
	_centerCanvasContainerView.frame = NSMakeRect(leftW + dividerThickness, 0.0, centerW, bounds.size.height);
	_rightInspectorContainerView.frame = NSMakeRect(leftW + dividerThickness + centerW + dividerThickness, 0.0, rightW, bounds.size.height);
	_isResizingMainSplitProgrammatically = NO;
	[_canvasView recalculateCanvasSize];
	[_minimapView setNeedsDisplay:YES];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
	if (notification.object != _mainSplitView || _isResizingMainSplitProgrammatically) {
		return;
	}
	CGFloat currentLeftW = NSWidth(_leftSidebarView.frame);
	if (currentLeftW >= kMinLeftSidebarWidth - 1.0 && currentLeftW <= kMaxLeftSidebarWidth + 1.0) {
		_leftSidebarWidth = currentLeftW;
	}
	CGFloat currentRightW = NSWidth(_rightInspectorContainerView.frame);
	if (currentRightW >= kMinRightInspectorWidth - 1.0 && currentRightW <= kMaxRightInspectorWidth + 1.0) {
		_rightInspectorWidth = currentRightW;
	}
	[_canvasView recalculateCanvasSize];
	[_minimapView setNeedsDisplay:YES];
}
#pragma mark - Reloading & Query Field Browser

- (NSArray<RptqQueryField *> *)allQueryFields {
	MADMacDocument *doc = self.madDocument;
	RptqQuery *q = doc.rptqQuery;
	if (!q) return @[];
	NSMutableArray<RptqQueryField *> *fields = [NSMutableArray array];
	for (RptqQueryTable *qt in q.hasQueryTables) {
		for (RptqQueryField *qf in qt.hasQueryFields) {
			[fields addObject:qf];
		}
	}
	return fields;
}

- (NSString *)displayLabelForQueryField:(RptqQueryField *)qf {
	if (!qf) return @"(Unbound)";
	NSString *tbl = qf.inQueryTable.alias.length > 0
		? qf.inQueryTable.alias
		: (qf.inQueryTable.databaseSchemaTable.name ?: @"Table");
	NSString *col = qf.databaseSchemaField.name ?: @"Field";
	return [NSString stringWithFormat:@"%@.%@", tbl, col];
}

- (void)rebuildFilteredQueryFields {
	NSArray<RptqQueryField *> *all = [self allQueryFields];
	NSString *filter = [_queryFieldsSearchField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (filter.length == 0) {
		_filteredQueryFields = all;
	} else {
		NSMutableArray<RptqQueryField *> *matches = [NSMutableArray array];
		for (RptqQueryField *qf in all) {
			NSString *label = [self displayLabelForQueryField:qf];
			if ([label rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound) {
				[matches addObject:qf];
			}
		}
		_filteredQueryFields = matches;
	}
	[_queryFieldsTableView reloadData];
}

- (void)queryFieldsSearchChanged:(__unused id)sender {
	[self rebuildFilteredQueryFields];
}

- (void)controlTextDidChange:(NSNotification *)obj {
	if (obj.object == _queryFieldsSearchField) {
		[self rebuildFilteredQueryFields];
	}
}

- (void)reloadSectionsTablePreservingSelection {
	BOOL wasUpdating = _isUpdatingInspector;
	_isUpdatingInspector = YES;
	[_sectionsTableView reloadData];
	RptqDocumentSection *sec = _canvasView.selectedSection;
	NSArray<RptqDocumentSection *> *sections = [_canvasView orderedSections];
	if (sec) {
		NSUInteger idx = [sections indexOfObject:sec];
		if (idx != NSNotFound) {
			[_sectionsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
		}
	}
	_isUpdatingInspector = wasUpdating;
}

- (void)reloadFromDocument {
	MADMacDocument *doc = self.madDocument;
	_canvasView.document = doc;
	NSArray<RptqDocumentSection *> *sections = [_canvasView orderedSections];
	if (!_canvasView.selectedSection && sections.count > 0) {
		RptqDocumentSection *detail = doc.rptqDocument.hasDetailSection;
		_canvasView.selectedSection = detail ?: sections.firstObject;
	}
	[self rebuildQueryFieldAndScopePopups];
	[self rebuildFilteredQueryFields];
	[self reloadSectionsTablePreservingSelection];
	[_canvasView recalculateCanvasSize];
	[_canvasView setNeedsDisplay:YES];
	[_minimapView setNeedsDisplay:YES];
	[self syncInspectorFromSelection];
}

- (void)rebuildQueryFieldAndScopePopups {
	MADMacDocument *doc = self.madDocument;

	// 1. Query field popup
	[_queryFieldPopup removeAllItems];
	[_queryFieldPopup addItemWithTitle:@"(Unbound)"];
	_queryFieldPopup.lastItem.tag = 0;
	for (RptqQueryField *qf in [self allQueryFields]) {
		[_queryFieldPopup addItemWithTitle:[self displayLabelForQueryField:qf]];
		_queryFieldPopup.lastItem.tag = (NSInteger)qf.identifier;
	}

	// 2. Element Section assignment popup
	[_elementSectionPopup removeAllItems];
	NSArray<RptqDocumentSection *> *sections = [_canvasView orderedSections];
	for (NSUInteger i = 0; i < sections.count; i++) {
		RptqDocumentSection *sec = sections[i];
		NSString *title = doc ? [doc displayTitleForSection:sec] : ([sec localizedDisplayName] ?: @"Section");
		[_elementSectionPopup addItemWithTitle:title];
		_elementSectionPopup.lastItem.tag = (NSInteger)i;
	}

	// 3. Aggregate Scope ("For Each") popup
	[_aggregateScopePopup removeAllItems];
	[_aggregateScopePopup addItemWithTitle:@"Entire Report"];
	_aggregateScopePopup.lastItem.tag = 0; // MTAggregateGroupByTypeReport
	[_aggregateScopePopup addItemWithTitle:@"Each Page"];
	_aggregateScopePopup.lastItem.tag = -1; // MTAggregateGroupByTypePage
	int32_t groupIndex = 1;
	for (RptqDocumentSection *sec in sections) {
		if ((MADDocumentSectionType)sec.type == MADDocumentSectionTypeGroupHeader) {
			NSString *secTitle = doc ? [doc displayTitleForSection:sec] : @"Group";
			NSString *gTitle = [NSString stringWithFormat:@"Group #%d (%@)", groupIndex, secTitle];
			[_aggregateScopePopup addItemWithTitle:gTitle];
			_aggregateScopePopup.lastItem.tag = groupIndex; // MTAggregateGroupByTypeSection, groupNumber = groupIndex
			groupIndex++;
		}
	}
}

#pragma mark - NSTableViewDataSource & NSTableViewDelegate (Sections & Query Fields)

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if (tableView == _sectionsTableView) {
		return (NSInteger)[_canvasView orderedSections].count;
	}
	if (tableView == _queryFieldsTableView) {
		return (NSInteger)_filteredQueryFields.count;
	}
	return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	MADMacDocument *doc = self.madDocument;
	if (tableView == _sectionsTableView) {
		NSArray<RptqDocumentSection *> *sections = [_canvasView orderedSections];
		if (row < 0 || (NSUInteger)row >= sections.count) return nil;
		RptqDocumentSection *sec = sections[(NSUInteger)row];
		MADDocumentSectionType sType = (MADDocumentSectionType)sec.type;
		BOOL isGroup = (sType == MADDocumentSectionTypeGroupHeader || sType == MADDocumentSectionTypeGroupFooter);

		if ([tableColumn.identifier isEqualToString:@"SectionName"]) {
			NSTextField *lbl = [NSTextField labelWithString:@""];
			NSString *prefix = isGroup ? @"  • " : @"● ";
			NSString *name = doc ? [doc displayTitleForSection:sec] : ([sec localizedDisplayName] ?: @"Section");
			if (!sec.visibility) name = [name stringByAppendingString:@" (Hidden)"];
			NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:[prefix stringByAppendingString:name]];
			NSColor *dotColor = [sec isEqual:_canvasView.selectedSection]
				? [NSColor controlAccentColor]
				: (sec.visibility ? [NSColor secondaryLabelColor] : [NSColor tertiaryLabelColor]);
			[attr addAttribute:NSForegroundColorAttributeName value:dotColor range:NSMakeRange(0, prefix.length)];
			[attr addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11.0 weight:isGroup ? NSFontWeightRegular : NSFontWeightMedium] range:NSMakeRange(0, attr.length)];
			lbl.attributedStringValue = attr;
			lbl.lineBreakMode = NSLineBreakByTruncatingTail;
			return lbl;
		} else {
			NSUInteger count = [_canvasView elementsInSection:sec].count;
			CGFloat h = sec.layoutHeight > 0 ? (CGFloat)sec.layoutHeight : MAX(36.0, (CGFloat)sec.height - 44.0);
			NSString *meta = sec.visibility
				? [NSString stringWithFormat:@"%lu · %.0fpt%@", (unsigned long)count, h, [sec producesFormFeed] ? @" ⇥" : @""]
				: @"Hidden";
			NSTextField *lbl = [NSTextField labelWithString:meta];
			lbl.font = [NSFont monospacedDigitSystemFontOfSize:10.0 weight:NSFontWeightRegular];
			lbl.textColor = [NSColor secondaryLabelColor];
			lbl.alignment = NSTextAlignmentRight;
			return lbl;
		}
	}

	if (tableView == _queryFieldsTableView) {
		if (row < 0 || (NSUInteger)row >= _filteredQueryFields.count) return nil;
		RptqQueryField *qf = _filteredQueryFields[(NSUInteger)row];
		NSTextField *lbl = [NSTextField labelWithString:[self displayLabelForQueryField:qf]];
		lbl.font = [NSFont systemFontOfSize:11.0 weight:NSFontWeightRegular];
		lbl.lineBreakMode = NSLineBreakByTruncatingTail;
		lbl.toolTip = @"Drag onto any report section on the canvas, or double-click to insert into the selected section";
		return lbl;
	}
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	if (_isUpdatingInspector) return;
	if (notification.object == _sectionsTableView) {
		NSInteger row = _sectionsTableView.selectedRow;
		NSArray<RptqDocumentSection *> *sections = [_canvasView orderedSections];
		if (row >= 0 && (NSUInteger)row < sections.count) {
			RptqDocumentSection *sec = sections[(NSUInteger)row];
			_canvasView.selectedSection = sec;
			[_canvasView scrollToSection:sec];
			[_canvasView setNeedsDisplay:YES];
			[_minimapView setNeedsDisplay:YES];
			[self syncInspectorFromSelection];
		}
	}
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
	if (tableView == _queryFieldsTableView) {
		if (row < 0 || (NSUInteger)row >= _filteredQueryFields.count) return nil;
		RptqQueryField *qf = _filteredQueryFields[(NSUInteger)row];
		NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
		[item setString:[NSString stringWithFormat:@"%lld", qf.identifier]
				forType:MADMacDesignerPasteboardTypeQueryField];
		[item setString:[self displayLabelForQueryField:qf]
				forType:NSPasteboardTypeString];
		return item;
	}
	return nil;
}

- (void)sectionsTableDoubleClicked:(__unused id)sender {
	MADMacDocument *doc = self.madDocument;
	NSInteger row = _sectionsTableView.clickedRow >= 0 ? _sectionsTableView.clickedRow : _sectionsTableView.selectedRow;
	NSArray<RptqDocumentSection *> *sections = [_canvasView orderedSections];
	if (row >= 0 && (NSUInteger)row < sections.count) {
		RptqDocumentSection *sec = sections[(NSUInteger)row];
		sec.visibility = !sec.visibility;
		[doc notifyDocumentMutated];
		[_canvasView recalculateCanvasSize];
		[_canvasView setNeedsDisplay:YES];
		[_minimapView setNeedsDisplay:YES];
		[self reloadSectionsTablePreservingSelection];
		[self syncInspectorFromSelection];
	}
}

- (void)queryFieldsTableDoubleClicked:(__unused id)sender {
	NSInteger row = _queryFieldsTableView.clickedRow >= 0 ? _queryFieldsTableView.clickedRow : _queryFieldsTableView.selectedRow;
	if (row < 0 || (NSUInteger)row >= _filteredQueryFields.count) return;
	RptqQueryField *qf = _filteredQueryFields[(NSUInteger)row];
	RptqDocumentSection *targetSec = [self ensureSelectedSection];
	if (!targetSec) return;
	NSPoint origin = [_canvasView nextAvailableOriginInSection:targetSec forElementSize:NSMakeSize(140.0, 22.0)];
	[self addDataField:qf inSection:targetSec atPoint:origin];
}

#pragma mark - Inspector Synchronization

- (void)syncInspectorFromSelection {
	_isUpdatingInspector = YES;
	[self rebuildQueryFieldAndScopePopups];

	MADMacDocument *doc = self.madDocument;
	RptqDocument *rptqDoc = doc.rptqDocument;
	if (rptqDoc) {
		CGSize sz = [MTPaper sizeForType:(MTPaperType)rptqDoc.papersize];
		if (fabs(sz.width - 595.0) < 10.0) {
			[_paperSizePopup selectItemAtIndex:2];
		} else if (fabs(sz.height - 1008.0) < 10.0) {
			[_paperSizePopup selectItemAtIndex:1];
		} else {
			[_paperSizePopup selectItemAtIndex:0];
		}
	}

	RptqDocumentSection *sec = _canvasView.selectedSection;
	NSArray<RptqDocumentSection *> *sections = [_canvasView orderedSections];
	if (sec) {
		NSUInteger idx = [sections indexOfObject:sec];
		if (idx != NSNotFound) {
			[_sectionsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
		}
		NSString *secTitle = doc ? [doc displayTitleForSection:sec] : ([sec localizedDisplayName] ?: @"Section");
		_selectedSectionBadgeLabel.stringValue = [NSString stringWithFormat:@"Band: %@", secTitle];
		CGFloat totalH = sec.layoutHeight > 0 ? (CGFloat)sec.layoutHeight : MAX(36.0, (CGFloat)sec.height - 44.0);
		_sectionHeightField.stringValue = [NSString stringWithFormat:@"%.0f", totalH];
		_sectionVisibleCheck.state = sec.visibility ? NSControlStateValueOn : NSControlStateValueOff;
		_sectionPageBreakCheck.state = [sec producesFormFeed] ? NSControlStateValueOn : NSControlStateValueOff;
	}

	NSOrderedSet<RptqDocumentElement *> *selectedSet = _canvasView.selectedElements;
	RptqDocumentElement *el = _canvasView.primarySelectedElement;
	BOOL hasEl = (el != nil);
	_noElementSelectedHintLabel.hidden = hasEl;
	_elementInspectorCardsStack.hidden = !hasEl;

	if (el) {
		BOOL isLabel = [el isKindOfClass:[RptqDocumentElementLabel class]];
		BOOL isData = [el isKindOfClass:[RptqDocumentElementLabelDataField class]];
		BOOL isAgg = [el isKindOfClass:[RptqDocumentElementAggregate class]];
		BOOL isBarcode = [el isKindOfClass:[RptqDocumentElementBarcode class]];
		BOOL isImg = [el isKindOfClass:[RptqDocumentElementImage class]];

		NSString *kindName = @"Element";
		if (isLabel) kindName = @"Static Label";
		else if (isData) kindName = @"Data Field";
		else if (isAgg) kindName = @"Summary Aggregate";
		else if (isBarcode) kindName = @"Barcode";
		else if (isImg) kindName = @"Image";
		if (selectedSet.count > 1) {
			_elementTypeBadgeLabel.stringValue = [NSString stringWithFormat:@"%lu Elements Selected (%@)", (unsigned long)selectedSet.count, kindName];
		} else {
			_elementTypeBadgeLabel.stringValue = kindName;
		}

		RptqDocumentSection *ownerSec = [_canvasView sectionContainingElement:el];
		if (ownerSec) {
			NSUInteger secIdx = [sections indexOfObject:ownerSec];
			if (secIdx != NSNotFound && secIdx < (NSUInteger)_elementSectionPopup.numberOfItems) {
				[_elementSectionPopup selectItemAtIndex:(NSInteger)secIdx];
			}
		}

		_staticTextRow.hidden = !(isLabel || isBarcode);
		_queryFieldRow.hidden = !(isData || isAgg || isBarcode);
		_aggregateFunctionRow.hidden = !isAgg;
		_aggregateScopeRow.hidden = !isAgg;
		_numericFormatRow.hidden = !(isData || isAgg);
		_barcodeSymbologyRow.hidden = !isBarcode;
		_barcodeOptionsRow.hidden = !isBarcode;
		_imagePickerRow.hidden = !isImg;

		if (isLabel) {
			_elementTextField.stringValue = ((RptqDocumentElementLabel *)el).text ?: @"";
		} else if (isBarcode) {
			RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)el;
			_elementTextField.stringValue = bc.inputStatic1 ?: @"";
			NSInteger symIdx = [_barcodeSymbologyPopup indexOfItemWithTag:bc.barcodeType];
			if (symIdx >= 0) [_barcodeSymbologyPopup selectItemAtIndex:symIdx];
			_barcodeHumanReadableCheck.state = bc.humanReadable ? NSControlStateValueOn : NSControlStateValueOff;
			NSInteger borderIdx = MIN(2, MAX(0, bc.barcodeBorderStyle));
			[_barcodeBorderPopup selectItemAtIndex:borderIdx];
			NSInteger qfTag = bc.referencesField1 ? (NSInteger)bc.referencesField1.identifier : 0;
			NSInteger qfIdx = [_queryFieldPopup indexOfItemWithTag:qfTag];
			if (qfIdx >= 0) [_queryFieldPopup selectItemAtIndex:qfIdx];
			else [_queryFieldPopup selectItemAtIndex:0];
		}

		if (isData || isAgg) {
			RptqQueryField *bound = isData
				? ((RptqDocumentElementLabelDataField *)el).referencesQueryField
				: ((RptqDocumentElementAggregate *)el).aggregateField;
			NSInteger tag = bound ? (NSInteger)bound.identifier : 0;
			NSInteger idx = [_queryFieldPopup indexOfItemWithTag:tag];
			if (idx >= 0) [_queryFieldPopup selectItemAtIndex:idx];
			else [_queryFieldPopup selectItemAtIndex:0];

			_numericFormatCheck.state = (el.numericFormat && el.numericFormat.enabled) ? NSControlStateValueOn : NSControlStateValueOff;
			_decimalsField.stringValue = [NSString stringWithFormat:@"%lld", el.numericFormat ? MAX((int64_t)0, el.numericFormat.decimalCount) : (int64_t)2];
		}

		if (isAgg) {
			RptqDocumentElementAggregate *agg = (RptqDocumentElementAggregate *)el;
			NSInteger fnIdx = 0;
			switch (agg.functionType) {
				case MTAggregateFunctionTypeSum:   fnIdx = 0; break;
				case MTAggregateFunctionTypeMean:  fnIdx = 1; break;
				case MTAggregateFunctionTypeCount: fnIdx = 2; break;
				case MTAggregateFunctionTypeFirst: fnIdx = 3; break;
				case MTAggregateFunctionTypeLast:  fnIdx = 4; break;
				case MTAggregateFunctionTypeMin:   fnIdx = 5; break;
				case MTAggregateFunctionTypeMax:   fnIdx = 6; break;
				default: fnIdx = 0; break;
			}
			[_aggregateTypePopup selectItemAtIndex:fnIdx];

			NSInteger scopeTag = 0;
			if (agg.groupType == MTAggregateGroupByTypePage) {
				scopeTag = -1;
			} else if (agg.groupType == MTAggregateGroupByTypeSection) {
				scopeTag = MAX(1, agg.groupNumber);
			}
			NSInteger scopeIdx = [_aggregateScopePopup indexOfItemWithTag:scopeTag];
			if (scopeIdx >= 0) [_aggregateScopePopup selectItemAtIndex:scopeIdx];
			else [_aggregateScopePopup selectItemAtIndex:0];
		}

		NSString *fname = el.fontname.length > 0 ? el.fontname : @"Helvetica";
		if ([_fontFamilyPopup indexOfItemWithTitle:fname] < 0) {
			[_fontFamilyPopup addItemWithTitle:fname];
		}
		[_fontFamilyPopup selectItemWithTitle:fname];
		_fontSizeField.stringValue = [NSString stringWithFormat:@"%.0f", el.fontsize > 0 ? el.fontsize : 12.0];
		_boldCheck.state = el.textStyle.bold ? NSControlStateValueOn : NSControlStateValueOff;
		_italicCheck.state = el.textStyle.italic ? NSControlStateValueOn : NSControlStateValueOff;
		_underlineCheck.state = el.textStyle.underline ? NSControlStateValueOn : NSControlStateValueOff;
		_strikethroughCheck.state = el.textStyle.strikethrough ? NSControlStateValueOn : NSControlStateValueOff;

		NSInteger hSeg = 0;
		if (el.alignment.horizontal == MADHorizontalAlignmentCenter) hSeg = 1;
		else if (el.alignment.horizontal == MADHorizontalAlignmentRight) hSeg = 2;
		_hAlignControl.selectedSegment = hSeg;

		NSInteger vSeg = 1;
		if (el.alignment.vertical == MADVerticalAlignmentTop) vSeg = 0;
		else if (el.alignment.vertical == MADVerticalAlignmentBottom) vSeg = 2;
		_vAlignControl.selectedSegment = vSeg;

		NSColor *fg = [el.foregroundColor isKindOfClass:[NSColor class]] ? (NSColor *)el.foregroundColor : [NSColor blackColor];
		_fgColorWell.color = fg;

		NSColor *bg = [el.backgroundColor isKindOfClass:[NSColor class]] ? (NSColor *)el.backgroundColor : nil;
		BOOL hasBg = (bg != nil && bg.alphaComponent > 0.01);
		_hasBgColorCheck.state = hasBg ? NSControlStateValueOn : NSControlStateValueOff;
		_bgColorWell.color = hasBg ? bg : [NSColor whiteColor];

		// Authoritative Geometry from elementRectInSectionContent: (reads el.rect.origin & el.rect.size)
		NSRect elRect = [_canvasView elementRectInSectionContent:el];
		_posXField.stringValue = [NSString stringWithFormat:@"%.0f", elRect.origin.x];
		_posYField.stringValue = [NSString stringWithFormat:@"%.0f", elRect.origin.y];
		_widthField.stringValue = [NSString stringWithFormat:@"%.0f", elRect.size.width];
		_heightField.stringValue = [NSString stringWithFormat:@"%.0f", elRect.size.height];

		RptqDirectionalAsymmetry *bw = el.border ? el.border.width : nil;
		_borderTopField.stringValue = [NSString stringWithFormat:@"%.1f", bw ? bw.top : 0.0];
		_borderBottomField.stringValue = [NSString stringWithFormat:@"%.1f", bw ? bw.bottom : 0.0];
		_borderLeftField.stringValue = [NSString stringWithFormat:@"%.1f", bw ? bw.left : 0.0];
		_borderRightField.stringValue = [NSString stringWithFormat:@"%.1f", bw ? bw.right : 0.0];
		_paddingAllField.stringValue = [NSString stringWithFormat:@"%.0f", el.padding ? el.padding.left : 2.0];
		_marginAllField.stringValue = [NSString stringWithFormat:@"%.0f", el.margin ? el.margin.left : 0.0];
	}

	_isUpdatingInspector = NO;
}
#pragma mark - Element Insertion, Movement, Duplication & Deletion

- (RptqDocumentSection *)ensureSelectedSection {
	MADMacDocument *doc = self.madDocument;
	RptqDocumentSection *sec = _canvasView.selectedSection;
	if (!sec) {
		sec = doc.rptqDocument.hasDetailSection ?: [_canvasView orderedSections].firstObject;
		_canvasView.selectedSection = sec;
	}
	if (sec && sec.hasRows.count == 0) {
		RptqStoreContext *ctx = doc.managedObjectContext;
		RptqDocumentSectionRows *row = (RptqDocumentSectionRows *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentSectionRows class]) identifier:0];
		row.rowNumber = 0;
		row.layoutHeight = MAX(40.0, sec.layoutHeight);
		row.inSection = sec;
		[sec addHasRowsFixed:row];
	}
	if (sec && !sec.visibility) {
		sec.visibility = YES;
	}
	return sec;
}

- (void)attachElement:(RptqDocumentElement *)element
			toSection:(RptqDocumentSection *)section
			  atPoint:(NSPoint)origin
			  withSize:(NSSize)size {
	MADMacDocument *doc = self.madDocument;
	RptqStoreContext *ctx = doc.managedObjectContext;
	[element setSizeWidth:(float)size.width height:(float)size.height];
	[section addDocumentObject:element withDropPoint:CGPointMake(origin.x, origin.y) managedObjectContext:ctx];
	[_canvasView setElement:element originInSectionContent:origin];

	RptqDocumentSectionRows *firstRow = section.hasRows.firstObject;
	if (firstRow) {
		element.inSectionRow = firstRow;
		if (origin.y + size.height + 6.0 > section.layoutHeight) {
			[section setInterfaceHeight:ceil(origin.y + size.height + 8.0)];
		}
	}

	[self registerUndoForInsertedElement:element inSection:section];
	[doc notifyDocumentMutated];
	_canvasView.selectedSection = section;
	[_canvasView selectElement:element extendSelection:NO];
	[_canvasView recalculateCanvasSize];
	[_canvasView setNeedsDisplay:YES];
	[_minimapView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
	[self syncInspectorFromSelection];
}

- (RptqDocumentElementLabel *)addStaticLabelInSection:(RptqDocumentSection *)section
											  atPoint:(NSPoint)origin {
	MADMacDocument *doc = self.madDocument;
	RptqDocumentSection *targetSec = section ?: [self ensureSelectedSection];
	if (!targetSec || !doc) return nil;
	if (targetSec.hasRows.count == 0) {
		_canvasView.selectedSection = targetSec;
		[self ensureSelectedSection];
	}
	RptqStoreContext *ctx = doc.managedObjectContext;
	RptqDocumentElementLabel *lbl = (RptqDocumentElementLabel *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabel class]) identifier:0];
	lbl.type = MADPrintPageElementTypeLabelStatic;
	lbl.text = @"Static Label";
	[self attachElement:lbl toSection:targetSec atPoint:origin withSize:NSMakeSize(124.0, 22.0)];
	return lbl;
}

- (RptqDocumentElementLabelDataField *)addDataField:(RptqQueryField *)queryField
										  inSection:(RptqDocumentSection *)section
											atPoint:(NSPoint)origin {
	MADMacDocument *doc = self.madDocument;
	RptqDocumentSection *targetSec = section ?: [self ensureSelectedSection];
	if (!targetSec || !doc) return nil;
	if (targetSec.hasRows.count == 0) {
		_canvasView.selectedSection = targetSec;
		[self ensureSelectedSection];
	}
	RptqStoreContext *ctx = doc.managedObjectContext;
	RptqDocumentElementLabelDataField *dl = (RptqDocumentElementLabelDataField *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier:0];
	dl.type = MADPrintPageElementTypeLabelDynamic;
	RptqQueryField *bound = queryField ?: [self allQueryFields].firstObject;
	if (bound) {
		dl.referencesQueryField = bound;
		dl.fieldID = bound.databaseSchemaField.name;
		dl.tableID = bound.inQueryTable.alias ?: bound.inQueryTable.databaseSchemaTable.name;
		dl.text = [NSString stringWithFormat:@"[%@.%@]", dl.tableID ?: @"", dl.fieldID ?: @""];
	} else {
		dl.text = @"[Data Field]";
	}
	[self attachElement:dl toSection:targetSec atPoint:origin withSize:NSMakeSize(140.0, 22.0)];
	return dl;
}

- (RptqDocumentElementAggregate *)addAggregateWithFunction:(int16_t)aggregateType
												queryField:(RptqQueryField *)queryField
												 inSection:(RptqDocumentSection *)section
												   atPoint:(NSPoint)origin {
	MADMacDocument *doc = self.madDocument;
	RptqDocumentSection *targetSec = section ?: [self ensureSelectedSection];
	if (!targetSec || !doc) return nil;
	if (targetSec.hasRows.count == 0) {
		_canvasView.selectedSection = targetSec;
		[self ensureSelectedSection];
	}
	RptqStoreContext *ctx = doc.managedObjectContext;
	RptqDocumentElementAggregate *agg = (RptqDocumentElementAggregate *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementAggregate class]) identifier:0];
	agg.type = MADPrintPageElementTypeAggregate;
	RptqQueryField *bound = queryField ?: [self allQueryFields].firstObject;
	MADDocumentSectionType sType = (MADDocumentSectionType)targetSec.type;
	MTAggregateGroupByType gType = MTAggregateGroupByTypeReport;
	int32_t gNum = 0;
	if (sType == MADDocumentSectionTypeGroupHeader || sType == MADDocumentSectionTypeGroupFooter) {
		gType = MTAggregateGroupByTypeSection;
		gNum = 1;
	} else if (sType == MADDocumentSectionTypePageHeader || sType == MADDocumentSectionTypePageFooter) {
		gType = MTAggregateGroupByTypePage;
	}
	agg.functionType = (MTAggregateFunctionType)aggregateType;
	agg.groupType = gType;
	agg.groupNumber = gNum;
	agg.aggregateField = bound;
	agg.aggregateFunction = nil;
	[self attachElement:agg toSection:targetSec atPoint:origin withSize:NSMakeSize(144.0, 22.0)];
	return agg;
}

- (RptqDocumentElementBarcode *)addBarcodeInSection:(RptqDocumentSection *)section
											atPoint:(NSPoint)origin {
	MADMacDocument *doc = self.madDocument;
	RptqDocumentSection *targetSec = section ?: [self ensureSelectedSection];
	if (!targetSec || !doc) return nil;
	if (targetSec.hasRows.count == 0) {
		_canvasView.selectedSection = targetSec;
		[self ensureSelectedSection];
	}
	RptqStoreContext *ctx = doc.managedObjectContext;
	RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementBarcode class]) identifier:0];
	bc.type = MADPrintPageElementTypeBarcode;
	bc.barcodeType = (int16_t)MADBarcodeTypeCODE128;
	bc.humanReadable = YES;
	bc.useStaticInput1 = YES;
	bc.inputStatic1 = @"MAD-2026";
	bc.scale = 1.0f;
	bc.barcodeHeight = 40;
	[self attachElement:bc toSection:targetSec atPoint:origin withSize:NSMakeSize(160.0, 48.0)];
	return bc;
}

- (RptqDocumentElementImage *)addImageInSection:(RptqDocumentSection *)section
										atPoint:(NSPoint)origin {
	MADMacDocument *doc = self.madDocument;
	RptqDocumentSection *targetSec = section ?: [self ensureSelectedSection];
	if (!targetSec || !doc) return nil;
	if (targetSec.hasRows.count == 0) {
		_canvasView.selectedSection = targetSec;
		[self ensureSelectedSection];
	}
	RptqStoreContext *ctx = doc.managedObjectContext;
	RptqDocumentElementImage *img = (RptqDocumentElementImage *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementImage class]) identifier:0];
	img.type = MADPrintPageElementTypeImage;
	[self attachElement:img toSection:targetSec atPoint:origin withSize:NSMakeSize(96.0, 64.0)];
	return img;
}

- (RptqDocumentElementLabel *)addLineRuleInSection:(RptqDocumentSection *)section
										   atPoint:(NSPoint)origin {
	MADMacDocument *doc = self.madDocument;
	RptqDocumentSection *targetSec = section ?: [self ensureSelectedSection];
	if (!targetSec || !doc) return nil;
	if (targetSec.hasRows.count == 0) {
		_canvasView.selectedSection = targetSec;
		[self ensureSelectedSection];
	}
	RptqStoreContext *ctx = doc.managedObjectContext;
	RptqDocumentElementLabel *line = (RptqDocumentElementLabel *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabel class]) identifier:0];
	line.type = MADPrintPageElementTypeLabelStatic;
	line.text = @"";
	if (line.border && line.border.width) {
		line.border.width.bottom = 1.5f;
	}
	[self attachElement:line toSection:targetSec atPoint:origin withSize:NSMakeSize(320.0, 8.0)];
	return line;
}

- (void)addStaticLabelAction:(__unused id)sender {
	RptqDocumentSection *sec = [self ensureSelectedSection];
	if (!sec) return;
	NSPoint pt = [_canvasView nextAvailableOriginInSection:sec forElementSize:NSMakeSize(124.0, 22.0)];
	[self addStaticLabelInSection:sec atPoint:pt];
}

- (void)addDataFieldAction:(__unused id)sender {
	RptqDocumentSection *sec = [self ensureSelectedSection];
	if (!sec) return;
	NSInteger selFieldRow = _queryFieldsTableView.selectedRow;
	RptqQueryField *qf = (selFieldRow >= 0 && (NSUInteger)selFieldRow < _filteredQueryFields.count)
		? _filteredQueryFields[(NSUInteger)selFieldRow]
		: [self allQueryFields].firstObject;
	NSPoint pt = [_canvasView nextAvailableOriginInSection:sec forElementSize:NSMakeSize(140.0, 22.0)];
	[self addDataField:qf inSection:sec atPoint:pt];
}

- (void)addAggregateAction:(__unused id)sender {
	RptqDocumentSection *sec = [self ensureSelectedSection];
	if (!sec) return;
	NSInteger selFieldRow = _queryFieldsTableView.selectedRow;
	RptqQueryField *qf = (selFieldRow >= 0 && (NSUInteger)selFieldRow < _filteredQueryFields.count)
		? _filteredQueryFields[(NSUInteger)selFieldRow]
		: [self allQueryFields].firstObject;
	NSPoint pt = [_canvasView nextAvailableOriginInSection:sec forElementSize:NSMakeSize(144.0, 22.0)];
	[self addAggregateWithFunction:MTAggregateFunctionTypeSum queryField:qf inSection:sec atPoint:pt];
}

- (void)addBarcodeAction:(__unused id)sender {
	RptqDocumentSection *sec = [self ensureSelectedSection];
	if (!sec) return;
	NSPoint pt = [_canvasView nextAvailableOriginInSection:sec forElementSize:NSMakeSize(160.0, 48.0)];
	[self addBarcodeInSection:sec atPoint:pt];
}

- (void)addImageAction:(__unused id)sender {
	RptqDocumentSection *sec = [self ensureSelectedSection];
	if (!sec) return;
	NSPoint pt = [_canvasView nextAvailableOriginInSection:sec forElementSize:NSMakeSize(96.0, 64.0)];
	[self addImageInSection:sec atPoint:pt];
}

- (void)addLineRuleAction:(__unused id)sender {
	RptqDocumentSection *sec = [self ensureSelectedSection];
	if (!sec) return;
	NSPoint pt = [_canvasView nextAvailableOriginInSection:sec forElementSize:NSMakeSize(320.0, 8.0)];
	[self addLineRuleInSection:sec atPoint:pt];
}

- (BOOL)moveSelectedElementsToSection:(RptqDocumentSection *)targetSection {
	if (!targetSection) return NO;
	NSArray<RptqDocumentElement *> *selected = [_canvasView.selectedElements.array copy];
	if (selected.count == 0) return NO;

	NSMutableArray<NSDictionary<NSString *, id> *> *moves = [NSMutableArray array];
	for (RptqDocumentElement *el in selected) {
		RptqDocumentSection *oldSec = [_canvasView sectionContainingElement:el];
		if (!oldSec || [oldSec isEqual:targetSection]) continue;
		NSRect oldRect = [_canvasView elementRectInSectionContent:el];
		[_canvasView moveElement:el toSection:targetSection atOrigin:oldRect.origin];
		NSRect newRect = [_canvasView elementRectInSectionContent:el];
		[moves addObject:@{
			@"element": el,
			@"oldSection": oldSec,
			@"newSection": targetSection,
			@"oldOrigin": [NSValue valueWithPoint:oldRect.origin],
			@"newOrigin": [NSValue valueWithPoint:newRect.origin]
		}];
	}
	if (moves.count == 0) return NO;
	_canvasView.selectedSection = targetSection;
	[self designerCanvas:_canvasView didMoveElements:moves];
	return YES;
}

- (void)elementSectionAssignmentChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	NSInteger idx = _elementSectionPopup.indexOfSelectedItem;
	NSArray<RptqDocumentSection *> *sections = [_canvasView orderedSections];
	if (idx < 0 || (NSUInteger)idx >= sections.count) return;
	RptqDocumentSection *targetSec = sections[(NSUInteger)idx];
	[self moveSelectedElementsToSection:targetSec];
}

- (void)duplicateSelectedElementsAction:(__unused id)sender {
	NSArray<RptqDocumentElement *> *selected = [_canvasView.selectedElements.array copy];
	if (selected.count == 0) return;

	NSMutableOrderedSet<RptqDocumentElement *> *newSelection = [NSMutableOrderedSet orderedSet];
	for (RptqDocumentElement *src in selected) {
		RptqDocumentSection *sec = [_canvasView sectionContainingElement:src] ?: [self ensureSelectedSection];
		if (!sec) continue;
		NSRect srcRect = [_canvasView elementRectInSectionContent:src];
		NSPoint dupOrigin = NSMakePoint(srcRect.origin.x + 16.0, srcRect.origin.y + 12.0);
		RptqDocumentElement *dup = nil;
		if ([src isKindOfClass:[RptqDocumentElementLabel class]]) {
			RptqDocumentElementLabel *lbl = [self addStaticLabelInSection:sec atPoint:dupOrigin];
			lbl.text = [((RptqDocumentElementLabel *)src).text copy];
			dup = lbl;
		} else if ([src isKindOfClass:[RptqDocumentElementLabelDataField class]]) {
			dup = [self addDataField:((RptqDocumentElementLabelDataField *)src).referencesQueryField inSection:sec atPoint:dupOrigin];
		} else if ([src isKindOfClass:[RptqDocumentElementAggregate class]]) {
			RptqDocumentElementAggregate *srcAgg = (RptqDocumentElementAggregate *)src;
			RptqDocumentElementAggregate *agg = [self addAggregateWithFunction:(int16_t)srcAgg.functionType queryField:srcAgg.aggregateField inSection:sec atPoint:dupOrigin];
			agg.groupType = srcAgg.groupType;
			agg.groupNumber = srcAgg.groupNumber;
			dup = agg;
		} else if ([src isKindOfClass:[RptqDocumentElementBarcode class]]) {
			RptqDocumentElementBarcode *srcBc = (RptqDocumentElementBarcode *)src;
			RptqDocumentElementBarcode *bc = [self addBarcodeInSection:sec atPoint:dupOrigin];
			bc.barcodeType = srcBc.barcodeType;
			bc.inputStatic1 = [srcBc.inputStatic1 copy];
			bc.useStaticInput1 = srcBc.useStaticInput1;
			bc.referencesField1 = srcBc.referencesField1;
			dup = bc;
		} else if ([src isKindOfClass:[RptqDocumentElementImage class]]) {
			RptqDocumentElementImage *img = [self addImageInSection:sec atPoint:dupOrigin];
			img.image = ((RptqDocumentElementImage *)src).image;
			dup = img;
		}
		if (dup) {
			[dup setSizeWidth:(float)srcRect.size.width height:(float)srcRect.size.height];
			dup.fontname = [src.fontname copy];
			dup.fontsize = src.fontsize;
			dup.foregroundColor = src.foregroundColor;
			dup.backgroundColor = src.backgroundColor;
			[newSelection addObject:dup];
		}
	}
	if (newSelection.count > 0) {
		[_canvasView setSelectedElementsSet:newSelection];
	}
}

- (void)deleteSelectedElementsAction:(__unused id)sender {
	MADMacDocument *doc = self.madDocument;
	NSArray<RptqDocumentElement *> *selected = [_canvasView.selectedElements.array copy];
	if (selected.count == 0) return;

	for (RptqDocumentElement *el in selected) {
		RptqDocumentSection *sec = [_canvasView sectionContainingElement:el];
		NSRect elRect = [_canvasView elementRectInSectionContent:el];
		for (RptqDocumentSection *s in [_canvasView orderedSections]) {
			for (RptqDocumentSectionRows *row in s.hasRows) {
				if ([row.hasObjects containsObject:el]) {
					[row removeHasObjectsObject:el];
				}
			}
		}
		el.inSectionRow = nil;
		if (sec) {
			[self registerUndoForRemovedElement:el fromSection:sec atOrigin:elRect.origin];
		}
	}

	[_canvasView clearElementSelection];
	[doc notifyDocumentMutated];
	[_canvasView recalculateCanvasSize];
	[_canvasView setNeedsDisplay:YES];
	[_minimapView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
	[self syncInspectorFromSelection];
}

- (void)sizeSelectedElementsToFitAction:(__unused id)sender {
	NSOrderedSet<RptqDocumentElement *> *selected = _canvasView.selectedElements;
	if (selected.count == 0) return;
	NSMutableArray<NSDictionary<NSString *, id> *> *changes = [NSMutableArray array];
	for (RptqDocumentElement *el in selected) {
		NSRect oldRect = [_canvasView elementRectInSectionContent:el];
		CGFloat fSize = el.fontsize > 4.0 ? (CGFloat)el.fontsize : 12.0;
		NSFont *font = (el.fontname.length > 0 ? [NSFont fontWithName:el.fontname size:fSize] : nil) ?: [NSFont systemFontOfSize:fSize];
		NSString *txt = [el designerRepresentationText];
		if (txt.length == 0) {
			if ([el isKindOfClass:[RptqDocumentElementLabel class]]) {
				txt = ((RptqDocumentElementLabel *)el).text ?: @"Label";
			} else {
				txt = @"Sample";
			}
		}
		NSSize measured = [txt sizeWithAttributes:@{ NSFontAttributeName: font }];
		CGFloat padW = el.padding ? (el.padding.left + el.padding.right + 12.0) : 16.0;
		CGFloat padH = el.padding ? (el.padding.top + el.padding.bottom + 6.0) : 8.0;
		NSSize newSize = NSMakeSize(MAX(36.0, ceil(measured.width + padW)), MAX(18.0, ceil(measured.height + padH)));
		[el setSizeWidth:(float)newSize.width height:(float)newSize.height];
		[changes addObject:@{
			@"element": el,
			@"oldOrigin": [NSValue valueWithPoint:oldRect.origin],
			@"oldSize": [NSValue valueWithSize:oldRect.size],
			@"newOrigin": [NSValue valueWithPoint:oldRect.origin],
			@"newSize": [NSValue valueWithSize:newSize]
		}];
	}
	[self designerCanvas:_canvasView didCommitElementGeometry:changes];
}

- (void)autoFitSelectedSectionHeightAction:(__unused id)sender {
	MADMacDocument *doc = self.madDocument;
	RptqDocumentSection *sec = _canvasView.selectedSection;
	if (!sec) return;
	CGFloat maxBottom = 28.0;
	for (RptqDocumentElement *el in [_canvasView elementsInSection:sec]) {
		NSRect r = [_canvasView elementRectInSectionContent:el];
		if (NSMaxY(r) + 8.0 > maxBottom) {
			maxBottom = ceil(NSMaxY(r) + 8.0);
		}
	}
	[sec setInterfaceHeight:maxBottom];
	[doc notifyDocumentMutated];
	[_canvasView recalculateCanvasSize];
	[_canvasView setNeedsDisplay:YES];
	[_minimapView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
	[self syncInspectorFromSelection];
}

- (void)quickAlignToolbarAction:(NSSegmentedControl *)sender {
	NSArray<RptqDocumentElement *> *selected = _canvasView.selectedElements.array;
	if (selected.count < 2) return;
	NSInteger seg = sender.selectedSegment;
	NSRect refRect = [_canvasView elementRectInSectionContent:selected.firstObject];

	NSMutableArray<NSDictionary<NSString *, id> *> *changes = [NSMutableArray array];
	for (NSUInteger i = 1; i < selected.count; i++) {
		RptqDocumentElement *el = selected[i];
		NSRect oldRect = [_canvasView elementRectInSectionContent:el];
		NSPoint newOrig = oldRect.origin;
		switch (seg) {
			case 0: newOrig.x = NSMinX(refRect); break;
			case 1: newOrig.x = NSMidX(refRect) - oldRect.size.width * 0.5; break;
			case 2: newOrig.x = NSMaxX(refRect) - oldRect.size.width; break;
			case 3: newOrig.y = NSMinY(refRect); break;
			case 4: newOrig.y = NSMidY(refRect) - oldRect.size.height * 0.5; break;
			case 5: newOrig.y = NSMaxY(refRect) - oldRect.size.height; break;
			default: break;
		}
		newOrig.x = MAX(0.0, newOrig.x);
		newOrig.y = MAX(0.0, newOrig.y);
		[_canvasView setElement:el originInSectionContent:newOrig];
		[changes addObject:@{
			@"element": el,
			@"oldOrigin": [NSValue valueWithPoint:oldRect.origin],
			@"oldSize": [NSValue valueWithSize:oldRect.size],
			@"newOrigin": [NSValue valueWithPoint:newOrig],
			@"newSize": [NSValue valueWithSize:oldRect.size]
		}];
	}
	if (changes.count > 0) {
		[self designerCanvas:_canvasView didCommitElementGeometry:changes];
	}
}

#pragma mark - Undo Registration Helpers

- (void)registerUndoForInsertedElement:(RptqDocumentElement *)element inSection:(RptqDocumentSection *)section {
	NSUndoManager *um = self.madDocument.undoManager;
	if (!um) return;
	NSRect elRect = [_canvasView elementRectInSectionContent:element];
	[[um prepareWithInvocationTarget:self] undoInsertedElement:element inSection:section atOrigin:elRect.origin];
	if (!um.isUndoing) {
		[um setActionName:@"Insert Element"];
	}
}

- (void)registerUndoForRemovedElement:(RptqDocumentElement *)element
						  fromSection:(RptqDocumentSection *)section
							 atOrigin:(NSPoint)origin {
	NSUndoManager *um = self.madDocument.undoManager;
	if (!um) return;
	[[um prepareWithInvocationTarget:self] restoreRemovedElement:element toSection:section atOrigin:origin];
	if (!um.isUndoing) {
		[um setActionName:@"Delete Element"];
	}
}

- (void)undoInsertedElement:(RptqDocumentElement *)element
				  inSection:(RptqDocumentSection *)section
				   atOrigin:(NSPoint)origin {
	MADMacDocument *doc = self.madDocument;
	for (RptqDocumentSectionRows *row in section.hasRows) {
		if ([row.hasObjects containsObject:element]) {
			[row removeHasObjectsObject:element];
		}
	}
	element.inSectionRow = nil;
	[self registerUndoForRemovedElement:element fromSection:section atOrigin:origin];
	[_canvasView clearElementSelection];
	[doc notifyDocumentMutated];
	[_canvasView recalculateCanvasSize];
	[_canvasView setNeedsDisplay:YES];
	[_minimapView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
	[self syncInspectorFromSelection];
}

- (void)restoreRemovedElement:(RptqDocumentElement *)element
					toSection:(RptqDocumentSection *)section
					 atOrigin:(NSPoint)origin {
	MADMacDocument *doc = self.madDocument;
	[_canvasView moveElement:element toSection:section atOrigin:origin];
	[self registerUndoForInsertedElement:element inSection:section];
	[doc notifyDocumentMutated];
	[_canvasView selectElement:element extendSelection:NO];
	[_canvasView recalculateCanvasSize];
	[_canvasView setNeedsDisplay:YES];
	[_minimapView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
	[self syncInspectorFromSelection];
}

#pragma mark - Inspector Edit Actions

- (NSSet<NSNumber *> *)selectedElementIdentifierSet {
	NSMutableSet<NSNumber *> *ids = [NSMutableSet set];
	for (RptqDocumentElement *el in _canvasView.selectedElements) {
		[ids addObject:@(el.identifier)];
	}
	return ids;
}

- (void)paperSizeChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	RptqDocument *rptqDoc = doc.rptqDocument;
	if (!rptqDoc) return;
	NSInteger idx = _paperSizePopup.indexOfSelectedItem;
	if (idx == 2) {
		rptqDoc.papersize = (int16_t)MTPaperTypeA4;
	} else if (idx == 1) {
		rptqDoc.papersize = (int16_t)MTPaperTypeLegal;
	} else {
		rptqDoc.papersize = (int16_t)MTPaperTypeLetter;
	}
	[doc notifyDocumentMutated];
	[_canvasView recalculateCanvasSize];
	[_canvasView setNeedsDisplay:YES];
	[_minimapView setNeedsDisplay:YES];
}

- (void)sectionHeightFieldEdited:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	RptqDocumentSection *sec = _canvasView.selectedSection;
	if (!sec) return;
	CGFloat h = MAX(24.0, MIN(600.0, _sectionHeightField.doubleValue));
	[sec setInterfaceHeight:h];
	[doc notifyDocumentMutated];
	[_canvasView recalculateCanvasSize];
	[_canvasView setNeedsDisplay:YES];
	[_minimapView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
}

- (void)sectionVisibleChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	RptqDocumentSection *sec = _canvasView.selectedSection;
	if (!sec) return;
	sec.visibility = (_sectionVisibleCheck.state == NSControlStateValueOn);
	[doc notifyDocumentMutated];
	[_canvasView recalculateCanvasSize];
	[_canvasView setNeedsDisplay:YES];
	[_minimapView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
}

- (void)sectionPageBreakChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	RptqDocumentSection *sec = _canvasView.selectedSection;
	if (!sec) return;
	[sec setProducesFormFeed:(_sectionPageBreakCheck.state == NSControlStateValueOn)];
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
}

- (void)elementTextEdited:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	RptqDocumentElement *el = _canvasView.primarySelectedElement;
	if (!el) return;
	if ([el isKindOfClass:[RptqDocumentElementLabel class]]) {
		((RptqDocumentElementLabel *)el).text = _elementTextField.stringValue ?: @"";
	} else if ([el isKindOfClass:[RptqDocumentElementBarcode class]]) {
		RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)el;
		bc.useStaticInput1 = YES;
		bc.inputStatic1 = _elementTextField.stringValue ?: @"";
	}
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
}

- (void)queryFieldChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	RptqDocumentElement *el = _canvasView.primarySelectedElement;
	if (!el) return;
	NSInteger tag = _queryFieldPopup.selectedItem.tag;
	RptqQueryField *chosen = nil;
	for (RptqQueryField *qf in [self allQueryFields]) {
		if ((NSInteger)qf.identifier == tag) {
			chosen = qf;
			break;
		}
	}
	if ([el isKindOfClass:[RptqDocumentElementLabelDataField class]]) {
		RptqDocumentElementLabelDataField *df = (RptqDocumentElementLabelDataField *)el;
		df.referencesQueryField = chosen;
		if (chosen) {
			df.fieldID = chosen.databaseSchemaField.name;
			df.tableID = chosen.inQueryTable.alias ?: chosen.inQueryTable.databaseSchemaTable.name;
			df.text = [NSString stringWithFormat:@"[%@.%@]", df.tableID ?: @"", df.fieldID ?: @""];
		}
	} else if ([el isKindOfClass:[RptqDocumentElementAggregate class]]) {
		RptqDocumentElementAggregate *agg = (RptqDocumentElementAggregate *)el;
		agg.aggregateField = chosen;
		agg.aggregateFunction = nil;
	} else if ([el isKindOfClass:[RptqDocumentElementBarcode class]]) {
		RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)el;
		if (chosen) {
			bc.useStaticInput1 = NO;
			bc.referencesField1 = chosen;
			bc.inputField1 = chosen.databaseSchemaField.name;
		} else {
			bc.useStaticInput1 = YES;
			bc.referencesField1 = nil;
		}
	}
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
}

- (void)aggregateTypeChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	RptqDocumentElement *el = _canvasView.primarySelectedElement;
	if (![el isKindOfClass:[RptqDocumentElementAggregate class]]) return;
	RptqDocumentElementAggregate *agg = (RptqDocumentElementAggregate *)el;
	MTAggregateFunctionType fn = MTAggregateFunctionTypeSum;
	switch (_aggregateTypePopup.indexOfSelectedItem) {
		case 0: fn = MTAggregateFunctionTypeSum; break;
		case 1: fn = MTAggregateFunctionTypeMean; break;
		case 2: fn = MTAggregateFunctionTypeCount; break;
		case 3: fn = MTAggregateFunctionTypeFirst; break;
		case 4: fn = MTAggregateFunctionTypeLast; break;
		case 5: fn = MTAggregateFunctionTypeMin; break;
		case 6: fn = MTAggregateFunctionTypeMax; break;
		default: fn = MTAggregateFunctionTypeSum; break;
	}
	agg.functionType = fn;
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
}

- (void)aggregateScopeChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	RptqDocumentElement *el = _canvasView.primarySelectedElement;
	if (![el isKindOfClass:[RptqDocumentElementAggregate class]]) return;
	RptqDocumentElementAggregate *agg = (RptqDocumentElementAggregate *)el;
	NSInteger tag = _aggregateScopePopup.selectedItem.tag;
	MTAggregateGroupByType gType = MTAggregateGroupByTypeReport;
	int32_t gNum = 0;
	if (tag == -1) {
		gType = MTAggregateGroupByTypePage;
	} else if (tag > 0) {
		gType = MTAggregateGroupByTypeSection;
		gNum = (int32_t)tag;
	}
	agg.groupType = gType;
	agg.groupNumber = gNum;
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
}

- (void)numericFormatChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	BOOL enabled = (_numericFormatCheck.state == NSControlStateValueOn);
	int64_t dec = MAX((int64_t)0, MIN((int64_t)6, (int64_t)_decimalsField.integerValue));
	for (RptqDocumentElement *el in _canvasView.selectedElements) {
		if (el.numericFormat) {
			el.numericFormat.enabled = enabled;
			el.numericFormat.decimalCount = dec;
		}
	}
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
}

- (void)barcodeSymbologyChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	RptqDocumentElement *el = _canvasView.primarySelectedElement;
	if (![el isKindOfClass:[RptqDocumentElementBarcode class]]) return;
	RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)el;
	bc.barcodeType = (int16_t)_barcodeSymbologyPopup.selectedItem.tag;
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
}

- (void)barcodeOptionsChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	RptqDocumentElement *el = _canvasView.primarySelectedElement;
	if (![el isKindOfClass:[RptqDocumentElementBarcode class]]) return;
	RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)el;
	bc.humanReadable = (_barcodeHumanReadableCheck.state == NSControlStateValueOn);
	bc.barcodeBorderStyle = (int16_t)MAX(0, _barcodeBorderPopup.indexOfSelectedItem);
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
}

- (void)chooseImageFileAction:(__unused id)sender {
	MADMacDocument *doc = self.madDocument;
	RptqDocumentElement *el = _canvasView.primarySelectedElement;
	if (![el isKindOfClass:[RptqDocumentElementImage class]]) return;
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.canChooseFiles = YES;
	panel.canChooseDirectories = NO;
	panel.allowsMultipleSelection = NO;
	NSURL *chosenURL = nil;
	if ([panel runModal] == NSModalResponseOK) {
		chosenURL = panel.URL;
	}
	if (chosenURL) {
		NSImage *img = [[NSImage alloc] initWithContentsOfURL:chosenURL];
		if (img) {
			((RptqDocumentElementImage *)el).image = img;
			[doc notifyDocumentMutated];
			[_canvasView setNeedsDisplay:YES];
		}
	}
}

- (void)typographyChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	NSSet<NSNumber *> *ids = [self selectedElementIdentifierSet];
	if (ids.count == 0 || !doc) return;
	MADDesignerLayout *layout = doc.designerLayout;
	NSString *fontName = _fontFamilyPopup.selectedItem.title ?: @"Helvetica";
	double fontSize = MAX(6.0, MIN(96.0, _fontSizeField.doubleValue));
	[layout updateElements:ids setFontname:fontName];
	[layout updateElements:ids setFontsize:fontSize];
	[layout updateElements:ids setBold:(_boldCheck.state == NSControlStateValueOn)];
	[layout updateElements:ids setItalic:(_italicCheck.state == NSControlStateValueOn)];
	[layout updateElements:ids setUnderline:(_underlineCheck.state == NSControlStateValueOn)];
	[layout updateElements:ids setStrikethrough:(_strikethroughCheck.state == NSControlStateValueOn)];
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
}

- (void)alignmentChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	NSSet<NSNumber *> *ids = [self selectedElementIdentifierSet];
	if (ids.count == 0 || !doc) return;
	MADDesignerLayout *layout = doc.designerLayout;

	int16_t h = (int16_t)MADHorizontalAlignmentLeft;
	if (_hAlignControl.selectedSegment == 1) h = (int16_t)MADHorizontalAlignmentCenter;
	else if (_hAlignControl.selectedSegment == 2) h = (int16_t)MADHorizontalAlignmentRight;
	[layout updateElements:ids setHorizontalAlignment:h];

	int16_t v = (int16_t)MADVerticalAlignmentCenter;
	if (_vAlignControl.selectedSegment == 0) v = (int16_t)MADVerticalAlignmentTop;
	else if (_vAlignControl.selectedSegment == 2) v = (int16_t)MADVerticalAlignmentBottom;
	[layout updateElements:ids setVerticalAlignment:v];

	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
}

- (void)colorChanged:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	NSColor *fg = _fgColorWell.color;
	NSColor *bg = (_hasBgColorCheck.state == NSControlStateValueOn)
		? _bgColorWell.color
		: [NSColor colorWithCalibratedWhite:1.0 alpha:0.0];
	for (RptqDocumentElement *el in _canvasView.selectedElements) {
		el.foregroundColor = fg;
		el.backgroundColor = bg;
	}
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
}

- (void)elementGeometryEdited:(__unused id)sender {
	if (_isUpdatingInspector) return;
	RptqDocumentElement *el = _canvasView.primarySelectedElement;
	if (!el) return;
	NSRect oldRect = [_canvasView elementRectInSectionContent:el];
	CGFloat newX = MAX(0.0, _posXField.doubleValue);
	CGFloat newY = MAX(0.0, _posYField.doubleValue);
	CGFloat newW = MAX(20.0, _widthField.doubleValue);
	CGFloat newH = MAX(12.0, _heightField.doubleValue);

	[_canvasView setElement:el originInSectionContent:NSMakePoint(newX, newY)];
	[el setSizeWidth:(float)newW height:(float)newH];

	NSArray *changes = @[@{
		@"element": el,
		@"oldOrigin": [NSValue valueWithPoint:oldRect.origin],
		@"oldSize": [NSValue valueWithSize:oldRect.size],
		@"newOrigin": [NSValue valueWithPoint:NSMakePoint(newX, newY)],
		@"newSize": [NSValue valueWithSize:NSMakeSize(newW, newH)]
	}];
	[self designerCanvas:_canvasView didCommitElementGeometry:changes];
}

- (void)elementBoxModelEdited:(__unused id)sender {
	if (_isUpdatingInspector) return;
	MADMacDocument *doc = self.madDocument;
	NSSet<NSNumber *> *ids = [self selectedElementIdentifierSet];
	if (ids.count == 0 || !doc) return;
	MADDesignerLayout *layout = doc.designerLayout;

	float bTop = (float)MAX(0.0, MIN(12.0, _borderTopField.doubleValue));
	float bBottom = (float)MAX(0.0, MIN(12.0, _borderBottomField.doubleValue));
	float bLeft = (float)MAX(0.0, MIN(12.0, _borderLeftField.doubleValue));
	float bRight = (float)MAX(0.0, MIN(12.0, _borderRightField.doubleValue));
	float pad = (float)MAX(0.0, MIN(40.0, _paddingAllField.doubleValue));
	float mar = (float)MAX(0.0, MIN(40.0, _marginAllField.doubleValue));

	[layout updateElements:ids setBorderTop:bTop];
	[layout updateElements:ids setBorderBottom:bBottom];
	[layout updateElements:ids setBorderLeft:bLeft];
	[layout updateElements:ids setBorderRight:bRight];
	[layout updateElements:ids setPaddingTop:pad];
	[layout updateElements:ids setPaddingBottom:pad];
	[layout updateElements:ids setPaddingLeft:pad];
	[layout updateElements:ids setPaddingRight:pad];
	[layout updateElements:ids setMarginTop:mar];
	[layout updateElements:ids setMarginBottom:mar];
	[layout updateElements:ids setMarginLeft:mar];
	[layout updateElements:ids setMarginRight:mar];
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
}

#pragma mark - Toolbar View Toggles & Zoom

- (void)toggleGridAction:(__unused id)sender {
	_canvasView.showGrid = (_gridToggleBtn.state == NSControlStateValueOn);
}

- (void)toggleSnapAction:(__unused id)sender {
	_canvasView.snapToGrid = (_snapToggleBtn.state == NSControlStateValueOn);
}

- (void)toggleRulersAction:(__unused id)sender {
	_canvasView.showRulers = (_rulersToggleBtn.state == NSControlStateValueOn);
}

- (void)zoomSliderChanged:(__unused id)sender {
	CGFloat z = _zoomSlider.doubleValue;
	_canvasView.zoomScale = z;
	_zoomPercentButton.title = [NSString stringWithFormat:@"%.0f%%", z * 100.0];
	[_minimapView setNeedsDisplay:YES];
}

- (void)resetZoomAction:(__unused id)sender {
	_zoomSlider.doubleValue = 1.0;
	_canvasView.zoomScale = 1.0;
	_zoomPercentButton.title = @"100%";
	[_minimapView setNeedsDisplay:YES];
}

#pragma mark - MADMacDesignerCanvasViewDelegate

- (void)designerCanvasSelectionDidChange:(__unused MADMacDesignerCanvasView *)canvasView {
	[_minimapView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
	[self syncInspectorFromSelection];
}

- (void)designerCanvasDidMutateDocument:(__unused MADMacDesignerCanvasView *)canvasView {
	[self.madDocument notifyDocumentMutated];
	[_minimapView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
	[self syncInspectorFromSelection];
}

- (void)designerCanvas:(__unused MADMacDesignerCanvasView *)canvasView
	didCommitElementGeometry:(NSArray<NSDictionary<NSString *, id> *> *)changes {
	if (changes.count == 0) return;
	[self applyElementGeometryChanges:changes isUndoOrRedo:NO];
}

- (void)applyElementGeometryChanges:(NSArray<NSDictionary<NSString *, id> *> *)changes
					   isUndoOrRedo:(BOOL)isUndoOrRedo {
	MADMacDocument *doc = self.madDocument;
	NSMutableArray<NSDictionary<NSString *, id> *> *inverseChanges = [NSMutableArray arrayWithCapacity:changes.count];
	for (NSDictionary<NSString *, id> *entry in changes) {
		RptqDocumentElement *el = entry[@"element"];
		NSPoint oldOrig = [entry[@"oldOrigin"] pointValue];
		NSSize oldSize = [entry[@"oldSize"] sizeValue];
		NSPoint newOrig = [entry[@"newOrigin"] pointValue];
		NSSize newSize = [entry[@"newSize"] sizeValue];
		if (!el) continue;

		if (isUndoOrRedo) {
			[_canvasView setElement:el originInSectionContent:newOrig];
			[el setSizeWidth:(float)newSize.width height:(float)newSize.height];
		}
		[inverseChanges addObject:@{
			@"element": el,
			@"oldOrigin": [NSValue valueWithPoint:newOrig],
			@"oldSize": [NSValue valueWithSize:newSize],
			@"newOrigin": [NSValue valueWithPoint:oldOrig],
			@"newSize": [NSValue valueWithSize:oldSize]
		}];
	}

	NSUndoManager *um = doc.undoManager;
	if (um && inverseChanges.count > 0) {
		[[um prepareWithInvocationTarget:self] applyElementGeometryChanges:inverseChanges isUndoOrRedo:YES];
		if (!um.isUndoing) {
			[um setActionName:@"Move / Resize Element"];
		}
	}

	[doc notifyDocumentMutated];
	[_canvasView recalculateCanvasSize];
	[_canvasView setNeedsDisplay:YES];
	[_minimapView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
	[self syncInspectorFromSelection];
}

- (void)designerCanvas:(__unused MADMacDesignerCanvasView *)canvasView
	didMoveElements:(NSArray<NSDictionary<NSString *, id> *> *)moves {
	if (moves.count == 0) return;
	[self applyCrossSectionElementMoves:moves isUndoOrRedo:NO];
}

- (void)applyCrossSectionElementMoves:(NSArray<NSDictionary<NSString *, id> *> *)moves
						 isUndoOrRedo:(BOOL)isUndoOrRedo {
	MADMacDocument *doc = self.madDocument;
	NSMutableArray<NSDictionary<NSString *, id> *> *inverseMoves = [NSMutableArray arrayWithCapacity:moves.count];
	for (NSDictionary<NSString *, id> *entry in moves) {
		RptqDocumentElement *el = entry[@"element"];
		RptqDocumentSection *oldSec = entry[@"oldSection"];
		RptqDocumentSection *newSec = entry[@"newSection"];
		NSPoint oldOrigin = [entry[@"oldOrigin"] pointValue];
		NSPoint newOrigin = [entry[@"newOrigin"] pointValue];
		if (!el || !oldSec || !newSec) continue;

		if (isUndoOrRedo) {
			[_canvasView moveElement:el toSection:newSec atOrigin:newOrigin];
			_canvasView.selectedSection = newSec;
		}
		[inverseMoves addObject:@{
			@"element": el,
			@"oldSection": newSec,
			@"newSection": oldSec,
			@"oldOrigin": [NSValue valueWithPoint:newOrigin],
			@"newOrigin": [NSValue valueWithPoint:oldOrigin]
		}];
	}

	NSUndoManager *um = doc.undoManager;
	if (um && inverseMoves.count > 0) {
		[[um prepareWithInvocationTarget:self] applyCrossSectionElementMoves:inverseMoves isUndoOrRedo:YES];
		if (!um.isUndoing) {
			[um setActionName:@"Move Element to Section"];
		}
	}

	[doc notifyDocumentMutated];
	[_canvasView recalculateCanvasSize];
	[_canvasView setNeedsDisplay:YES];
	[_minimapView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
	[self syncInspectorFromSelection];
}

- (void)designerCanvas:(__unused MADMacDesignerCanvasView *)canvasView
	didCommitSectionResize:(RptqDocumentSection *)section
				 oldHeight:(CGFloat)oldHeight
				 newHeight:(CGFloat)newHeight {
	[self applySectionHeightResize:section oldHeight:oldHeight newHeight:newHeight isUndoOrRedo:NO];
}

- (void)applySectionHeightResize:(RptqDocumentSection *)section
					   oldHeight:(CGFloat)oldHeight
					   newHeight:(CGFloat)newHeight
					isUndoOrRedo:(BOOL)isUndoOrRedo {
	if (!section) return;
	MADMacDocument *doc = self.madDocument;
	if (isUndoOrRedo) {
		[section setInterfaceHeight:newHeight];
	}
	NSUndoManager *um = doc.undoManager;
	if (um) {
		[[um prepareWithInvocationTarget:self] applySectionHeightResize:section
															  oldHeight:newHeight
															  newHeight:oldHeight
														   isUndoOrRedo:YES];
		if (!um.isUndoing) {
			[um setActionName:@"Resize Section"];
		}
	}
	[doc notifyDocumentMutated];
	[_canvasView recalculateCanvasSize];
	[_canvasView setNeedsDisplay:YES];
	[_minimapView setNeedsDisplay:YES];
	[self reloadSectionsTablePreservingSelection];
	[self syncInspectorFromSelection];
}

- (void)designerCanvas:(__unused MADMacDesignerCanvasView *)canvasView
	didDropQueryFieldWithIdentifier:(int64_t)fieldIdentifier
						  inSection:(RptqDocumentSection *)section
							atPoint:(NSPoint)dropPoint {
	RptqQueryField *matched = nil;
	for (RptqQueryField *qf in [self allQueryFields]) {
		if (qf.identifier == fieldIdentifier) {
			matched = qf;
			break;
		}
	}
	[self addDataField:matched inSection:section atPoint:dropPoint];
}

- (void)designerCanvas:(__unused MADMacDesignerCanvasView *)canvasView
	didDropElementKind:(NSInteger)elementKind
			 inSection:(RptqDocumentSection *)section
			   atPoint:(NSPoint)dropPoint {
	switch ((MADMacPaletteElementKind)elementKind) {
		case MADMacPaletteElementKindLabel:
			[self addStaticLabelInSection:section atPoint:dropPoint];
			break;
		case MADMacPaletteElementKindDataField:
			[self addDataField:nil inSection:section atPoint:dropPoint];
			break;
		case MADMacPaletteElementKindAggregate:
			[self addAggregateWithFunction:MTAggregateFunctionTypeSum queryField:nil inSection:section atPoint:dropPoint];
			break;
		case MADMacPaletteElementKindBarcode:
			[self addBarcodeInSection:section atPoint:dropPoint];
			break;
		case MADMacPaletteElementKindImage:
			[self addImageInSection:section atPoint:dropPoint];
			break;
		case MADMacPaletteElementKindLineRule:
			[self addLineRuleInSection:section atPoint:dropPoint];
			break;
	}
}

- (void)designerCanvas:(__unused MADMacDesignerCanvasView *)canvasView
	didInlineEditLabel:(RptqDocumentElementLabel *)label
			   oldText:(NSString *)oldText
			   newText:(NSString *)newText {
	[self applyInlineLabelEdit:label oldText:oldText newText:newText isUndoOrRedo:NO];
}

- (void)applyInlineLabelEdit:(RptqDocumentElementLabel *)label
					 oldText:(NSString *)oldText
					 newText:(NSString *)newText
				isUndoOrRedo:(BOOL)isUndoOrRedo {
	if (!label) return;
	MADMacDocument *doc = self.madDocument;
	if (isUndoOrRedo) {
		label.text = newText;
	}
	NSUndoManager *um = doc.undoManager;
	if (um) {
		[[um prepareWithInvocationTarget:self] applyInlineLabelEdit:label
															oldText:newText
															newText:oldText
													   isUndoOrRedo:YES];
		if (!um.isUndoing) {
			[um setActionName:@"Edit Label Text"];
		}
	}
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
	[self syncInspectorFromSelection];
}

- (void)designerCanvas:(__unused MADMacDesignerCanvasView *)canvasView
	requestContextMenuForElement:(RptqDocumentElement *)element
					   inSection:(RptqDocumentSection *)section
					   withEvent:(NSEvent *)event {
	MADMacDocument *doc = self.madDocument;
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Designer Context Menu"];
	if (element) {
		[menu addItemWithTitle:@"Duplicate" action:@selector(duplicateSelectedElementsAction:) keyEquivalent:@""];
		[menu addItemWithTitle:@"Size to Fit Content" action:@selector(sizeSelectedElementsToFitAction:) keyEquivalent:@""];

		NSMenuItem *moveItem = [[NSMenuItem alloc] initWithTitle:@"Move to Band" action:nil keyEquivalent:@""];
		NSMenu *moveSubmenu = [[NSMenu alloc] initWithTitle:@"Move to Band"];
		NSArray<RptqDocumentSection *> *sections = [_canvasView orderedSections];
		RptqDocumentSection *curSec = [_canvasView sectionContainingElement:element];
		for (NSUInteger i = 0; i < sections.count; i++) {
			RptqDocumentSection *sec = sections[i];
			NSString *secTitle = doc ? [doc displayTitleForSection:sec] : ([sec localizedDisplayName] ?: @"Section");
			NSMenuItem *secItem = [[NSMenuItem alloc] initWithTitle:secTitle
															 action:@selector(contextMenuMoveToSectionAction:)
													  keyEquivalent:@""];
			secItem.target = self;
			secItem.tag = (NSInteger)i;
			secItem.state = [sec isEqual:curSec] ? NSControlStateValueOn : NSControlStateValueOff;
			[moveSubmenu addItem:secItem];
		}
		moveItem.submenu = moveSubmenu;
		[menu addItem:moveItem];

		[menu addItem:[NSMenuItem separatorItem]];
		NSMenuItem *delItem = [[NSMenuItem alloc] initWithTitle:@"Delete"
														 action:@selector(deleteSelectedElementsAction:)
												  keyEquivalent:@""];
		delItem.target = self;
		[menu addItem:delItem];
	} else if (section) {
		_canvasView.selectedSection = section;
		[menu addItemWithTitle:@"Insert Static Label" action:@selector(addStaticLabelAction:) keyEquivalent:@""];
		[menu addItemWithTitle:@"Insert Data Field" action:@selector(addDataFieldAction:) keyEquivalent:@""];
		[menu addItemWithTitle:@"Insert Aggregate" action:@selector(addAggregateAction:) keyEquivalent:@""];
		[menu addItemWithTitle:@"Insert Barcode" action:@selector(addBarcodeAction:) keyEquivalent:@""];
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItemWithTitle:@"Fit Band Height to Elements" action:@selector(autoFitSelectedSectionHeightAction:) keyEquivalent:@""];
	}
	for (NSMenuItem *item in menu.itemArray) {
		if (!item.target) item.target = self;
	}
	[NSMenu popUpContextMenu:menu withEvent:event forView:_canvasView];
}

- (void)contextMenuMoveToSectionAction:(NSMenuItem *)sender {
	NSArray<RptqDocumentSection *> *sections = [_canvasView orderedSections];
	if (sender.tag >= 0 && (NSUInteger)sender.tag < sections.count) {
		[self moveSelectedElementsToSection:sections[(NSUInteger)sender.tag]];
	}
}

- (void)designerCanvasRequestDeleteSelection:(__unused MADMacDesignerCanvasView *)canvasView {
	[self deleteSelectedElementsAction:nil];
}

- (void)designerCanvasRequestDuplicateSelection:(__unused MADMacDesignerCanvasView *)canvasView {
	[self duplicateSelectedElementsAction:nil];
}

@end
