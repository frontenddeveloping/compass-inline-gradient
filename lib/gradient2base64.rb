require "base64"
require "open-uri"
require "sass"
require "rmagick"
require "tinypng"


module Sass::Script::Functions
    module Gradient2Base64
        include Sass::Script::Color
        @DEFAULT_CONTENT_TYPE = "image/png"
        @DEFAULT_TYPE = "linear"
        @DEFAULT_ANGLE = "to left"
        @DEFAULT_STOP_COLORS = []
        @DEFAULT_SIZE = [100, 100]
        @DEFAULT_PNG_OPTIMIZATION = 1
        def gradient2base64(type = @DEFAULT_TYPE, angle = @DEFAULT_ANGLE , stop_colors = @DEFAULT_STOP_COLORS, size = @DEFAULT_SIZE, noPngOptimization = @DEFAULT_PNG_OPTIMIZATION)
            if type == "linear"
                return self.linear_gradient2base64(angle, stop_colors, size, noPngOptimization)
            else type == "radial"
                return self.radial_gradient2base64(angle, stop_colors, size, noPngOptimization)
        end
        def linear_gradient2base64(angle, stop_colors, noPngOptimization)
            =begin
                I use http://www.w3.org/TR/css3-images/#linear-gradient-syntax

                <linear-gradient> = linear-gradient(
                    [ [ <angle> | to <side-or-corner> ] ,]?
                    <color-stop>[, <color-stop>]+
                )
                <side-or-corner> = [left | right] || [top | bottom]

                it means that
                    - angle is string <angle> | to <side-or-corner>
                    - stop_colors is array of <color-stop> string
            =end
            fill = Magick::GradientFill.new(0, 0, size[0], size[1], "#FFF", "#000")
            image = Magick::Image.new(50, 1000, fill)
            image2base64(image, noPngOptimization)
        end
        def radial_gradient2base64(angle, stop_colors, size, noPngOptimization)

        end

        private

        def side2angle (side)
            side2angle_object = {
                 "to_top" => "0deg",
                 "to_right" => "90deg",
                 "to_bottom" => "180deg",
                 "to_left"  => "270deg"
            }
            side_name = side.gsub("\s", "_")
            side2angle_object[side_name] or side
        end
        def color2hex (color)
            =begin
                Color can be:
                    - rgba
                    - rgb
                    - hex
                I use Sass::Script::Color class
            =end

            color = color.to_s

            if color.start_with?('rgba')
                rgba = color.split(",").map { |s| s.to_i }
                color = Color.new(rgba[0..2]).with(:alpha => rgba[3])
            else if color.start_with?('rba')
                rgb = color.split(",").map { |s| s.to_i }
                color = Color.new(rgba[0..2])
            end

            color
        end
        def percentage2px
        end
        def map_color_stop
            =begin
                I use http://www.w3.org/TR/css3-images/#color-stop-syntax
                <color-stop> = <color> [ <percentage> | <length> ]?
            =end
        end
        def image2base64(image, noPngOptimization)
            image.format = "png"
            if noPngOptimization.to_s == "1" or noPngOptimization.to_s == "true"
                client = TinyPNG::Client.new
                image = client.shrink(image.to_blob)
                image = image.to_file
                image = File.read(image)
            else
                image = image.to_blob
            end
            Sass::Script::String.new(Base64.encode64(image).gsub("\n",""))
        end
    end
end