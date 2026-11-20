//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Windows;
using Mad.Designer.Windows.Engine;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.ViewModels;

/// <summary>The MAD Designer workspace's view model — the WPF counterpart of the Mac's
/// <c>MADMacDesignerViewController</c>. It owns the report-layout snapshot, the selection,
/// the zoom/grid/snap/ruler state, the non-overlap placement heuristic, and the mutation
/// wrappers over the engine. Every mutation round-trips through the engine and replaces the
/// snapshot atomically.</summary>
public sealed class DesignerViewModel : ObservableObject
{
    /// <summary>The designer's fixed 8pt alignment grid.</summary>
    public const double GridSpacing = 8.0;

    private const double PaperWidth = 612.0;
    private const double LeftMargin = 18.0;
    private const double RightMargin = 18.0;
    private const double ContentWidth = PaperWidth - LeftMargin - RightMargin;

    private readonly EngineService _engine;
    private int _handle = -1;
    private LayoutModel _model = new(0, Array.Empty<LayoutSection>(), Array.Empty<LayoutElement>(), Array.Empty<LayoutField>());
    private long _selectedSectionId;
    private readonly List<long> _selectedElementIds = new();
    private double _zoom = 1.0;
    private bool _showGrid = true;
    private bool _snapToGrid = true;
    private bool _showRulers = true;
    private bool _isBusy;
    private string? _errorText;
    private bool _isUpdatingInspector;
    private readonly UndoRedoStack _undoRedo = new();
    private IReadOnlyList<BarcodeSymbology> _barcodeTypes = Array.Empty<BarcodeSymbology>();
    private IReadOnlyList<BarcodeInputOption> _barcodeInputOptions = new[] { new BarcodeInputOption(0, "") };

    public DesignerViewModel(EngineService engine)
    {
        _engine = engine ?? throw new ArgumentNullException(nameof(engine));
        AddLabelCommand = new AsyncRelayCommand(() => AddPaletteAsync("label", 124, 22), () => HasDocument);
        AddDataFieldCommand = new AsyncRelayCommand(() => AddPaletteAsync("data-field", 140, 22), () => HasDocument);
        AddAggregateCommand = new AsyncRelayCommand(() => AddPaletteAsync("aggregate", 144, 22), () => HasDocument);
        AddImageCommand = new AsyncRelayCommand(() => AddPaletteAsync("image", 96, 64), () => HasDocument);
        AddLineRuleCommand = new AsyncRelayCommand(() => AddPaletteAsync("line", 320, 8), () => HasDocument);
        AddBarcodeCommand = new AsyncRelayCommand(() => AddPaletteAsync("barcode", 160, 48), () => HasDocument);
        DeleteElementCommand = new AsyncRelayCommand(DeleteElementAsync, () => HasDocument && SelectedElementIds.Count > 0);
        DuplicateElementCommand = new AsyncRelayCommand(DuplicateElementAsync, () => HasDocument && SelectedElementIds.Count > 0);
        UndoCommand = new AsyncRelayCommand(UndoAsync, () => _undoRedo.CanUndo);
        RedoCommand = new AsyncRelayCommand(RedoAsync, () => _undoRedo.CanRedo);
    }

    public bool HasDocument => _handle >= 0;

    public AsyncRelayCommand AddLabelCommand { get; }
    public AsyncRelayCommand AddDataFieldCommand { get; }
    public AsyncRelayCommand AddAggregateCommand { get; }
    public AsyncRelayCommand AddImageCommand { get; }
    public AsyncRelayCommand AddLineRuleCommand { get; }
    public AsyncRelayCommand AddBarcodeCommand { get; }
    public AsyncRelayCommand DeleteElementCommand { get; }
    public AsyncRelayCommand DuplicateElementCommand { get; }
    public AsyncRelayCommand UndoCommand { get; }
    public AsyncRelayCommand RedoCommand { get; }

    public bool CanUndo => _undoRedo.CanUndo;
    public bool CanRedo => _undoRedo.CanRedo;

    public LayoutModel Model => _model;
    public IReadOnlyList<LayoutSection> Sections => _model.Sections;
    public IReadOnlyList<LayoutElement> Elements => _model.Elements;
    public IReadOnlyList<LayoutField> Fields => _model.Fields;

    /// <summary>The symbologies the engine's <c>barcode-types</c> catalogue offers.</summary>
    public IReadOnlyList<BarcodeSymbology> BarcodeTypes => _barcodeTypes;

    /// <summary>The barcode input picker's rows: the static input first, then every query field.</summary>
    public IReadOnlyList<BarcodeInputOption> BarcodeInputOptions => _barcodeInputOptions;

