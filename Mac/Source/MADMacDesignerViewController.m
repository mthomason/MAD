//
//  MADMacDesignerViewController.m
//  MAD Designer (macOS Native)
//

#import "MADMacDesignerViewController.h"
#import "MADMacDesignerCanvasView.h"
#import "MADMacDocument.h"
#import "MADMacTipBar.h"

#import <MAD/MAD.h>
#import <MADBarcodes/MADBarcodes.h>

static const CGFloat kDefaultLeftSidebarWidth = 220.0;
static const CGFloat kMinLeftSidebarWidth = 180.0;
static const CGFloat kMaxLeftSidebarWidth = 340.0;

static const CGFloat kDefaultRightInspectorWidth = 260.0;
static const CGFloat kMinRightInspectorWidth = 220.0;
static const CGFloat kMaxRightInspectorWidth = 380.0;

static NSMutableArray<RptqDocumentElement *> *sElementClipboard = nil;
static __weak MADMacDocument *sElementClipboardDocument = nil;

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
@property (nonatomic, strong, readwrite) NSTextField *fieldsHeaderLabel;
@property (nonatomic, strong) NSTextField *emptyLayoutHintLabel;
@property (nonatomic, strong, readwrite) NSSearchField *queryFieldsSearchField;
@property (nonatomic, strong, readwrite) NSTableView *queryFieldsTableView;
@property (nonatomic, strong) NSArray<RptqQueryField *> *filteredQueryFields;
@property (nonatomic, assign) int64_t loadedQueryIdentifier;

// Center canvas controls
@property (nonatomic, strong, readwrite) MADMacDesignerCanvasView *canvasView;
@property (nonatomic, strong) NSScrollView *canvasScrollView;
@property (nonatomic, strong) NSSlider *zoomSlider;
@property (nonatomic, strong) NSButton *zoomPercentButton;
@property (nonatomic, strong, readwrite, nullable) NSPopUpButton *insertPopUpButton;
@property (nonatomic, strong) NSPopUpButton *viewOptionsButton;
@property (nonatomic, strong) MADMacTipBar *tipBar;
@property (nonatomic, assign) BOOL leftSidebarHidden;
@property (nonatomic, assign) BOOL inspectorHidden;
@property (nonatomic, assign) BOOL minimapHidden;

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

	_tipBar = [MADMacTipBar tipBarWithIdentifier:@"designer"
											text:NSLocalizedString(@"Start here: create or pick a report band, then use Insert to add elements. Drag query fields from the left onto the page.", @"First-run tip in the designer workspace.")];
	_tipBar.translatesAutoresizingMaskIntoConstraints = NO;
	[rootView addSubview:_tipBar];

	[NSLayoutConstraint activateConstraints:@[
		[_tipBar.topAnchor constraintEqualToAnchor:_topWorkspaceBar.bottomAnchor],
		[_tipBar.leadingAnchor constraintEqualToAnchor:_centerCanvasContainerView.leadingAnchor],
		[_tipBar.trailingAnchor constraintEqualToAnchor:_centerCanvasContainerView.trailingAnchor],
		[_tipBar.heightAnchor constraintEqualToConstant:30.0],

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

- (NSMenuItem *)menuItemForElementKind:(MADMacPaletteElementKind)kind
                                  title:(NSString *)title
                                 symbol:(NSString *)symbol {
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title
												 action:@selector(insertElementFromMenu:)
										  keyEquivalent:[NSString stringWithFormat:@"%ld", (long)kind]];
	item.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagOption;
	item.toolTip = title;
	item.target = self;
	item.tag = kind;
	if (@available(macOS 11.0, *)) {
		NSImage *image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:title];
		if (image != nil) item.image = image;
	}
	return item;
}

- (NSPopUpButton *)makeInsertButton {
	NSPopUpButton *button = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:YES];
	[button addItemWithTitle:NSLocalizedString(@"Insert", @"Designer insert menu button title.")];
	button.font = [NSFont systemFontOfSize:12.0 weight:NSFontWeightMedium];
	button.toolTip = NSLocalizedString(@"Insert a label, data field, aggregate, image, barcode, or horizontal rule into the selected band.", @"Tooltip for the designer insert menu.");
	button.accessibilityLabel = NSLocalizedString(@"Insert", @"Accessibility label for the designer insert menu.");
	button.translatesAutoresizingMaskIntoConstraints = NO;
	if (@available(macOS 11.0, *)) {
		NSImage *image = [NSImage imageWithSystemSymbolName:@"plus" accessibilityDescription:NSLocalizedString(@"Insert", @"Accessibility description for the insert button icon.")];
		if (image != nil) {
			button.image = image;
			button.imagePosition = NSImageLeading;
		}
	}
	NSMenu *menu = button.menu;
	[menu addItem:[self menuItemForElementKind:MADMacPaletteElementKindLabel
										 title:NSLocalizedString(@"Static Label", @"Insert menu item that inserts a static label.")
										symbol:@"textformat"]];
	[menu addItem:[self menuItemForElementKind:MADMacPaletteElementKindDataField
										 title:NSLocalizedString(@"Data Field", @"Insert menu item that inserts a field bound to the query.")
										symbol:@"tablecells"]];
	[menu addItem:[self menuItemForElementKind:MADMacPaletteElementKindAggregate
										 title:NSLocalizedString(@"Aggregate", @"Insert menu item that inserts an aggregate.")
										symbol:@"sum"]];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItem:[self menuItemForElementKind:MADMacPaletteElementKindImage
										 title:NSLocalizedString(@"Image", @"Insert menu item that inserts an image.")
										symbol:@"photo"]];
	[menu addItem:[self menuItemForElementKind:MADMacPaletteElementKindBarcode
										 title:NSLocalizedString(@"Barcode", @"Insert menu item that inserts a barcode.")
										symbol:@"barcode"]];
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItem:[self menuItemForElementKind:MADMacPaletteElementKindLineRule
										 title:NSLocalizedString(@"Horizontal Rule", @"Insert menu item that inserts a horizontal rule.")
										symbol:@"minus"]];
	menu.autoenablesItems = YES;
	return button;
}

- (NSPopUpButton *)makeViewOptionsButton {
	NSPopUpButton *button = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:YES];
	[button addItemWithTitle:NSLocalizedString(@"View", @"Designer view-options menu button title.")];
	button.controlSize = NSControlSizeSmall;
	button.font = [NSFont systemFontOfSize:11.0];
	button.toolTip = NSLocalizedString(@"Show or hide the grid, rulers, minimap, and sidebars.", @"Tooltip for the designer view options menu.");
	button.accessibilityLabel = NSLocalizedString(@"View Options", @"Accessibility label for the designer view options menu.");
	button.translatesAutoresizingMaskIntoConstraints = NO;
	if (@available(macOS 11.0, *)) {
		NSImage *image = [NSImage imageWithSystemSymbolName:@"slider.horizontal.3" accessibilityDescription:NSLocalizedString(@"View Options", @"Accessibility description for the view options icon.")];
		if (image != nil) {
			button.image = image;
			button.imagePosition = NSImageLeading;
		}
	}
	NSMenu *menu = button.menu;
	void (^add)(NSString *, SEL) = ^(NSString *title, SEL action) {
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:@""];
		item.target = self;
		[menu addItem:item];
	};
	add(NSLocalizedString(@"Grid", @"Designer view option that shows the alignment grid."), @selector(toggleGridFromMenu:));
	add(NSLocalizedString(@"Snap to Grid", @"Designer view option that snaps elements to the grid."), @selector(toggleSnapFromMenu:));
	add(NSLocalizedString(@"Rulers", @"Designer view option that shows the rulers."), @selector(toggleRulersFromMenu:));
	[menu addItem:[NSMenuItem separatorItem]];
	add(NSLocalizedString(@"Minimap", @"Designer view option that shows the page minimap."), @selector(toggleMinimapFromMenu:));
	add(NSLocalizedString(@"Left Sidebar", @"Designer view option that shows the left sidebar."), @selector(toggleLeftSidebarFromMenu:));
	add(NSLocalizedString(@"Inspector", @"Designer view option that shows the inspector."), @selector(toggleInspectorFromMenu:));
	menu.autoenablesItems = YES;
	return button;
}

