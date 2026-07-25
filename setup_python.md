# Python 环境诊断与官方版安装指南

> 本文档帮助您判断当前 Python 是否为微软商店版，并提供与商店版共存的官方版安装方案。

---

## 一、什么是「微软商店版 Python」

微软商店版 Python（Microsoft Store Python）是从 Windows 应用商店安装的 Python，安装路径形如：

```
C:\Users\<你的用户名>\AppData\Local\Microsoft\WindowsApps\Python311\python.exe
```

它有几个对 wxauto 致命的缺点：

| 问题 | 影响 |
|---|---|
| 路径重定向（sandbox） | `pip install` 装的包被装到沙箱目录，其他工具读不到 |
| COM 权限受限 | wxauto 依赖的 pywin32 经常初始化失败，控制微信时报错 |
| 任务计划程序不友好 | 通过任务计划程序调用时，沙箱环境会拒绝部分 API |
| `pythonw.exe` 缺失 | `pythonw` 常被替换为别名指向商店，运行时弹窗提示购买 |

**结论：商店版 Python 几乎无法让 wxauto 正常工作。必须改用官方版。**

---

## 二、先做一次自我诊断

打开 Windows 命令提示符（按 `Win + R` 输入 `cmd` 回车），依次执行：

### ① 看 python 命令指向哪里

```bat
where python
```

- 如果输出含 `WindowsApps`：**当前是微软商店版**，按本文档第三步安装官方版。
- 如果输出形如 `C:\Python311\python.exe` 或 `%LOCALAPPDATA%\Programs\Python\Python311\python.exe`：是官方版，无需重装。

### ② 看 Python 版本

```bat
python --version
```

- wxauto 推荐 **Python 3.8 ~ 3.13**。
- **Python 3.14 太新**，部分依赖（pywin32 等）尚未完全适配，**强烈建议改用 3.11**。

### ③ 看 py launcher 是否可用

```bat
py --version
py -0p
```

- 如果 `py` 命令可用，`py -0p` 会列出系统所有已装 Python 版本及路径，是后续切换版本的最强工具。
- 如果 `py` 不可用，安装官方版 Python 时勾选 py launcher 即可。

---

## 三、安装官方版 Python 3.11（与商店版共存，无需卸载）

### 第 1 步：下载

访问官方下载页：<https://www.python.org/downloads/release/python-3119/>

页面下方 **Files** 区域，根据系统位数选择：

- 64 位系统选：**Windows installer (64-bit)** → `python-3.11.9-amd64.exe`
- 32 位系统选：**Windows installer (32-bit)** → `python-3.11.9.exe`

> 不知道选哪个？现在 Windows 几乎都是 64 位，选 64-bit 即可。

### 第 2 步：安装时关键勾选项

双击下载的安装包，**第一屏务必勾选**：

- ✅ **Use admin privileges when installing py.exe**（建议勾选）
- ✅ **Add python.exe to PATH**（强烈建议勾选！）

然后点 **Customize installation**，下一步勾选：

- ✅ Documentation
- ✅ pip
- ✅ tcl/tk and IDLE
- ✅ **py launcher**（必选）
- ✅ **for all users**（推荐，让所有用户都能用）

「Advanced Options」页面：
- 勾选 **Install Python 3.11 for all users**
- 安装位置建议：`C:\Python311\`（好记好配置）

### 第 3 步：安装完成后验证

**关掉旧的命令行窗口**（重要！PATH 变更不刷新），重新打开一个 cmd：

```bat
py -0p
```

应能看到两行类似输出：

```
 -V:311 *        C:\Python311\python.exe
 -V:3.14         C:\Users\xxx\AppData\Local\Microsoft\WindowsApps\Python314\python.exe
```

`*` 标记的是默认版本。如果默认还是 3.14 商店版，可以这样强制指定：

```bat
py -3.11 --version
```

输出 `Python 3.11.9` 即成功。

### 第 4 步：让 pip 也走官方版

```bat
py -3.11 -m pip --version
```

看到路径含 `C:\Python311\` 即正确。

---

## 四、配置本仓库脚本使用官方版 Python

仓库内 `run_daily.bat` 顶部已预留配置项：

```bat
set "PYTHON_EXE=py -3.11"
```

`py -3.11` 会自动调用官方版 3.11 解释器，绕过商店版 3.14。这是**最推荐**的方式，无需写死路径。

如果您想用绝对路径，也可以改成：

```bat
set "PYTHON_EXE=C:\Python311\python.exe"
```

---

## 五、安装依赖时也走官方版

仓库 `install_deps.bat` 已经会自动诊断。如果它检测出当前 python 是商店版，请手动执行以下命令安装依赖：

```bat
py -3.11 -m pip install --upgrade wxauto pywin32
```

注意一定要带 `py -3.11 -m`，否则可能装到商店版的沙箱目录。

---

## 六、常见问题

### Q1：装了官方版后，原本商店版 3.14 还能用吗？

能。两个 Python 互不干扰，商店版只会在您输入 `python` 命令时被调用；只要脚本里用 `py -3.11`，就走官方版。

### Q2：能否直接卸载商店版？

可以，但没必要。卸载方式：
- 设置 → 应用 → 已安装的应用 → 搜索 "Python" → 卸载带 "Microsoft Corporation" 标识的 Python 条目。
- 卸载后系统里若有其他程序依赖商店版 Python（如某些 UWP 应用），可能会出问题，**不建议折腾**。

### Q3：装完官方版后，python 命令还指向商店版怎么办？

按以下顺序检查 PATH（系统属性 → 高级 → 环境变量 → Path）：

1. `C:\Python311\` 或 `C:\Python311\Scripts\` 应排在 `C:\Users\<用户>\AppData\Local\Microsoft\WindowsApps\` 之前。
2. 把商店版路径上移到列表底部（或删除该条目）。
3. 重启命令行窗口生效。

### Q4：任务计划程序里调 py -3.11 失败？

可能原因：任务计划程序的「起始于」字段没填或填错。
- 任务属性 → 操作 → 编辑：
  - 程序或脚本：`D:\safety_reminder\run_daily.bat`
  - 起始于：`D:\safety_reminder\`（**末尾带反斜杠**）

### Q5：能不能完全不用 Python，直接打包成 .exe？

可以，但商店版 Python 打包出的 .exe 依然不能正常工作。请先按本文档装好官方版 Python，再做打包：

```bat
py -3.11 -m pip install pyinstaller
py -3.11 -m PyInstaller --onefile --noconsole --name safety_reminder send_safety_reminder.py
```

生成的 `dist\safety_reminder.exe` 可独立运行。但**不推荐**：
- wxauto 是 UI 自动化工具，无控制台运行会让调试困难
- 文案若改动需要重新打包

建议保留 Python 脚本方式。
