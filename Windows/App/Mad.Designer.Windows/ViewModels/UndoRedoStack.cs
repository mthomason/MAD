//  Copyright © 2012-2026 Michael Thomason. SPDX-License-Identifier: MIT

using Mad.Designer.Windows.Models;

namespace Mad.Designer.Windows.ViewModels;

/// <summary>One undoable mutation: its display name and the closures that apply and reverse it.</summary>
public sealed record UndoableEdit(string Name, Func<Task<LayoutModel>> Undo, Func<Task<LayoutModel>> Redo);

/// <summary>A small client-side undo/redo stack — the WPF counterpart of the Mac's
/// <c>NSUndoManager</c>. WPF has no undo manager, so each mutation pushes an inverse call.</summary>
public sealed class UndoRedoStack
{
    private readonly Stack<UndoableEdit> _undo = new();
    private readonly Stack<UndoableEdit> _redo = new();

    public bool CanUndo => _undo.Count > 0;
    public bool CanRedo => _redo.Count > 0;

    public void Push(UndoableEdit edit)
    {
        _undo.Push(edit);
        _redo.Clear();
    }

    /// <summary>Discards the whole history. Used when the designer switches to another node, so
    /// an edit recorded against one node's layout is never replayed against another's.</summary>
    public void Clear()
    {
        _undo.Clear();
        _redo.Clear();
    }

    public async Task<LayoutModel> UndoAsync()
    {
        var edit = _undo.Pop();
        var model = await edit.Undo().ConfigureAwait(false);
        _redo.Push(edit);
        return model;
    }

    public async Task<LayoutModel> RedoAsync()
    {
        var edit = _redo.Pop();
        var model = await edit.Redo().ConfigureAwait(false);
        _undo.Push(edit);
        return model;
    }
}
