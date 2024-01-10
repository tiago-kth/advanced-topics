library(magick)
library(png)

img_jpg <- magick::image_read("desenhos-vi_1.jpg")

img_png <- magick::image_convert(img_jpg, format = "png", colorspace = "gray") %>%
  magick::image_sample("64x64!")

magick::image_write(img_png, "vi-png.png")

img <- png::readPNG("vi-png.png")

img[1,34,2]