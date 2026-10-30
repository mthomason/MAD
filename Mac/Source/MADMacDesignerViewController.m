//
//  MADMacDesignerViewController.m
//  MAD Designer (macOS)
//
//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT
//

#import "MADMacDesignerViewController.h"
#import "MADMacDesignerCanvasView.h"
#import "MADMacDocument.h"

#import <MAD/MAD.h>
#import <MADBarcodes/MADBarcodes.h>

@interface MADMacDesignerViewController () <NSTableViewDataSource, NSTableViewDelegate, MADMacDesignerCanvasViewDelegate>

@property (nonatomic, strong) NSTableView *sectionsTableView;
@property (nonatomic, strong) MADMacDesignerCanvasView *canvasView;
@property (nonatomic, strong) NSSlider *zoomSlider;
@property (nonatomic, strong) NSTextField *zoomLabel;

// Section Inspector Controls
@property (nonatomic, strong) NSTextField *sectionHeightField;
@property (nonatomic, strong) NSButton *sectionVisibleCheckbox;
@property (nonatomic, strong) NSButton *sectionFormFeedCheckbox;

// Element Inspector Controls
@property (nonatomic, strong) NSTextField *elementSummaryLabel;
@property (nonatomic, strong) NSTextField *posXField;
@property (nonatomic, strong) NSTextField *posYField;
@property (nonatomic, strong) NSTextField *widthField;
@property (nonatomic, strong) NSTextField *heightField;

@property (nonatomic, strong) NSPopUpButton *fontFamilyPopup;
@property (nonatomic, strong) NSTextField *fontSizeField;
@property (nonatomic, strong) NSButton *boldCheckbox;
@property (nonatomic, strong) NSButton *italicCheckbox;
@property (nonatomic, strong) NSButton *underlineCheckbox;
@property (nonatomic, strong) NSButton *strikethroughCheckbox;

@property (nonatomic, strong) NSPopUpButton *horizAlignPopup;
@property (nonatomic, strong) NSPopUpButton *vertAlignPopup;

@property (nonatomic, strong) NSColorWell *foregroundColorWell;
@property (nonatomic, strong) NSColorWell *backgroundColorWell;
@property (nonatomic, strong) NSTextField *borderWidthField;

@property (nonatomic, strong) NSTextField *staticTextField;
@property (nonatomic, strong) NSPopUpButton *queryFieldPopup;
@property (nonatomic, strong) NSPopUpButton *aggregateFuncPopup;
@property (nonatomic, strong) NSPopUpButton *barcodeSymbologyPopup;

@property (nonatomic, copy) NSArray<RptqDocumentSection *> *sections;
@property (nonatomic, copy) NSArray<RptqQueryField *> *availableQueryFields;
@property (nonatomic, assign) BOOL updatingInspector;

@end

@implementation MADMacDesignerViewController

- (instancetype)initWithDocument:(MADMacDocument *)document {
	if (self = [super initWithNibName:nil bundle:nil]) {
		_document = document;
		_sections = @[];
		_availableQueryFields = @[];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView {
	NSSplitView *split = [[NSSplitView alloc] initWithFrame:NSMakeRect(0, 0, 1200, 740)];
	split.vertical = YES;
	split.dividerStyle = NSSplitViewDividerStyleThin;
	split.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

	NSView *leftSidebar = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 240, 740)];
	NSScrollView *centerScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 680, 740)];
	centerScroll.hasVerticalScroller = YES;
	centerScroll.hasHorizontalScroller = YES;
	centerScroll.borderType = NSNoBorder;
	centerScroll.backgroundColor = [NSColor underPageBackgroundColor];

	_canvasView = [[MADMacDesignerCanvasView alloc] initWithFrame:NSMakeRect(0, 0, 680, 900)];
	_canvasView.document = _document;
	_canvasView.delegate = self;
	centerScroll.documentView = _canvasView;

	NSView *rightInspector = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 280, 740)];

	[self populateLeftSidebar:leftSidebar];
	[self populateRightInspector:rightInspector];

	[split addSubview:leftSidebar];
	[split addSubview:centerScroll];
	[split addSubview:rightInspector];
	[split adjustSubviews];
	[split setPosition:240 ofDividerAtIndex:0];
	[split setPosition:910 ofDividerAtIndex:1];

	self.view = split;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleDocumentNotification:)
												 name:MADMacDocumentDidMutateNotification
											   object:_document];
	[self reloadFromDocument];
}

- (void)handleDocumentNotification:(NSNotification *) __unused note {
	[self reloadFromDocument];
}

