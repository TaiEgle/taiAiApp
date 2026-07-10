# 帧不错 - Flutter 重构版

AI 图像与视频生成工具，使用 Flutter 从零重构自 uni-app X 版本。

## 功能特性

- **图片生成**: 文生图 / 图生图
- **视频生成**: 文生视频 / 图生视频 / 多图视频 / 关键帧视频
- **异步轮询**: 视频生成进度实时显示
- **历史记录**: 本地持久化最近 5 张图片和 3 个视频
- **配置中心**: API 地址、Key、返回格式、图片尺寸
- **玻璃拟态 UI**: 渐变光球背景 + 毛玻璃卡片

## 技术栈

| 层 | 技术 |
|---|---|
| 框架 | Flutter 3.x |
| 语言 | Dart 3 |
| 状态管理 | Provider (ChangeNotifier) |
| HTTP | Dio |
| 本地存储 | shared_preferences |
| 图片选择 | image_picker |
| 缓存 | cached_network_image |

## 项目结构

```
lib/
├── main.dart                    # 入口
├── flutter_app.dart             # 统一导出
├── models/
│   └── models.dart              # 数据模型 (ImageSize, VideoMode, API responses...)
├── providers/
│   └── app_provider.dart        # 全局状态管理 (AppState + ChangeNotifier)
├── services/
│   ├── storage_service.dart     # SharedPreferences 本地存储
│   ├── image_service.dart       # 图片生成 API
│   └── video_service.dart       # 视频生成 API + 轮询逻辑
├── widgets/
│   ├── mode_bar.dart            # 模式切换标签 (文生图/图生图, 4种视频模式)
│   ├── input_area.dart          # 图片输入区 (提示词 + 图片上传)
│   ├── result_area.dart         # 图片结果展示 + 全屏查看
│   ├── history_section.dart     # 图片历史记录网格
│   ├── config_panel.dart        # 设置面板覆盖层
│   ├── video_input_area.dart    # 视频输入区 (提示词 + 高级选项 + 多图上传)
│   ├── video_result_area.dart   # 视频结果 + 进度环 + 轮询
│   ├── video_history_section.dart # 视频历史记录网格
│   └── widgets.dart             # 统一导出
├── pages/
│   └── main_page.dart           # 主页面 (全部业务逻辑)
└── theme/
    └── app_theme.dart           # 主题常量 + 渐变光球动画
```

## 快速开始

```bash
# 安装依赖
flutter pub get

# 运行 (需连接设备或模拟器)
flutter run

# 分析检查
flutter analyze

# 构建 APK
flutter build apk --release

# 构建 iOS
flutter build ios --release
```

## 与原版的对应关系

| uni-app X 文件 | Flutter 文件 |
|---|---|
| `stores/app.ts` | `providers/app_provider.dart` |
| `utils/http.ts` | `services/image_service.dart` |
| `utils/videoApi.ts` | `services/video_service.dart` |
| `components/ModeBar.uvue` | `widgets/mode_bar.dart` |
| `components/InputArea.uvue` | `widgets/input_area.dart` |
| `components/ResultArea.uvue` | `widgets/result_area.dart` |
| `components/HistorySection.uvue` | `widgets/history_section.dart` |
| `components/ConfigPanel.uvue` | `widgets/config_panel.dart` |
| `components/VideoModeBar.uvue` | `widgets/mode_bar.dart` (VideoModeBar) |
| `components/VideoInputArea.uvue` | `widgets/video_input_area.dart` |
| `components/VideoResultArea.uvue` | `widgets/video_result_area.dart` |
| `components/VideoHistorySection.uvue` | `widgets/video_history_section.dart` |
| `pages/index/index.uvue` | `pages/main_page.dart` |

## API 端点

- **图片**: `POST {apiUrl}` — 默认 `https://apihub.agnes-ai.com/v1/images/generations`
- **视频提交**: `POST {videoBaseUrl}/v1/videos`
- **视频轮询**: `GET {videoBaseUrl}/agnesapi?video_id={id}&model_name=agnes-video-v2.0`

## 注意事项

- 当前视频播放器为占位实现，需安装 `video_player` 包并正确初始化
- 图片/视频保存功能需添加 `share_plus` 或 `file_saver` 包
- Android 需要 API 级别 21+ (minSdkVersion 21)
- iOS 需要部署目标 12.0+