    public long SelectedSectionId { get => _selectedSectionId; private set => Set(ref _selectedSectionId, value); }

    public IReadOnlyList<long> SelectedElementIds => _selectedElementIds;

    public LayoutElement? PrimaryElement
        => _model.Elements.FirstOrDefault(e => e.Id == _selectedElementIds.FirstOrDefault());

    public double Zoom { get => _zoom; set => Set(ref _zoom, Math.Clamp(value, 0.5, 2.5)); }
    public bool ShowGrid { get => _showGrid; set => Set(ref _showGrid, value); }
    public bool SnapToGrid { get => _snapToGrid; set => Set(ref _snapToGrid, value); }
    public bool ShowRulers { get => _showRulers; set => Set(ref _showRulers, value); }

    public bool IsBusy { get => _isBusy; private set => Set(ref _isBusy, value); }
    public string? ErrorText { get => _errorText; private set => Set(ref _errorText, value); }

    public async Task LoadAsync(int handle)
    {
        _handle = handle;
        OnPropertyChanged(nameof(HasDocument));
        RaiseCanExecuteChanged();
        try
        {
            _barcodeTypes = await _engine.BarcodeTypesAsync();
        }
        catch (Exception exception)
        {
            _barcodeTypes = Array.Empty<BarcodeSymbology>();
            ErrorText = exception.Message;
        }
        OnPropertyChanged(nameof(BarcodeTypes));
        await ReloadAsync();
    }

    public async Task ReloadAsync()
    {
        if (!HasDocument) return;
        try
        {
            ApplyModel(await _engine.LayoutModelAsync(_handle));
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
        }
    }

    public void SelectSection(long id)
    {
        SelectedSectionId = id;
        RaiseInspectorChanged();
    }

    public void SelectElement(long id, bool extend)
    {
        if (extend)
        {
            if (_selectedElementIds.Contains(id)) _selectedElementIds.Remove(id);
            else _selectedElementIds.Add(id);
        }
        else
        {
            _selectedElementIds.Clear();
            _selectedElementIds.Add(id);
        }

        var element = _model.Elements.FirstOrDefault(e => e.Id == id);
        if (element != null) SelectedSectionId = element.Section;

        OnPropertyChanged(nameof(SelectedElementIds));
        OnPropertyChanged(nameof(PrimaryElement));
        RaiseInspectorChanged();
        RaiseCanExecuteChanged();
    }

    public void ClearElementSelection()
    {
        _selectedElementIds.Clear();
        OnPropertyChanged(nameof(SelectedElementIds));
        OnPropertyChanged(nameof(PrimaryElement));
        RaiseInspectorChanged();
        RaiseCanExecuteChanged();
    }

    /// <summary>Computes a non-overlapping placement point in a section for a new element of the
    /// given size — the Mac's <c>nextAvailableOriginInSection:forElementSize:</c> ported to C#.</summary>
    public static Point NextAvailableOrigin(
        IReadOnlyList<LayoutElement> elements, long sectionId, double w, double h, double gridSpacing, bool snap)
    {
        var existing = elements.Where(e => e.Section == sectionId).ToList();
        if (existing.Count == 0) return new Point(16.0, 10.0);

        double bottomRowY = 10.0;
        foreach (var el in existing)
        {
            if (el.Y > bottomRowY + 4.0) bottomRowY = el.Y;
        }

        double rightmostOnBottomRow = 16.0;
        double maxBottomEdge = 10.0;
        foreach (var el in existing)
        {
            double maxY = el.Y + el.H;
            if (maxY > maxBottomEdge) maxBottomEdge = maxY;
            if (Math.Abs(el.Y - bottomRowY) <= 10.0 && el.X + el.W > rightmostOnBottomRow)
            {
                rightmostOnBottomRow = el.X + el.W;
            }
        }

        double candidateX = rightmostOnBottomRow + 12.0;
        double candidateY = bottomRowY;
        if (candidateX + w > ContentWidth - 8.0)
        {
            candidateX = 16.0;
            candidateY = maxBottomEdge + 8.0;
        }

        if (snap && gridSpacing > 1.0)
        {
            candidateX = Math.Round(candidateX / gridSpacing) * gridSpacing;
            candidateY = Math.Round(candidateY / gridSpacing) * gridSpacing;
        }

        for (int attempt = 0; attempt < 24; attempt++)
        {
            if (!existing.Any(el => Intersects(candidateX, candidateY, w, h, el))) break;
            candidateX += 16.0;
            if (candidateX + w > ContentWidth - 8.0)
            {
                candidateX = 16.0;
                candidateY += Math.Max(16.0, h + 6.0);
            }
        }

        return new Point(Math.Max(0.0, candidateX), Math.Max(0.0, candidateY));
    }