- (void)populateLeftSidebar:(NSView *)container {
	NSTextField *secHeader = [NSTextField labelWithString:@"Report Sections"];
	secHeader.font = [NSFont boldSystemFontOfSize:12.5];

	_sectionsTableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 210, 210)];
	_sectionsTableView.usesAlternatingRowBackgroundColors = YES;
	_sectionsTableView.rowHeight = 22.0;
	_sectionsTableView.delegate = self;
	_sectionsTableView.dataSource = self;
	NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:@"section"];
	col.title = @"Section";
	col.width = 200.0;
	[_sectionsTableView addTableColumn:col];

	NSScrollView *secScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 216, 210)];
	secScroll.hasVerticalScroller = YES;
	secScroll.borderType = NSBezelBorder;
	secScroll.documentView = _sectionsTableView;
	[secScroll.heightAnchor constraintEqualToConstant:210].active = YES;

	NSTextField *paletteHeader = [NSTextField labelWithString:@"Insert Element in Section"];
	paletteHeader.font = [NSFont boldSystemFontOfSize:12.5];

	NSButton *btnLabel = [NSButton buttonWithTitle:@"+ Static Label" target:self action:@selector(addStaticLabelElement:)];
	NSButton *btnField = [NSButton buttonWithTitle:@"+ Data Field" target:self action:@selector(addDataFieldElement:)];
	NSButton *btnAgg = [NSButton buttonWithTitle:@"+ Aggregate Function" target:self action:@selector(addAggregateElement:)];
	NSButton *btnBarcode = [NSButton buttonWithTitle:@"+ Barcode (Zint)" target:self action:@selector(addBarcodeElement:)];
	NSButton *btnImage = [NSButton buttonWithTitle:@"+ Image…" target:self action:@selector(addImageElement:)];
	NSButton *btnDelete = [NSButton buttonWithTitle:@"Delete Selected Element" target:self action:@selector(deleteSelectedElements:)];

	_zoomLabel = [NSTextField labelWithString:@"Canvas Zoom: 100%"];
	_zoomLabel.font = [NSFont systemFontOfSize:11.5];
	_zoomSlider = [NSSlider sliderWithValue:100.0 minValue:50.0 maxValue:200.0 target:self action:@selector(zoomSliderChanged:)];

	NSStackView *stack = [NSStackView stackViewWithViews:@[
		secHeader, secScroll,
		paletteHeader, btnLabel, btnField, btnAgg, btnBarcode, btnImage, btnDelete,
		_zoomLabel, _zoomSlider
	]];
	stack.orientation = NSUserInterfaceLayoutOrientationVertical;
	stack.alignment = NSLayoutAttributeLeading;
	stack.spacing = 8.0;
	stack.translatesAutoresizingMaskIntoConstraints = NO;

	[container addSubview:stack];
	[NSLayoutConstraint activateConstraints:@[
		[stack.topAnchor constraintEqualToAnchor:container.topAnchor constant:12],
		[stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],
		[stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-12],
	]];
}

- (NSStackView *)labeledRow:(NSString *)title control:(NSView *)control {
	NSTextField *lbl = [NSTextField labelWithString:title];
	lbl.font = [NSFont systemFontOfSize:11.5];
	[lbl.widthAnchor constraintEqualToConstant:92].active = YES;
	NSStackView *row = [NSStackView stackViewWithViews:@[lbl, control]];
	row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
	row.spacing = 6.0;
	return row;
}

