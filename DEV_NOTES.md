# DEV_NOTES.md

> 项目开发记录：所有开发事项、技术点、问题与解决方案统一记录于此。

## 开发日志

### 2026-10-06 开发环境搭建完成

- 检查现状：Git 已装（C 盘，2.55）；海洋CMS 已通过 phpStudy 部署在 `http://localhost:8080/`（返回 200，无需再装 PHP 环境）；Flutter / JDK / Android SDK 均缺失。
- **全部新软件安装在 D 盘**：
  - Flutter SDK 3.47.6（stable，Dart 3.13.5）→ `D:\flutter`
  - Microsoft OpenJDK 17.0.20.1 → `D:\java\jdk-17`
  - Android SDK → `D:\Android\Sdk`（cmdline-tools 19.0 + platform-tools 37.0.1 + platforms;android-36 + build-tools;36.0.0）
- 配置了用户级环境变量：`JAVA_HOME`、`ANDROID_HOME`、`ANDROID_SDK_ROOT`、`PUB_HOSTED_URL`、`FLUTTER_STORAGE_BASE_URL`，并将 `D:\flutter\bin` 等追加到用户 Path。
- 执行 `flutter config --android-sdk D:\Android\Sdk` 持久化 SDK 路径，并接受全部 Android 许可协议。
- `flutter doctor` 最终结果：Flutter √、Android toolchain √；剩余警告（Visual Studio 不完整、github.com 不可达）不影响 Android 开发，予以忽略。

### 2026-10-06 首页开发完成（第一步：客户端骨架 + 首页）

- 项目骨架：在当前目录执行 `flutter create --org com.tvbox --platforms android,ios,web --project-name tvbox .`
- 新增依赖：`http`（接口请求）、`cached_network_image`（海报图片缓存）
- 代码分层：`lib/core`（主题、接口配置）、`lib/models`（数据模型）、`lib/services`（接口服务）、`lib/widgets`（公共组件）、`lib/pages`（页面）
- 按 `resource/首页` 效果图实现首页：
  - 黑色顶栏：Logo + 站名 + 圆角搜索框 + 描边「筛选」按钮
  - 频道 Tab：首页 / Netflix / 电影 / 电视剧 / 短剧 / 动漫（可横向滚动，选中红色加粗 + 底部红条）
  - 首页频道内容：轮播图（自动播放 + 指示点）→「每日推荐」横滑海报 →「近期热播电影」3 列网格（均带「更多 >」入口）
  - 其它频道：3 列海报网格，支持下拉刷新、上拉自动加载更多
  - 频道内容懒加载（切到哪个频道才请求），`IndexedStack` 保留各频道滚动位置
- 已在模拟器（emulator-5554）安装运行并截图比对效果图：首页、电影、电视剧、动漫（空态）均正常。

### 2026-10-06 顶部频道导航改为接口动态生成

- 需求：顶部导航内容必须来自接口，不能写死。
- 数据源：`ac=videotypes` 返回分类树（两级），客户端 `Channel.buildFromTypes()` 生成频道列表：
  - 第一项固定「首页」（聚合内容），其余 = CMS 顶级分类
  - 每个频道的取数范围 = 该分类及其全部子分类 id（`SeaCmsApi.fetchMergedList` 并发合并）
- 频道加载失败时保留「首页」频道不阻塞使用，并弹出带「重试」的提示。
- 客户端删除了原来写死的 `Channel.all`（Netflix / 短剧），`Channel` 也不再保留 keyword 兜底字段。
- 实测顶部导航变为：**首页 / 电影 / 电视剧 / 综艺 / 动漫**；电影、电视剧有数据；综艺、动漫为真实的空态（CMS 里确实没有这两类影片，视频仅分布在 爱情片3 / 科幻片2 / 恐怖片12 / 大陆剧90 / 日韩剧38 五个子分类下）。
- **修复了 CMS 接口 bug**：`json.php` 的 `get_video_types()` / `get_news_types()` 递归时复用固定游标名 `types`，内层查询会覆盖外层同名游标，导致 `ac=videotypes` 只返回第一个父分类和第一个子分类。改为每层唯一游标名（`types_<upid>`）后返回完整分类树。

