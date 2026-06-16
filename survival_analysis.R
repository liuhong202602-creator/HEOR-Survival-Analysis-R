install.packages(c("survival", "survminer"))
# ==============================================================================
# HEOR Project: Survival Analysis on Lung Cancer Patient Cohorts
# Objective: Clean clinical data, fit a Kaplan-Meier model, and visualize survival curves.
# ==============================================================================

# 1. 加载 HEOR 核心生存分析包
library(survival)
library(survminer)

# 2. 载入 R 自带的真实临床试验数据集 (NCCTG Lung Cancer Data)
data(lung)

# 【数据清洗与标签优化】
# 为了让图表更具可读性（更职业化），我们将性别(sex)从 1 和 2 转换为 "Male" 和 "Female"
lung$sex <- factor(lung$sex, levels = c(1, 2), labels = c("Male", "Female"))

# 查看数据前几行，确保数据正确加载
head(lung)


# 3. 构建生存对象 (Survival Object)
# time: 患者存活天数; status: 2 代表死亡(Event), 1 代表数据截尾(Censored)
# 在 R 中，survival 对象默认以 status == 2 或 TRUE 代表事件发生
surv_object <- Surv(time = lung$time, event = lung$status == 2)


# 4. 拟合 Kaplan-Meier 模型 (按性别分组对比)
# ~ sex 表示我们想对比男性和女性在生存率上的差异
km_fit <- survfit(surv_object ~ sex, data = lung)


# 5. 绘制符合 HTA / 医药研报标准的生存曲线
# 这张图会展示生存概率随时间（天数）的变化，并带有置信区间和统计学显著性检验(p-value)
km_plot <- ggsurvplot(
  km_fit,
  data = lung,
  
  # 视觉与图表优化
  title    = "Kaplan-Meier Survival Curves by Gender (NCCTG Lung Cancer)",
  xlab     = "Time in Days",                 # X轴：生存天数
  ylab     = "Survival Probability",          # Y轴：生存概率 (1.0 -> 0)
  palette  = c("#E7B800", "#2E9FDF"),        # 高级配色：男性黄色，女性蓝色
  
  # 临床研报核心要素
  pval     = TRUE,                           # 自动计算并显示 Log-rank 检验的 P 值
  conf.int = TRUE,                           # 显示 95% 置信区间阴影（证明数据的可靠性）
  censor   = TRUE,                           # 在曲线上标记出“中途退出试验/失去随访”的患者(Tick marks)
  
  # 风险表（HEOR 报告必备！）
  risk.table = TRUE,                         # 在图表下方显示 "Number at risk" 表格
  risk.table.col = "strata",                 # 风险表文字颜色与曲线一致
  risk.table.height = 0.25,                  # 调整风险表所占的高度比例
  
  # 整体样式
  ggtheme = theme_bw()                       # 使用干净、商务的网格背景
)

# 6. 在 RStudio 中渲染出图
print(km_plot)