- (void)populateRightInspector:(NSView *)container {
	// Section properties
	NSTextField *secHeader = [NSTextField labelWithString:@"Selected Section"];
	secHeader.font = [NSFont boldSystemFontOfSize:12.5];

	_sectionHeightField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 80, 22)];
	_sectionHeightField.target = self;
	_sectionHeightField.action = @selector(sectionInspectorEdited:);

	_sectionVisibleCheckbox = [NSButton checkboxWithTitle:@"Section Visible" target:self action:@selector(sectionInspectorEdited:)];
	_sectionFormFeedCheckbox = [NSButton checkboxWithTitle:@"Page Break After Section" target:self action:@selector(sectionInspectorEdited:)];

	// Element properties
	NSTextField *elemHeader = [NSTextField labelWithString:@"Selected Element Inspector"];
	elemHeader.font = [NSFont boldSystemFontOfSize:12.5];

	_elementSummaryLabel = [NSTextField labelWithString:@"No element selected"];
	_elementSummaryLabel.font = [NSFont systemFontOfSize:11.5];
	_elementSummaryLabel.textColor = [NSColor secondaryLabelColor];

	_posXField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 64, 22)];
	_posXField.target = self;
	_posXField.action = @selector(elementGeometryEdited:);
	_posYField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 64, 22)];
	_posYField.target = self;
	_posYField.action = @selector(elementGeometryEdited:);
	_widthField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 64, 22)];
	_widthField.target = self;
	_widthField.action = @selector(elementGeometryEdited:);
	_heightField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 64, 22)];
	_heightField.target = self;
	_heightField.action = @selector(elementGeometryEdited:);

	_fontFamilyPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 150, 24) pullsDown:NO];
	[_fontFamilyPopup addItemsWithTitles:@[@"Helvetica", @"Helvetica Neue", @"Courier", @"Times New Roman", @"Arial", @"Menlo", @"Georgia"]];
	_fontFamilyPopup.target = self;
	_fontFamilyPopup.action = @selector(elementStyleEdited:);

	_fontSizeField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 64, 22)];
	_fontSizeField.target = self;
	_fontSizeField.action = @selector(elementStyleEdited:);

	_boldCheckbox = [NSButton checkboxWithTitle:@"Bold" target:self action:@selector(elementStyleEdited:)];
	_italicCheckbox = [NSButton checkboxWithTitle:@"Italic" target:self action:@selector(elementStyleEdited:)];
	_underlineCheckbox = [NSButton checkboxWithTitle:@"Underline" target:self action:@selector(elementStyleEdited:)];
	_strikethroughCheckbox = [NSButton checkboxWithTitle:@"Strike" target:self action:@selector(elementStyleEdited:)];
	NSStackView *traitsRow1 = [NSStackView stackViewWithViews:@[_boldCheckbox, _italicCheckbox]];
	NSStackView *traitsRow2 = [NSStackView stackViewWithViews:@[_underlineCheckbox, _strikethroughCheckbox]];

	_horizAlignPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 140, 24) pullsDown:NO];
	[_horizAlignPopup addItemsWithTitles:@[@"Left", @"Center", @"Right", @"Justified"]];
	_horizAlignPopup.target = self;
	_horizAlignPopup.action = @selector(elementStyleEdited:);

	_vertAlignPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 140, 24) pullsDown:NO];
	[_vertAlignPopup addItemsWithTitles:@[@"Top", @"Middle", @"Bottom"]];
	_vertAlignPopup.target = self;
	_vertAlignPopup.action = @selector(elementStyleEdited:);

	_foregroundColorWell = [[NSColorWell alloc] initWithFrame:NSMakeRect(0, 0, 48, 24)];
	_foregroundColorWell.target = self;
	_foregroundColorWell.action = @selector(elementColorEdited:);
	[_foregroundColorWell.widthAnchor constraintEqualToConstant:52].active = YES;

	_backgroundColorWell = [[NSColorWell alloc] initWithFrame:NSMakeRect(0, 0, 48, 24)];
	_backgroundColorWell.target = self;
	_backgroundColorWell.action = @selector(elementColorEdited:);
	[_backgroundColorWell.widthAnchor constraintEqualToConstant:52].active = YES;

	_borderWidthField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 64, 22)];
	_borderWidthField.target = self;
	_borderWidthField.action = @selector(elementStyleEdited:);

	_staticTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 150, 22)];
	_staticTextField.placeholderString = @"Label / Barcode text";
	_staticTextField.target = self;
	_staticTextField.action = @selector(elementDataBindingEdited:);

	_queryFieldPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 150, 24) pullsDown:NO];
	_queryFieldPopup.target = self;
	_queryFieldPopup.action = @selector(elementDataBindingEdited:);

	_aggregateFuncPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 150, 24) pullsDown:NO];
	[_aggregateFuncPopup addItemsWithTitles:@[@"SUM", @"MEAN (AVG)", @"COUNT", @"FIRST", @"LAST", @"MIN", @"MAX"]];
	_aggregateFuncPopup.target = self;
	_aggregateFuncPopup.action = @selector(elementDataBindingEdited:);

	_barcodeSymbologyPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 150, 24) pullsDown:NO];
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
	_barcodeSymbologyPopup.action = @selector(elementDataBindingEdited:);

	NSStackView *stack = [NSStackView stackViewWithViews:@[
		secHeader,
		[self labeledRow:@"Height (pt):" control:_sectionHeightField],
		_sectionVisibleCheckbox,
		_sectionFormFeedCheckbox,
		elemHeader,
		_elementSummaryLabel,
		[self labeledRow:@"X (pt):" control:_posXField],
		[self labeledRow:@"Y (pt):" control:_posYField],
		[self labeledRow:@"Width (pt):" control:_widthField],
		[self labeledRow:@"Height (pt):" control:_heightField],
		[self labeledRow:@"Font Family:" control:_fontFamilyPopup],
		[self labeledRow:@"Font Size:" control:_fontSizeField],
		traitsRow1,
		traitsRow2,
		[self labeledRow:@"Horiz Align:" control:_horizAlignPopup],
		[self labeledRow:@"Vert Align:" control:_vertAlignPopup],
		[self labeledRow:@"Text Color:" control:_foregroundColorWell],
		[self labeledRow:@"Fill Color:" control:_backgroundColorWell],
		[self labeledRow:@"Border (pt):" control:_borderWidthField],
		[self labeledRow:@"Text / Value:" control:_staticTextField],
		[self labeledRow:@"Query Field:" control:_queryFieldPopup],
		[self labeledRow:@"Aggregate:" control:_aggregateFuncPopup],
		[self labeledRow:@"Symbology:" control:_barcodeSymbologyPopup],
	]];
	stack.orientation = NSUserInterfaceLayoutOrientationVertical;
	stack.alignment = NSLayoutAttributeLeading;
	stack.spacing = 6.0;
	stack.translatesAutoresizingMaskIntoConstraints = NO;

	[container addSubview:stack];
	[NSLayoutConstraint activateConstraints:@[
		[stack.topAnchor constraintEqualToAnchor:container.topAnchor constant:12],
		[stack.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:12],
		[stack.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-12],
	]];
}

