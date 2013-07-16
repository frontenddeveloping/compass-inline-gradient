require "base64"
require "open-uri"
require "sass"
require "rmagick"
require "tinypng"


module Sass::Script::Functions
    module InlineGradient
        include Sass::Script::Color
        @DEFAULT_CONTENT_TYPE = "image/png"
        @DEFAULT_TYPE = "linear"
        @DEFAULT_ANGLE = "to left"
        @DEFAULT_COLOR_STOPS = []
        @DEFAULT_SIZE = [100, 100]
        @DEFAULT_PNG_OPTIMIZATION = 1
        def inline_gradient(type = @DEFAULT_TYPE, angle = @DEFAULT_ANGLE , color_stops = @DEFAULT_COLOR_STOPS, size = @DEFAULT_SIZE, noPngOptimization = @DEFAULT_PNG_OPTIMIZATION)
            if type == "linear"
                return self.inline_linear_gradient(angle, color_stops, size, noPngOptimization)
            else type == "radial"
                return self.inline_radial_gradient(angle, color_stops, size, noPngOptimization)
        end
        def inline_linear_gradient(angle, color_stops, size, noPngOptimization)
            <<-DOC
                I use http://www.w3.org/TR/css3-images/#linear-gradient-syntax

                <linear-gradient> = linear-gradient(
                    [ [ <angle> | to <side-or-corner> ] ,]?
                    <color-stop>[, <color-stop>]+
                )
                <side-or-corner> = [left | right] || [top | bottom]

                it means that
                    - angle is string <angle> | to <side-or-corner>
                    - color_stops is array of <color-stop> string

                example: inline-linear-gradient(to right, [#1e5799 0%, #2989d8 50%, #207cca 51%, #7db9e8 100%], [100, 100])
            DOC

            angle = side2angle(angle)

            if angle.to_n == 0 or angle.to_n == 180
                gradient_direction = 'vertical'
                all_distance = size[1]
            elsif angle.to_n == 90 or angle.to_n == 270
                gradient_direction = 'horizontal'
                all_distance = size[0]
            else
                gradient_direction = 'custom'
                all_distance = size[0] #TODO увеличить сторону на косинус или синус
            end

            #get info from first stop color
            first_color_stop = color_stops[0]
            first_color_stop_arr = first_color_stop.strip.split(' ')
            first_color = color2hex(first_color_stop_arr[0])
            first_color_distance = first_color_stop_arr[1]

            prev_distance = distance2px(first_color_distance, all_distance)
            prev_color = first_color

            image_list = ImageList.new

            color_stops[1..color_stop.size].map do |color_stop|
                color_stop_arr = color_stop.strip.split(' ')

                current_color = color2hex(color_stop_arr[0])
                current_distance = color_stop_arr[1]

                fill = Magick::GradientFill.new(0, 0, 0, current_distance - prev_distance, prev_color, current_color)
                image_list.new_image(0, current_distance - prev_distance, fill);

                prev_distance = current_distance
                prev_color = current_color
            end

            if gradient_direction == 'vertical'
                image = image_list.append(true) #concat top to bottom images
            else #custom and horizontal
                image = image_list.append(false) #concat left to right images
            end

            if gradient_direction == 'custom'
                #rotate
            end

            data_uri_image = image2base64(image, noPngOptimization)
            Sass::Script::String.new("url(data:" + @DEFAULT_CONTENT_TYPE + ";base64," + data_uri_image + ")")
        end
        def inline_radial_gradient(angle, color_stops, size, noPngOptimization)

        end

        private

        def distance2px (distance, all_distance)
            distance = distance.to_s;
            if distance.end_with?('%')
                distance = ( distance.to_f / 100 ) * all_distance
            end
            distance.to_i
        end
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
            <<-DOC
                Color can be:
                    - rgba
                    - rgb
                    - hex
                I use Sass::Script::Color class
            DOC

            color = color.to_s

            if color.start_with?('rgba')
                rgba = color.split(",").map { |s| s.to_i }
                color = Color.new(rgba[0..2]).with(:alpha => rgba[3])
            elsif color.start_with?('rba')
                rgb = color.split(",").map { |s| s.to_i }
                color = Color.new(rgba[0..2])
            end

            color
        end
        def map_color_stop (color_stops)
            <<-DOC
                I use http://www.w3.org/TR/css3-images/#color-stop-syntax
                <color-stop> = <color> [ <percentage> | <length> ]?
            DOC
            color_stops.map do |color_stop|

            end
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
            Base64.encode64(image).gsub("\n","")
        end
        declare :inline_gradient
        declare :inline_linear_gradient
        declare :inline_radial_gradient
    end
end