    public Point NextAvailableOrigin(long sectionId, double w, double h)
        => NextAvailableOrigin(_model.Elements, sectionId, w, h, GridSpacing, SnapToGrid);

    // ---- mutation wrappers (each records its inverse for client-side undo) ----

    public Task AddElementAsync(string kind, long section, double x, double y)
    {
        long newId = 0;
        Func<Task<LayoutModel>> doAdd = async () =>
        {
            var model = await _engine.AddElementAsync(_handle, kind, section, x, y);
            newId = model.Elements.MaxBy(e => e.Id)!.Id;
            return model;
        };
        return MutateAsync(Localizer.Get("Undo.InsertElement"), doAdd, () => _engine.RemoveElementsAsync(_handle, new[] { newId }), doAdd);
    }

    public Task RemoveElementsAsync(IReadOnlyList<long> elements)
    {
        var removed = _model.Elements.Where(e => elements.Contains(e.Id)).ToList();
        var restoredIds = new List<long>();
        return MutateAsync(
            Localizer.Get("Undo.DeleteElement"),
            () => _engine.RemoveElementsAsync(_handle, elements),
            removed.Count > 0 ? () => RestoreElementsAsync(removed, restoredIds) : null,
            () => _engine.RemoveElementsAsync(_handle, restoredIds.Count > 0 ? restoredIds.ToArray() : elements.ToArray()));
    }

    public Task DuplicateElementsAsync(IReadOnlyList<long> elements)
    {
        var before = new HashSet<long>(_model.Elements.Select(e => e.Id));
        long[] dupIds = Array.Empty<long>();
        Func<Task<LayoutModel>> doDup = async () =>
        {
            var model = await _engine.DuplicateElementsAsync(_handle, elements);
            dupIds = model.Elements.Where(e => !before.Contains(e.Id)).Select(e => e.Id).ToArray();
            return model;
        };
        return MutateAsync(Localizer.Get("Undo.DuplicateElement"), doDup, () => _engine.RemoveElementsAsync(_handle, dupIds), doDup);
    }

    public Task MoveElementsAsync(IReadOnlyList<long> elements, long section)
    {
        var oldSections = elements
            .Where(id => _model.Elements.Any(e => e.Id == id))
            .Select(id => (Id: id, Section: _model.Elements.First(e => e.Id == id).Section))
            .ToList();

        Func<Task<LayoutModel>>? undoFn = null;
        if (oldSections.Count > 0)
        {
            undoFn = async () =>
            {
                LayoutModel? model = null;
                foreach (var (id, oldSection) in oldSections)
                {
                    model = await _engine.MoveElementsAsync(_handle, new[] { id }, oldSection);
                }
                return model!;
            };
        }

        return MutateAsync(
            Localizer.Get("Undo.MoveElement"),
            () => _engine.MoveElementsAsync(_handle, elements, section),
            undoFn,
            () => _engine.MoveElementsAsync(_handle, elements, section));
    }

    /// <summary>Moves one element to another section and sets its origin relative to that section,
    /// as a single undoable edit (the cross-band drag). One undo returns the section <em>and</em>
    /// the origin.</summary>
    public Task MoveElementToSectionAsync(long elementId, long newSection, double nx, double ny)
    {
        var el = _model.Elements.FirstOrDefault(e => e.Id == elementId);
        if (el == null) return Task.CompletedTask;

        long oldSection = el.Section;
        double ox = el.X, oy = el.Y, w = el.W, h = el.H;

        Func<Task<LayoutModel>> doMove = async () =>
        {
            var model = await _engine.MoveElementsAsync(_handle, new[] { elementId }, newSection);
            return await _engine.SetElementGeometryAsync(_handle, new[] { new ElementGeometry(elementId, nx, ny, w, h) });
        };
        Func<Task<LayoutModel>> undoMove = async () =>
        {
            var model = await _engine.MoveElementsAsync(_handle, new[] { elementId }, oldSection);
            return await _engine.SetElementGeometryAsync(_handle, new[] { new ElementGeometry(elementId, ox, oy, w, h) });
        };

        return MutateAsync(Localizer.Get("Undo.MoveElement"), doMove, undoMove, doMove);
    }