- (NSView *)buildTopWorkspaceBar {
	NSView *bar = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1220, 38)];
	bar.wantsLayer = YES;
	bar.layer.backgroundColor = [NSColor windowBackgroundColor].CGColor;

	_insertPopUpButton = [self makeInsertButton];

	_viewOptionsButton = [self makeViewOptionsButton];

	_zoomSlider = [NSSlider sliderWithValue:1.0 minValue:0.5 maxValue:2.0 target:self action:@selector(zoomSliderChanged:)];
	_zoomSlider.controlSize = NSControlSizeSmall;
	_zoomSlider.toolTip = NSLocalizedString(@"Zoom the canvas from 50 percent to 200 percent.", @"Tooltip for the designer zoom slider.");
	_zoomSlider.accessibilityLabel = NSLocalizedString(@"Canvas Zoom", @"Accessibility label for the designer zoom slider.");
	[_zoomSlider.widthAnchor constraintEqualToConstant:96.0].active = YES;

	_zoomPercentButton = [NSButton buttonWithTitle:@"100%" target:self action:@selector(resetZoomAction:)];
	_zoomPercentButton.bezelStyle = NSBezelStyleRecessed;
	_zoomPercentButton.showsBorderOnlyWhileMouseInside = YES;
	_zoomPercentButton.controlSize = NSControlSizeSmall;
	_zoomPercentButton.font = [NSFont monospacedDigitSystemFontOfSize:11.0 weight:NSFontWeightMedium];
	_zoomPercentButton.toolTip = NSLocalizedString(@"Click to reset zoom to 100%.", @"Tooltip for the zoom percentage button.");
	_zoomPercentButton.accessibilityLabel = NSLocalizedString(@"Reset Canvas Zoom", @"Accessibility label for the zoom percentage button.");

	NSStackView *leftStack = [NSStackView stackViewWithViews:@[_insertPopUpButton]];
	leftStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	leftStack.spacing = 8.0;
	leftStack.alignment = NSLayoutAttributeCenterY;
	leftStack.translatesAutoresizingMaskIntoConstraints = NO;
	[bar addSubview:leftStack];

	NSStackView *rightStack = [NSStackView stackViewWithViews:@[_viewOptionsButton, _zoomSlider, _zoomPercentButton]];
	rightStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	rightStack.spacing = 8.0;
	rightStack.alignment = NSLayoutAttributeCenterY;
	rightStack.translatesAutoresizingMaskIntoConstraints = NO;
	[bar addSubview:rightStack];

	NSTextField *hint = [NSTextField labelWithString:NSLocalizedString(@"Click Insert, or drag a query field from the left onto a band.", @"Designer toolbar hint beside the Insert button.")];
	hint.font = [NSFont systemFontOfSize:11.0];
	hint.textColor = [NSColor tertiaryLabelColor];
	hint.translatesAutoresizingMaskIntoConstraints = NO;
	[bar addSubview:hint];

	NSBox *bottomLine = [[NSBox alloc] init];
	bottomLine.boxType = NSBoxSeparator;
	bottomLine.translatesAutoresizingMaskIntoConstraints = NO;
	[bar addSubview:bottomLine];

	[NSLayoutConstraint activateConstraints:@[
		[leftStack.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor constant:12.0],
		[leftStack.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
		[hint.leadingAnchor constraintEqualToAnchor:leftStack.trailingAnchor constant:12.0],
		[hint.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
		[hint.trailingAnchor constraintLessThanOrEqualToAnchor:rightStack.leadingAnchor constant:-12.0],
		[rightStack.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor constant:-12.0],
		[rightStack.centerYAnchor constraintEqualToAnchor:bar.centerYAnchor],
		[bottomLine.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor],
		[bottomLine.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor],
		[bottomLine.bottomAnchor constraintEqualToAnchor:bar.bottomAnchor]
	]];

	return bar;
}

- (void)populateLeftSidebar:(NSView *)container {
	NSTextField *minimapHeader = [NSTextField labelWithString:NSLocalizedString(@"PAGE & SECTION MINIMAP", @"Designer sidebar heading for the page and section minimap.")];
	minimapHeader.font = [NSFont systemFontOfSize:10.0 weight:NSFontWeightBold];
	minimapHeader.textColor = [NSColor secondaryLabelColor];
	minimapHeader.translatesAutoresizingMaskIntoConstraints = NO;
	minimapHeader.tag = 0x4D4150;

	NSTextField *minimapSub = [NSTextField labelWithString:NSLocalizedString(@"Click a band to jump & select", @"Designer minimap hint.")];
	minimapSub.font = [NSFont systemFontOfSize:9.5];
	minimapSub.textColor = [NSColor tertiaryLabelColor];
	minimapSub.translatesAutoresizingMaskIntoConstraints = NO;
	minimapSub.tag = 0x4D4150;

	_minimapView = [[MADMacDesignerMinimapView alloc] initWithFrame:NSMakeRect(0, 0, 200, 128)];
	_minimapView.translatesAutoresizingMaskIntoConstraints = NO;
	_minimapView.wantsLayer = YES;
	_minimapView.layer.cornerRadius = 5.0;
	_minimapView.layer.masksToBounds = YES;

	NSTextField *sectionsHeader = [NSTextField labelWithString:NSLocalizedString(@"REPORT BANDS", @"Designer sidebar heading for the report band list.")];
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
	_sectionsTableView.toolTip = NSLocalizedString(@"Jump to a report band and select it on the canvas.", @"Tooltip for the report band list.");
	_sectionsTableView.accessibilityLabel = NSLocalizedString(@"Report Bands", @"Accessibility label for the report band list.");

	NSTableColumn *secNameCol = [[NSTableColumn alloc] initWithIdentifier:@"SectionName"];
	secNameCol.title = NSLocalizedString(@"Section", @"Report band list column header.");
	secNameCol.width = 200.0;
	secNameCol.minWidth = 120.0;
	secNameCol.resizingMask = NSTableColumnAutoresizingMask;
	[_sectionsTableView addTableColumn:secNameCol];
	_sectionsTableView.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;

	NSScrollView *sectionsScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 200, 165)];
	sectionsScroll.documentView = _sectionsTableView;
	sectionsScroll.hasVerticalScroller = YES;
	sectionsScroll.borderType = NSBezelBorder;
	sectionsScroll.translatesAutoresizingMaskIntoConstraints = NO;

	_fieldsHeaderLabel = [NSTextField labelWithString:NSLocalizedString(@"QUERY FIELDS (DRAG TO CANVAS)", @"Designer sidebar heading for the query field list.")];
	_fieldsHeaderLabel.font = [NSFont systemFontOfSize:10.0 weight:NSFontWeightBold];
	_fieldsHeaderLabel.textColor = [NSColor secondaryLabelColor];
	_fieldsHeaderLabel.translatesAutoresizingMaskIntoConstraints = NO;

	// Shown when the selected node's layout has no elements: an empty band is authorable,
	// not an error.
	_emptyLayoutHintLabel = [NSTextField wrappingLabelWithString:NSLocalizedString(@"Add elements to design this report.", @"Designer hint when the selected node's report layout has no elements.")];
	_emptyLayoutHintLabel.font = [NSFont systemFontOfSize:9.5];
	_emptyLayoutHintLabel.textColor = [NSColor tertiaryLabelColor];
	_emptyLayoutHintLabel.translatesAutoresizingMaskIntoConstraints = NO;
	_emptyLayoutHintLabel.hidden = YES;

	_queryFieldsSearchField = [[NSSearchField alloc] initWithFrame:NSZeroRect];
	_queryFieldsSearchField.placeholderString = NSLocalizedString(@"Filter query fields…", @"Search field placeholder that filters the query field list.");
	_queryFieldsSearchField.controlSize = NSControlSizeSmall;
	_queryFieldsSearchField.font = [NSFont systemFontOfSize:11.0];
	_queryFieldsSearchField.delegate = self;
	_queryFieldsSearchField.target = self;
	_queryFieldsSearchField.action = @selector(queryFieldsSearchChanged:);
	_queryFieldsSearchField.translatesAutoresizingMaskIntoConstraints = NO;
	_queryFieldsSearchField.toolTip = NSLocalizedString(@"Filter the field list by name.", @"Tooltip for the query field search field.");
	_queryFieldsSearchField.accessibilityLabel = NSLocalizedString(@"Filter Query Fields", @"Accessibility label for the query field search field.");

	_queryFieldsTableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 200, 220)];
	_queryFieldsTableView.headerView = nil;
	_queryFieldsTableView.rowHeight = 23.0;
	_queryFieldsTableView.dataSource = self;
	_queryFieldsTableView.delegate = self;
	_queryFieldsTableView.target = self;
	_queryFieldsTableView.doubleAction = @selector(queryFieldsTableDoubleClicked:);
	[_queryFieldsTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:YES];
	_queryFieldsTableView.toolTip = NSLocalizedString(@"Drag a field onto a report band, or double-click to insert it into the selected band.", @"Tooltip for the query field list.");
	_queryFieldsTableView.accessibilityLabel = NSLocalizedString(@"Query Fields", @"Accessibility label for the query field list.");

	NSTableColumn *fieldCol = [[NSTableColumn alloc] initWithIdentifier:@"QueryFieldName"];
	fieldCol.title = NSLocalizedString(@"Field", @"Query field list column header.");
	fieldCol.width = 190.0;
	[_queryFieldsTableView addTableColumn:fieldCol];

	NSScrollView *fieldsScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 200, 220)];
	fieldsScroll.documentView = _queryFieldsTableView;
	fieldsScroll.hasVerticalScroller = YES;
	fieldsScroll.borderType = NSBezelBorder;
	fieldsScroll.translatesAutoresizingMaskIntoConstraints = NO;

	NSTextField *fieldsHint = [NSTextField labelWithString:NSLocalizedString(@"Drag onto any band or double-click to insert", @"Designer sidebar hint under the query field list.")];
	fieldsHint.font = [NSFont systemFontOfSize:9.5];
	fieldsHint.textColor = [NSColor tertiaryLabelColor];
	fieldsHint.lineBreakMode = NSLineBreakByTruncatingTail;
	fieldsHint.translatesAutoresizingMaskIntoConstraints = NO;

	[container addSubview:minimapHeader];
	[container addSubview:minimapSub];
	[container addSubview:_minimapView];
	[container addSubview:sectionsHeader];
	[container addSubview:sectionsScroll];
	[container addSubview:_emptyLayoutHintLabel];
	[container addSubview:_fieldsHeaderLabel];
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

		[_emptyLayoutHintLabel.topAnchor constraintEqualToAnchor:sectionsScroll.bottomAnchor constant:4.0],
		[_emptyLayoutHintLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10.0],
		[_emptyLayoutHintLabel.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10.0],

		[_fieldsHeaderLabel.topAnchor constraintEqualToAnchor:_emptyLayoutHintLabel.bottomAnchor constant:8.0],
		[_fieldsHeaderLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:10.0],
		[_fieldsHeaderLabel.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-10.0],

		[_queryFieldsSearchField.topAnchor constraintEqualToAnchor:_fieldsHeaderLabel.bottomAnchor constant:4.0],
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
	NSBox *sectionCard = [self makeInspectorCardBoxWithTitle:NSLocalizedString(@"1 · PAGE & SELECTED SECTION", @"Inspector card title. Keep the leading number.") stackOut:&sectionCardStack];

	_paperSizePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	[_paperSizePopup addItemsWithTitles:@[
		NSLocalizedString(@"US Letter (8.5 × 11 in)", @"Paper size name. Keep US Letter and the dimensions."),
		NSLocalizedString(@"US Legal (8.5 × 14 in)", @"Paper size name. Keep US Legal and the dimensions."),
		NSLocalizedString(@"A4 (210 × 297 mm)", @"Paper size name. Keep A4 and the dimensions.")
	]];
	_paperSizePopup.target = self;
	_paperSizePopup.action = @selector(paperSizeChanged:);
	_paperSizePopup.toolTip = NSLocalizedString(@"The paper size the report renders on.", @"Tooltip for the paper size popup.");
	_paperSizePopup.accessibilityLabel = NSLocalizedString(@"Paper Size", @"Accessibility label for the paper size popup.");
	[sectionCardStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"Paper", @"Inspector row label for the paper size.") control:_paperSizePopup]];

	NSBox *secInnerSep = [[NSBox alloc] init];
	secInnerSep.boxType = NSBoxSeparator;
	[sectionCardStack addArrangedSubview:secInnerSep];
	[secInnerSep.widthAnchor constraintEqualToAnchor:sectionCardStack.widthAnchor].active = YES;

	_selectedSectionBadgeLabel = [NSTextField labelWithString:NSLocalizedString(@"Band: Report Detail", @"Inspector badge placeholder before a band is selected.")];
	_selectedSectionBadgeLabel.font = [NSFont systemFontOfSize:11.5 weight:NSFontWeightSemibold];
	_selectedSectionBadgeLabel.textColor = [NSColor controlAccentColor];
	_selectedSectionBadgeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	[sectionCardStack addArrangedSubview:_selectedSectionBadgeLabel];

	_sectionHeightField = [self makeNumericInputFieldWithAction:@selector(sectionHeightFieldEdited:)];
	_sectionHeightField.toolTip = NSLocalizedString(@"The height of the selected report band in points.", @"Tooltip for the band height field.");
	_sectionHeightField.accessibilityLabel = NSLocalizedString(@"Band Height", @"Accessibility label for the band height field.");
	NSButton *autoFitSecBtn = [NSButton buttonWithTitle:NSLocalizedString(@"Fit Height", @"Inspector button that fits the band height to its elements.")
												 target:self
												 action:@selector(autoFitSelectedSectionHeightAction:)];
	autoFitSecBtn.bezelStyle = NSBezelStyleRounded;
	autoFitSecBtn.controlSize = NSControlSizeSmall;
	autoFitSecBtn.font = [NSFont systemFontOfSize:10.5];
	autoFitSecBtn.toolTip = NSLocalizedString(@"Shrink or expand section height to snugly fit its elements", @"Tooltip for the Fit Height button.");

	NSStackView *secHeightControls = [NSStackView stackViewWithViews:@[_sectionHeightField, autoFitSecBtn]];
	secHeightControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	secHeightControls.spacing = 4.0;
	[sectionCardStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"Height (pt)", @"Inspector row label. pt is points.") control:secHeightControls]];

	_sectionVisibleCheck = [NSButton checkboxWithTitle:NSLocalizedString(@"Section Visible", @"Inspector checkbox that hides or shows the band.")
												target:self
												action:@selector(sectionVisibleChanged:)];
	_sectionVisibleCheck.toolTip = NSLocalizedString(@"Show or hide the selected report band.", @"Tooltip for the section visibility checkbox.");
	_sectionVisibleCheck.accessibilityLabel = NSLocalizedString(@"Section Visibility", @"Accessibility label for the section visibility checkbox.");
	_sectionVisibleCheck.controlSize = NSControlSizeSmall;
	_sectionVisibleCheck.font = [NSFont systemFontOfSize:11.0];

	_sectionPageBreakCheck = [NSButton checkboxWithTitle:NSLocalizedString(@"Page Break After", @"Inspector checkbox that starts a new page after the band.")
												  target:self
												  action:@selector(sectionPageBreakChanged:)];
	_sectionPageBreakCheck.toolTip = NSLocalizedString(@"Start a new page after the selected band.", @"Tooltip for the page break checkbox.");
	_sectionPageBreakCheck.accessibilityLabel = NSLocalizedString(@"Page Break After Section", @"Accessibility label for the page break checkbox.");
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

	NSTextField *elemMajorHeader = [NSTextField labelWithString:NSLocalizedString(@"2 · SELECTED ELEMENT INSPECTOR", @"Inspector card title. Keep the leading number.")];
	elemMajorHeader.font = [NSFont systemFontOfSize:10.5 weight:NSFontWeightBold];
	elemMajorHeader.textColor = [NSColor labelColor];
	[rootStack addArrangedSubview:elemMajorHeader];

	_noElementSelectedHintLabel = [NSTextField wrappingLabelWithString:
		NSLocalizedString(@"No element selected.\n\nClick an element on the canvas to inspect and style it, or drag a Query Field from the left sidebar onto any report band.", @"Inspector hint shown when no element is selected.")];
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
	NSBox *idCard = [self makeInspectorCardBoxWithTitle:NSLocalizedString(@"ELEMENT & BAND ASSIGNMENT", @"Inspector card title for the element identity and band assignment.") stackOut:&idCardStack];

	_elementTypeBadgeLabel = [NSTextField labelWithString:NSLocalizedString(@"Static Label", @"Element type name: a text label that does not come from the query.")];
	_elementTypeBadgeLabel.font = [NSFont systemFontOfSize:11.5 weight:NSFontWeightSemibold];
	_elementTypeBadgeLabel.textColor = [NSColor controlAccentColor];
	_elementTypeBadgeLabel.lineBreakMode = NSLineBreakByTruncatingTail;
	[idCardStack addArrangedSubview:_elementTypeBadgeLabel];

	_elementSectionPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	_elementSectionPopup.toolTip = NSLocalizedString(@"Move the selected elements to another report band.", @"Tooltip for the element section popup.");
	_elementSectionPopup.accessibilityLabel = NSLocalizedString(@"Element Band", @"Accessibility label for the element section popup.");
	_elementSectionPopup.target = self;
	_elementSectionPopup.action = @selector(elementSectionAssignmentChanged:);
	_elementSectionPopup.toolTip = NSLocalizedString(@"Move the selected element(s) to another report section", @"Tooltip for the band assignment popup.");
	[idCardStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"Band", @"Inspector row label for the report band assignment.") control:_elementSectionPopup]];

	NSButton *dupBtn = [NSButton buttonWithTitle:NSLocalizedString(@"Duplicate", @"Inspector button that duplicates the selected elements.") target:self action:@selector(duplicateSelectedElementsAction:)];
	dupBtn.bezelStyle = NSBezelStyleRounded;
	dupBtn.controlSize = NSControlSizeSmall;
	dupBtn.font = [NSFont systemFontOfSize:11.0];
	dupBtn.toolTip = NSLocalizedString(@"Duplicate the selected elements.", @"Tooltip for the inspector duplicate button.");
	dupBtn.accessibilityLabel = NSLocalizedString(@"Duplicate Elements", @"Accessibility label for the inspector duplicate button.");

	NSButton *delBtn = [NSButton buttonWithTitle:NSLocalizedString(@"Delete", @"Inspector button that deletes the selected elements.") target:self action:@selector(deleteSelectedElementsAction:)];
	delBtn.bezelStyle = NSBezelStyleRounded;
	delBtn.controlSize = NSControlSizeSmall;
	delBtn.font = [NSFont systemFontOfSize:11.0];
	delBtn.toolTip = NSLocalizedString(@"Delete the selected elements.", @"Tooltip for the inspector delete button.");
	delBtn.accessibilityLabel = NSLocalizedString(@"Delete Elements", @"Accessibility label for the inspector delete button.");
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
	_contentBindingCard = [self makeInspectorCardBoxWithTitle:NSLocalizedString(@"CONTENT & DATA BINDING", @"Inspector card title for the element content and data binding.") stackOut:&bindingStack];

	_elementTextField = [[NSTextField alloc] initWithFrame:NSZeroRect];
	_elementTextField.placeholderString = NSLocalizedString(@"Label or barcode text…", @"Inspector text field placeholder for label and barcode content.");
	_elementTextField.target = self;
	_elementTextField.action = @selector(elementTextEdited:);
	_elementTextField.toolTip = NSLocalizedString(@"The label or barcode text.", @"Tooltip for the element text field.");
	_elementTextField.accessibilityLabel = NSLocalizedString(@"Element Text", @"Accessibility label for the element text field.");
	_staticTextRow = [self makeInspectorRowWithLabel:NSLocalizedString(@"Text", @"Inspector row label for the label text.") control:_elementTextField];
	[bindingStack addArrangedSubview:_staticTextRow];

	_queryFieldPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	_queryFieldPopup.target = self;
	_queryFieldPopup.action = @selector(queryFieldChanged:);
	_queryFieldPopup.toolTip = NSLocalizedString(@"The query field this element is bound to.", @"Tooltip for the bound-field popup.");
	_queryFieldPopup.accessibilityLabel = NSLocalizedString(@"Bound Query Field", @"Accessibility label for the bound-field popup.");
	_queryFieldRow = [self makeInspectorRowWithLabel:NSLocalizedString(@"Field", @"Inspector row label for the bound query field.") control:_queryFieldPopup];
	[bindingStack addArrangedSubview:_queryFieldRow];

	_aggregateTypePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	_aggregateTypePopup.toolTip = NSLocalizedString(@"The aggregate function to apply.", @"Tooltip for the aggregate function popup.");
	_aggregateTypePopup.accessibilityLabel = NSLocalizedString(@"Aggregate Function", @"Accessibility label for the aggregate function popup.");
	[_aggregateTypePopup addItemsWithTitles:@[
		NSLocalizedString(@"SUM", @"Aggregate function name. SQL; do not translate."),
		NSLocalizedString(@"MEAN (AVG)", @"Aggregate function name. AVG is SQL; do not translate."),
		NSLocalizedString(@"COUNT", @"Aggregate function name. SQL; do not translate."),
		NSLocalizedString(@"FIRST", @"Aggregate function name. SQL; do not translate."),
		NSLocalizedString(@"LAST", @"Aggregate function name. SQL; do not translate."),
		NSLocalizedString(@"MIN", @"Aggregate function name. SQL; do not translate."),
		NSLocalizedString(@"MAX", @"Aggregate function name. SQL; do not translate.")
	]];
	_aggregateTypePopup.target = self;
	_aggregateTypePopup.action = @selector(aggregateTypeChanged:);
	_aggregateFunctionRow = [self makeInspectorRowWithLabel:NSLocalizedString(@"Function", @"Inspector row label for the aggregate function.") control:_aggregateTypePopup];
	[bindingStack addArrangedSubview:_aggregateFunctionRow];

	_aggregateScopePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	_aggregateScopePopup.toolTip = NSLocalizedString(@"Whether the aggregate covers the whole report, a page, or one grouping.", @"Tooltip for the aggregate scope popup.");
	_aggregateScopePopup.accessibilityLabel = NSLocalizedString(@"Aggregate Scope", @"Accessibility label for the aggregate scope popup.");
	_aggregateScopePopup.target = self;
	_aggregateScopePopup.action = @selector(aggregateScopeChanged:);
	_aggregateScopeRow = [self makeInspectorRowWithLabel:NSLocalizedString(@"Scope", @"Inspector row label for the aggregate scope.") control:_aggregateScopePopup];
	[bindingStack addArrangedSubview:_aggregateScopeRow];

	_numericFormatCheck = [NSButton checkboxWithTitle:NSLocalizedString(@"Numeric", @"Inspector checkbox that formats the value as a number.") target:self action:@selector(numericFormatChanged:)];
	_numericFormatCheck.toolTip = NSLocalizedString(@"Format the bound value as a number.", @"Tooltip for the numeric format checkbox.");
	_numericFormatCheck.accessibilityLabel = NSLocalizedString(@"Numeric Format", @"Accessibility label for the numeric format checkbox.");
	_numericFormatCheck.controlSize = NSControlSizeSmall;
	_numericFormatCheck.font = [NSFont systemFontOfSize:11.0];

	NSTextField *decLbl = [NSTextField labelWithString:NSLocalizedString(@"Dec:", @"Inspector label for the decimal-place count.")];
	decLbl.font = [NSFont systemFontOfSize:11.0];
	decLbl.textColor = [NSColor secondaryLabelColor];
	_decimalsField = [self makeNumericInputFieldWithAction:@selector(numericFormatChanged:)];
	[_decimalsField.widthAnchor constraintEqualToConstant:34.0].active = YES;

	NSStackView *numFormatControls = [NSStackView stackViewWithViews:@[_numericFormatCheck, decLbl, _decimalsField]];
	numFormatControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	numFormatControls.spacing = 4.0;
	_numericFormatRow = [self makeInspectorRowWithLabel:NSLocalizedString(@"Format", @"Inspector row label for the number format.") control:numFormatControls];
	[bindingStack addArrangedSubview:_numericFormatRow];

	_barcodeSymbologyPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	_barcodeSymbologyPopup.toolTip = NSLocalizedString(@"The barcode symbology to encode.", @"Tooltip for the barcode symbology popup.");
	_barcodeSymbologyPopup.accessibilityLabel = NSLocalizedString(@"Barcode Symbology", @"Accessibility label for the barcode symbology popup.");
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
	_barcodeSymbologyRow = [self makeInspectorRowWithLabel:NSLocalizedString(@"Symbology", @"Inspector row label for the barcode symbology.") control:_barcodeSymbologyPopup];
	[bindingStack addArrangedSubview:_barcodeSymbologyRow];

	_barcodeHumanReadableCheck = [NSButton checkboxWithTitle:NSLocalizedString(@"Show Text", @"Inspector checkbox that prints the barcode value below the bars.") target:self action:@selector(barcodeOptionsChanged:)];
	_barcodeHumanReadableCheck.toolTip = NSLocalizedString(@"Print the encoded value below the barcode.", @"Tooltip for the human-readable barcode checkbox.");
	_barcodeHumanReadableCheck.accessibilityLabel = NSLocalizedString(@"Human Readable Barcode", @"Accessibility label for the human-readable barcode checkbox.");
	_barcodeHumanReadableCheck.controlSize = NSControlSizeSmall;
	_barcodeHumanReadableCheck.font = [NSFont systemFontOfSize:11.0];
	_barcodeBorderPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	[_barcodeBorderPopup addItemsWithTitles:@[
		NSLocalizedString(@"No Border", @"Barcode border style: none."),
		NSLocalizedString(@"Bind Bars", @"Barcode border style: bars only."),
		NSLocalizedString(@"Box Frame", @"Barcode border style: a full frame.")
	]];
	_barcodeBorderPopup.target = self;
	_barcodeBorderPopup.action = @selector(barcodeOptionsChanged:);
	NSStackView *bcOptControls = [NSStackView stackViewWithViews:@[_barcodeHumanReadableCheck, _barcodeBorderPopup]];
	bcOptControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	bcOptControls.spacing = 6.0;
	_barcodeOptionsRow = [self makeInspectorRowWithLabel:NSLocalizedString(@"Options", @"Inspector row label for the barcode options.") control:bcOptControls];
	[bindingStack addArrangedSubview:_barcodeOptionsRow];

	_chooseImageButton = [NSButton buttonWithTitle:NSLocalizedString(@"Choose Image…", @"Inspector button that opens an image chooser.") target:self action:@selector(chooseImageFileAction:)];
	_chooseImageButton.bezelStyle = NSBezelStyleRounded;
	_chooseImageButton.toolTip = NSLocalizedString(@"Choose the image file this element displays.", @"Tooltip for the inspector choose-image button.");
	_chooseImageButton.accessibilityLabel = NSLocalizedString(@"Choose Image", @"Accessibility label for the inspector choose-image button.");
	_imagePickerRow = [self makeInspectorRowWithLabel:NSLocalizedString(@"Image", @"Inspector row label for the image file.") control:_chooseImageButton];
	[bindingStack addArrangedSubview:_imagePickerRow];

	[_elementInspectorCardsStack addArrangedSubview:_contentBindingCard];
	[_contentBindingCard.widthAnchor constraintEqualToAnchor:_elementInspectorCardsStack.widthAnchor].active = YES;

	// -------------------------------------------------------------------------
	// CARD 2C: TYPOGRAPHY, ALIGNMENT & COLORS
	// -------------------------------------------------------------------------
	NSStackView *typoStack = nil;
	NSBox *typoCard = [self makeInspectorCardBoxWithTitle:NSLocalizedString(@"TYPOGRAPHY & APPEARANCE", @"Inspector card title for typography and colours.") stackOut:&typoStack];

	_fontFamilyPopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
	[_fontFamilyPopup addItemsWithTitles:@[
		NSLocalizedString(@"Helvetica", @"Font family name. Technical; do not translate."),
		NSLocalizedString(@"HelveticaNeue", @"Font family name. Technical; do not translate."),
		NSLocalizedString(@"ArialMT", @"Font family name. Technical; do not translate."),
		NSLocalizedString(@"Courier", @"Font family name. Technical; do not translate."),
		NSLocalizedString(@"TimesNewRomanPSMT", @"Font family name. Technical; do not translate."),
		NSLocalizedString(@"Avenir-Book", @"Font family name. Technical; do not translate."),
		NSLocalizedString(@"Menlo-Regular", @"Font family name. Technical; do not translate."),
		NSLocalizedString(@"Georgia", @"Font family name. Technical; do not translate.")
	]];
	_fontFamilyPopup.target = self;
	_fontFamilyPopup.action = @selector(typographyChanged:);
	_fontFamilyPopup.toolTip = NSLocalizedString(@"The font family for the selected elements.", @"Tooltip for the font family popup.");
	_fontFamilyPopup.accessibilityLabel = NSLocalizedString(@"Font Family", @"Accessibility label for the font family popup.");
	[typoStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"Font", @"Inspector row label for the font family.") control:_fontFamilyPopup]];

	_fontSizeField = [self makeNumericInputFieldWithAction:@selector(typographyChanged:)];
	_fontSizeField.toolTip = NSLocalizedString(@"The font size in points.", @"Tooltip for the font size field.");
	_fontSizeField.accessibilityLabel = NSLocalizedString(@"Font Size", @"Accessibility label for the font size field.");
	[typoStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"Size (pt)", @"Inspector row label for the font size in points.") control:_fontSizeField]];

	_boldCheck = [NSButton checkboxWithTitle:NSLocalizedString(@"B", @"Typography checkbox: bold. A one-letter style abbreviation; do not translate.") target:self action:@selector(typographyChanged:)];
	_boldCheck.font = [NSFont boldSystemFontOfSize:11.0];
	_boldCheck.controlSize = NSControlSizeSmall;
	_italicCheck = [NSButton checkboxWithTitle:NSLocalizedString(@"I", @"Typography checkbox: italic. A one-letter style abbreviation; do not translate.") target:self action:@selector(typographyChanged:)];
	_italicCheck.font = [NSFontManager.sharedFontManager convertFont:[NSFont systemFontOfSize:11.0] toHaveTrait:NSItalicFontMask];
	_italicCheck.controlSize = NSControlSizeSmall;
	_underlineCheck = [NSButton checkboxWithTitle:NSLocalizedString(@"U", @"Typography checkbox: underline. A one-letter style abbreviation; do not translate.") target:self action:@selector(typographyChanged:)];
	_underlineCheck.font = [NSFont systemFontOfSize:11.0];
	_underlineCheck.controlSize = NSControlSizeSmall;
	_strikethroughCheck = [NSButton checkboxWithTitle:NSLocalizedString(@"S", @"Typography checkbox: strikethrough. A one-letter style abbreviation; do not translate.") target:self action:@selector(typographyChanged:)];
	_strikethroughCheck.font = [NSFont systemFontOfSize:11.0];
	_strikethroughCheck.controlSize = NSControlSizeSmall;

	NSStackView *styleChecks = [NSStackView stackViewWithViews:@[_boldCheck, _italicCheck, _underlineCheck, _strikethroughCheck]];
	styleChecks.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	styleChecks.spacing = 8.0;
	[typoStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"Style", @"Inspector row label for the bold/italic/underline/strikethrough toggles.") control:styleChecks]];

	_hAlignControl = [NSSegmentedControl segmentedControlWithLabels:@[
		NSLocalizedString(@"Left", @"Horizontal alignment: left."),
		NSLocalizedString(@"Center", @"Horizontal alignment: centre."),
		NSLocalizedString(@"Right", @"Horizontal alignment: right.")
	]
													   trackingMode:NSSegmentSwitchTrackingSelectOne
															 target:self
															 action:@selector(alignmentChanged:)];
	_hAlignControl.toolTip = NSLocalizedString(@"Horizontal alignment of the text.", @"Tooltip for the horizontal alignment control.");
	_hAlignControl.accessibilityLabel = NSLocalizedString(@"Horizontal Alignment", @"Accessibility label for the horizontal alignment control.");
	[typoStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"H-Align", @"Inspector row label for horizontal alignment.") control:_hAlignControl]];

	_vAlignControl = [NSSegmentedControl segmentedControlWithLabels:@[
		NSLocalizedString(@"Top", @"Vertical alignment: top."),
		NSLocalizedString(@"Middle", @"Vertical alignment: middle."),
		NSLocalizedString(@"Bottom", @"Vertical alignment: bottom.")
	]
													   trackingMode:NSSegmentSwitchTrackingSelectOne
															 target:self
															 action:@selector(alignmentChanged:)];
	_vAlignControl.toolTip = NSLocalizedString(@"Vertical alignment of the text.", @"Tooltip for the vertical alignment control.");
	_vAlignControl.accessibilityLabel = NSLocalizedString(@"Vertical Alignment", @"Accessibility label for the vertical alignment control.");
	[typoStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"V-Align", @"Inspector row label for vertical alignment.") control:_vAlignControl]];

	_fgColorWell = [[NSColorWell alloc] initWithFrame:NSMakeRect(0, 0, 38, 22)];
	_fgColorWell.target = self;
	_fgColorWell.action = @selector(colorChanged:);
	_fgColorWell.toolTip = NSLocalizedString(@"The text colour of the selected elements.", @"Tooltip for the foreground colour well.");
	_fgColorWell.accessibilityLabel = NSLocalizedString(@"Text Color", @"Accessibility label for the foreground colour well.");
	[_fgColorWell.widthAnchor constraintEqualToConstant:40.0].active = YES;
	[_fgColorWell.heightAnchor constraintEqualToConstant:22.0].active = YES;

	_hasBgColorCheck = [NSButton checkboxWithTitle:NSLocalizedString(@"Fill", @"Inspector checkbox that fills the element background.") target:self action:@selector(colorChanged:)];
	_hasBgColorCheck.controlSize = NSControlSizeSmall;
	_hasBgColorCheck.font = [NSFont systemFontOfSize:11.0];

	_bgColorWell = [[NSColorWell alloc] initWithFrame:NSMakeRect(0, 0, 38, 22)];
	_bgColorWell.target = self;
	_bgColorWell.action = @selector(colorChanged:);
	_bgColorWell.toolTip = NSLocalizedString(@"The background fill colour of the selected elements.", @"Tooltip for the background colour well.");
	_bgColorWell.accessibilityLabel = NSLocalizedString(@"Background Color", @"Accessibility label for the background colour well.");
	[_bgColorWell.widthAnchor constraintEqualToConstant:40.0].active = YES;
	[_bgColorWell.heightAnchor constraintEqualToConstant:22.0].active = YES;

	NSStackView *colorRowControls = [NSStackView stackViewWithViews:@[_fgColorWell, _hasBgColorCheck, _bgColorWell]];
	colorRowControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	colorRowControls.spacing = 6.0;
	[typoStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"Colors", @"Inspector row label for the foreground and background colours.") control:colorRowControls]];

	[_elementInspectorCardsStack addArrangedSubview:typoCard];
	[typoCard.widthAnchor constraintEqualToAnchor:_elementInspectorCardsStack.widthAnchor].active = YES;

	// -------------------------------------------------------------------------
	// CARD 2D: POSITION, SIZE & BOX MODEL (Borders, Padding, Margin)
	// -------------------------------------------------------------------------
	NSStackView *geomStack = nil;
	NSBox *geomCard = [self makeInspectorCardBoxWithTitle:NSLocalizedString(@"POSITION, SIZE & BOX MODEL", @"Inspector card title for position, size, border, padding and margin.") stackOut:&geomStack];

	_posXField = [self makeNumericInputFieldWithAction:@selector(elementGeometryEdited:)];
	_posYField = [self makeNumericInputFieldWithAction:@selector(elementGeometryEdited:)];
	_widthField = [self makeNumericInputFieldWithAction:@selector(elementGeometryEdited:)];
	_heightField = [self makeNumericInputFieldWithAction:@selector(elementGeometryEdited:)];

	NSTextField *yLbl = [NSTextField labelWithString:NSLocalizedString(@"Y:", @"Inspector label for the vertical position in points.")];
	yLbl.font = [NSFont systemFontOfSize:11.0];
	yLbl.textColor = [NSColor secondaryLabelColor];
	NSStackView *xyRow = [NSStackView stackViewWithViews:@[_posXField, yLbl, _posYField]];
	xyRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	xyRow.spacing = 4.0;
	xyRow.distribution = NSStackViewDistributionFillProportionally;
	[geomStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"X / Y (pt)", @"Inspector row label for the position in points.") control:xyRow]];

	NSTextField *hLbl = [NSTextField labelWithString:NSLocalizedString(@"H:", @"Inspector label for the height in points.")];
	hLbl.font = [NSFont systemFontOfSize:11.0];
	hLbl.textColor = [NSColor secondaryLabelColor];
	NSStackView *whRow = [NSStackView stackViewWithViews:@[_widthField, hLbl, _heightField]];
	whRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	whRow.spacing = 4.0;
	whRow.distribution = NSStackViewDistributionFillProportionally;
	[geomStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"W / H (pt)", @"Inspector row label for the size in points.") control:whRow]];

	_borderTopField = [self makeNumericInputFieldWithAction:@selector(elementBoxModelEdited:)];
	_borderTopField.toolTip = NSLocalizedString(@"Top Border (pt)", @"Tooltip for the top border width field, in points.");
	_borderBottomField = [self makeNumericInputFieldWithAction:@selector(elementBoxModelEdited:)];
	_borderBottomField.toolTip = NSLocalizedString(@"Bottom Border (pt)", @"Tooltip for the bottom border width field, in points.");
	_borderLeftField = [self makeNumericInputFieldWithAction:@selector(elementBoxModelEdited:)];
	_borderLeftField.toolTip = NSLocalizedString(@"Left Border (pt)", @"Tooltip for the left border width field, in points.");
	_borderRightField = [self makeNumericInputFieldWithAction:@selector(elementBoxModelEdited:)];
	_borderRightField.toolTip = NSLocalizedString(@"Right Border (pt)", @"Tooltip for the right border width field, in points.");

	NSStackView *bordersGrid = [NSStackView stackViewWithViews:@[
		_borderTopField, _borderBottomField, _borderLeftField, _borderRightField
	]];
	bordersGrid.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	bordersGrid.spacing = 3.0;
	bordersGrid.distribution = NSStackViewDistributionFillEqually;
	[geomStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"Border T/B/L/R", @"Inspector row label for the four border widths: top, bottom, left, right.") control:bordersGrid]];

	_paddingAllField = [self makeNumericInputFieldWithAction:@selector(elementBoxModelEdited:)];
	_marginAllField = [self makeNumericInputFieldWithAction:@selector(elementBoxModelEdited:)];
	NSTextField *mLbl = [NSTextField labelWithString:NSLocalizedString(@"M:", @"Inspector label for the margin in points.")];
	mLbl.font = [NSFont systemFontOfSize:11.0];
	mLbl.textColor = [NSColor secondaryLabelColor];
	NSStackView *padMarRow = [NSStackView stackViewWithViews:@[_paddingAllField, mLbl, _marginAllField]];
	padMarRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	padMarRow.spacing = 4.0;
	padMarRow.distribution = NSStackViewDistributionFillProportionally;
	[geomStack addArrangedSubview:[self makeInspectorRowWithLabel:NSLocalizedString(@"Pad / Margin", @"Inspector row label for padding and margin in points.") control:padMarRow]];

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
		return _leftSidebarHidden ? 0.0 : MAX(proposedMinimumPosition, kMinLeftSidebarWidth);
	}
	if (dividerIndex == 1) {
		CGFloat totalW = NSWidth(splitView.bounds);
		if (_inspectorHidden) return totalW;
		CGFloat left = _leftSidebarHidden ? 0.0 : _leftSidebarWidth;
		return MAX(left + 280.0, totalW - kMaxRightInspectorWidth);
	}
	return proposedMinimumPosition;
}

