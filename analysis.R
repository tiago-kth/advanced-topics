library(png)
library(tidyverse)

# devtools::install_github("jlmelville/coil20")
# library(coil20)
# coil20 <- download_coil20(verbose = TRUE)
# saveRDS(coil20, "coil20.rds")

# a <- png::readPNG("./coil-20-proc/obj1__0.png")

files <- list.files("./coil-20-proc")

get_column_names <- function() {
  
  column_names <- character(128 * 128)
  n <- 1
  
  for (i in 1:128) {
    for (j in 1:128) {
      
      column_names[n] <- paste0("i",i,"_","j",j)
      n <- n + 1
      
    }
  }

  return(column_names)
  
}


process_filename <- function(filename) {
  
  filename_components <- str_split(filename, "__")[[1]]
  label <- str_remove(filename_components[1], "obj")
  view <- str_remove(filename_components[2], ".png")
  
  info <- character(3)
  
  info[1] <- filename
  info[2] <- label
  info[3] <- view
  
  return(info)
  
}

process_file <- function(filename) {
  
  path <- paste0("./coil-20-proc/", filename)
  
  png_content <- png::readPNG(path)
  
  J <- ncol(png_content)
  I <- nrow(png_content)
  
  len <- I * J
  
  data_point <- numeric(len)
  n <- 1
  
  for (i in 1:I) {
    for (j in 1:J) {
      
      data_point[n] <- png_content[i,j]
      n <- n + 1
      
    }
  }
  
  return(data_point)
  
}


# process files -----------------------------------------------------------

lista <- list()
k <- 1

for (arq in files) {
  
  contents <- process_file(arq)
  lista[[k]] <- contents
  k <- k + 1

}

mat <- do.call(rbind, lista)
df <- as.data.frame(mat)

df_col_names <- get_column_names()
colnames(df) <- df_col_names

df$filename <- files

df <- df %>%
  rowwise() %>%
  mutate(
    
    label = str_remove(
      str_split(filename, "__")[[1]][1], 
      "obj"),
    
    view = str_remove(
      str_split(filename, "__")[[1]][2], 
      ".png")
    
  )

#a <- process_file("obj1__0.png")
#coil20 <- readRDS("coil20.rds")
#show_object(coil20, object = 4, pose = 0)

library(Rtsne)

coil20_no_label <- mat#coil20[,1:ncol(coil20)-1]

normalized <- Rtsne::normalize_input(coil20_no_label)#as.matrix(coil20_no_label))

perps <- c(1, 10, 36, 50, 72)

run_experiment <- function(perp) {
  
  print(paste0("x", perp))
  
  tsne <- Rtsne::Rtsne(normalized, perplexity = perp)
  
  print("tsne finalized.")
  print(tsne$Y[,1][2])
  
  result <- list()
  
  result[[paste0("x", perp)]] <- tsne$Y[,1]
  result[[paste0("y", perp)]] <- tsne$Y[,2]
  
  return(result)
  
}

# perps1 <- c(1, 10)
# perps2 <- c(36, 50, 72)
# res1 <- purrr::map(perps1, run_experiment)
# res2 <- purrr::map(perps2, run_experiment)
# results <- c(res1, res2)


# tsne10 <- Rtsne::Rtsne(normalized, perplexity = 10)
# x10 <- tsne10$Y[,1]
# y10 <- tsne10$Y[,2]

visdata <- data.frame(label = df$label, view = df$view, filename = df$filename)

for (i in 1:length(results)) {
  
  names_cols <- names(results[[i]])
  
  for (k in 1:length(results[[i]])) {

    visdata[,names_cols[k]] <- results[[i]][k]
  }

}

write_rds(visdata, "visdata.rds")

jsonlite::write_json(visdata, "coil20-data.json")

ggplot(visdata, aes(x72,y72)) + geom_text(aes(label = label, color = label))
ggsave("coil20_perp72.png")



file_names <- visdata %>% select(label, view, filename) %>%
  arrange(as.numeric(label), as.numeric(view)) %>%
  mutate(path = paste0('./coil-20-proc/', filename))

image_files <- file_names$path

library(magick)

images <- lapply(image_files, image_read)

process_coil <- function(images){
  
  acc_img <- NULL
  flag_first_line <- TRUE
  # current_obj <- images[[1]]
  
  for (n in 0:19) {
    
    current_obj <- images[[n * 72 + 1]]
    
    for (r in 2:72) {
      
      current_obj <- image_append(c(current_obj, images[[n * 72 + r]]), stack = FALSE)
      
    } 
    
    if (flag_first_line) {
      flag_first_line <- FALSE
      acc_img <- current_obj
    } else {
      acc_img <- image_append(c(acc_img, current_obj), stack = TRUE)
    }
    
  }
  
  # for (r in 2:72) {
  #   
  #   # print(r)
  #   
  #   # if (r %/% 72 == 1) {
  #   #   
  #   #   current_obj <- images[[r]]
  #   #   
  #   # } else {
  #     
  #     current_obj <- image_append(c(current_obj, images[[r]]), stack = FALSE)
  #     
  #   # }
  #   
  #   # if (r %/% 72 == 0) {
  #   #   
  #   #   if (flag_first_line) {
  #   #     
  #   #     flag_first_line <- FALSE
  #   #     acc_img <- current_obj
  #   #     
  #   #   } else {
  #   #     
  #   #     acc_img <- image_append(c(acc_img, current_obj), stack = TRUE)
  #   #     
  #   #   }
  #   #   
  #   # }
  #   
  # } 
  
  return(acc_img)
}


sprite_sheet <- process_coil(images)

magick::image_write(sprite_sheet, "sprite-sheet.png")
