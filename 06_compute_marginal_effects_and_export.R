# ==========================================
# 06_compute_marginal_effects_and_export.R
# Compute marginal effects and export figures/tables
# ==========================================

library(data.table)
library(ggplot2)

m_het1 <- readRDS("out/models/m_het1.rds")
m_bread <- readRDS("out/models/m_bread.rds")

calc_marginal_effects <- function(model, base_term, interact_term, labels){
  b <- coef(model)
  V <- vcov(model)
  
  terms <- c(base_term, interact_term)
  b_sub <- b[terms]
  V_sub <- V[terms, terms]
  
  one <- function(z, label){
    cvec <- c(1, z)
    est <- sum(cvec * b_sub)
    se  <- sqrt(as.numeric(t(cvec) %*% V_sub %*% cvec))
    p   <- 2 * (1 - pnorm(abs(est / se)))
    
    data.table(
      scenario = label,
      z_value = z,
      estimate = est,
      std_error = se,
      p_value = p,
      percent_change = 100 * (exp(est) - 1),
      ci_lower = 100 * (exp(est - 1.96 * se) - 1),
      ci_upper = 100 * (exp(est + 1.96 * se) - 1)
    )
  }
  
  rbindlist(list(
    one(-1, labels[1]),
    one(0,  labels[2]),
    one(1,  labels[3])
  ))
}

# Male wage premium marginal effects
mfx_mw <- calc_marginal_effects(
  m_het1,
  "post2016_clean:male",
  "post2016_clean:male:z_male_wage_premium_2015",
  c(
    "Low male wage premium (-1 SD)",
    "Mean male wage premium (0 SD)",
    "High male wage premium (+1 SD)"
  )
)

# Breadwinner exposure marginal effects
mfx_bw <- calc_marginal_effects(
  m_bread,
  "post2016_clean:male",
  "post2016_clean:male:z_breadwinner_exposure_2015",
  c(
    "Low breadwinner exposure (-1 SD)",
    "Mean breadwinner exposure (0 SD)",
    "High breadwinner exposure (+1 SD)"
  )
)

fwrite(mfx_mw, "out/tables/D3_marginal_effects_male_wage_premium.csv")
fwrite(mfx_bw, "out/tables/D3_marginal_effects_breadwinner_exposure.csv")

# Figure 1
mfx_mw_plot <- copy(mfx_mw)
mfx_mw_plot[, z_label := factor(
  z_value,
  levels = c(-1, 0, 1),
  labels = c("Low wage premium\n(-1 SD)",
             "Mean wage premium\n(0 SD)",
             "High wage premium\n(+1 SD)")
)]

fig1 <- ggplot(mfx_mw_plot, aes(x = z_label, y = percent_change)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.12) +
  labs(
    x = NULL,
    y = "Male-specific reform effect (%)",
    title = "Male-specific post-reform effect by wage premium",
    subtitle = "Marginal effects at low, mean, and high male wage premium"
  ) +
  theme_minimal(base_size = 12)

ggsave("out/figures/Figure1_marginal_effects_wagepremium.png",
       fig1, width = 7, height = 4.8, dpi = 300)

# Figure 2
mfx_bw_plot <- copy(mfx_bw)
mfx_bw_plot[, z_label := factor(
  z_value,
  levels = c(-1, 0, 1),
  labels = c("Low breadwinner exposure\n(-1 SD)",
             "Mean breadwinner exposure\n(0 SD)",
             "High breadwinner exposure\n(+1 SD)")
)]

fig2 <- ggplot(mfx_bw_plot, aes(x = z_label, y = percent_change)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper), width = 0.12) +
  labs(
    x = NULL,
    y = "Male-specific reform effect (%)",
    title = "Male-specific post-reform effect by breadwinner exposure",
    subtitle = "Marginal effects at low, mean, and high breadwinner exposure"
  ) +
  theme_minimal(base_size = 12)

ggsave("out/figures/Figure2_marginal_effects_breadwinner_exposure.png",
       fig2, width = 7, height = 4.8, dpi = 300)

cat("06 completed.\n")