    public Task SetElementGeometryAsync(IReadOnlyList<ElementGeometry> elements)
    {
        var newGeom = elements.ToList();
        var oldGeom = elements
            .Select(g =>
            {
                var el = _model.Elements.FirstOrDefault(e => e.Id == g.Id);
                return new ElementGeometry(g.Id, el?.X ?? 0, el?.Y ?? 0, el?.W ?? 0, el?.H ?? 0);
            })
            .ToList();

        return MutateAsync(
            Localizer.Get("Undo.MoveResize"),
            () => _engine.SetElementGeometryAsync(_handle, newGeom),
            () => _engine.SetElementGeometryAsync(_handle, oldGeom),
            () => _engine.SetElementGeometryAsync(_handle, newGeom));
    }

    public Task SetElementContentAsync(long element, ElementContent content)
    {
        var old = _model.Elements.FirstOrDefault(e => e.Id == element);
        return MutateAsync(
            Localizer.Get("Undo.EditContent"),
            () => _engine.SetElementContentAsync(_handle, element, content),
            old != null ? () => _engine.SetElementContentAsync(_handle, element, CaptureContent(old)) : null,
            () => _engine.SetElementContentAsync(_handle, element, content));
    }

    public Task SetElementTypographyAsync(IReadOnlyList<long> elements, ElementTypography style)
    {
        var oldStyles = elements
            .Where(id => _model.Elements.Any(e => e.Id == id))
            .Select(id => _model.Elements.First(e => e.Id == id))
            .Select(CaptureTypography)
            .ToList();

        return MutateAsync(
            Localizer.Get("Undo.EditTypography"),
            () => _engine.SetElementTypographyAsync(_handle, elements, style),
            oldStyles.Count > 0 ? () => RestoreTypographyAsync(elements.ToList(), oldStyles) : null,
            () => _engine.SetElementTypographyAsync(_handle, elements, style));
    }

    public Task SetElementBoxModelAsync(IReadOnlyList<long> elements, ElementBoxModel box)
    {
        var oldBoxes = elements
            .Where(id => _model.Elements.Any(e => e.Id == id))
            .Select(id => _model.Elements.First(e => e.Id == id))
            .Select(CaptureBoxModel)
            .ToList();

        return MutateAsync(
            Localizer.Get("Undo.EditBoxModel"),
            () => _engine.SetElementBoxModelAsync(_handle, elements, box),
            oldBoxes.Count > 0 ? () => RestoreBoxModelAsync(elements.ToList(), oldBoxes) : null,
            () => _engine.SetElementBoxModelAsync(_handle, elements, box));
    }

    public Task SetSectionAsync(long section, double? height, bool? visible, bool? pageBreak)
    {
        var old = _model.Sections.FirstOrDefault(s => s.Id == section);
        return MutateAsync(
            Localizer.Get("Undo.EditSection"),
            () => _engine.SetSectionAsync(_handle, section, height, visible, pageBreak),
            old != null ? () => _engine.SetSectionAsync(_handle, section, old.Height, old.Visible, old.PageBreak) : null,
            () => _engine.SetSectionAsync(_handle, section, height, visible, pageBreak));
    }

    public Task SetPaperSizeAsync(int paperSize)
    {
        int old = _model.PaperSize;
        return MutateAsync(
            Localizer.Get("Undo.PaperSize"),
            () => _engine.SetPaperSizeAsync(_handle, paperSize),
            () => _engine.SetPaperSizeAsync(_handle, old),
            () => _engine.SetPaperSizeAsync(_handle, paperSize));
    }

    private static ElementContent CaptureContent(LayoutElement el) => new(
        Text: el.Text,
        Field: el.IsBarcode ? (el.Barcode?.Field ?? 0) : (el.Field != 0 ? el.Field : null),
        Function: el.IsAggregate ? (int)el.Function : null,
        Scope: el.IsAggregate ? (int)el.Scope : null,
        Group: el.IsAggregate ? el.Group : null)
    {
        BarcodeType = el.Barcode?.Symbology,
        HumanReadable = el.Barcode?.HumanReadable,
        BorderStyle = el.Barcode?.BorderStyle,
    };

    private static ElementTypography CaptureTypography(LayoutElement el) => new(
        FontName: el.FontName, FontSize: el.FontSize, Bold: el.Bold, Italic: el.Italic,
        Underline: el.Underline, Strikethrough: el.Strikethrough,
        HAlign: (int)el.HAlign, VAlign: (int)el.VAlign);

    private static ElementBoxModel CaptureBoxModel(LayoutElement el) => new(
        BorderTop: el.BorderTop, BorderBottom: el.BorderBottom, BorderLeft: el.BorderLeft,
        BorderRight: el.BorderRight, Padding: el.Padding, Margin: el.Margin);

