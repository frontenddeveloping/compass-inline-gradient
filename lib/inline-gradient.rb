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


def distance2px (distance, width)
    distance = distance.to_s
    if distance.end_with?("%")
        percents = Sass::Script::Number.new(distance.gsub("%", "").strip)
        all_persents = Sass::Script::Number.new(100)
        distance = percents.div(all_persents).times(width)
    else
        distance = Sass::Script::Number.new(distance.to_i)
    end
    distance
end

def side2angle (side)
    side2angle_object = {
         "to_top" => 0,
         "to_right" => 90,
         "to_bottom" => 180,
         "to_left"  => 270
    }
    side_name = side.to_s.strip.gsub("\s", "_")
    side2angle_object[side_name] or side.to_i
end

def image2base64(image)
    image.format = "png"

    begin
        #online mode
        client = TinyPNG::Client.new
        image = client.shrink(image.to_blob)
        image = File.read(image.to_file)
    rescue Exception => e
        #offline mode
        image = image.to_blob
    end

    Base64.encode64(image).gsub("\n","")
end

module Sass::Script::Functions

    DEFAULT_TYPE = Sass::Script::String.new "linear"
    DEFAULT_ANGLE = "to bottom" #http://www.w3.org/TR/css3-images/#linear-gradient-examples to bottom is default
    DEFAULT_COLOR_STOPS = ["#FFF 0%", "#000 100%"]
    DEFAULT_WIDTH = Sass::Script::Number.new 100
    DEFAULT_HEIGHT = Sass::Script::Number.new 100

    def inline_gradient(type = DEFAULT_TYPE, width = DEFAULT_WIDTH, height = DEFAULT_HEIGHT, angle = DEFAULT_ANGLE , *color_stops)

        assert_type(type, :String)
        assert_type(width, :Number)
        assert_type(height, :Number)

        if color_stops.size == 0
            color_stops = DEFAULT_COLOR_STOPS
        end

        if type.to_s == "linear"
            return self.inline_linear_gradient(width, height, angle, color_stops)
        elsif type.to_s == "radial"
            #return self.inline_radial_gradient(width, height, angle, color_stops)
        end

    end

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

        if color_stops.class != Array
            color_stops = color_stops.split(',')
        end

        # The vertical gradient needs to change sides to be like horizonlat
        # After creation vertical gradient just needs to be rotated
        angle = side2angle(angle)
        if angle % 180 == 0
            width, height = height, width
        end

        need_rotation = angle != 90

        #get info from first stop color
        first_color_stop = color_stops.shift()
        first_color_stop_arr = first_color_stop.to_s.strip.split(' ')
        first_color = first_color_stop_arr[0].to_s
        first_color_distance = first_color_stop_arr[1]

        prev_distance = distance2px(first_color_distance, width)
        prev_color = first_color

        image_list = Magick::ImageList.new

        color_stops.each do |color_stop|
            # Making a single image for each pair of "color stop" values in color_stops.
            # Images concats after this iterator.
            # In this iterator there is no matter is gradient vertical or horizontal.
            # Vertical gradient will just rotate after images concatination
            color_stop_arr = color_stop.to_s.strip.split(' ')

            current_color = color_stop_arr[0].to_s
            current_distance = distance2px(color_stop_arr[1], width)

            new_image_width = current_distance.minus(prev_distance).value.ceil

            #TODO check rgba mode of Magick
            fill = Magick::GradientFill.new(0, 0, 0, new_image_width, prev_color, current_color)
            image_list.new_image(new_image_width, height.to_i, fill);

            prev_distance = current_distance
            prev_color = current_color
        end

        image = image_list.append(false) #concat from left to right

        if need_rotation
            # Magick has a different start point, difference is -90deg
            angle = angle - 90;
            if angle % 90 != 0
                deg2rad = angle / 180.0 * Math::PI
                adding_delta_x = Math.cos( (90 - angle) / 180.0 * Math::PI ) * height.to_i
                adding_delta_y = Math.tan(deg2rad) * width.to_i
                adding_delta_x = adding_delta_x.abs.ceil
                adding_delta_y = adding_delta_y.abs.ceil
                image.scale!(width.to_i + adding_delta_x, height.to_i + adding_delta_y)
                image.rotate!(angle)
                image.crop!(adding_delta_x / 2, adding_delta_y / 2, width.to_i + adding_delta_x / 2, height.to_i + adding_delta_y / 2)
            elsif angle != 0#TODO check
                image.rotate!(angle)
            end
        end

        data_uri_image = image2base64(image)
        Sass::Script::String.new("url(data:image/png;base64," + data_uri_image + ")")
    end

    #def inline_radial_gradient(width, height, angle, color_stops)
        #GradientFill with 0,0,0,0 is radial
    #end

end