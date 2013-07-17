require "base64"

#safe require for compass compile in compass progect with non gem library usage
require "sass" if not defined?(Sass)

begin
    require "rmagick" if not defined?(Magick)
rescue LoadError => e
    #catch LoadError
end

begin
    require "tinypng" if not defined?(TinyPNG)
rescue LoadError => e
    #catch LoadError
end

module InlineGradient

    include Sass::Script

    DEFAULT_CONTENT_TYPE = "image/png"
    DEFAULT_TYPE = "linear"
    DEFAULT_ANGLE = "to left"
    DEFAULT_COLOR_STOPS = ["#FFF 0%", "#000 100%"]
    DEFAULT_WIDTH = 100
    DEFAULT_HEIGHT = 100
    
    def inline_gradient(type = DEFAULT_TYPE, width = DEFAULT_WIDTH, height = DEFAULT_HEIGHT, angle = DEFAULT_ANGLE , *color_stops)

        if color_stops.size == 0
            color_stops = DEFAULT_COLOR_STOPS
        end

        if type == "linear"
            return self.inline_linear_gradient(width, height, angle, color_stops)
        else type == "radial"
            return self.inline_radial_gradient(width, height, angle, color_stops)
        end

    end
    #declare :inline_gradient

    def inline_linear_gradient(width, height, angle, color_stops)
        <<-DOC
            I use http://www.w3.org/TR/css3-images/#linear-gradient-syntax

            <linear-gradient> = linear-gradient(
                [ [ <angle> | to <side-or-corner> ] ,]?
                <color-stop>[, <color-stop>]+
            )
            <side-or-corner> = [left | right] || [top | bottom]

            it means that
                - angle is string <angle> | to <side-or-corner>
                - color_stops is string of <color-stop> string

            example: inline-gradient(linear, 100, 100, to left, #1e5799 0%, #2989d8 50%, #207cca 51%, #7db9e8 100%)
        DOC

        angle = side2angle(angle)
        color_stops = color_stops.split(',')
        size = size.split(',').map{|s| s.to_f}

        if angle.to_n == 0 or angle.to_n == 180
            gradient_direction = 'vertical'
            all_distance = size[1]
        elsif angle.to_n == 90 or angle.to_n == 270
            gradient_direction = 'horizontal'
            all_distance = size[0]
        else
            gradient_direction = 'custom'
            all_distance = size.max
        end

        #get info from first stop color
        first_color_stop = color_stops.shift()
        first_color_stop_arr = first_color_stop.strip.split(' ')
        first_color = color2hex(first_color_stop_arr[0])
        first_color_distance = first_color_stop_arr[1]

        prev_distance = distance2px(first_color_distance, all_distance)
        prev_color = first_color

        image_list = ImageList.new

        color_stops.each do |color_stop|
            color_stop_arr = color_stop.strip.split(' ')

            current_color = color2hex(color_stop_arr[0])
            current_distance = distance2px(color_stop_arr[1], all_distance)

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

        data_uri_image = image2base64(image)
        Sass::Script::String.new("url(data:" + DEFAULT_CONTENT_TYPE + ";base64," + data_uri_image + ")")
    end
    #declare :inline_linear_gradient

    def inline_radial_gradient(width, height, angle, color_stops)
        #GradientFill with 0,0,0,0 is radial
    end
    #declare :inline_radial_gradient

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
    def image2base64(image)
        image.format = "png"

        begin
            #online mode
            client = TinyPNG::Client.new
            image = client.shrink(image.to_blob)
            image = image.to_file
            image = File.read(image)
        rescue Exception => e
            #offline mode
            image = image.to_blob
        end

        Base64.encode64(image).gsub("\n","")
    end
end


module Sass::Script::Functions
    include InlineGradient
end