    private static string KindFor(LayoutElement el) => el switch
    {
        { IsDataField: true } => "data-field",
        { IsAggregate: true } => "aggregate",
        { IsImage: true } => "image",
        { IsBarcode: true } => "barcode",
        { IsLineRule: true } => "line",
        _ => "label",
    };

    private async Task<LayoutModel> RestoreTypographyAsync(IReadOnlyList<long> ids, IReadOnlyList<ElementTypography> styles)
    {
        LayoutModel? model = null;
        for (int i = 0; i < ids.Count; i++)
        {
            model = await _engine.SetElementTypographyAsync(_handle, new[] { ids[i] }, styles[i]);
        }
        return model!;
    }

    private async Task<LayoutModel> RestoreBoxModelAsync(IReadOnlyList<long> ids, IReadOnlyList<ElementBoxModel> boxes)
    {
        LayoutModel? model = null;
        for (int i = 0; i < ids.Count; i++)
        {
            model = await _engine.SetElementBoxModelAsync(_handle, new[] { ids[i] }, boxes[i]);
        }
        return model!;
    }

    private async Task<LayoutModel> RestoreElementsAsync(IReadOnlyList<LayoutElement> elements, List<long> newIds)
    {
        LayoutModel? model = null;
        newIds.Clear();
        foreach (var el in elements)
        {
            model = await _engine.AddElementAsync(_handle, KindFor(el), el.Section, el.X, el.Y);
            var newEl = model.Elements.MaxBy(e => e.Id)!;
            newIds.Add(newEl.Id);
            model = await _engine.SetElementContentAsync(_handle, newEl.Id, CaptureContent(el));
            model = await _engine.SetElementTypographyAsync(_handle, new[] { newEl.Id }, CaptureTypography(el));
            model = await _engine.SetElementBoxModelAsync(_handle, new[] { newEl.Id }, CaptureBoxModel(el));
            model = await _engine.SetElementGeometryAsync(_handle, new[] { new ElementGeometry(newEl.Id, el.X, el.Y, el.W, el.H) });
        }
        return model!;
    }

    // ---- inspector edit-properties (commit on change; guard suppresses re-entrancy) ----

    public LayoutSection? SelectedSection => _model.Sections.FirstOrDefault(s => s.Id == SelectedSectionId);

    public int PaperSizeIndex
    {
        get => _model.PaperSize switch { 19 => 2, 7 => 1, _ => 0 };
        set
        {
            if (_isUpdatingInspector || !HasDocument) return;
            int paper = value switch { 2 => 19, 1 => 7, _ => 2 };
            _ = SetPaperSizeAsync(paper);
        }
    }

    public double SelectedSectionHeight
    {
        get => SelectedSection?.Height ?? 0;
        set
        {
            if (_isUpdatingInspector || SelectedSectionId == 0) return;
            _ = SetSectionAsync(SelectedSectionId, Math.Max(24, value), null, null);
        }
    }

    public bool SelectedSectionVisible
    {
        get => SelectedSection?.Visible ?? false;
        set
        {
            if (_isUpdatingInspector || SelectedSectionId == 0) return;
            _ = SetSectionAsync(SelectedSectionId, null, value, null);
        }
    }

    public bool SelectedSectionPageBreak
    {
        get => SelectedSection?.PageBreak ?? false;
        set
        {
            if (_isUpdatingInspector || SelectedSectionId == 0) return;
            _ = SetSectionAsync(SelectedSectionId, null, null, value);
        }
    }

    public string ElementTypeName => PrimaryElement switch
    {
        { IsLabel: true } => Localizer.Get("Designer.Element.Label"),
        { IsDataField: true } => Localizer.Get("Designer.Element.DataField"),
        { IsAggregate: true } => Localizer.Get("Designer.Element.Aggregate"),
        { IsImage: true } => Localizer.Get("Designer.Element.Image"),
        { IsBarcode: true } => Localizer.Get("Designer.Element.Barcode"),
        { IsLineRule: true } => Localizer.Get("Designer.Element.Line"),
        _ => Localizer.Get("Designer.Element.Generic"),
    };

    public long ElementSectionId
    {
        get => PrimaryElement?.Section ?? 0;
        set
        {
            if (_isUpdatingInspector || PrimaryElement is not { } el) return;
            _ = MoveElementsAsync(new[] { el.Id }, value);
        }
    }

    public string ElementText
    {
        get => PrimaryElement?.Text ?? "";
        set
        {
            if (_isUpdatingInspector || PrimaryElement is not { } el) return;
            _ = SetElementContentAsync(el.Id, new ElementContent(Text: value));
        }
    }

