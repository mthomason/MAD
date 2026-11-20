//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Text.Json;
using Mad.Designer.Windows.Infrastructure;

namespace Mad.Designer.Windows.Models;

/// <summary>A report band type, matching the engine's <c>MADocumentSectionType</c>.</summary>
public enum SectionType
{
    Unknown = 0,
    ReportHeader = 1,
    ReportFooter = 2,
    PageHeader = 3,
    PageFooter = 4,
    Body = 5,
    GroupHeader = 6,
    GroupFooter = 7,
}

/// <summary>A report element kind, matching <c>MADPrintPageElementType</c> (MADDocumentObjectType.h).</summary>
public enum ElementType
{
    LabelDynamic = 0,
    LabelStatic = 1,
    Image = 2,
    Chart = 3,
    Formula = 4,
    Aggregate = 5,
    GroupKey = 6,
    AggregateFunctionList = 7,
    Whitespace = 8,
    Barcode = 9,
    LabelLink = 10,
}

/// <summary>An aggregate function, matching <c>MTAggregateFunctionType</c>.</summary>
public enum AggregateFunction
{
    Unknown = 0,
    Sum = 2,
    Mean = 3,
    First = 5,
    Last = 7,
    Count = 11,
    Min = 13,
    Max = 17,
}

/// <summary>An aggregate scope, matching <c>MTAggregateGroupByType</c>.</summary>
public enum AggregateScope
{
    Unknown = 0,
    Page = 2,
    Report = 3,
    Section = 5,
}

/// <summary>Horizontal text alignment, matching <c>MADHorizontalAlignment</c>. Named to avoid
/// a collision with <see cref="System.Windows.HorizontalAlignment"/> in the WPF views.</summary>
public enum ElementHAlign
{
    Left = 0,
    Center = 1,
    Right = 2,
}

/// <summary>Vertical text alignment, matching <c>MADVerticalAlignment</c>. Named to avoid a
/// collision with <see cref="System.Windows.VerticalAlignment"/> in the WPF views.</summary>
public enum ElementVAlign
{
    Top = 0,
    Center = 1,
    Bottom = 2,
}

/// <summary>The three paper sizes the designer exposes, matching <c>MTPaperType</c>.</summary>
public enum PaperSize
{
    Letter = 2,
    Legal = 7,
    A4 = 19,
}

/// <summary>One report band (Report Header, Page Header, Group Header/Footer, Detail, …).</summary>
public sealed record LayoutSection(
    long Id,
    SectionType Type,
    string Title,
    double Height,
    bool Visible,
    bool PageBreak,
    string? GroupField)
{
    /// <summary>The band's localized name. The engine's <see cref="Title"/> is English, so the
    /// app maps the type (and the group's field) through the language dictionaries.</summary>
    public string DisplayTitle => Type switch
    {
        SectionType.ReportHeader => Localizer.Get("Section.ReportHeader"),
        SectionType.PageHeader => Localizer.Get("Section.PageHeader"),
        SectionType.Body => Localizer.Get("Section.Body"),
        SectionType.PageFooter => Localizer.Get("Section.PageFooter"),
        SectionType.ReportFooter => Localizer.Get("Section.ReportFooter"),
        SectionType.GroupHeader => string.IsNullOrEmpty(GroupField)
            ? Localizer.Get("Section.GroupHeader")
            : Localizer.Format("Section.GroupHeaderField", GroupField),
        SectionType.GroupFooter => string.IsNullOrEmpty(GroupField)
            ? Localizer.Get("Section.GroupFooter")
            : Localizer.Format("Section.GroupFooterField", GroupField),
        _ => Localizer.Get("Section.Unknown"),
    };

    internal static LayoutSection Parse(JsonElement e) => new(
        LayoutJson.Long(e, "id"),
        (SectionType)LayoutJson.Int(e, "type"),
        LayoutJson.Str(e, "title"),
        LayoutJson.Double(e, "height"),
        LayoutJson.Bool(e, "visible"),
        LayoutJson.Bool(e, "pageBreak"),
        LayoutJson.NullableStr(e, "groupField"));
}

