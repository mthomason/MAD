//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.IO;
using Mad.Designer.Windows.Infrastructure;
using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.ViewModels;

/// <summary>The About window's three tabs: Overview, License &amp; Notice, and Acknowledgements.
/// The content is drawn from <see cref="WindowsLicenseRegistry"/> and the committed licence texts,
/// so the window renders the Windows component set (never the Apple one) and the relink offer.</summary>
public sealed class AboutViewModel : ObservableObject
{
    private WindowsComponent? _selectedComponent;

    public AboutViewModel()
    {
        Components = WindowsLicenseRegistry.Components;
        Overview = WindowsLicenseRegistry.OverviewText;
        LicenseNotice = BuildLicenseNotice();
        SelectedComponent = Components.FirstOrDefault();
    }

    public string Version { get; } = "v9.0 (r4433)";
    public string Copyright { get; } = "Copyright © 2012–2026 Michael Thomason";

    public string Overview { get; }
    public string LicenseNotice { get; }
    public IReadOnlyList<WindowsComponent> Components { get; }

    public WindowsComponent? SelectedComponent
    {
        get => _selectedComponent;
        set
        {
            if (Set(ref _selectedComponent, value))
            {
                OnPropertyChanged(nameof(SelectedAcknowledgement));
            }
        }
    }

    public string SelectedAcknowledgement => SelectedComponent == null
        ? "Select a component to view its licence and attribution."
        : BuildAcknowledgement(SelectedComponent);

    private static string BuildAcknowledgement(WindowsComponent component)
    {
        string license = WindowsLicenseRegistry.ReadLicenseText(component) ?? "(license text not found)";
        return $"{component.Name}\n{component.License}\n\n{component.Details}\n\n{component.LicenseTitle}\n\n{license}";
    }

    private static string BuildLicenseNotice()
    {
        string notice = ReadFileOrEmpty(Path.Combine(MadPathResolver.RepoRoot(), "NOTICE"));
        string mit = ReadFileOrEmpty(Path.Combine(MadPathResolver.RepoRoot(), "LICENSE"));
        string lgpl21 = ReadFileOrEmpty(Path.Combine(MadPathResolver.LicensesRoot(), "Windows", "LGPL-2.1.txt"));
        string lgpl30 = ReadFileOrEmpty(Path.Combine(MadPathResolver.LicensesRoot(), "LGPL-3.0.txt"));

        return $"{WindowsLicenseRegistry.BrandNotice}\n\n" +
               $"NOTICE\n\n{notice}\n\n" +
               $"{WindowsLicenseRegistry.RelinkOffer}\n\n" +
               $"MIT License\n\n{mit}\n\n" +
               $"GNU Lesser General Public License v2.1\n\n{lgpl21}\n\n" +
               $"GNU Lesser General Public License v3.0\n\n{lgpl30}";
    }

    private static string ReadFileOrEmpty(string path)
        => File.Exists(path) ? File.ReadAllText(path) : "(text not found)";
}