- (CGFloat)splitView:(__unused NSSplitView *)splitView
	constrainMaxCoordinate:(CGFloat)proposedMaximumPosition
			   ofSubviewAt:(NSInteger)dividerIndex {
	if (dividerIndex == 0) {
		return _leftSidebarHidden ? 0.0 : MIN(proposedMaximumPosition, kMaxLeftSidebarWidth);
	}
	if (dividerIndex == 1) {
		CGFloat totalW = NSWidth(splitView.bounds);
		if (_inspectorHidden) return totalW;
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

	CGFloat leftW = _leftSidebarHidden ? 0.0 : MIN(kMaxLeftSidebarWidth, MAX(kMinLeftSidebarWidth, _leftSidebarWidth));
	CGFloat rightW = _inspectorHidden ? 0.0 : MIN(kMaxRightInspectorWidth, MAX(kMinRightInspectorWidth, _rightInspectorWidth));
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
	if (!_leftSidebarHidden &&
		currentLeftW >= kMinLeftSidebarWidth - 1.0 && currentLeftW <= kMaxLeftSidebarWidth + 1.0) {
		_leftSidebarWidth = currentLeftW;
	}
	CGFloat currentRightW = NSWidth(_rightInspectorContainerView.frame);
	if (!_inspectorHidden &&
		currentRightW >= kMinRightInspectorWidth - 1.0 && currentRightW <= kMaxRightInspectorWidth + 1.0) {
		_rightInspectorWidth = currentRightW;
	}
	[_canvasView recalculateCanvasSize];
	[_minimapView setNeedsDisplay:YES];
}
#pragma mark - Reloading & Query Field Browser

- (NSArray<RptqQueryField *> *)displayedQueryFields {
	return _filteredQueryFields ?: @[];
}

- (NSArray<RptqQueryField *> *)allQueryFields {
	MADMacDocument *doc = self.madDocument;
	RptqQuery *q = doc.selectedQuery;
	if (q == nil) return @[];
	// The Result and every composing node bind to their own output fields, in output
	// order; a field with no output key is a join/filter field, not a report column.
	if ([doc queryShowsReportColumns:q]) {
		return [q orderedOutputFieldsWithError:NULL] ?: @[];
	}
	// A leaf binds to its own query fields.
	NSMutableArray<RptqQueryField *> *fields = [NSMutableArray array];
	for (RptqQueryTable *qt in q.hasQueryTables) {
		for (RptqQueryField *qf in qt.hasQueryFields) {
			[fields addObject:qf];
		}
	}
	return fields;
}

/// The selected node's detail band (its own, not the document's).
- (nullable RptqDocumentSection *)selectedNodeDetailSection {
	for (RptqDocumentSection *sec in [_canvasView orderedSections]) {
		if ((MADDocumentSectionType)sec.type == MADDocumentSectionTypeBody) return sec;
	}
	return nil;
}

- (NSUInteger)selectedNodeElementCount {
	NSUInteger count = 0;
	for (RptqDocumentSection *sec in [_canvasView orderedSections]) {
		count += [_canvasView elementsInSection:sec].count;
	}
	return count;
}

- (NSString *)displayLabelForQueryField:(RptqQueryField *)qf {
	if (!qf) return @"(Unbound)";
	if (qf.outputKey.length > 0) {
		return qf.outputKey;
	}
	NSString *tbl = qf.inQueryTable.alias.length > 0
		? qf.inQueryTable.alias
		: (qf.inQueryTable.databaseSchemaTable.name ?: (qf.inQueryTable.upstreamQuery.name ?: @"Table"));
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
	// Element insertion/removal runs through here; keep the empty-layout hint current.
	_emptyLayoutHintLabel.hidden = ([self selectedNodeElementCount] > 0);
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
	// A section from another node is not a valid target here: clear the element
	// selection so an edit can never be replayed against the wrong node's objects.
	if (_canvasView.selectedSection != nil && ![sections containsObject:_canvasView.selectedSection]) {
		[_canvasView setSelectedElementsSet:[NSOrderedSet orderedSet]];
		_canvasView.selectedSection = nil;
	}
	if (_canvasView.selectedSection == nil && sections.count > 0) {
		_canvasView.selectedSection = [self selectedNodeDetailSection] ?: sections.firstObject;
	}

	BOOL showsColumns = [doc queryShowsReportColumns:doc.selectedQuery];
	_fieldsHeaderLabel.stringValue = showsColumns
		? NSLocalizedString(@"REPORT COLUMNS (DRAG TO CANVAS)", @"Designer sidebar heading for a Result's or a composing node's report columns.")
		: NSLocalizedString(@"QUERY FIELDS (DRAG TO CANVAS)", @"Designer sidebar heading for the query field list.");
	_emptyLayoutHintLabel.hidden = ([self selectedNodeElementCount] > 0);

	// A filter typed for one node must not blank the next node's field list.
	int64_t queryIdentifier = doc.selectedQuery != nil ? doc.selectedQuery.identifier : 0;
	if (queryIdentifier != self.loadedQueryIdentifier) {
		self.loadedQueryIdentifier = queryIdentifier;
		_queryFieldsSearchField.stringValue = @"";
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
	[_queryFieldPopup addItemWithTitle:NSLocalizedString(@"(Unbound)", @"Field popup item for an element that is not bound to a field.")];
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
		NSString *title = doc ? [doc displayTitleForSection:sec] : ([sec localizedDisplayName] ?: NSLocalizedString(@"Section", @"Generic report band name."));
		[_elementSectionPopup addItemWithTitle:title];
		_elementSectionPopup.lastItem.tag = (NSInteger)i;
	}

	// 3. Aggregate Scope ("For Each") popup
	[_aggregateScopePopup removeAllItems];
	[_aggregateScopePopup addItemWithTitle:NSLocalizedString(@"Entire Report", @"Aggregate scope: one value for the whole report.")];
	_aggregateScopePopup.lastItem.tag = 0; // MTAggregateGroupByTypeReport
	[_aggregateScopePopup addItemWithTitle:NSLocalizedString(@"Each Page", @"Aggregate scope: one value per page.")];
	_aggregateScopePopup.lastItem.tag = -1; // MTAggregateGroupByTypePage
	int32_t groupIndex = 1;
	for (RptqDocumentSection *sec in sections) {
		if ((MADDocumentSectionType)sec.type == MADDocumentSectionTypeGroupHeader) {
			NSString *secTitle = doc ? [doc displayTitleForSection:sec] : NSLocalizedString(@"Group", @"Generic grouping band name.");
			NSString *gTitle = [[NSString alloc] initWithFormat:NSLocalizedString(@"Group #%1$d (%2$@)", @"Aggregate scope: one value per group. %1$d is the group level, %2$@ the band name."), groupIndex, secTitle];
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

		if (![tableColumn.identifier isEqualToString:@"SectionName"]) return nil;
		NSTextField *lbl = [NSTextField labelWithString:@""];
		NSString *prefix = isGroup ? @"  • " : @"● ";
		NSString *name = doc ? [doc displayTitleForSection:sec] : ([sec localizedDisplayName] ?: NSLocalizedString(@"Section", @"Generic report band name."));
		if (!sec.visibility) name = [name stringByAppendingString:NSLocalizedString(@" (Hidden)", @"Suffix on a hidden report band name. Keep the leading space.")];
		NSString *rowText = [prefix stringByAppendingString:name];
		NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:rowText];
		NSColor *dotColor = [sec isEqual:_canvasView.selectedSection]
			? [NSColor controlAccentColor]
			: (sec.visibility ? [NSColor secondaryLabelColor] : [NSColor tertiaryLabelColor]);
		[attr addAttribute:NSForegroundColorAttributeName value:dotColor range:NSMakeRange(0, prefix.length)];
		[attr addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11.0 weight:isGroup ? NSFontWeightRegular : NSFontWeightMedium] range:NSMakeRange(0, attr.length)];
		lbl.attributedStringValue = attr;
		lbl.lineBreakMode = NSLineBreakByTruncatingTail;
		return lbl;
	}

	if (tableView == _queryFieldsTableView) {
		if (row < 0 || (NSUInteger)row >= _filteredQueryFields.count) return nil;
		RptqQueryField *qf = _filteredQueryFields[(NSUInteger)row];
		NSTextField *lbl = [NSTextField labelWithString:[self displayLabelForQueryField:qf]];
		lbl.font = [NSFont systemFontOfSize:11.0 weight:NSFontWeightRegular];
		lbl.lineBreakMode = NSLineBreakByTruncatingTail;
		lbl.toolTip = NSLocalizedString(@"Drag onto any report section on the canvas, or double-click to insert into the selected section", @"Tooltip on a query field row in the designer sidebar.");
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
		NSString *secTitle = doc ? [doc displayTitleForSection:sec] : ([sec localizedDisplayName] ?: NSLocalizedString(@"Section", @"Generic report band name."));
		_selectedSectionBadgeLabel.stringValue = [[NSString alloc] initWithFormat:NSLocalizedString(@"Band: %@", @"Inspector badge with the selected band name."), secTitle];
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

		NSString *kindName = NSLocalizedString(@"Element", @"Generic document element name.");
		if (isLabel) kindName = NSLocalizedString(@"Static Label", @"Element type name: a text label that does not come from the query.");
		else if (isData) kindName = NSLocalizedString(@"Data Field", @"Element type name: a field bound to the query.");
		else if (isAgg) kindName = NSLocalizedString(@"Summary Aggregate", @"Element type name: an aggregate value.");
		else if (isBarcode) kindName = NSLocalizedString(@"Barcode", @"Element type name: a barcode.");
		else if (isImg) kindName = NSLocalizedString(@"Image", @"Element type name: an image.");
		if (selectedSet.count > 1) {
			_elementTypeBadgeLabel.stringValue = [[NSString alloc] initWithFormat:NSLocalizedString(@"%1$lu Elements Selected (%2$@)", @"Inspector badge when several elements are selected. %1$lu is the count, %2$@ the kind."), (unsigned long)selectedSet.count, kindName];
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
		sec = [self selectedNodeDetailSection] ?: [_canvasView orderedSections].firstObject;
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
	lbl.text = NSLocalizedString(@"Static Label", @"Canvas placeholder text for a newly inserted static label.");
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
		if (bound.outputKey.length > 0) {
			dl.fieldID = bound.outputKey;
			dl.tableID = bound.inQueryTable.upstreamQuery.name;
			dl.text = [NSString stringWithFormat:@"[%@]", bound.outputKey];
		} else {
			// A leaf's result table is keyed by the compiled "<alias>.<field>" identifier;
			// use the same alias the renderer resolves (queryAlias, not the bare alias).
			dl.fieldID = bound.databaseSchemaField.name;
			dl.tableID = [bound.inQueryTable queryAlias] ?: bound.inQueryTable.databaseSchemaTable.name;
			dl.text = [NSString stringWithFormat:@"[%@.%@]", dl.tableID ?: @"", dl.fieldID ?: @""];
		}
	} else {
		dl.text = NSLocalizedString(@"[Data Field]", @"Canvas placeholder text for a newly inserted data field.");
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

- (nullable RptqDocumentElement *)cloneElement:(RptqDocumentElement *)src
								   intoSection:(RptqDocumentSection *)sec
									   atPoint:(NSPoint)dupOrigin {
	if (src == nil || sec == nil) return nil;
	NSRect srcRect = [_canvasView elementRectInSectionContent:src];
	RptqDocumentElement *dup = nil;
	if ([src isKindOfClass:[RptqDocumentElementLabel class]]) {
		RptqDocumentElementLabel *srcLabel = (RptqDocumentElementLabel *)src;
		BOOL isRule = srcLabel.border != nil && srcLabel.border.width.bottom > 0.0 && srcLabel.text.length == 0;
		if (isRule) {
			dup = [self addLineRuleInSection:sec atPoint:dupOrigin];
		} else {
			RptqDocumentElementLabel *lbl = [self addStaticLabelInSection:sec atPoint:dupOrigin];
			lbl.text = [srcLabel.text copy];
			dup = lbl;
		}
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
	if (dup != nil) {
		[dup setSizeWidth:(float)srcRect.size.width height:(float)srcRect.size.height];
		dup.fontname = [src.fontname copy];
		dup.fontsize = src.fontsize;
		dup.foregroundColor = src.foregroundColor;
		dup.backgroundColor = src.backgroundColor;
	}
	return dup;
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
		RptqDocumentElement *dup = [self cloneElement:src intoSection:sec atPoint:dupOrigin];
		if (dup) [newSelection addObject:dup];
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
		[um setActionName:NSLocalizedString(@"Insert Element", @"Undo action name for inserting an element.")];
	}
}

- (void)registerUndoForRemovedElement:(RptqDocumentElement *)element
						  fromSection:(RptqDocumentSection *)section
							 atOrigin:(NSPoint)origin {
	NSUndoManager *um = self.madDocument.undoManager;
	if (!um) return;
	[[um prepareWithInvocationTarget:self] restoreRemovedElement:element toSection:section atOrigin:origin];
	if (!um.isUndoing) {
		[um setActionName:NSLocalizedString(@"Delete Element", @"Undo action name for deleting elements.")];
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
			if (chosen.outputKey.length > 0) {
				df.fieldID = chosen.outputKey;
				df.tableID = chosen.inQueryTable.upstreamQuery.name;
				df.text = [NSString stringWithFormat:@"[%@]", chosen.outputKey];
			} else {
				df.fieldID = chosen.databaseSchemaField.name;
				df.tableID = chosen.inQueryTable.alias ?: chosen.inQueryTable.databaseSchemaTable.name;
				df.text = [NSString stringWithFormat:@"[%@.%@]", df.tableID ?: @"", df.fieldID ?: @""];
			}
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
	_canvasView.showGrid = !_canvasView.showGrid;
	[_canvasView setNeedsDisplay:YES];
}

- (void)toggleSnapAction:(__unused id)sender {
	_canvasView.snapToGrid = !_canvasView.snapToGrid;
}

- (void)toggleRulersAction:(__unused id)sender {
	_canvasView.showRulers = !_canvasView.showRulers;
	[_canvasView setNeedsDisplay:YES];
}

- (void)toggleGridFromMenu:(__unused id)sender { [self toggleGridAction:sender]; }
- (void)toggleSnapFromMenu:(__unused id)sender { [self toggleSnapAction:sender]; }
- (void)toggleRulersFromMenu:(__unused id)sender { [self toggleRulersAction:sender]; }

- (BOOL)gridVisible { return _canvasView.showGrid; }
- (BOOL)snapEnabled { return _canvasView.snapToGrid; }
- (BOOL)rulersVisible { return _canvasView.showRulers; }

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

- (void)zoomInAction:(nullable id)sender {
	_zoomSlider.doubleValue = MIN(2.0, _canvasView.zoomScale * 1.25);
	[self zoomSliderChanged:sender];
}

- (void)zoomOutAction:(nullable id)sender {
	_zoomSlider.doubleValue = MAX(0.5, _canvasView.zoomScale / 1.25);
	[self zoomSliderChanged:sender];
}

- (void)zoomActualSizeAction:(nullable id)sender {
	[self resetZoomAction:sender];
}

#pragma mark - Sidebars & Minimap

- (BOOL)leftSidebarVisible { return !_leftSidebarHidden; }
- (BOOL)inspectorVisible { return !_inspectorHidden; }
- (BOOL)minimapVisible { return !_minimapHidden; }

- (void)toggleLeftSidebarAction:(nullable id) __unused sender {
	_leftSidebarHidden = !_leftSidebarHidden;
	_leftSidebarView.hidden = _leftSidebarHidden;
	[self splitView:_mainSplitView resizeSubviewsWithOldSize:_mainSplitView.bounds.size];
}

- (void)toggleInspectorAction:(nullable id) __unused sender {
	_inspectorHidden = !_inspectorHidden;
	_rightInspectorContainerView.hidden = _inspectorHidden;
	[self splitView:_mainSplitView resizeSubviewsWithOldSize:_mainSplitView.bounds.size];
}

- (void)toggleMinimapAction:(nullable id) __unused sender {
	_minimapHidden = !_minimapHidden;
	_minimapView.hidden = _minimapHidden;
	for (NSView *view in _leftSidebarView.subviews) {
		if (view.tag == 0x4D4150) {	// "MAP": the minimap headings and hint
			view.hidden = _minimapHidden;
		}
	}
}

- (void)toggleLeftSidebarFromMenu:(nullable id)sender { [self toggleLeftSidebarAction:sender]; }
- (void)toggleInspectorFromMenu:(nullable id)sender { [self toggleInspectorAction:sender]; }
- (void)toggleMinimapFromMenu:(nullable id)sender { [self toggleMinimapAction:sender]; }

#pragma mark - Insert & Selection Commands

- (BOOL)canInsertElement {
	return [_canvasView orderedSections].count > 0;
}

- (NSUInteger)selectedElementCount {
	return _canvasView.selectedElements.count;
}

- (void)insertElementFromMenu:(NSMenuItem *)sender {
	switch ((MADMacPaletteElementKind)sender.tag) {
		case MADMacPaletteElementKindLabel: [self addStaticLabelAction:sender]; break;
		case MADMacPaletteElementKindDataField: [self addDataFieldAction:sender]; break;
		case MADMacPaletteElementKindAggregate: [self addAggregateAction:sender]; break;
		case MADMacPaletteElementKindImage: [self addImageAction:sender]; break;
		case MADMacPaletteElementKindBarcode: [self addBarcodeAction:sender]; break;
		case MADMacPaletteElementKindLineRule: [self addLineRuleAction:sender]; break;
		default: break;
	}
}

- (void)alignSelectedElementsWithMode:(NSInteger)mode {
	NSArray<RptqDocumentElement *> *selected = _canvasView.selectedElements.array;
	if (selected.count < 2) return;
	NSSegmentedControl *sender = [[NSSegmentedControl alloc] initWithFrame:NSZeroRect];
	sender.segmentCount = 6;
	sender.selectedSegment = mode;
	[self quickAlignToolbarAction:sender];
}

- (BOOL)canvasIsFocusRelated {
	NSResponder *responder = self.view.window.firstResponder;
	while (responder != nil) {
		if (responder == _canvasView) return YES;
		if (responder == self.view) break;
		responder = responder.nextResponder;
	}
	return NO;
}

- (void)selectAllElementsAction:(__unused id)sender {
	[_canvasView selectAllElementsInSelectedSection];
}

- (void)copySelectedElementsAction:(__unused id)sender {
	NSArray<RptqDocumentElement *> *selected = _canvasView.selectedElements.array;
	if (selected.count == 0) return;
	sElementClipboard = [selected mutableCopy];
	sElementClipboardDocument = self.madDocument;
}

- (void)cutSelectedElementsAction:(id)sender {
	if (_canvasView.selectedElements.count == 0) return;
	[self copySelectedElementsAction:sender];
	[self deleteSelectedElementsAction:sender];
}

- (BOOL)canPasteElements {
	return sElementClipboard.count > 0 && sElementClipboardDocument == self.madDocument && sElementClipboardDocument != nil;
}

- (void)pasteElementsAction:(__unused id)sender {
	if (![self canPasteElements]) return;
	RptqDocumentSection *section = [self ensureSelectedSection];
	if (section == nil) return;
	NSMutableOrderedSet<RptqDocumentElement *> *newSelection = [NSMutableOrderedSet orderedSet];
	for (RptqDocumentElement *source in sElementClipboard) {
		if (source.inSectionRow == nil) continue;
		NSRect rect = [_canvasView elementRectInSectionContent:source];
		NSPoint origin = NSMakePoint(rect.origin.x + 16.0, rect.origin.y + 12.0);
		RptqDocumentElement *copy = [self cloneElement:source intoSection:section atPoint:origin];
		if (copy != nil) [newSelection addObject:copy];
	}
	if (newSelection.count > 0) {
		[_canvasView setSelectedElementsSet:newSelection];
	}
}

- (void)toggleBoldStyleAction:(__unused id)sender {
	if (_canvasView.selectedElements.count == 0) return;
	_boldCheck.state = (_boldCheck.state == NSControlStateValueOn) ? NSControlStateValueOff : NSControlStateValueOn;
	[self typographyChanged:sender];
}

- (void)toggleItalicStyleAction:(__unused id)sender {
	if (_canvasView.selectedElements.count == 0) return;
	_italicCheck.state = (_italicCheck.state == NSControlStateValueOn) ? NSControlStateValueOff : NSControlStateValueOn;
	[self typographyChanged:sender];
}

- (void)toggleUnderlineStyleAction:(__unused id)sender {
	if (_canvasView.selectedElements.count == 0) return;
	_underlineCheck.state = (_underlineCheck.state == NSControlStateValueOn) ? NSControlStateValueOff : NSControlStateValueOn;
	[self typographyChanged:sender];
}

#pragma mark Standard Responder Actions

- (void)copy:(nullable id)sender {
	if ([self canvasIsFocusRelated]) [self copySelectedElementsAction:sender];
}

- (void)cut:(nullable id)sender {
	if ([self canvasIsFocusRelated]) [self cutSelectedElementsAction:sender];
}

- (void)paste:(nullable id)sender {
	if ([self canvasIsFocusRelated]) [self pasteElementsAction:sender];
}

- (void)delete:(nullable id)sender {
	if ([self canvasIsFocusRelated]) [self deleteSelectedElementsAction:sender];
}

- (void)duplicate:(nullable id)sender {
	if ([self canvasIsFocusRelated]) [self duplicateSelectedElementsAction:sender];
}

- (void)selectAll:(nullable id)sender {
	if ([self canvasIsFocusRelated]) [self selectAllElementsAction:sender];
}

#pragma mark - Menu Validation

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	SEL action = menuItem.action;
	if (action == @selector(insertElementFromMenu:)) return [self canInsertElement];
	if (action == @selector(copy:) || action == @selector(cut:)) {
		return [self canvasIsFocusRelated] && self.selectedElementCount > 0;
	}
	if (action == @selector(paste:)) {
		return [self canvasIsFocusRelated] && [self canPasteElements];
	}
	if (action == @selector(delete:) || action == @selector(duplicate:)) {
		return [self canvasIsFocusRelated] && self.selectedElementCount > 0;
	}
	if (action == @selector(selectAll:)) return [self canvasIsFocusRelated];
	if (action == @selector(toggleGridFromMenu:)) {
		menuItem.state = self.gridVisible ? NSControlStateValueOn : NSControlStateValueOff;
		return YES;
	}
	if (action == @selector(toggleSnapFromMenu:)) {
		menuItem.state = self.snapEnabled ? NSControlStateValueOn : NSControlStateValueOff;
		return YES;
	}
	if (action == @selector(toggleRulersFromMenu:)) {
		menuItem.state = self.rulersVisible ? NSControlStateValueOn : NSControlStateValueOff;
		return YES;
	}
	if (action == @selector(toggleMinimapFromMenu:)) {
		menuItem.state = self.minimapVisible ? NSControlStateValueOn : NSControlStateValueOff;
		return YES;
	}
	if (action == @selector(toggleLeftSidebarFromMenu:)) {
		menuItem.state = self.leftSidebarVisible ? NSControlStateValueOn : NSControlStateValueOff;
		return YES;
	}
	if (action == @selector(toggleInspectorFromMenu:)) {
		menuItem.state = self.inspectorVisible ? NSControlStateValueOn : NSControlStateValueOff;
		return YES;
	}
	return YES;
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
			[um setActionName:NSLocalizedString(@"Move / Resize Element", @"Undo action name for moving or resizing an element.")];
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
			[um setActionName:NSLocalizedString(@"Move Element to Section", @"Undo action name for moving an element to another band.")];
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
			[um setActionName:NSLocalizedString(@"Resize Section", @"Undo action name for resizing a band.")];
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
			[um setActionName:NSLocalizedString(@"Edit Label Text", @"Undo action name for editing a label text.")];
		}
	}
	[doc notifyDocumentMutated];
	[_canvasView setNeedsDisplay:YES];
	[self syncInspectorFromSelection];
}

- (NSMenuItem *)contextItemWithTitle:(NSString *)title action:(SEL)action symbol:(NSString *)symbol {
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:@""];
	item.target = self;
	if (@available(macOS 11.0, *)) {
		NSImage *image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:title];
		if (image != nil) item.image = image;
	}
	return item;
}