/// <summary>One placed report element, flattened from the engine's <c>RptqDocumentElement</c>
/// plus its rect/content/typography/box-model sub-objects.</summary>
public sealed record LayoutElement(
    long Id,
    ElementType Type,
    long Section,
    double X,
    double Y,
    double W,
    double H,
    string Text,
    long Field,
    string Table,
    string Column,
    AggregateFunction Function,
    AggregateScope Scope,
    int Group,
    string FontName,
    double FontSize,
    bool Bold,
    bool Italic,
    bool Underline,
    bool Strikethrough,
    ElementHAlign HAlign,
    ElementVAlign VAlign,
    double BorderTop,
    double BorderBottom,
    double BorderLeft,
    double BorderRight,
    double Padding,
    double Margin)
{
    /// <summary>True for a horizontal line rule (a static label with empty text and a bottom border).</summary>
    public bool IsLineRule => Type == ElementType.LabelStatic && string.IsNullOrEmpty(Text) && BorderBottom > 0;

    /// <summary>True for a static label (any static-label element that is not a line rule).</summary>
    public bool IsLabel => Type == ElementType.LabelStatic && !IsLineRule;

    public bool IsDataField => Type == ElementType.LabelDynamic;
    public bool IsAggregate => Type == ElementType.Aggregate;
    public bool IsImage => Type == ElementType.Image;
    public bool IsBarcode => Type == ElementType.Barcode;

    /// <summary>The barcode settings and sample symbol the engine bakes into the snapshot, or
    /// null for every other element.</summary>
    public BarcodeContent? Barcode { get; init; }

    /// <summary>An image element's stored picture (base64 PNG), or null for every other
    /// element.</summary>
    public ImageContent? Image { get; init; }

    internal static LayoutElement Parse(JsonElement e) => new(
        LayoutJson.Long(e, "id"),
        (ElementType)LayoutJson.Int(e, "type"),
        LayoutJson.Long(e, "section"),
        LayoutJson.Double(e, "x"),
        LayoutJson.Double(e, "y"),
        LayoutJson.Double(e, "w"),
        LayoutJson.Double(e, "h"),
        LayoutJson.Str(e, "text"),
        LayoutJson.Long(e, "field"),
        LayoutJson.Str(e, "table"),
        LayoutJson.Str(e, "column"),
        (AggregateFunction)LayoutJson.Int(e, "function"),
        (AggregateScope)LayoutJson.Int(e, "scope"),
        LayoutJson.Int(e, "group"),
        LayoutJson.Str(e, "fontname"),
        LayoutJson.Double(e, "fontsize"),
        LayoutJson.Bool(e, "bold"),
        LayoutJson.Bool(e, "italic"),
        LayoutJson.Bool(e, "underline"),
        LayoutJson.Bool(e, "strikethrough"),
        (ElementHAlign)LayoutJson.Int(e, "hAlign"),
        (ElementVAlign)LayoutJson.Int(e, "vAlign"),
        LayoutJson.Double(e, "borderTop"),
        LayoutJson.Double(e, "borderBottom"),
        LayoutJson.Double(e, "borderLeft"),
        LayoutJson.Double(e, "borderRight"),
        LayoutJson.Double(e, "padding"),
        LayoutJson.Double(e, "margin"))
    {
        // A barcode or image element carries one nested member each; the other
        // elements' shape is unchanged (the members are read only when present).
        Barcode = e.TryGetProperty("barcode", out var barcode) && barcode.ValueKind == JsonValueKind.Object
            ? BarcodeContent.Parse(barcode)
            : null,
        Image = e.TryGetProperty("image", out var image) && image.ValueKind == JsonValueKind.Object
            ? ImageContent.Parse(image)
            : null,
    };
}

