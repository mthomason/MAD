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

    public DesignerViewModel(EngineService engine)
    {
        _engine = engine ?? throw new ArgumentNullException(nameof(engine));
    }

    public bool HasDocument => _handle >= 0;

    public LayoutModel Model => _model;
    public IReadOnlyList<LayoutSection> Sections => _model.Sections;
    public IReadOnlyList<LayoutElement> Elements => _model.Elements;
    public IReadOnlyList<LayoutField> Fields => _model.Fields;

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

    public void SelectSection(long id) => SelectedSectionId = id;

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
    }

    public void ClearElementSelection()
    {
        _selectedElementIds.Clear();
        OnPropertyChanged(nameof(SelectedElementIds));
        OnPropertyChanged(nameof(PrimaryElement));
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

    // ---- mutation wrappers (thin; each re-applies the snapshot) ----

    public Task AddElementAsync(string kind, long section, double x, double y)
        => MutateAsync(() => _engine.AddElementAsync(_handle, kind, section, x, y));

    public Task RemoveElementsAsync(IReadOnlyList<long> elements)
        => MutateAsync(() => _engine.RemoveElementsAsync(_handle, elements));

    public Task DuplicateElementsAsync(IReadOnlyList<long> elements)
        => MutateAsync(() => _engine.DuplicateElementsAsync(_handle, elements));

    public Task MoveElementsAsync(IReadOnlyList<long> elements, long section)
        => MutateAsync(() => _engine.MoveElementsAsync(_handle, elements, section));

    public Task SetElementGeometryAsync(IReadOnlyList<ElementGeometry> elements)
        => MutateAsync(() => _engine.SetElementGeometryAsync(_handle, elements));

    public Task SetElementContentAsync(long element, ElementContent content)
        => MutateAsync(() => _engine.SetElementContentAsync(_handle, element, content));

    public Task SetElementTypographyAsync(IReadOnlyList<long> elements, ElementTypography style)
        => MutateAsync(() => _engine.SetElementTypographyAsync(_handle, elements, style));

    public Task SetElementBoxModelAsync(IReadOnlyList<long> elements, ElementBoxModel box)
        => MutateAsync(() => _engine.SetElementBoxModelAsync(_handle, elements, box));

    public Task SetSectionAsync(long section, double? height, bool? visible, bool? pageBreak)
        => MutateAsync(() => _engine.SetSectionAsync(_handle, section, height, visible, pageBreak));

    public Task SetPaperSizeAsync(int paperSize)
        => MutateAsync(() => _engine.SetPaperSizeAsync(_handle, paperSize));

    private static bool Intersects(double x, double y, double w, double h, LayoutElement el)
        => x < el.X + el.W && x + w > el.X && y < el.Y + el.H && y + h > el.Y;

    private async Task MutateAsync(Func<Task<LayoutModel>> mutation)
    {
        if (!HasDocument) return;
        IsBusy = true;
        ErrorText = null;
        try
        {
            ApplyModel(await mutation());
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

    private void ApplyModel(LayoutModel model)
    {
        _model = model;
        _selectedElementIds.RemoveAll(id => !model.Elements.Any(e => e.Id == id));
        if (_selectedSectionId != 0 && !model.Sections.Any(s => s.Id == _selectedSectionId))
        {
            SelectedSectionId = 0;
        }

        OnPropertyChanged(nameof(Model));
        OnPropertyChanged(nameof(Sections));
        OnPropertyChanged(nameof(Elements));
        OnPropertyChanged(nameof(Fields));
        OnPropertyChanged(nameof(SelectedElementIds));
        OnPropertyChanged(nameof(PrimaryElement));
    }
}
