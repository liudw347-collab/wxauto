#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
==================================================================
定州市第八中学 - 假期安全提醒每日自动发送脚本
==================================================================
功能：
    1. 每天定时向【班级家长群】发送当日安全提醒文案
    2. 自动截图所发送的消息
    3. 将截图转发至【班主任工作群】

依赖：wxauto >= 2.x  （pip install wxauto）
运行环境：Windows 10/11 + 微信 PC 版（已登录、窗口可见）
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

# --- 群名设置 ---
# 测试模式：True  → 仅发到"文件传输助手"，先验证脚本可用再切到正式
# 正式模式：False → 发到下方真实群名
TEST_MODE = True

PARENT_GROUP_NAME = "XX班家长群"      # 正式：班级家长群（接收安全提醒）
WORK_GROUP_NAME   = "班主任工作群"     # 正式：班主任工作群（接收截图转发）
TEST_TARGET       = "FileHelper"      # 测试模式下的目标（文件传输助手）

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
#                        主 流 程
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


def send_once() -> bool:
    """执行一次完整流程：发送 → 截图 → 转发。成功返回 True。"""
    try:
        from wxauto import WeChat
    except ImportError:
        logging.error("未安装 wxauto，请先运行 install_deps.bat 或执行：pip install wxauto")
        return False

    # 1) 连接微信
    try:
        wx = WeChat()
        logging.info("✓ 微信已连接")
    except Exception as e:
        logging.error(f"连接微信失败，请确认：① 微信 PC 版已登录；② 微信窗口未最小化；③ 未运行多个微信实例。错误：{e}")
        return False

    parent_target, work_target = get_targets()
    reminder_text = build_reminder_text()
    today_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    screenshot_path = os.path.join(SCREENSHOT_DIR, f"reminder_{today_str}.png")

    # 2) 向家长群发送文案
    try:
        wx.SendMsg(msg=reminder_text, who=parent_target)
        logging.info(f"✓ 安全提醒已发送至【{parent_target}】")
    except Exception as e:
        logging.error(f"发送到【{parent_target}】失败：{e}")
        return False

    # 3) 等待消息渲染后截图
    time.sleep(SEND_WAIT_SECONDS)
    try:
        # 不同 wxauto 版本截图 API 名略不同，做兼容处理
        if hasattr(wx, "Screenshot"):
            # 新版 API：Screenshot(full, savepath)
            try:
                wx.Screenshot(full=True, savepath=screenshot_path)
            except TypeError:
                wx.Screenshot(savedpath=screenshot_path)
        elif hasattr(wx, "SaveCurrentChat"):
            wx.SaveCurrentChat(screenshot_path)
        else:
            raise RuntimeError("wxauto 版本不支持截图方法，请升级：pip install -U wxauto")
        logging.info(f"✓ 截图已保存：{screenshot_path}")
    except Exception as e:
        logging.error(f"截图失败：{e}")
        return False

    # 4) 将截图转发至工作群
    try:
        wx.SendFiles(filepath=screenshot_path, who=work_target)
        logging.info(f"✓ 截图已转发至【{work_target}】")
    except Exception as e:
        logging.error(f"转发截图到【{work_target}】失败：{e}")
        return False

    return True


def main():
    setup_logging()
    mode = "测试模式（文件传输助手）" if TEST_MODE else "正式模式"
    logging.info(f"====== 开始执行每日安全提醒任务 [{mode}] ======")

    for attempt in range(1, MAX_RETRY + 1):
        logging.info(f"第 {attempt}/{MAX_RETRY} 次尝试 ...")
        if send_once():
            logging.info("✓✓✓ 任务执行成功 ✓✓✓")
            return 0
        if attempt < MAX_RETRY:
            logging.info(f"等待 {RETRY_INTERVAL} 秒后重试 ...")
            time.sleep(RETRY_INTERVAL)

    logging.error("✗ 已达最大重试次数，任务失败。请检查微信是否登录、群名是否正确。")
    return 1


if __name__ == "__main__":
    sys.exit(main())
