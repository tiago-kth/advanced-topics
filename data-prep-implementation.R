library(tidyverse)
library(dbscan)
library(dslabs)
library(Rtsne)
library(colorspace)

datagap <- dslabs::gapminder %>% filter(
  year == 2011) %>%
  na.omit() %>%
  mutate(
    gdp_million = gdp/1000000,
    log_gdp = log10(gdp)
  ) %>%
  unique()

skimr::skim(datagap)

data_selected <- datagap %>% select(
  country, infant_mortality, life_expectancy
) 

dups <- data_selected %>% select(-country) %>% duplicated() 

data_dup <- data_selected %>% mutate(dups = dups) %>% filter(dups == TRUE)

data_selected_mod <- data_selected %>%
  mutate(infant_mortality = ifelse(country %in% c("Israel", "South Korea"), infant_mortality + 0.1, infant_mortality)) %>%
  select(-country) %>%
  as.matrix()

clust <- dbscan::dbscan(data_selected_mod, eps = 4)

data_tsne <- data_selected_mod %>%
  Rtsne::normalize_input() %>%
  Rtsne::Rtsne(perplexity = 20)

datagap_vis <- datagap %>%
  mutate(
    grp = clust$cluster,
    x = data_tsne$Y[,1],
    y = data_tsne$Y[,2])

ggplot(datagap_vis, aes(x = infant_mortality, life_expectancy)) + 
  geom_point(aes(color = as.factor(grp))) +
  coord_fixed() +
  theme_minimal()

ggplot(datagap_vis, aes(x = x, y = y)) + 
  geom_point(aes(color = as.factor(grp))) +
  theme_minimal()

clust_tsne <- datagap_vis %>% select(x, y) %>% as.matrix() %>% dbscan::dbscan(eps = 3)

datagap_vis$grp_tsne <- clust_tsne$cluster

ggplot(datagap_vis, aes(x = x, y = y)) + 
  geom_point(aes(color = as.factor(grp_tsne))) +
  theme_minimal()


ggplot(datagap, aes(x = gdp_million, y = life_expectancy, size = population, color = continent)) + 
  geom_point() +
  scale_x_log10(breaks = c(1e3, 1e5, 1e7), labels = c("US$ 1 billion", "US$ 100 billion", "US$ 10 trillion")) + #scales::number_format(big.mark = ".")) +
  scale_color_discrete_qualitative(palette = "Set 2") +
  labs(x = "GDP", y = "Life Expectancy") +
  theme_minimal()
