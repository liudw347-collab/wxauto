#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
==================================================================
定州市第八中学 - 假期安全提醒每日自动发送脚本（v3 · 多后端）
==================================================================
功能：
    1. 每天定时向【班级家长群】发送当日安全提醒文案
    2. 自动截图所发送的消息
    3. 将截图转发至【班主任工作群】

支持两种后端（按微信版本选择）：

  BACKEND = "pywechat127"  ← 推荐！支持微信 4.1.6+（含 4.1.9+ 新版）
                            pip install pywechat127
                            import from pyweixin

  BACKEND = "wxauto4"      ← 备选。仅支持微信 4.1.0 - 4.1.8.107
                            pip install wxauto4

依赖安装（任选一种）：
  py -3.11 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pywechat127
  py -3.11 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple wxauto4

运行环境：
    - Windows 10/11
    - 微信 PC 版 4.1.x（推荐 pywechat127 后端，支持最新版）
    - Python 3.10 ~ 3.12（推荐 3.11）
==================================================================
"""

import os
import sys
import time
import logging
from datetime import datetime

# ====================================================================
#                        配 置 区 （请按需修改）
# ====================================================================

# --- 后端选择 ---
# "auto"     -> 自动检测已安装的后端（推荐）
# "pywechat" -> 使用 pywechat127（支持微信 4.1.6+，含 4.1.9+ 新版）
# "wxauto4"  -> 使用 wxauto4（仅支持微信 4.1.0 - 4.1.8.107）
BACKEND = "auto"

# --- 群名设置 ---
# 测试模式：True  → 仅发到「文件传输助手」，先验证脚本可用再切到正式
# 正式模式：False → 发到下方真实群名
TEST_MODE = True

PARENT_GROUP_NAME = "XX班家长群"      # 正式：班级家长群（接收安全提醒）
WORK_GROUP_NAME   = "班主任工作群"     # 正式：班主任工作群（接收截图转发）
TEST_TARGET       = "文件传输助手"      # 测试模式下的目标

# --- 路径设置（默认放在 D 盘，可按需修改）---
BASE_DIR          = r"D:\safety_reminder"
SCREENSHOT_DIR    = os.path.join(BASE_DIR, "screenshots")
LOG_FILE          = os.path.join(BASE_DIR, "send.log")

# --- 容错设置 ---
MAX_RETRY         = 3       # 失败重试次数
RETRY_INTERVAL    = 10      # 每次重试间隔（秒）
SEND_WAIT_SECONDS = 3       # 发送后到截图的等待秒数（消息渲染需要时间）

# ====================================================================
#                        文 案 模 板
# ====================================================================

def build_reminder_text() -> str:
    """根据当前日期动态生成安全提醒文案"""
    today = datetime.now().strftime("%Y年%m月%d日")
    return f"""严谨治校  勤奋进取

定州市第八中学假期安全提醒:
       为确保同学们度过一个安全、健康的假期，特提醒以下注意事项：

1. 交通安全
      遵守交通规则，不闯红灯、不骑电动车，过马路走斑马线。
      乘坐正规车辆，不坐超载车、黑车，拒乘无牌无证车辆。

2. 防溺水安全
      禁止私自到水库、河道、池塘等危险水域玩耍或游泳。

3. 居家安全
       注意用火用电安全。独自在家时锁好门窗，不轻易给陌生人开门，
       遇到紧急情况及时联系家长或报警。

4. 网络安全
       警惕网络诈骗，不轻易点击陌生链接或转账，遇到可疑情况及时告知家长。

5. 饮食卫生
       注意饮食均衡，不暴饮暴食，少吃生冷、油炸食品。

6. 心理健康
       多与家人沟通交流，适当参加户外运动或兴趣活动，缓解学习压力。
       遇到问题及时向家长、老师或心理老师求助。

温馨提示：
       外出活动前告知家长去向。
       注意天气变化，及时增减衣物，预防感冒。

      安全无小事，防范于未然！祝同学们假期愉快，平安返校！