/// <summary>An image element's picture: the PNG bytes the engine stores, base64 encoded
/// (empty when the element has none).</summary>
public sealed record ImageContent(string DataBase64)
{
    internal static ImageContent Parse(JsonElement e) => new(LayoutJson.Str(e, "data"));
}

/// <summary>One barcode element's settings, plus the base64 PNG the engine rendered for the
/// designer's canvas (empty when zint refused the sample input).</summary>
public sealed record BarcodeContent(
    int Symbology,
    string SymbologyName,
    bool HumanReadable,
    int BorderStyle,
    bool UseStaticInput,
    string StaticInput,
    long Field,
    string PreviewBase64)
{
    internal static BarcodeContent Parse(JsonElement e) => new(
        LayoutJson.Int(e, "type"),
        LayoutJson.Str(e, "name"),
        LayoutJson.Bool(e, "humanReadable"),
        LayoutJson.Int(e, "borderStyle"),
        LayoutJson.Bool(e, "useStaticInput"),
        LayoutJson.Str(e, "staticInput"),
        LayoutJson.Long(e, "field"),
        LayoutJson.Str(e, "preview"));
}

/// <summary>One entry in the engine's symbology catalogue (<c>barcode-types</c>).</summary>
public sealed record BarcodeSymbology(int Id, string Name)
{
    internal static BarcodeSymbology Parse(JsonElement e) => new(
        LayoutJson.Int(e, "id"),
        LayoutJson.Str(e, "name"));
}

/// <summary>One query field the designer can bind a data field or aggregate to.</summary>
public sealed record LayoutField(long Id, string Name, string Table, string Display)
{
    internal static LayoutField Parse(JsonElement e) => new(
        LayoutJson.Long(e, "id"),
        LayoutJson.Str(e, "name"),
        LayoutJson.Str(e, "table"),
        LayoutJson.Str(e, "display"));
}

/// <summary>The full report-layout model the engine exposes over <c>layout-model</c>.</summary>
public sealed record LayoutModel(
    int PaperSize,
    IReadOnlyList<LayoutSection> Sections,
    IReadOnlyList<LayoutElement> Elements,
    IReadOnlyList<LayoutField> Fields)
{
    public static LayoutModel Parse(JsonElement root)
    {
        int paperSize = LayoutJson.Int(root, "paperSize");

        var sections = new List<LayoutSection>();
        if (root.TryGetProperty("sections", out var sectionsEl))
        {
            foreach (var e in sectionsEl.EnumerateArray()) sections.Add(LayoutSection.Parse(e));
        }

        var elements = new List<LayoutElement>();
        if (root.TryGetProperty("elements", out var elementsEl))
        {
            foreach (var e in elementsEl.EnumerateArray()) elements.Add(LayoutElement.Parse(e));
        }

        var fields = new List<LayoutField>();
        if (root.TryGetProperty("fields", out var fieldsEl))
        {
            foreach (var e in fieldsEl.EnumerateArray()) fields.Add(LayoutField.Parse(e));
        }

        return new LayoutModel(paperSize, sections, elements, fields);
    }
}

/// <summary>Tolerant JSON accessors for the layout snapshot — every field defaults rather than
/// throwing, because an element's shape varies by its type.</summary>
internal static class LayoutJson
{
    public static int Int(JsonElement e, string name) =>
        e.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.Number ? v.GetInt32() : 0;

    public static long Long(JsonElement e, string name) =>
        e.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.Number ? v.GetInt64() : 0;

    public static double Double(JsonElement e, string name) =>
        e.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.Number ? v.GetDouble() : 0;

    public static bool Bool(JsonElement e, string name) =>
        e.TryGetProperty(name, out var v) && (v.ValueKind == JsonValueKind.True || v.ValueKind == JsonValueKind.False) && v.GetBoolean();

    public static string Str(JsonElement e, string name) =>
        e.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString() ?? "" : "";

    public static string? NullableStr(JsonElement e, string name) =>
        e.TryGetProperty(name, out var v) && v.ValueKind == JsonValueKind.String ? v.GetString() : null;
}