    /// <summary>The selected barcode's symbology, as an index into <see cref="BarcodeTypes"/>.</summary>
    public int ElementBarcodeSymbologyIndex
    {
        get
        {
            if (PrimaryElement?.Barcode is not { } barcode) return -1;
            for (int index = 0; index < _barcodeTypes.Count; index++)
            {
                if (_barcodeTypes[index].Id == barcode.Symbology) return index;
            }
            return -1;
        }
        set
        {
            if (_isUpdatingInspector || PrimaryElement is not { } el) return;
            if (value < 0 || value >= _barcodeTypes.Count) return;
            _ = SetElementContentAsync(el.Id, new ElementContent { BarcodeType = _barcodeTypes[value].Id });
        }
    }

    public bool ElementBarcodeHumanReadable
    {
        get => PrimaryElement?.Barcode?.HumanReadable ?? false;
        set
        {
            if (_isUpdatingInspector || PrimaryElement is not { } el) return;
            _ = SetElementContentAsync(el.Id, new ElementContent { HumanReadable = value });
        }
    }

    /// <summary>0 = no border, 1 = bind the bars, 2 = a full frame (the Mac inspector's order).</summary>
    public int ElementBarcodeBorderIndex
    {
        get => Math.Clamp(PrimaryElement?.Barcode?.BorderStyle ?? 0, 0, 2);
        set
        {
            if (_isUpdatingInspector || PrimaryElement is not { } el) return;
            _ = SetElementContentAsync(el.Id, new ElementContent { BorderStyle = Math.Clamp(value, 0, 2) });
        }
    }

    /// <summary>The barcode's input: 0 is the static string (edited as the element's text),
    /// any other value is a query field's id.</summary>
    public long ElementBarcodeInputId
    {
        get => PrimaryElement?.Barcode is { UseStaticInput: false } barcode ? barcode.Field : 0;
        set
        {
            if (_isUpdatingInspector || PrimaryElement is not { } el) return;
            _ = SetElementContentAsync(el.Id, new ElementContent { Field = value });
        }
    }

    public double ElementX { get => PrimaryElement?.X ?? 0; set => SetGeometry(value, null, null, null); }
    public double ElementY { get => PrimaryElement?.Y ?? 0; set => SetGeometry(null, value, null, null); }
    public double ElementW { get => PrimaryElement?.W ?? 0; set => SetGeometry(null, null, value, null); }
    public double ElementH { get => PrimaryElement?.H ?? 0; set => SetGeometry(null, null, null, value); }

    public string ElementFontName { get => PrimaryElement?.FontName ?? ""; set => SetTypography(fontName: value); }
    public double ElementFontSize { get => PrimaryElement?.FontSize ?? 12; set => SetTypography(fontSize: value); }
    public bool ElementBold { get => PrimaryElement?.Bold ?? false; set => SetTypography(bold: value); }
    public bool ElementItalic { get => PrimaryElement?.Italic ?? false; set => SetTypography(italic: value); }
    public bool ElementUnderline { get => PrimaryElement?.Underline ?? false; set => SetTypography(underline: value); }
    public bool ElementStrikethrough { get => PrimaryElement?.Strikethrough ?? false; set => SetTypography(strikethrough: value); }

    public int ElementHAlignIndex
    {
        get => PrimaryElement?.HAlign switch { ElementHAlign.Center => 1, ElementHAlign.Right => 2, _ => 0 };
        set { if (_isUpdatingInspector || PrimaryElement is { }) SetTypography(hAlign: value); }
    }

    public int ElementVAlignIndex
    {
        get => PrimaryElement?.VAlign switch { ElementVAlign.Top => 0, ElementVAlign.Bottom => 2, _ => 1 };
        set { if (_isUpdatingInspector || PrimaryElement is { }) SetTypography(vAlign: value); }
    }

    public double ElementBorderTop { get => PrimaryElement?.BorderTop ?? 0; set => SetBoxModel(borderTop: value); }
    public double ElementBorderBottom { get => PrimaryElement?.BorderBottom ?? 0; set => SetBoxModel(borderBottom: value); }
    public double ElementBorderLeft { get => PrimaryElement?.BorderLeft ?? 0; set => SetBoxModel(borderLeft: value); }
    public double ElementBorderRight { get => PrimaryElement?.BorderRight ?? 0; set => SetBoxModel(borderRight: value); }
    public double ElementPadding { get => PrimaryElement?.Padding ?? 0; set => SetBoxModel(padding: value); }
    public double ElementMargin { get => PrimaryElement?.Margin ?? 0; set => SetBoxModel(margin: value); }