崇德 励志 和谐 进取
善教 好学 友爱 创新
家校携手，共育共赢共未来!

                   {today}
           —— 定州市第八中学"""


# ====================================================================
#                        工 具 函 数
# ====================================================================

def setup_logging():
    """配置日志（同时输出到文件和控制台）"""
    os.makedirs(BASE_DIR, exist_ok=True)
    os.makedirs(SCREENSHOT_DIR, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[
            logging.FileHandler(LOG_FILE, encoding="utf-8"),
            logging.StreamHandler(sys.stdout),
        ],
    )


def get_targets():
    """根据 TEST_MODE 返回 (家长群目标, 工作群目标)"""
    if TEST_MODE:
        logging.warning("⚠ 当前为测试模式，消息仅发送至【文件传输助手】")
        return TEST_TARGET, TEST_TARGET
    return PARENT_GROUP_NAME, WORK_GROUP_NAME


def detect_backend() -> str:
    """自动检测已安装的后端：优先 pywechat127，其次 wxauto4"""
    if BACKEND != "auto":
        return BACKEND

    # 优先 pywechat127（支持新版微信）
    try:
        import pyweixin  # noqa: F401
        return "pywechat"
    except ImportError:
        pass

    # 其次 wxauto4（仅支持 4.1.8.107 及以下）
    try:
        import wxauto4  # noqa: F401
        return "wxauto4"
    except ImportError:
        pass

    return ""


def screenshot_wechat_window_win32(save_path: str) -> bool:
    """
    用 win32gui + PrintWindow 截取微信窗口区域并保存为 PNG。
    适用于 wxauto4 后端（wxauto4 无内置截图方法）。
    """
    try:
        import win32gui
        import win32ui
        import win32con
        from ctypes import windll
        from PIL import Image

        wechat_hwnd = None

        def _enum_callback(hwnd, _):
            nonlocal wechat_hwnd
            if win32gui.IsWindowVisible(hwnd):
                cls = win32gui.GetClassName(hwnd)
                # 微信 4.x 主窗口类名
                if cls == "WeChatMainWndForPC":
                    wechat_hwnd = hwnd
                    return False
            return True

        win32gui.EnumWindows(_enum_callback, None)

        if not wechat_hwnd:
            wechat_hwnd = win32gui.FindWindow("WeChatMainWndForPC", None)

        if not wechat_hwnd:
            logging.error("未找到微信主窗口（类名 WeChatMainWndForPC）。")
            return False

        try:
            win32gui.ShowWindow(wechat_hwnd, win32con.SW_RESTORE)
            win32gui.SetForegroundWindow(wechat_hwnd)
            time.sleep(0.5)
        except Exception:
            pass

        left, top, right, bottom = win32gui.GetWindowRect(wechat_hwnd)
        width = right - left
        height = bottom - top
        if width <= 0 or height <= 0:
            logging.error(f"微信窗口尺寸异常：{width}x{height}")
            return False

        hwnd_dc = win32gui.GetWindowDC(wechat_hwnd)
        mfc_dc = win32ui.CreateDCFromHandle(hwnd_dc)
        save_dc = mfc_dc.CreateCompatibleDC()
        bmp_obj = win32ui.CreateBitmap()
        bmp_obj.CreateCompatibleBitmap(mfc_dc, width, height)
        save_dc.SelectObject(bmp_obj)

        result = windll.user32.PrintWindow(wechat_hwnd, save_dc.GetSafeHdc(), 0x00000002)
        if result != 1:
            save_dc.BitBlt((0, 0), (width, height), mfc_dc, (0, 0), win32con.SRCCOPY)

        bmp_obj.SaveBitmapFile(save_dc, save_path)

        save_dc.DeleteDC()
        mfc_dc.DeleteDC()
        win32gui.ReleaseDC(wechat_hwnd, hwnd_dc)
        win32gui.DeleteObject(bmp_obj.GetHandle())

        if os.path.exists(save_path) and os.path.getsize(save_path) > 1000:
            try:
                with Image.open(save_path) as img:
                    img.verify()
                return True
            except Exception:
                pass

        logging.error(f"截图文件异常：{save_path}")
        return False

    except Exception as e:
        logging.error(f"截图失败：{e}")
        return False


def screenshot_full_screen_pyautogui(save_path: str) -> bool:
    """
    用 PyAutoGUI 截取整个屏幕（pywechat127 自带依赖）。
    适用于 pywechat127 后端。
    """
    try:
        import pyautogui
        # 把微信拉到前台（pywechat127 已通过 Navigator.open_dialog_window 处理）
        time.sleep(0.5)
        img = pyautogui.screenshot(save_path)
        if img is None and os.path.exists(save_path):
            return True
        return os.path.exists(save_path) and os.path.getsize(save_path) > 1000
    except Exception as e:
        logging.error(f"截图失败：{e}")
        return False


# ====================================================================
#                  后端实现：pywechat127
# ====================================================================

def send_once_pywechat() -> bool:
    """使用 pywechat127 (pyweixin 包) 后端执行完整流程"""
    try:
        from pyweixin import Messages, Files, Navigator, Tools, GlobalConfig
    except ImportError:
        logging.error(
            "未安装 pywechat127，请执行：\n"
            "  py -3.11 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pywechat127"
        )
        return False

    # 全局参数
    GlobalConfig.is_maximize = False
    GlobalConfig.close_weixin = False
    GlobalConfig.search_pages = 0  # 用顶部搜索栏

    # 1) 连接微信
    try:
        if not Tools.is_weixin_running():
            logging.error("微信未运行，请先打开微信 4.1.6+ 并扫码登录")
            return False
        main_window = Navigator.open_weixin()
        logging.info("✓ 微信已连接（pywechat127 后端）")
        if hasattr(Tools, "about_weixin"):
            logging.info(f"  微信版本信息：{Tools.about_weixin()}")
    except Exception as e:
        logging.error(f"连接微信失败：{e}")
        return False

    parent_target, work_target = get_targets()
    reminder_text = build_reminder_text()
    today_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    screenshot_path = os.path.join(SCREENSHOT_DIR, f"reminder_{today_str}.png")

    # 2) 向家长群发送文案（pywechat 一站式调用，无需先 ChatWith）
    try:
        Messages.send_messages_to_friend(
            friend=parent_target,
            messages=[reminder_text],
            close_weixin=False,
        )
        logging.info(f"✓ 安全提醒已发送至【{parent_target}】")
    except Exception as e:
        logging.error(f"发送到【{parent_target}】失败：{e}")
        return False

    # 3) 截图（pywechat127 无通用截图 API，用 PyAutoGUI 全屏截图）
    time.sleep(SEND_WAIT_SECONDS)
    if not screenshot_full_screen_pyautogui(screenshot_path):
        return False
    logging.info(f"✓ 截图已保存：{screenshot_path}")

    # 4) 将截图转发至工作群
    try:
        Files.send_files_to_friend(
            friend=work_target,
            files=[screenshot_path],
            close_weixin=False,
        )
        logging.info(f"✓ 截图已转发至【{work_target}】")
    except Exception as e:
        logging.error(f"转发截图到【{work_target}】失败：{e}")
        return False

    return True


# ====================================================================
#                  后端实现：wxauto4
# ====================================================================

def send_once_wxauto4() -> bool:
    """使用 wxauto4 后端执行完整流程"""
    try:
        from wxauto4 import WeChat
    except ImportError:
        logging.error(
            "未安装 wxauto4，请执行：\n"
            "  py -3.11 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple wxauto4"
        )
        return False

    # 1) 连接微信
    try:
        wx = WeChat()
        logging.info("✓ 微信已连接（wxauto4 后端）")
    except Exception as e:
        logging.error(
            f"连接微信失败，请确认：① 微信 PC 版 4.1.x 已登录；② 微信窗口未最小化；"
            f"③ 未运行多个微信实例。错误：{e}"
        )
        return False

    parent_target, work_target = get_targets()
    reminder_text = build_reminder_text()
    today_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    screenshot_path = os.path.join(SCREENSHOT_DIR, f"reminder_{today_str}.png")

    # 2) 向家长群发送文案
    try:
        wx.ChatWith(parent_target)
        time.sleep(1)
        result = wx.SendMsg(msg=reminder_text, who=parent_target)
        if result is not None and not bool(result):
            raise RuntimeError(f"SendMsg 返回失败：{result}")
        logging.info(f"✓ 安全提醒已发送至【{parent_target}】")
    except Exception as e:
        logging.error(f"发送到【{parent_target}】失败：{e}")
        return False

    # 3) 截图
    time.sleep(SEND_WAIT_SECONDS)
    if not screenshot_wechat_window_win32(screenshot_path):
        return False
    logging.info(f"✓ 截图已保存：{screenshot_path}")

    # 4) 将截图转发至工作群
    try:
        wx.ChatWith(work_target)
        time.sleep(1)
        result = wx.SendFiles(filepath=screenshot_path, who=work_target)
        if result is not None and not bool(result):
            raise RuntimeError(f"SendFiles 返回失败：{result}")
        logging.info(f"✓ 截图已转发至【{work_target}】")
    except Exception as e:
        logging.error(f"转发截图到【{work_target}】失败：{e}")
        return False

    return True


# ====================================================================
#                        主 流 程
# ====================================================================

def main():
    setup_logging()
    backend = detect_backend()
    if not backend:
        logging.error(
            "未检测到任何后端，请安装其中之一：\n"
            "  推荐（支持新版微信）：py -3.11 -m pip install pywechat127\n"
            "  备选（仅支持微信 4.1.8.107）：py -3.11 -m pip install wxauto4"
        )
        return 1

    mode = "测试模式（文件传输助手）" if TEST_MODE else "正式模式"
    logging.info(f"====== 开始执行每日安全提醒任务 [{mode}] | 后端：{backend} ======")

    send_func = send_once_pywechat if backend == "pywechat" else send_once_wxauto4

    for attempt in range(1, MAX_RETRY + 1):
        logging.info(f"第 {attempt}/{MAX_RETRY} 次尝试 ...")
        if send_func():
            logging.info("✓✓✓ 任务执行成功 ✓✓✓")
            return 0
        if attempt < MAX_RETRY:
            logging.info(f"等待 {RETRY_INTERVAL} 秒后重试 ...")
            time.sleep(RETRY_INTERVAL)

    logging.error("✗ 已达最大重试次数，任务失败。请检查微信是否登录、群名是否正确。")
    return 1


if __name__ == "__main__":
    sys.exit(main())
