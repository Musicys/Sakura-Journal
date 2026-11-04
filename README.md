# 夜樱手账 (Sakura Journal)

<p align="center">
  <img src="image.png" alt="夜樱手账" width="480" />
</p>

**夜樱手账**是一款只保存在本机的手账应用 —— 用 Flutter 构建，没有账号、没有云端、没有上传，你的每一篇手记都留在你自己的设备里。

## ✨ 功能特性

- **手记编辑**：标题 + 正文，支持多张图片插入，图片保存在应用私有目录
- **便签纸色**：多种手账纸色可选，打造属于你的手记质感
- **心情印记**：为每篇手记标记当下心情，便签左上角自动盖上首字印章
- **置顶与收藏**：重要手记一键置顶，喜欢的手记加入收藏
- **日历视图**：按日期翻阅，回顾某一天写下的心情
- **时间线视图**：以时间顺序纵览所有手记
- **记忆回放**：像翻阅纸质手账一样，重新走进过去的某一天
- **纯本地存储**：数据仅存于本机，删除应用即彻底清除，绝不联网同步

## 🛠 技术栈

- [Flutter](https://flutter.dev) / Dart
- [shared_preferences](https://pub.dev/packages/shared_preferences) —— 手记数据本地持久化
- [image_picker](https://pub.dev/packages/image_picker) —— 从相册/相机选取图片
- [path_provider](https://pub.dev/packages/path_provider) —— 应用私有目录管理
- [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) —— 应用图标生成

## 📂 项目结构

```
lib/
├── main.dart              # 应用入口
├── data/                  # 数据层（手记存储 / 媒体存储，含 Web 条件导入）
├── models/                # 数据模型（Note）
├── screens/               # 页面（首页框架、编辑器、日历、时间线、记忆回放、手记列表面板）
├── theme/                 # 樱花主题（配色、便签纸色、心情图形）
├── utils/                 # 工具（手账日期处理）
└── widgets/               # 通用组件（便签卡片、日期条目、装饰、删除弹窗）
```

## 🚀 快速开始

```bash
# 1. 克隆项目
git clone https://github.com/Musicys/Sakura-Journal.git
cd Sakura-Journal

# 2. 安装依赖
flutter pub get

# 3. 运行
flutter run
```

## 📱 平台支持

| Android | iOS | Windows | macOS | Linux | Web |
| :-----: | :-: | :-----: | :---: | :---: | :-: |
|    ✅    | ✅  |    ✅    |   ✅   |   ✅   | ✅  |

## 📄 许可证

仅供学习交流使用。
