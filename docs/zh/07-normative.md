---
layout: default
lang: zh-CN
---

## 7. 格式应当如何定义

这是规范性目标。它有意与现有格式保持很小的差异，因为现有格式已经接近正确。

### 7.1 按内容而非名称识别

`.mad` 文件应当以一个固定的文件头开始，位于压缩流**之外**，这样读取器可以从最初的几个字节识别它：

```
offset 0  8 bytes   "MADFILE\0"      magic
offset 8  2 bytes   uint16 LE        format major version
offset 10 2 bytes   uint16 LE        format minor version
offset 12 4 bytes   uint32 LE        flags (bit 0: WAL checkpointed)
offset 16 ...       bzip2 stream
```

理由：这正是消除 Windows 问题的办法。扩展名成为文件浏览器的*约定*，而不是识别文件的东西。一个重命名为 `.zip` 的 `.mad`，或者通过会破坏扩展名的渠道收到的文档，仍然可以被识别为 `.mad`。它还能在不减压的情况下检测版本。

该文件头与两份已发布的示例不向后兼容。这*只*在读取器可以回退的情况下可以接受：没有 `MADFILE` 魔数 → 当作旧版 v0 文档处理（§7.4）。

### 7.2 经过检查点的存储

写入器在归档前对存储的 WAL 执行检查点，因此 WAL 和 SHM 成员变为可选，而发现它们的读取器必须重放它们，而不是忽略它们。结果记录在文件头的标志位 0 中——**不是**记录在 `meta.plist` 中；后者在检查点运行之前就已写入，因此该标志是权威记录，且无需减压即可读取。

这也会缩小文档：`Music` 示例有三分之一的字节花在一个 WAL 上，而检查点会把它折入主文件。

### 7.3 成员

| 成员 | 必需 | 内容 |
|---|---|---|
| `meta.plist` | 是 | `generator`、`version` |
| `StoreContent/<name>` | 是 | 文档定义 |
| `StoreContent/<name>-wal` / `-shm` | 否 | 仅当未执行检查点时存在（文件头标志位 0 = 0） |
| `AdditionalContent/` | 否 | `thumbnail@2x.png` |

### 7.4 兼容性

- **v0**——当前发布的格式：没有魔数，可能有 WAL，`version` 为 1。读取器必须无限期接受它；两份示例文档都是 v0。
- **v1**——魔数文件头、经过检查点的存储、`version` 为 1，以及上述新成员。

写入器输出 v1，除此之外 `meta.plist` 保持不变。读取器通过魔数缺失来检测 v0。
