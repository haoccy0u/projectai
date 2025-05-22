# ProjectAI - Godot游戏框架

这是一个基于Godot 4.x引擎开发的游戏框架项目，集成了一套完整的核心系统架构。

## 项目概述

本项目实现了一个模块化的游戏框架，主要包含以下核心功能：

- **CoreSystem**: 核心系统框架
这部分基于godot_core_system改进得到，主要功能如下
  - 自动加载机制
  - 更好的场景管理
  - 事件系统
  - 日志系统

- **场景系统 (SceneSystem)**
  - 场景树管理
  - 场景栈
  - 场景转换效果
  - 异步加载

- **状态机系统 (StateMachine)**
  - 基础状态机框架
  - 游戏流程状态管理
  - 可嵌套的状态机结构

- **UI系统**
  - 全局UI层
  - 混合式UI管理（全局+局部）
  - UI组件基类

## 项目结构

```
ProjectAI/
├── addons/
│   └── godot_core_system/     # 核心系统插件
├── scenes/                    # 场景文件
├── scripts/                   # 脚本文件
│   ├── game_flow_machine.gd   # 游戏流程状态机
│   └── ...
├── UISystem/                  # UI系统
└── project.godot             # 项目配置文件
```

## 核心功能

### 场景系统

场景系统维护了以下永久性根节点结构：

```
Root
└── CoreSystemRoot
    ├── SceneManager
    ├── GlobalUILayer
    └── SceneContainer
```

### 游戏流程状态机

实现了完整的游戏状态管理：

- 主菜单状态 (MenuState)
- 游戏状态 (GameState)
  - 地图状态 (MapState)
  - 探索状态 (ExploreState)
  - 对话状态 (DialogState)
- 暂停状态 (PauseState)

### 事件系统

提供了一套完整的游戏事件定义和处理机制，主要事件包括：

- 开始新游戏
- 加载游戏
- 暂停/恢复
- 返回主菜单

## 使用说明

1. 确保已安装Godot 4.x版本
2. 克隆项目到本地
3. 使用Godot编辑器打开项目
4. CoreSystem会自动加载并初始化必要的系统组件

## 开发计划

- [ ] 完善UI管理系统和UI组件的视觉呈现
- [ ] 添加存档系统
- [ ] 优化场景转换效果
- [ ] 添加异步io管理器

## 技术特性

- 基于Godot 4.x
- GDScript编写
- 模块化架构
- 完整的状态管理
- 事件驱动设计 
