# ==============================================================================
# HEOR End-to-End Project: Survival Analysis & Economic Evaluation (PSM)
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. 环境准备与数据加载
# ------------------------------------------------------------------------------
# 如果未安装，请先运行: install.packages(c("survival", "survminer", "ggplot2"))
library(survival)
library(survminer)
library(ggplot2)

# 强制重置 ggplot2 全局主题，彻底规避 element_grob 样式冲突报错
theme_set(theme_grey()) 

# 【修复：直接从包内抓取数据集】确保 100% 成功加载，不弹 Warning
lung <- survival::lung

# 【数据清洗】将性别编码 (1, 2) 转换为具有实际医疗意义的标签
lung$sex <- factor(lung$sex, levels = c(1, 2), labels = c("Male", "Female"))


# ------------------------------------------------------------------------------
# 2. 建立 Kaplan-Meier 生存分析模型
# ------------------------------------------------------------------------------
# 构建终点事件：time 为生存天数，status == 2 代表患者死亡（Event）
surv_object <- Surv(time = lung$time, event = lung$status == 2)

# 拟合生存曲线，按性别（sex）进行队列分层
km_fit <- survfit(surv_object ~ sex, data = lung)


# ------------------------------------------------------------------------------
# 3. 绘制符合 HTA 申报标准的生存曲线图
# ------------------------------------------------------------------------------
km_plot <- ggsurvplot(
  km_fit,
  data = lung,
  title    = "Kaplan-Meier Survival Curves by Gender (NCCTG Lung Cancer)",
  xlab     = "Time in Days",
  ylab     = "Survival Probability",
  palette  = c("#E7B800", "#2E9FDF"), # 经典医药研报配色：男黄、女蓝
  pval     = TRUE,                    # 自动进行 Log-rank 检验并显示 P 值
  conf.int = TRUE,                    # 显示 95% 置信区间阴影
  censor   = TRUE,                    # 标记出数据截尾（中途退出/失访患者）
  
  # 英国 NICE 审批必看的风险表（Number at risk）
  risk.table = TRUE,
  risk.table.col = "strata",
  risk.table.height = 0.25,
  
  # 【修复：使用经典主题】完美避开高级文本组件导致的图形渲染报错
  ggtheme = theme_classic() 
)

# 在 RStudio 界面中打印渲染生存曲线图
print(km_plot)


# ------------------------------------------------------------------------------
# 4. 卫生经济学扩展：分区生存模型 (Partitioned-Survival Model)
# ------------------------------------------------------------------------------
# 设定模拟的时间视窗（700天，处于随访期内）
tau <- 700  

# 【修复：统一使用 km_fit】提取限制性平均生存时间 (RMST)，即生存曲线下面积 (AUC)
tab <- summary(km_fit, rmean = tau)$table

# 将平均存活天数 (Days) 除以 365.25，转化为卫生经济学核心指标：生命年 (Life-Years, LY)
ly <- tab[, "rmean"] / 365.25                  

# 设定临床价值与成本假设（标签需与 tab 的行名 'sex=Male' 和 'sex=Female' 严格对齐）
utility <- 0.75                                                # 健康效用值 (Utility)
cost    <- c("sex=Male" = 30000, "sex=Female" = 12000)        # 模拟每位患者的总治疗费用 (£)

# 计算质量调整生命年 (QALY = Life-Years * Utility)
qaly <- ly * utility

# 计算增量成本效益比 (ICER = Delta Cost / Delta QALY)
delta_cost <- cost["sex=Male"] - cost["sex=Female"]
delta_qaly <- qaly["sex=Male"] - qaly["sex=Female"]
icer       <- delta_cost / delta_qaly

# ------------------------------------------------------------------------------
# 5. 打印并输出最终的 HEOR 评估报告
# ------------------------------------------------------------------------------
cat("\n========================================================\n")
cat("          HEOR ECONOMIC EVALUATION REPORT               \n")
cat("========================================================\n")
cat(sprintf("Male Mean Life-Years (LY)   : %.3f years\n", ly["sex=Male"]))
cat(sprintf("Female Mean Life-Years (LY) : %.3f years\n", ly["sex=Female"]))
cat("--------------------------------------------------------\n")
cat(sprintf("Incremental QALYs (ΔQALY)   : %.3f\n", delta_qaly))
cat(sprintf("Incremental Cost (ΔCost)    : GBP %.0f\n", delta_cost))
cat(sprintf("Calculated ICER             : GBP %.0f per QALY\n", icer))
cat("--------------------------------------------------------\n")
cat("HEOR Insight: Since the Male cohort incurs higher costs but yields \n")
cat("fewer QALYs, it is 'Strictly Dominated' by the Female cohort. \n")
cat("========================================================\n")