#pragma mark - Reload & Sync

- (void)reloadFromDocument {
	_sections = [_document orderedSections] ?: @[];	// Weak instance variable '_document' is accessed multiple times in this method but may be unpredictably set to nil; assign to a strong variable to keep the object alive

	NSMutableArray<RptqQueryField *> *qFields = [[NSMutableArray alloc] init];
	for (RptqQueryTable *qt in _document.rptqQuery.hasQueryTables) {
		for (RptqQueryField *qf in qt.hasQueryFields) {
			[qFields addObject:qf];
		}
	}
	_availableQueryFields = qFields;

	[_queryFieldPopup removeAllItems];
	[_queryFieldPopup addItemWithTitle:@"(None)"];
	_queryFieldPopup.lastItem.tag = 0;
	for (RptqQueryField *qf in _availableQueryFields) {
		NSString *title = [NSString stringWithFormat:@"%@.%@",
						   qf.inQueryTable.alias ?: qf.inQueryTable.databaseSchemaTable.name ?: @"",
						   qf.databaseSchemaField.name ?: @""];
		[_queryFieldPopup addItemWithTitle:title];
		_queryFieldPopup.lastItem.tag = (NSInteger)qf.identifier;
	}

	[_sectionsTableView reloadData];
	[_canvasView recalculateCanvasFrame];
	[_canvasView setNeedsDisplay:YES];
	[self syncInspectorFromSelection];
}

