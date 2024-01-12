library(tidyverse)
library(dbscan)
library(dslabs)
library(Rtsne)
library(colorspace)
library(extrafont)
loadfonts()

glimpse(dslabs::gapminder)

datagap <- dslabs::gapminder %>% filter(
  year == 2011) %>%
  na.omit() %>%
  mutate(
    gdp_million = gdp/1000000,
    log_gdp = log10(gdp)
  ) %>%
  unique()

datagap_num <- datagap %>%
  mutate(log_pop = log10(population)) %>%
  select(-country, -year, -continent, -region, -gdp, -gdp_million, -population)

skimr::skim(datagap)

data_selected <- datagap %>% select(
  country, infant_mortality, life_expectancy
) 

dups <- data_selected %>% select(-country) %>% duplicated() 

data_dup <- data_selected %>% mutate(dups = dups) %>% filter(dups == TRUE)

data_selected_mod <- data_selected %>%
  mutate(infant_mortality = ifelse(country %in% c("Israel", "South Korea"), infant_mortality + 0.1, infant_mortality)) %>%
  select(-country) %>%
  as.matrix() %>%
  Rtsne::normalize_input()

data_selected_all <- datagap_num %>%
  as.matrix() %>%
  Rtsne::normalize_input()

epsilon <- 0.02
clust <- dbscan::dbscan(data_selected_all, eps = epsilon, minPts = 4)

perplexity <- 40 

data_tsne <- data_selected_all %>%
  #Rtsne::normalize_input() %>% #comment for non-normalized input
  Rtsne::Rtsne(perplexity = perplexity)

data_cluster_tsne <- data.frame(
  x = data_tsne$Y[,1],
  y = data_tsne$Y[,2]
) %>%
  as.matrix() %>%
  Rtsne::normalize_input() %>%
  dbscan::dbscan(eps = epsilon, minPts = 4)

datagap_vis <- datagap %>%
  mutate(
    grp = clust$cluster,
    grp_tsne = data_cluster_tsne$cluster,
    x = data_tsne$Y[,1],
    y = data_tsne$Y[,2])

#vis_normalized_cluster <- as.data.frame(data_selected_mod) %>%
#  mutate(grp = clust$cluster)

ggplot(datagap_vis,#vis_normalized_cluster, 
       aes(x = infant_mortality, life_expectancy)) + 
  geom_point(aes(color = as.factor(grp)), size = 3) +
  coord_fixed() +
  labs(title = paste("Epsilon:", epsilon), x = "Infant Mortality", y = "Life Expectancy", color = "Cluster") +
  scale_color_manual(values = c("black", colorspace::qualitative_hcl(palette = "Set 3", n = max(clust$cluster))), labels = c("Outliers", 1:max(clust$cluster))) +
  theme_minimal() +
  theme(
    text = element_text(family = "Fira Code")
  )

label_plot <- str_replace(epsilon, "\\.", "")
ggsave(paste0("gapminder-infmort-lifeexp-epsilon-no-normalization", label_plot, ".png"), width = 10, height = 4)

# t-sne plot
ggplot(datagap_vis,#vis_normalized_cluster, 
       aes(x = x, y = y)) + 
  geom_point(aes(color = as.factor(grp)), size = 3) +
  coord_fixed() +
  labs(title = "t-SNE Plot -- high-dimensional clusters", x = "x", y = "y", color = "Cluster",
       subtitle = paste("Perplexity:", perplexity, ", Epsilon:", epsilon)) +
  scale_color_manual(values = c("black", colorspace::qualitative_hcl(palette = "Set 3", n = max(clust$cluster))), labels = c("Outliers", 1:max(clust$cluster))) +
  theme_minimal() +
  theme(
    text = element_text(family = "Fira Code")
  )

label_plot_tsne <- str_replace(perplexity, "\\.", "")
ggsave(paste0("gapminder-tsne-hi-clusters", label_plot_tsne, ".png"), width = 6, height = 10)

#tsne clusters plot
# t-sne plot
ggplot(datagap_vis,#vis_normalized_cluster, 
       aes(x = x, y = y)) + 
  geom_point(aes(color = as.factor(grp_tsne)), size = 3) +
  coord_fixed() +
  labs(title = "t-SNE Plot -- low-dimensional clusters", x = "x", y = "y", color = "t-SNE Cluster",
       subtitle = paste("Perplexity:", perplexity, ", Epsilon:", epsilon)) +
  scale_color_manual(values = c("black", colorspace::qualitative_hcl(palette = "Set 3", n = max(datagap_vis$grp_tsne))), labels = c("Outliers", 1:max(datagap_vis$grp_tsne))) +
  theme_minimal() +
  theme(
    text = element_text(family = "Fira Code")
  )

