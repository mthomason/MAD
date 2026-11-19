//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using System.Runtime.InteropServices;

namespace Mad.Designer.Windows.Infrastructure;

/// <summary>Windows Credential Manager-backed <see cref="ICredentialStore"/> — the Windows
/// counterpart of the Mac app's <c>MADKeyChain</c>, which the engine excludes on Windows.
/// Each key is stored as a generic credential target named <c>MAD/&lt;key&gt;</c>.</summary>
public sealed class WindowsCredentialStore : ICredentialStore
{
    private const int CredTypeGeneric = 1;
    private const int CredPersistLocalMachine = 2;

    public void Save(string key, string username, string password)
    {
        string target = "MAD/" + key;
        CredDelete(target, CredTypeGeneric, 0);

        var credential = new CREDENTIAL
        {
            Type = CredTypeGeneric,
            TargetName = target,
            UserName = username,
            CredentialBlob = Marshal.StringToCoTaskMemUni(password),
            CredentialBlobSize = (uint)(password.Length * sizeof(char)),
            Persist = CredPersistLocalMachine,
        };

        try
        {
            if (!CredWrite(ref credential, 0))
            {
                throw new InvalidOperationException("could not write the credential to Windows Credential Manager.");
            }
        }
        finally
        {
            if (credential.CredentialBlob != IntPtr.Zero)
            {
                Marshal.FreeCoTaskMem(credential.CredentialBlob);
            }
        }
    }

    public bool TryRead(string key, out string username, out string password)
    {
        username = "";
        password = "";

        if (!CredRead("MAD/" + key, CredTypeGeneric, 0, out IntPtr credentialPtr))
        {
            return false;
        }

        try
        {
            var credential = Marshal.PtrToStructure<CREDENTIAL>(credentialPtr);
            username = credential.UserName ?? "";
            password = credential.CredentialBlobSize > 0
                ? Marshal.PtrToStringUni(credential.CredentialBlob, (int)(credential.CredentialBlobSize / sizeof(char))) ?? ""
                : "";
            return true;
        }
        finally
        {
            CredFree(credentialPtr);
        }
    }

    public void Delete(string key)
    {
        CredDelete("MAD/" + key, CredTypeGeneric, 0);
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct CREDENTIAL
    {
        public uint Flags;
        public uint Type;
        [MarshalAs(UnmanagedType.LPWStr)] public string TargetName;
        [MarshalAs(UnmanagedType.LPWStr)] public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public uint CredentialBlobSize;
        public IntPtr CredentialBlob;
        public uint Persist;
        public uint AttributeCount;
        public IntPtr Attributes;
        [MarshalAs(UnmanagedType.LPWStr)] public string TargetAlias;
        [MarshalAs(UnmanagedType.LPWStr)] public string UserName;
    }

    [DllImport("advapi32.dll", EntryPoint = "CredReadW", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredRead(string target, int type, int flags, out IntPtr credential);

    [DllImport("advapi32.dll", EntryPoint = "CredWriteW", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredWrite(ref CREDENTIAL credential, int flags);

    [DllImport("advapi32.dll", EntryPoint = "CredDeleteW", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredDelete(string target, int type, int flags);

    [DllImport("advapi32.dll", EntryPoint = "CredFree", SetLastError = true)]
    private static extern void CredFree(IntPtr buffer);
}
