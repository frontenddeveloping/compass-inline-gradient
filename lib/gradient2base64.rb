require "sass"
require "compass"
require "rmagick"
require "base64"

module Sass::Script::Functions
    def gradient2base64(type, angle, stop_colors)
        =begin
        fill = Magick::GradientFill.new(0, 0, 0, 1000, '#FFF', '#000')
        image = Magick::Image.new(50, 1000, fill)
        image.rotate(90)
        image.alpha(Magick::SetAlphaChannel)
        image.virtual_pixel_method = Magick::TransparentVirtualPixelMethod
        image = image.distort(Magick::PolarDistortion, [0]) do
          self.define('distort:Radius_Max', 49)
        end
        image.transpose
        image = image.crop(0, 475, 50, 50, true)
        image.write('test.png')
        =end
    end
    def linear-gradient2base64
    end
    def radial-gradient2base64
    end
end