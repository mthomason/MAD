//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>The credential surface the connection assistant uses to store and recall
/// database passwords. SQLite connections (which need no credentials) never touch it.</summary>
public interface ICredentialStore
{
    void Save(string key, string username, string password);
    bool TryRead(string key, out string username, out string password);
    void Delete(string key);
}