- (NSMenu *)insertContextSubmenu {
	NSMenu *menu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Insert", @"Context submenu title for inserting elements.")];
	NSArray<NSArray *> *rows = @[
		@[NSLocalizedString(@"Static Label", @"Context menu item that inserts a static label."), @"textformat", @(MADMacPaletteElementKindLabel)],
		@[NSLocalizedString(@"Data Field", @"Context menu item that inserts a data field."), @"tablecells", @(MADMacPaletteElementKindDataField)],
		@[NSLocalizedString(@"Aggregate", @"Context menu item that inserts an aggregate."), @"sum", @(MADMacPaletteElementKindAggregate)],
		@[NSLocalizedString(@"Image", @"Context menu item that inserts an image."), @"photo", @(MADMacPaletteElementKindImage)],
		@[NSLocalizedString(@"Barcode", @"Context menu item that inserts a barcode."), @"barcode", @(MADMacPaletteElementKindBarcode)],
		@[NSLocalizedString(@"Horizontal Rule", @"Context menu item that inserts a horizontal rule."), @"minus", @(MADMacPaletteElementKindLineRule)],
	];
	for (NSUInteger i = 0; i < rows.count; i++) {
		if (i == 3) [menu addItem:[NSMenuItem separatorItem]];
		NSMenuItem *item = [self contextItemWithTitle:rows[i][0] action:@selector(insertElementFromMenu:) symbol:rows[i][1]];
		item.tag = [rows[i][2] integerValue];
		item.keyEquivalent = [NSString stringWithFormat:@"%ld", (long)item.tag];
		item.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagOption;
		item.toolTip = rows[i][0];
		[menu addItem:item];
	}
	menu.autoenablesItems = YES;
	return menu;
}

