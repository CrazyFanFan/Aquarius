# Aquarius

[![Swift](https://github.com/CrazyFanFan/Aquarius/actions/workflows/xcodebuild.yml/badge.svg?branch=main)](https://github.com/CrazyFanFan/Aquarius/actions/workflows/xcodebuild.yml)

[English](https://github.com/CrazyFanFan/Aquarius/blob/master/README.md)

一个通过分析"Podfile.lock"获取各个库之间的依赖关系的工具。
支持以下操作：
- “依赖树”分析；
- “影响树”分析；
- 搜索
- 复制

"影响树"并非通用概念，而是我暂时这么称呼一种影响关系；有了解更好的名字的，欢迎留言。自上而下的看Podfile.lock记录了各模块之间的依赖关系；反之，自下而上的看，则可以推出每个库的变更最大的影响范围，我将其称之为"影响树"。其中根节点是变动的库，其子节点是依赖库的所有库，递归下去即可得到"影响树"。

**[更新日志](./ChangeLog/change_log.md)**

## 环境

- Xcode: 版本 ≥ Xcode14.0 (Task.detached 在更低版本有运行时问题)
- OSX: 版本 ≥ 11.0

## 预览
![Image](./Screenshots/s_1.jpg)

## 使用
- 克隆这个仓库
- 打开 **Aquarius.xcodeproj** （要求Xcode版本 ≥ 11.0）
- 等待“Swift Packages”处理完， 按下`Command` + `R`即可。

```shell
git clone https://github.com/CrazyFanFan/Aquarius.git
cd Aquarius
open Aquarius.xcodeproj
```

## 作者
Crazy凡, [ccrazyfan@gmail.com](mailto:ccrazyfan@gmail.com)

## License
[LICENSE](https://github.com/CrazyFanFan/Aquarius/blob/master/LICENSE)