- (void)syncInspectorFromSelection {
	_updatingInspector = YES;

	RptqDocumentSection *sec = _canvasView.selectedSection;
	if (sec != nil) {
		CGFloat h = sec.layoutHeight > 0 ? (CGFloat)sec.layoutHeight : MAX(36.0, (CGFloat)sec.height - 44.0);
		_sectionHeightField.stringValue = [NSString stringWithFormat:@"%.0f", h];
		_sectionVisibleCheckbox.state = sec.visibility ? NSControlStateValueOn : NSControlStateValueOff;
		_sectionFormFeedCheckbox.state = [sec producesFormFeed] ? NSControlStateValueOn : NSControlStateValueOff;
	}

	RptqDocumentElement *el = [_canvasView primarySelectedElement];
	BOOL hasEl = (el != nil);
	_posXField.enabled = hasEl;
	_posYField.enabled = hasEl;
	_widthField.enabled = hasEl;
	_heightField.enabled = hasEl;
	_fontFamilyPopup.enabled = hasEl;
	_fontSizeField.enabled = hasEl;
	_boldCheckbox.enabled = hasEl;
	_italicCheckbox.enabled = hasEl;
	_underlineCheckbox.enabled = hasEl;
	_strikethroughCheckbox.enabled = hasEl;
	_horizAlignPopup.enabled = hasEl;
	_vertAlignPopup.enabled = hasEl;
	_foregroundColorWell.enabled = hasEl;
	_backgroundColorWell.enabled = hasEl;
	_borderWidthField.enabled = hasEl;
	_staticTextField.enabled = hasEl;
	_queryFieldPopup.enabled = hasEl;
	_aggregateFuncPopup.enabled = [el isKindOfClass:[RptqDocumentElementAggregate class]];
	_barcodeSymbologyPopup.enabled = [el isKindOfClass:[RptqDocumentElementBarcode class]];

	if (!hasEl) {
		_elementSummaryLabel.stringValue = @"No element selected";
		_updatingInspector = NO;
		return;
	}

	_elementSummaryLabel.stringValue = [NSString stringWithFormat:@"%@ (#%lld)", NSStringFromClass([el class]), el.identifier];
	_posXField.stringValue = [NSString stringWithFormat:@"%.0f", el.dropPoint.x];
	_posYField.stringValue = [NSString stringWithFormat:@"%.0f", el.dropPoint.y];
	_widthField.stringValue = [NSString stringWithFormat:@"%.0f", MAX(32.0, el.rect.size.width)];
	_heightField.stringValue = [NSString stringWithFormat:@"%.0f", MAX(16.0, el.rect.size.height)];

	if (el.fontname.length > 0) {
		if ([_fontFamilyPopup itemWithTitle:el.fontname] == nil) {	// Warning: Implicit conversion from nullable pointer 'NSString * _Nullable' to non-nullable pointer type 'NSString * _Nonnull'
			[_fontFamilyPopup addItemWithTitle:el.fontname];	// Warning: Implicit conversion from nullable pointer 'NSString * _Nullable' to non-nullable pointer type 'NSString * _Nonnull'
		}
		[_fontFamilyPopup selectItemWithTitle:el.fontname];		// Warning: Implicit conversion from nullable pointer 'NSString * _Nullable' to non-nullable pointer type 'NSString * _Nonnull'
	}
	_fontSizeField.stringValue = [NSString stringWithFormat:@"%.1f", el.fontsize > 0 ? el.fontsize : 12.0];
	_boldCheckbox.state = el.textStyle.bold ? NSControlStateValueOn : NSControlStateValueOff;
	_italicCheckbox.state = el.textStyle.italic ? NSControlStateValueOn : NSControlStateValueOff;
	_underlineCheckbox.state = el.textStyle.underline ? NSControlStateValueOn : NSControlStateValueOff;
	_strikethroughCheckbox.state = el.textStyle.strikethrough ? NSControlStateValueOn : NSControlStateValueOff;

	[_horizAlignPopup selectItemAtIndex:MAX(0, MIN(3, (NSInteger)el.alignment.horizontal))];
	[_vertAlignPopup selectItemAtIndex:MAX(0, MIN(2, (NSInteger)el.alignment.vertical))];

	if ([el.foregroundColor isKindOfClass:[NSColor class]]) {
		_foregroundColorWell.color = (NSColor *)el.foregroundColor;
	} else {
		_foregroundColorWell.color = [NSColor blackColor];
	}
	if ([el.backgroundColor isKindOfClass:[NSColor class]]) {
		_backgroundColorWell.color = (NSColor *)el.backgroundColor;
	} else {
		_backgroundColorWell.color = [NSColor clearColor];
	}
	_borderWidthField.stringValue = [NSString stringWithFormat:@"%.1f", el.border.width.top];

	if ([el isKindOfClass:[RptqDocumentElementLabel class]]) {
		_staticTextField.stringValue = ((RptqDocumentElementLabel *)el).text ?: @"";
	} else if ([el isKindOfClass:[RptqDocumentElementBarcode class]]) {
		RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)el;
		_staticTextField.stringValue = bc.inputStatic1 ?: @"";
		[_barcodeSymbologyPopup selectItemWithTag:bc.barcodeType];
		[_queryFieldPopup selectItemWithTag:(NSInteger)bc.referencesField1.identifier];
	} else if ([el isKindOfClass:[RptqDocumentElementLabelDataField class]]) {
		RptqDocumentElementLabelDataField *df = (RptqDocumentElementLabelDataField *)el;
		_staticTextField.stringValue = df.text ?: @"";
		[_queryFieldPopup selectItemWithTag:(NSInteger)df.referencesQueryField.identifier];
	} else if ([el isKindOfClass:[RptqDocumentElementAggregate class]]) {
		RptqDocumentElementAggregate *agg = (RptqDocumentElementAggregate *)el;
		_staticTextField.stringValue = [agg designerRepresentationText] ?: @"";
		[_queryFieldPopup selectItemWithTag:(NSInteger)agg.aggregateField.identifier];
	}

	_updatingInspector = NO;
}

#pragma mark - Element Insertion Actions

- (nullable RptqDocumentSection *)targetSectionForInsertion {
	if (_canvasView.selectedSection != nil) return _canvasView.selectedSection;
	return _document.rptqDocument.hasDetailSection ?: _sections.firstObject;
}

- (void)ensureSectionHasRow:(RptqDocumentSection *)section {
	if (section.hasRows.count == 0) {
		RptqStoreContext *ctx = _document.managedObjectContext;
		RptqDocumentSectionRows *row = (RptqDocumentSectionRows *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentSectionRows class]) identifier:0];
		row.rowNumber = 0;
		row.inSection = section;
		[section addHasRowsFixed:row];
	}
}

- (void)addStaticLabelElement:(nullable id) __unused sender {
	RptqDocumentSection *section = [self targetSectionForInsertion];
	RptqStoreContext *ctx = _document.managedObjectContext;	// Warning: Weak instance variable '_document' is accessed multiple times in this method but may be unpredictably set to nil; assign to a strong variable to keep the object alive
	if (section == nil || ctx == nil) return;
	[self ensureSectionHasRow:section];

	RptqDocumentElementLabel *label = (RptqDocumentElementLabel *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabel class]) identifier:0];
	label.type = MADPrintPageElementTypeLabelStatic;
	label.text = @"Static Label";
	[label setSizeWidth:140.0f height:22.0f];
	[section addDocumentObject:label withDropPoint:CGPointMake(16.0, 10.0) managedObjectContext:ctx];

	[_document notifyDocumentMutated];
	[_canvasView selectElement:label inSection:section];
}

