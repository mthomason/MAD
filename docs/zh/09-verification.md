---
layout: default
lang: zh-CN
---

## 9. 验证

§§2–5 中的主张是可复现的（从仓库根目录运行）：

```sh
tar tjf MADDesigner/Resources/Assets/Samples.xcassets/Reports/Music.dataset/Music.mad
mkdir -p /tmp/mad && tar xjf … -C /tmp/mad
plutil -p /tmp/mad/meta.plist
file /tmp/mad/StoreContent/analyitics
```

§5 中的主张可以从设备或模拟器容器中复现：

```sh
ls -la ~/Library/Developer/CoreSimulator/Devices/<UDID>/data/Library/Caches/<dataTableIdHash>/
```

任何对格式的更改都必须扩展 `project/MAD_CLI.md` §6 中描述的往返测试夹具，使本文件中的定义由测试而不是由这段文字来固定。容器的测试夹具自 2026-10-16 起存在
（`../../Linux/Tests/MADArchiveManagerTests.m`：解包、重新打包、再次解包，成员列表和字节保持不变），而 §7.2 的检查点标志位由设置它的写入器（`mad write`）固定。写入器的*可复现模式*——固定的成员时间、所有者 0、排序遍历——是两个平台文档相等的原因；它是可选的，因此普通归档仍会记录文件系统的元数据，而且它不是格式版本（无论哪种方式文件都是 v1）。§5 是目前没有此类夹具的部分——这里的伴随文件是根据测量描述的，如果测量不再成立，也不会有任何测试失败。