- (NSMenu *)buildContextMenuForElement:(nullable RptqDocumentElement *)element
							 inSection:(nullable RptqDocumentSection *)section {
	NSMenu *menu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Designer Context Menu", @"Title of the designer canvas context menu. Never shown to the user.")];
	menu.autoenablesItems = YES;

	NSMenuItem *insertParent = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Insert", @"Context submenu title for inserting elements.") action:nil keyEquivalent:@""];
	insertParent.submenu = [self insertContextSubmenu];
	[menu addItem:insertParent];

	if (element != nil) {
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItem:[self contextItemWithTitle:NSLocalizedString(@"Cut", @"Context menu item that cuts the selection.") action:@selector(cutSelectedElementsAction:) symbol:@"scissors"]];
		[menu addItem:[self contextItemWithTitle:NSLocalizedString(@"Copy", @"Context menu item that copies the selection.") action:@selector(copySelectedElementsAction:) symbol:@"doc.on.doc"]];
		[menu addItem:[self contextItemWithTitle:NSLocalizedString(@"Duplicate", @"Context menu item that duplicates the selection.") action:@selector(duplicateSelectedElementsAction:) symbol:@"plus.square.on.square"]];
		[menu addItem:[self contextItemWithTitle:NSLocalizedString(@"Delete", @"Context menu item that deletes the selection.") action:@selector(deleteSelectedElementsAction:) symbol:@"trash"]];
		[menu addItem:[NSMenuItem separatorItem]];
		[menu addItem:[self contextItemWithTitle:NSLocalizedString(@"Size to Fit Content", @"Context menu item that resizes the element to its text.") action:@selector(sizeSelectedElementsToFitAction:) symbol:@"arrow.up.left.and.arrow.down.right"]];

		NSMenuItem *alignParent = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Align", @"Context submenu title for aligning the selected elements.") action:nil keyEquivalent:@""];
		NSMenu *alignMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Align", @"Context submenu title for aligning the selected elements.")];
		NSArray<NSArray *> *alignRows = @[
			@[NSLocalizedString(@"Align Left", @"Context menu item that aligns selected elements to the left."), @"align.horizontal.left", @0],
			@[NSLocalizedString(@"Align Center", @"Context menu item that centers selected elements horizontally."), @"align.horizontal.center", @1],
			@[NSLocalizedString(@"Align Right", @"Context menu item that aligns selected elements to the right."), @"align.horizontal.right", @2],
			@[NSLocalizedString(@"Align Top", @"Context menu item that aligns selected elements to the top."), @"align.vertical.top", @3],
			@[NSLocalizedString(@"Align Middle", @"Context menu item that centers selected elements vertically."), @"align.vertical.center", @4],
			@[NSLocalizedString(@"Align Bottom", @"Context menu item that aligns selected elements to the bottom."), @"align.vertical.bottom", @5],
		];
		for (NSArray *row in alignRows) {
			NSMenuItem *item = [self contextItemWithTitle:row[0] action:@selector(contextMenuAlignAction:) symbol:row[1]];
			item.tag = [row[2] integerValue];
			[alignMenu addItem:item];
		}
		alignParent.submenu = alignMenu;
		[menu addItem:alignParent];

		NSMenuItem *moveItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Move to Band", @"Context submenu title that moves the element to another band.") action:nil keyEquivalent:@""];
		NSMenu *moveSubmenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Move to Band", @"Context submenu title that moves the element to another band.")];
		NSArray<RptqDocumentSection *> *sections = [_canvasView orderedSections];
		RptqDocumentSection *curSec = [_canvasView sectionContainingElement:element];
		MADMacDocument *doc = self.madDocument;
		for (NSUInteger i = 0; i < sections.count; i++) {
			RptqDocumentSection *sec = sections[i];
			NSString *secTitle = doc ? [doc displayTitleForSection:sec] : ([sec localizedDisplayName] ?: NSLocalizedString(@"Section", @"Generic report band name."));
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
	}

	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItem:[self contextItemWithTitle:NSLocalizedString(@"Select All Elements", @"Context menu item that selects every element in the band.") action:@selector(selectAllElementsAction:) symbol:@"rectangle.dashed"]];
	[menu addItem:[self contextItemWithTitle:NSLocalizedString(@"Fit Band Height to Elements", @"Context menu item that fits the band height to its elements.") action:@selector(autoFitSelectedSectionHeightAction:) symbol:@"arrow.up.and.down"]];

	return menu;
}

- (void)designerCanvas:(__unused MADMacDesignerCanvasView *)canvasView
	requestContextMenuForElement:(nullable RptqDocumentElement *)element
					   inSection:(nullable RptqDocumentSection *)section
					   withEvent:(NSEvent *)event {
	if (element == nil && section != nil) {
		_canvasView.selectedSection = section;
	}
	NSMenu *menu = [self buildContextMenuForElement:element inSection:section];
	[NSMenu popUpContextMenu:menu withEvent:event forView:_canvasView];
}

- (void)contextMenuAlignAction:(NSMenuItem *)sender {
	[self alignSelectedElementsWithMode:sender.tag];
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