ggsave(paste0("gapminder-tsne-low-clusters", label_plot_tsne, ".png"), width = 6, height = 10)




ggplot(datagap_vis, aes(x = infant_mortality, life_expectancy)) + 
  geom_point(aes(color = as.factor(grp))) +
  coord_fixed() +
  theme_minimal()

ggplot(datagap_vis, aes(x = x, y = y)) + 
  geom_point(aes(color = as.factor(grp))) +
  theme_minimal()

clust_tsne <- datagap_vis %>% select(x, y) %>% as.matrix() %>% Rtsne::normalize_input() %>% dbscan::dbscan(eps = 0.1)

datagap_vis$grp_tsne <- clust_tsne$cluster

ggplot(datagap_vis, aes(x = x, y = y)) + 
  geom_point(aes(color = as.factor(grp_tsne))) +
  theme_minimal()


# Plots for the Presentation ----------------------------------------------

ggplot(datagap, aes(x = gdp_million, y = life_expectancy, size = population, color = continent)) + 
  geom_point() +
  scale_x_log10(breaks = c(1e3, 1e5, 1e7), labels = c("US$ 1 billion", "US$ 100 billion", "US$ 10 trillion")) + #scales::number_format(big.mark = ".")) +
  scale_color_discrete_qualitative(palette = "Set 2") +
  scale_size(breaks = c(1e6, 1e8, 1e9), labels = c("1 million", "100 million", "1 billion")) +
  labs(x = "GDP", y = "Life Expectancy", size = "Pop", color = "Continent") +
  theme_minimal() +
  theme(
    text = element_text(family = "Fira Code")
  )

ggsave("gapminder-bubble.png")

library(GGally)

ggpairs(datagap_num)
ggsave("gapminder-scatterplot-matrix.png")




# clusters comparison -----------------------------------------------------

library(mclust)
library(cluster)

cluster_hi <- clust$cluster
cluster_lo <- data_cluster_tsne$cluster

# Adjusted Rand Index
ari <- adjustedRandIndex(cluster_hi, cluster_lo)

experiment <- function(perplexity, epsilon, minpts) {
  
  clust_hi <- dbscan::dbscan(data_selected_all, eps = epsilon, minPts = minpts)$cluster

  data_tsne <- data_selected_all %>%
    Rtsne::Rtsne(perplexity = perplexity)
  
  clust_lo <- data.frame(
    x = data_tsne$Y[,1],
    y = data_tsne$Y[,2]
  ) %>%
    as.matrix() %>%
    Rtsne::normalize_input() %>%
    dbscan::dbscan(eps = epsilon, minPts = minpts) %>%
    .$cluster
  
  # Adjusted Rand Index
  return(c(adjustedRandIndex(clust_hi, clust_lo), length(unique(clust_hi)), length(unique(clust_lo))))
  
}

experiment(10, 0.05, 3)

perps <- c(10, 20, 30, 40, 50)
epss <- c(0.01, 0.02, 0.03, 0.04, 0.05, 0.06)
minspts <- c(2, 3, 4, 5, 6)

len_df <- length(perps) * length(epss) * length(minspts)

results <- data.frame(
  perplexity = rep(0, len_df), 
  epsilon = rep(0, len_df), 
  minPts = rep(0, len_df), 
  nclusters_hi = rep(0, len_df),
  nclusters_lo = rep(0, len_df),
  ari = rep(0, len_df)
)

i <- 1

for (perp in perps) {
  for (eps in epss) {
    for (mpts in minspts) {
      
      res <- experiment(perp, eps, mpts)
      
      results[i, "perplexity"] <- perp
      results[i, "epsilon"] <- eps
      results[i, "minPts"] <- mpts
      results[i, "nclusters_hi"] <- res[2]
      results[i, "nclusters_lo"] <- res[3]
      results[i, "ari"] <- res[1]
      
      i <- i + 1
      
    }
  }
}

results %>% arrange(-ari)

ggplot(results, aes(x = perplexity, y = epsilon, size = ari)) + geom_point()

ggplot(results, aes(x = ari, y = 0)) + geom_jitter()