### 接口约定（本地海洋CMS json.php）

- 首页聚合：`ac=home` → `site` / `hot_videos`（轮播）/ `new_videos`（近期热播）/ `recommend_videos`（推荐位）/ `news`
- 列表：`ac=videolist` 支持 `page` / `pagesize` / `type` / `order`（time、hit 等）/ `keyword` / `commend`
- 分类为**两级结构**：视频挂在子分类上（如 电影(1) → 动作片5/爱情片6/科幻片7/恐怖片8…），父分类 `type=1` 查不到数据，因此频道取数采用「父分类 + 子分类一起请求后合并按上架时间排序」（`SeaCmsApi.fetchMergedList`）
- 短剧在 CMS 中没有对应分类，频道用 `keyword=短剧` 搜索兜底
- «每日推荐»：CMS 推荐位未配置时自动回退到热门数据，避免栏目空白
- 注意：接口返回 UTF-8，必须用 `utf8.decode(response.bodyBytes)` 解码，否则中文乱码

## 技术点记录

- **Flutter 国内镜像**：`PUB_HOSTED_URL=https://pub.flutter-io.cn`、`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`，避免直连 google/pub.dev 超时；镜像版本清单接口 `https://storage.flutter-io.cn/flutter_infra_release/releases/releases_windows.json` 可获取最新 stable 版本号与 sha256。
- **免 Android Studio 安装 Android SDK**：下载 `commandlinetools-win-*.zip` 解压到 `<sdk>\cmdline-tools\latest`，用 `sdkmanager --sdk_root=<sdk> platform-tools "platforms;android-36" "build-tools;36.0.0"` 命令行安装，无需完整 IDE。
- **sdkmanager 许可自动应答**：PowerShell 直接管道 `("y`n"*30) | sdkmanager.bat` 无效，需生成应答文件后用 cmd 重定向 stdin（`< yes.txt`）。
- **Flutter 指定 SDK 路径**：`flutter config --android-sdk <path>` 写入全局配置，否则 `flutter doctor --android-licenses` 报 "Unable to locate Android SDK"。
- **大文件下载校验**：断点续传（curl `-C -`）拼接过损坏分段导致 SHA256 不匹配，删除后完整重下即可；解压前务必校验。
- **接口地址（重要）**：模拟器/真机与电脑不在同一网络命名空间，**必须使用电脑的局域网 IP**：`http://192.168.3.35:8080`（标准 AVD 的 `10.0.2.2` 在第三方模拟器/真机上不可用）。配置集中在 `lib/core/api_config.dart`，支持 `flutter run --dart-define=API_BASE_URL=http://localhost:8080` 覆盖（桌面/iOS 模拟器调试用）。
- **Android 明文 HTTP**：Android 9+ 默认禁止 http，需在 `android/app/src/main/AndroidManifest.xml` 加 `<uses-permission android:name="android.permission.INTERNET"/>` 与 `android:usesCleartextTraffic="true"`。
- **Gradle 仓库镜像（国内网络必配）**：本机直连 `repo.maven.apache.org` 被 CDN 劫持（证书为自签 `O=redirect-cnzz`），Gradle 报 `PKIX path building failed`。解决方案：在 `android/settings.gradle.kts`、`android/build.gradle.kts` 与 Flutter 内置构建 `D:\flutter\packages\flutter_tools\gradle\settings.gradle.kts`（**flutter upgrade 会覆盖，升级后需重加**）中优先加入阿里云镜像 `maven.aliyun.com/repository/{gradle-plugin,google,public}`，另在 `~/.gradle/init.gradle` 全局追加镜像。
  - 注意：Flutter 内置构建使用 `RepositoriesMode.FAIL_ON_PROJECT_REPOS`，**不能**往 `project.repositories` 里加仓库，只能加到 buildscript / settings 级。