- (void)addDataFieldElement:(nullable id) __unused sender {
	RptqDocumentSection *section = [self targetSectionForInsertion];
	RptqStoreContext *ctx = _document.managedObjectContext;	// Warning: Weak instance variable '_document' is accessed multiple times in this method but may be unpredictably set to nil; assign to a strong variable to keep the object alive
	if (section == nil || ctx == nil) return;
	[self ensureSectionHasRow:section];

	RptqDocumentElementLabelDataField *df = (RptqDocumentElementLabelDataField *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementLabelDataField class]) identifier:0];
	df.type = MADPrintPageElementTypeLabelDynamic;
	RptqQueryField *firstField = _availableQueryFields.firstObject;
	if (firstField != nil) {
		df.referencesQueryField = firstField;
		df.fieldID = firstField.databaseSchemaField.name;
		df.tableID = firstField.inQueryTable.alias ?: firstField.inQueryTable.databaseSchemaTable.name;
		df.text = [NSString stringWithFormat:@"[%@.%@]", df.tableID ?: @"", df.fieldID ?: @""];
	} else {
		df.text = @"[Data Field]";
	}
	[df setSizeWidth:160.0f height:22.0f];
	[section addDocumentObject:df withDropPoint:CGPointMake(16.0, 10.0) managedObjectContext:ctx];

	[_document notifyDocumentMutated];
	[_canvasView selectElement:df inSection:section];
}

- (void)addAggregateElement:(nullable id) __unused sender {
	RptqDocumentSection *section = [self targetSectionForInsertion];
	RptqStoreContext *ctx = _document.managedObjectContext;		// Warning: Weak instance variable '_document' is accessed multiple times in this method but may be unpredictably set to nil; assign to a strong variable to keep the object alive
	if (section == nil || ctx == nil) return;
	[self ensureSectionHasRow:section];

	RptqDocumentElementAggregate *agg = (RptqDocumentElementAggregate *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementAggregate class]) identifier:0];
	agg.type = MADPrintPageElementTypeAggregate;
	RptqQueryField *firstField = _availableQueryFields.firstObject;
	[agg updateAggregateFunctionWithFunctionType:MTAggregateFunctionTypeCount
									   inputType:MTAggregateFunctionInputTypeField
									   groupType:MTAggregateGroupByTypeReport
							   aggregateObjectID:firstField ? firstField.identifier : 0
									 groupNumber:0];
	[agg setSizeWidth:140.0f height:22.0f];
	[section addDocumentObject:agg withDropPoint:CGPointMake(16.0, 10.0) managedObjectContext:ctx];

	[_document notifyDocumentMutated];
	[_canvasView selectElement:agg inSection:section];
}

- (void)addBarcodeElement:(nullable id) __unused sender {
	RptqDocumentSection *section = [self targetSectionForInsertion];
	RptqStoreContext *ctx = _document.managedObjectContext;		// Warning: Weak instance variable '_document' is accessed multiple times in this method but may be unpredictably set to nil; assign to a strong variable to keep the object alive
	if (section == nil || ctx == nil) return;
	[self ensureSectionHasRow:section];

	RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementBarcode class]) identifier:0];
	bc.type = MADPrintPageElementTypeBarcode;
	bc.barcodeType = (int16_t)MADBarcodeTypeCODE128;
	bc.humanReadable = YES;
	bc.useStaticInput1 = YES;
	bc.inputStatic1 = @"MAD-2026";
	bc.scale = 1.0f;
	bc.barcodeHeight = 40;
	[bc setSizeWidth:180.0f height:56.0f];
	[section addDocumentObject:bc withDropPoint:CGPointMake(16.0, 10.0) managedObjectContext:ctx];

	[_document notifyDocumentMutated];
	[_canvasView selectElement:bc inSection:section];
}

