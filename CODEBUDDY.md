# CODEBUDDY.md

> 本文件会被 CodeBuddy 在每次对话时自动读取，用于存放项目约定和 Agent 工作规范。

## 项目信息

- 项目名称：tvbox
- 项目简述：本项目是使用 海洋CMS(https://bbs.seacms.net/special-2)作为后台 使用 Flutter开发Android 和 iOS 客户端，开发一款观影app。 海洋CMS提供API给app使用，api文档参考 https://bbs.seacms.net/special-2
- 技术栈：
- Android 和 iOS 客户端使用 Flutter 开发，使用 Dart 语言开发。
- 客服端播放器使用原生的第三方成熟的库不要用h5

## 项目需求描述
1. app 尽量简单
2. 首页效果图参考 resource
3. 海洋CMS本地部署地址为 http://localhost:8080/  接口地址为http://localhost:8080/json.php

### 原生播放器要求
1. 播放器长按可以按照3倍速率播放
2. 播放器屏幕右边上下滑动可以调音量大小
3. 播放器最下面的工具栏 有播放/暂停 全屏 锁定等 按钮




## Agent 工作规范

1. **开发记录**：所有开发事项、技术点、问题与解决方案，统一记录在项目根目录的 `DEV_NOTES.md` 中，按其既有栏目格式追加更新。
2. **修改代码后**：如有值得记录的变更或技术点，主动同步更新 `DEV_NOTES.md` 的「开发日志」和「技术点记录」栏目。
3. **目录结构** ：如果有新增目录或者文件请在 `CODEBUDDY.md` 中更新「目录结构」栏目。并且说明每个目录和文件的作用


## 编码约定

- 多写注释

## 开发环境（2026-10-06 已搭建，软件全部装在 D 盘）

| 软件 | 版本 | 安装位置 |
| ---- | ---- | ---- |
| Flutter SDK | 3.47.6 stable（Dart 3.13.5） | `D:\flutter` |
| Microsoft OpenJDK | 17.0.20.1 LTS | `D:\java\jdk-17` |
| Android SDK | platform-tools 37.0.1 / android-36 / build-tools 36.0.0 | `D:\Android\Sdk` |
| Git | 2.55.0（原已安装） | `C:\Program Files\Git` |
| 海洋CMS（phpStudy 部署） | - | `D:\phpstudy_pro`，接口 `http://localhost:8080/json.php` |


## 目录结构

```
tvbox
├── resource # 效果图参考
│   └── 首页 # 首页效果图（首页.png）
├── lib # Flutter 源码
│   ├── main.dart # 应用入口（MaterialApp + 主题）
│   ├── core # 基础配置
│   │   ├── api_config.dart # 接口地址配置（默认 http://192.168.3.35:8080，可用 --dart-define 覆盖）
│   │   └── app_theme.dart # 全局配色（黑色顶栏/红色强调）与主题
│   ├── models # 数据模型
│   │   ├── channel.dart # 频道模型（由接口分类树生成：首页 + 各顶级分类）
│   │   ├── video_type.dart # CMS 分类树模型（ac=videotypes 返回的两级分类）
│   │   ├── home_data.dart # 首页聚合数据（site/hot/recommend/new）
│   │   ├── video_item.dart # 视频条目（片名、海报、更新状态、演员等）
│   │   └── video_page.dart # 分页结果（list/total/page/totalpage）
│   ├── services # 接口服务
│   │   └── sea_cms_api.dart # 海洋CMS json.php 封装（单例，统一异常与多分类合并）
│   ├── widgets # 公共组件
│   │   ├── banner_carousel.dart # 首页轮播图（自动播放 + 指示点）
│   │   ├── channel_tab_bar.dart # 频道 Tab 栏
│   │   ├── home_top_bar.dart # 首页顶栏（Logo/站名/搜索框/筛选）
│   │   ├── section_header.dart # 栏目标题条（含「更多 >」）
│   │   ├── state_views.dart # 加载中 / 加载失败 / 空数据 占位视图
│   │   ├── video_card.dart # 海报卡片（含网络图片占位与兜底）
│   │   └── video_grid_view.dart # 通用 3 列网格列表（下拉刷新 + 上拉加载更多）
│   └── pages # 页面
│       ├── home_page.dart # 首页（顶栏 + 频道 Tab + 各频道内容）
│       └── video_list_page.dart # 通用视频列表页（各栏目「更多」入口）
├── android # Android 工程（已配置 INTERNET 权限、明文 HTTP、Gradle 阿里云镜像）
├── ios # iOS 工程
├── web # Web 工程
├── test # 测试（当前为海报卡片组件测试）
├── CODEBUDDY.md # 项目约定与 Agent 工作规范（IDE 每次对话自动读取）
├── DEV_NOTES.md # 开发日志、技术点记录、问题与解决方案
```

## 客户端结构说明

- 首页 = 顶栏（固定）+ 频道 Tab + 频道内容区（`IndexedStack` 保留滚动位置，频道内容懒加载）
- **频道导航由接口生成**：`ac=videotypes` 分类树 → `Channel.buildFromTypes()`，第一项固定「首页」，其余为 CMS 顶级分类（当前：电影 / 电视剧 / 综艺 / 动漫）
- 频道取数：`Channel.typeIds` 为「父分类 + 全部子分类」，`SeaCmsApi.fetchMergedList` 并发请求后合并按上架时间排序（海洋CMS 视频挂在子分类上，父分类直接查为空）
- 详情页 / 播放页尚未开发，点击影片暂以提示代替

## 后台接口（本地海洋CMS）

- 接口文件：`D:\phpstudy_pro\WWW\qiyi\json.php`，统一返回 `{code, msg, data}`
- 客户端使用：`home`（首页聚合）、`videotypes`（分类树）、`videolist`（列表，支持 page/pagesize/type/order/keyword/commend）
- 注意：`json.php` 的分类递归接口曾因游标名复用被截断，已修复为每层唯一游标名，改动该文件时请保留该修复