- **脚本化验证方式**（比 `flutter run` 更适合自动验证）：`flutter build apk --debug` → `adb install -r` → `adb shell am start -n 包名/.MainActivity` → `adb exec-out screencap -p > x.png`，再用图片查看比对效果图；Tab 点击用 `adb shell input tap x y`（1080x1920 屏幕下频道栏 y≈266）。
- **海洋CMS 分类接口坑**：`ac=videotypes` 的递归实现里游标名必须每层唯一（见“问题与解决方案”），否则分类树被截断；另外 `ac=list` 只返回接口文档目录，不返回分类，分类只能从 `videotypes` 取。
- **频道取数范围**：CMS 视频挂在子分类，顶级分类（电影/电视剧）直接查 `type=<父id>` 会是空，所以一个频道要聚合「父 id + 全部子 id」再按上架时间排序去重。
- **PowerShell 读接口 JSON**：`curl -o` 写的文件是 UTF-8，必须用 `[System.IO.File]::ReadAllBytes` + `Encoding.UTF8.GetString` 读取，否则中文乱码并可能让 `ConvertFrom-Json` 解析失败；报错信息里出现的“换行”多为控制台折行显示，不代表内容真有换行。

## 问题与解决方案

- **问题**：后台 `Start-Process` 启动的下载进程随命令会话结束被回收，导致下载中断且文件为 0 字节。
  **解决**：改用前台 `curl.exe` 直接下载；SHA256 校验失败时删除后重下。
- **问题**：PowerShell 中向 `.bat` 管道输入 `y` 无法传递给 sdkmanager，许可无法自动接受。
  **解决**：把 30 行 `y` 写入文本文件，用 `cmd /c "xxx.bat ... < yes.txt"` 重定向标准输入。
- **问题**：IDE 命令实际由 cmd 解释执行，PowerShell 语法（如 `#` 注释）直接报错。
  **解决**：把 PowerShell 命令写入 `.ps1` 脚本文件，用 `powershell -NoProfile -ExecutionPolicy Bypass -File xxx.ps1` 执行。
- **问题**：App 在模拟器上提示「无法连接服务器 http://10.0.2.2:8080」。
  **解决**：把接口地址改为电脑局域网 IP `http://192.168.3.35:8080`（见 `lib/core/api_config.dart`）。
- **问题**：模拟器进程、后台下载进程会随命令会话结束被回收，导致「启动模拟器→安装→截图」分多条命令执行时设备消失。
  **解决**：把「启动模拟器 + 等待开机 + 安装 APK + 启动应用 + 截图」写入同一个脚本一次执行；已有设备（emulator-5554）运行时则直接复用。
- **问题**：`flutter build apk` 报 `JAVA_HOME is not set`。
  **解决**：每次执行 Flutter/Gradle 命令前显式设置 `JAVA_HOME=D:\java\jdk-17` 与 `ANDROID_HOME=D:\Android\Sdk` 并加入 Path。
- **问题**：本机 Android 模拟器缺少加速驱动（AEHD/WHPX 未安装），`emulator -accel-check` 报 "hypervisor driver is not installed"。
  **解决**：改用已连接可用设备（emulator-5554）验证；如需启用本机 AVD，需安装加速驱动并重启系统。
- **问题**：`ac=videotypes` 只返回「电影 → 动作片」一个分类，顶部导航无法按接口生成。
  **原因**：`json.php` 中 `get_video_types()` 递归调用时用了同一个游标名 `types`，内层 `$dsql->Execute('types')` 覆盖了外层游标，外层 `while` 循环在第一行后就结束（每层都少一行）。
  **解决**：游标名改为每层唯一 —— `$dsql->Execute('types_' . $upid)` / `GetArray('types_' . $upid)`；`get_news_types()` 同样问题一并修复为 `ntypes_<upid>`。修复后接口返回完整分类树（电影/电视剧/综艺/动漫）。