- (void)addImageElement:(nullable id) __unused sender {
	RptqDocumentSection *section = [self targetSectionForInsertion];
	RptqStoreContext *ctx = _document.managedObjectContext;		// Warning: Weak instance variable '_document' is accessed multiple times in this method but may be unpredictably set to nil; assign to a strong variable to keep the object alive
	if (section == nil || ctx == nil) return;

	NSOpenPanel *panel = [NSOpenPanel openPanel];
	panel.title = @"Choose Image for Report Element";
	panel.canChooseFiles = YES;
	panel.canChooseDirectories = NO;
	if ([panel runModal] != NSModalResponseOK || panel.URL == nil) return;

	NSImage *image = [[NSImage alloc] initWithContentsOfURL:panel.URL];		// Warning: Implicit conversion from nullable pointer 'NSURL * _Nullable' to non-nullable pointer type 'NSURL * _Nonnull'
	if (image == nil) return;

	[self ensureSectionHasRow:section];
	RptqDocumentElementImage *imgEl = (RptqDocumentElementImage *)[ctx insertObjectForEntity:NSStringFromClass([RptqDocumentElementImage class]) identifier:0];
	imgEl.type = MADPrintPageElementTypeImage;
	imgEl.image = image;
	[imgEl setSizeWidth:120.0f height:80.0f];
	[section addDocumentObject:imgEl withDropPoint:CGPointMake(16.0, 10.0) managedObjectContext:ctx];

	[_document notifyDocumentMutated];
	[_canvasView selectElement:imgEl inSection:section];
}

- (void)deleteSelectedElements:(nullable id)sender {
	[_canvasView deleteSelectedElements:sender];
}

#pragma mark - Inspector Edit Handlers

- (void)zoomSliderChanged:(id) __unused sender {
	CGFloat pct = _zoomSlider.doubleValue;
	_zoomLabel.stringValue = [NSString stringWithFormat:@"Canvas Zoom: %.0f%%", pct];
	_canvasView.zoomScale = pct / 100.0;
}

- (void)sectionInspectorEdited:(id) __unused sender {
	if (_updatingInspector) return;
	RptqDocumentSection *sec = _canvasView.selectedSection;
	if (sec == nil) return;

	double newH = MAX(24.0, _sectionHeightField.doubleValue);
	[sec setInterfaceHeight:newH];
	sec.visibility = (_sectionVisibleCheckbox.state == NSControlStateValueOn);
	[sec setProducesFormFeed:(_sectionFormFeedCheckbox.state == NSControlStateValueOn)];
	[_document notifyDocumentMutated];
}

- (void)elementGeometryEdited:(id) __unused sender {
	if (_updatingInspector) return;
	RptqDocumentElement *el = [_canvasView primarySelectedElement];
	if (el == nil) return;

	[el setOriginPoint:CGPointMake(MAX(0.0, _posXField.doubleValue), MAX(0.0, _posYField.doubleValue))];
	NSSet<NSNumber *> *ids = [_canvasView.selectedElementIdentifiers copy];
	[_document.designerLayout updateElements:ids setSizeWidth:MAX(16.0f, _widthField.floatValue)];		// Warning: Weak instance variable '_document' is accessed multiple times in this method but may be unpredictably set to nil; assign to a strong variable to keep the object alive
	[_document.designerLayout updateElements:ids setSizeHeight:MAX(12.0f, _heightField.floatValue)];
	[_document notifyDocumentMutated];
}

- (void)elementStyleEdited:(id) __unused sender {
	if (_updatingInspector) return;
	NSSet<NSNumber *> *ids = [_canvasView.selectedElementIdentifiers copy];
	if (ids.count == 0) return;

	MADDesignerLayout *layout = _document.designerLayout;		// Warning: Weak instance variable '_document' is accessed multiple times in this method but may be unpredictably set to nil; assign to a strong variable to keep the object alive
	NSString *fontName = _fontFamilyPopup.selectedItem.title ?: @"Helvetica";
	[layout updateElements:ids setFontname:fontName];
	[layout updateElements:ids setFontsize:MAX(6.0, _fontSizeField.doubleValue)];
	[layout updateElements:ids setBold:(_boldCheckbox.state == NSControlStateValueOn)];
	[layout updateElements:ids setItalic:(_italicCheckbox.state == NSControlStateValueOn)];
	[layout updateElements:ids setUnderline:(_underlineCheckbox.state == NSControlStateValueOn)];
	[layout updateElements:ids setStrikethrough:(_strikethroughCheckbox.state == NSControlStateValueOn)];
	[layout updateElements:ids setHorizontalAlignment:(int16_t)_horizAlignPopup.indexOfSelectedItem];
	[layout updateElements:ids setVerticalAlignment:(int16_t)_vertAlignPopup.indexOfSelectedItem];

	float bw = MAX(0.0f, _borderWidthField.floatValue);
	[layout updateElements:ids setBorderTop:bw];
	[layout updateElements:ids setBorderBottom:bw];
	[layout updateElements:ids setBorderLeft:bw];
	[layout updateElements:ids setBorderRight:bw];

	[_document notifyDocumentMutated];
}

- (void)elementColorEdited:(id) __unused sender {
	if (_updatingInspector) return;
	RptqDocumentElement *el = [_canvasView primarySelectedElement];
	if (el == nil) return;
	el.foregroundColor = _foregroundColorWell.color;
	el.backgroundColor = _backgroundColorWell.color;
	[_document notifyDocumentMutated];
}