    private void SetGeometry(double? x, double? y, double? w, double? h)
    {
        if (_isUpdatingInspector || PrimaryElement is not { } el) return;
        _ = SetElementGeometryAsync(new[] { new ElementGeometry(el.Id, x ?? el.X, y ?? el.Y, w ?? el.W, h ?? el.H) });
    }

    private void SetTypography(string? fontName = null, double? fontSize = null, bool? bold = null, bool? italic = null, bool? underline = null, bool? strikethrough = null, int? hAlign = null, int? vAlign = null)
    {
        if (_isUpdatingInspector || PrimaryElement is not { } el) return;
        _ = SetElementTypographyAsync(new[] { el.Id }, new ElementTypography(fontName, fontSize, bold, italic, underline, strikethrough, hAlign, vAlign));
    }

    private void SetBoxModel(double? borderTop = null, double? borderBottom = null, double? borderLeft = null, double? borderRight = null, double? padding = null, double? margin = null)
    {
        if (_isUpdatingInspector || PrimaryElement is not { } el) return;
        _ = SetElementBoxModelAsync(new[] { el.Id }, new ElementBoxModel(borderTop, borderBottom, borderLeft, borderRight, padding, margin));
    }

    private async Task DeleteElementAsync()
    {
        if (SelectedElementIds.Count == 0) return;
        var ids = SelectedElementIds.ToList();
        await RemoveElementsAsync(ids);
        ClearElementSelection();
    }

    private async Task DuplicateElementAsync()
    {
        if (SelectedElementIds.Count == 0) return;
        await DuplicateElementsAsync(SelectedElementIds.ToList());
    }

    private async Task AddPaletteAsync(string kind, double w, double h)
    {
        if (!HasDocument) return;
        long section = ResolveTargetSection();
        if (section == 0) return;

        var origin = NextAvailableOrigin(section, w, h);
        await AddElementAsync(kind, section, origin.X, origin.Y);
    }

    /// <summary>Inserts a data field bound to the given query field (double-click in the sidebar).</summary>
    public async Task InsertDataFieldAsync(long fieldId)
    {
        if (!HasDocument) return;
        long section = ResolveTargetSection();
        if (section == 0) return;

        var origin = NextAvailableOrigin(section, 140, 22);
        long newId = 0;
        Func<Task<LayoutModel>> doInsert = async () =>
        {
            var afterAdd = await _engine.AddElementAsync(_handle, "data-field", section, origin.X, origin.Y);
            newId = afterAdd.Elements.MaxBy(e => e.Id)!.Id;
            return await _engine.SetElementContentAsync(_handle, newId, new ElementContent(Field: fieldId));
        };
        await MutateAsync(Localizer.Get("Undo.InsertDataField"), doInsert, () => _engine.RemoveElementsAsync(_handle, new[] { newId }), doInsert);
    }

    /// <summary>Flips a band's visibility (double-click in the sections outline).</summary>
    public async Task ToggleSectionVisibilityAsync(long sectionId)
    {
        var section = _model.Sections.FirstOrDefault(s => s.Id == sectionId);
        if (section == null) return;
        await SetSectionAsync(sectionId, null, !section.Visible, null);
    }

    private long ResolveTargetSection()
        => SelectedSectionId != 0 && _model.Sections.Any(s => s.Id == SelectedSectionId)
            ? SelectedSectionId
            : (_model.Sections.FirstOrDefault(s => s.Type == SectionType.Body)?.Id
               ?? _model.Sections.FirstOrDefault()?.Id ?? 0);

    private void RaiseCanExecuteChanged()
    {
        AddLabelCommand.RaiseCanExecuteChanged();
        AddDataFieldCommand.RaiseCanExecuteChanged();
        AddAggregateCommand.RaiseCanExecuteChanged();
        AddImageCommand.RaiseCanExecuteChanged();
        AddLineRuleCommand.RaiseCanExecuteChanged();
        AddBarcodeCommand.RaiseCanExecuteChanged();
        DeleteElementCommand.RaiseCanExecuteChanged();
        DuplicateElementCommand.RaiseCanExecuteChanged();
    }

    private static bool Intersects(double x, double y, double w, double h, LayoutElement el)
        => x < el.X + el.W && x + w > el.X && y < el.Y + el.H && y + h > el.Y;