- (void)elementDataBindingEdited:(id) __unused sender {
	if (_updatingInspector) return;
	RptqDocumentElement *el = [_canvasView primarySelectedElement];
	if (el == nil) return;

	NSInteger fieldID = _queryFieldPopup.selectedItem.tag;
	RptqQueryField *qf = fieldID > 0 ? [RptqQueryField queryFieldForObjectID:fieldID managedObjectContext:_document.managedObjectContext] : nil;

	if ([el isKindOfClass:[RptqDocumentElementLabel class]]) {
		((RptqDocumentElementLabel *)el).text = _staticTextField.stringValue ?: @"";
	} else if ([el isKindOfClass:[RptqDocumentElementLabelDataField class]]) {
		RptqDocumentElementLabelDataField *df = (RptqDocumentElementLabelDataField *)el;
		if (qf != nil) {
			df.referencesQueryField = qf;
			df.fieldID = qf.databaseSchemaField.name;
			df.tableID = qf.inQueryTable.alias ?: qf.inQueryTable.databaseSchemaTable.name;
			df.text = [NSString stringWithFormat:@"[%@.%@]", df.tableID ?: @"", df.fieldID ?: @""];
		}
	} else if ([el isKindOfClass:[RptqDocumentElementAggregate class]]) {
		RptqDocumentElementAggregate *agg = (RptqDocumentElementAggregate *)el;
		MTAggregateFunctionType fn = MTAggregateFunctionTypeSum;
		switch (_aggregateFuncPopup.indexOfSelectedItem) {
			case 0: fn = MTAggregateFunctionTypeSum; break;
			case 1: fn = MTAggregateFunctionTypeMean; break;
			case 2: fn = MTAggregateFunctionTypeCount; break;
			case 3: fn = MTAggregateFunctionTypeFirst; break;
			case 4: fn = MTAggregateFunctionTypeLast; break;
			case 5: fn = MTAggregateFunctionTypeMin; break;
			case 6: fn = MTAggregateFunctionTypeMax; break;
			default: fn = MTAggregateFunctionTypeCount; break;
		}
		[agg updateAggregateFunctionWithFunctionType:fn
										   inputType:MTAggregateFunctionInputTypeField
										   groupType:agg.groupType
								   aggregateObjectID:qf ? qf.identifier : agg.aggregateField.identifier
										 groupNumber:agg.groupNumber];
	} else if ([el isKindOfClass:[RptqDocumentElementBarcode class]]) {
		RptqDocumentElementBarcode *bc = (RptqDocumentElementBarcode *)el;
		bc.barcodeType = (int16_t)_barcodeSymbologyPopup.selectedItem.tag;
		if (qf != nil) {
			bc.useStaticInput1 = NO;
			bc.referencesField1 = qf;
			bc.inputField1 = qf.databaseSchemaField.name;
		} else {
			bc.useStaticInput1 = YES;
			bc.inputStatic1 = _staticTextField.stringValue ?: @"MAD-2026";
		}
	}

	[_document notifyDocumentMutated];
}

#pragma mark - MADMacDesignerCanvasViewDelegate

- (void)canvasViewSelectionDidChange:(id) __unused sender {
	[self syncInspectorFromSelection];
	if (_canvasView.selectedSection != nil) {
		NSUInteger idx = [_sections indexOfObject:_canvasView.selectedSection];		// Warning: Implicit conversion from nullable pointer 'RptqDocumentSection * _Nullable' to non-nullable pointer type 'RptqDocumentSection * _Nonnull'
		if (idx != NSNotFound) {
			[_sectionsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx] byExtendingSelection:NO];
		}
	}
}

- (void)canvasViewDidMutateElements:(id) __unused sender {
	[self syncInspectorFromSelection];
}

#pragma mark - NSTableViewDataSource & Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *) __unused tableView {
	return (NSInteger)_sections.count;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *) __unused tableColumn row:(NSInteger)row {
	NSString *title = @"";
	if ((NSUInteger)row < _sections.count) {
		RptqDocumentSection *sec = _sections[(NSUInteger)row];
		title = [_document displayTitleForSection:sec];
	}
	NSTextField *cell = [tableView makeViewWithIdentifier:@"SecCell" owner:self];
	if (cell == nil) {
		cell = [NSTextField labelWithString:title];
		cell.identifier = @"SecCell";
		cell.font = [NSFont systemFontOfSize:12.0];
		cell.lineBreakMode = NSLineBreakByTruncatingTail;
	} else {
		cell.stringValue = title;
	}
	return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *) __unused notification {
	NSInteger row = _sectionsTableView.selectedRow;
	if (row >= 0 && (NSUInteger)row < _sections.count) {
		_canvasView.selectedSection = _sections[(NSUInteger)row];
		[_canvasView setNeedsDisplay:YES];
		[self syncInspectorFromSelection];
	}
}

@end