    private async Task MutateAsync(string name, Func<Task<LayoutModel>> doFn, Func<Task<LayoutModel>>? undoFn = null, Func<Task<LayoutModel>>? redoFn = null)
    {
        if (!HasDocument) return;
        IsBusy = true;
        ErrorText = null;
        try
        {
            ApplyModel(await doFn());
            if (undoFn != null)
            {
                _undoRedo.Push(new UndoableEdit(name, undoFn, redoFn ?? doFn));
                OnUndoChanged();
            }
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
        }
        finally
        {
            IsBusy = false;
        }
    }

    public async Task UndoAsync()
    {
        if (!_undoRedo.CanUndo) return;
        IsBusy = true;
        ErrorText = null;
        try
        {
            ApplyModel(await _undoRedo.UndoAsync());
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
        }
        finally
        {
            IsBusy = false;
            OnUndoChanged();
        }
    }

    public async Task RedoAsync()
    {
        if (!_undoRedo.CanRedo) return;
        IsBusy = true;
        ErrorText = null;
        try
        {
            ApplyModel(await _undoRedo.RedoAsync());
        }
        catch (Exception exception)
        {
            ErrorText = exception.Message;
        }
        finally
        {
            IsBusy = false;
            OnUndoChanged();
        }
    }

    private void OnUndoChanged()
    {
        OnPropertyChanged(nameof(CanUndo));
        OnPropertyChanged(nameof(CanRedo));
        UndoCommand.RaiseCanExecuteChanged();
        RedoCommand.RaiseCanExecuteChanged();
    }

    private void ApplyModel(LayoutModel model)
    {
        _isUpdatingInspector = true;
        _model = model;
        _selectedElementIds.RemoveAll(id => !model.Elements.Any(e => e.Id == id));
        if (_selectedSectionId != 0 && !model.Sections.Any(s => s.Id == _selectedSectionId))
        {
            SelectedSectionId = 0;
        }

        var inputOptions = new List<BarcodeInputOption>
        {
            new(0, Localizer.Get("Designer.Barcode.StaticInput")),
        };
        foreach (var field in model.Fields) inputOptions.Add(new BarcodeInputOption(field.Id, field.Display));
        _barcodeInputOptions = inputOptions;

        OnPropertyChanged(nameof(Model));
        OnPropertyChanged(nameof(Sections));
        OnPropertyChanged(nameof(Elements));
        OnPropertyChanged(nameof(Fields));
        OnPropertyChanged(nameof(BarcodeInputOptions));
        OnPropertyChanged(nameof(SelectedElementIds));
        OnPropertyChanged(nameof(PrimaryElement));
        RaiseInspectorChanged();
        _isUpdatingInspector = false;
        RaiseCanExecuteChanged();
    }

    private void RaiseInspectorChanged()
    {
        OnPropertyChanged(nameof(SelectedSection));
        OnPropertyChanged(nameof(PaperSizeIndex));
        OnPropertyChanged(nameof(SelectedSectionHeight));
        OnPropertyChanged(nameof(SelectedSectionVisible));
        OnPropertyChanged(nameof(SelectedSectionPageBreak));
        OnPropertyChanged(nameof(ElementTypeName));
        OnPropertyChanged(nameof(ElementSectionId));
        OnPropertyChanged(nameof(ElementText));
        OnPropertyChanged(nameof(ElementX));
        OnPropertyChanged(nameof(ElementY));
        OnPropertyChanged(nameof(ElementW));
        OnPropertyChanged(nameof(ElementH));
        OnPropertyChanged(nameof(ElementFontName));
        OnPropertyChanged(nameof(ElementFontSize));
        OnPropertyChanged(nameof(ElementBold));
        OnPropertyChanged(nameof(ElementItalic));
        OnPropertyChanged(nameof(ElementUnderline));
        OnPropertyChanged(nameof(ElementStrikethrough));
        OnPropertyChanged(nameof(ElementHAlignIndex));
        OnPropertyChanged(nameof(ElementVAlignIndex));
        OnPropertyChanged(nameof(ElementBorderTop));
        OnPropertyChanged(nameof(ElementBorderBottom));
        OnPropertyChanged(nameof(ElementBorderLeft));
        OnPropertyChanged(nameof(ElementBorderRight));
        OnPropertyChanged(nameof(ElementPadding));
        OnPropertyChanged(nameof(ElementMargin));
        OnPropertyChanged(nameof(ElementBarcodeSymbologyIndex));
        OnPropertyChanged(nameof(ElementBarcodeHumanReadable));
        OnPropertyChanged(nameof(ElementBarcodeBorderIndex));
        OnPropertyChanged(nameof(ElementBarcodeInputId));
    }
}

/// <summary>One row in the barcode input picker: the static input (id 0) or a query field.</summary>
public sealed record BarcodeInputOption(long Id, string Display);
