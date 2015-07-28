require 'RMagick'

class AnalyticsCharts::CustomPie
  include Magick
  attr_accessor :pie_center_x
  attr_accessor :pie_center_y
  attr_accessor :pie_radius
  attr_accessor :label_hash
  attr_accessor :pie_label_hash
  attr_accessor :label_start_x
  attr_accessor :label_start_y
  attr_accessor :label_offset
  def initialize(image_path, label_hash, pie_label_hash)
    @base_image = Image.read(image_path)[0]
    @columns = @base_image.columns
    @rows = @base_image.rows
    @d = Draw.new
    @data = Hash.new # Value is array with two items
    @aggregate = Array([0,0,0,0]) # Cluster brands into categories
    @thresholds = Array(["","","",""]) # Will populate with integer thresholds
    @label_hash = Hash.new
    @pie_label_hash = Hash.new
    @label_hash = label_hash if label_hash
    @pie_label_hash = pie_label_hash if pie_label_hash
    set_pie_colors(%w(#AD1F25 #BE6428 #C1B630 #1E753B #FFFFFF))
  end

  def set_label_values(label_start_x, label_start_y, label_offset)
    @label_start_x = label_start_x
    @label_start_y = label_start_y
    @label_offset = label_offset
  end

  def set_pie_geometry(x, y, radius)
    @pie_center_x = x
    @pie_center_y = y
    @pie_radius = radius
  end

  def set_pie_colors(list)
    @colors = list
  end

  def highest_score(index, score)
    @thresholds[index] = score
  end
  def insert_pie_data(name, amount, quality)
    #convert all '&#39; instances to an apostrophe
    name = name.gsub(/&#39;/, "\'")
    # Figure out whether to give name a 0,1,2, or 3
    [0,1,2,3].each do |rank|
      next if @thresholds[rank].is_a?(String)
      if quality <= @thresholds[rank]
        @data[name] =  [amount, rank]
        @aggregate[rank] += amount
        break
      end
    end
  end

  def insert_text_with_circle(x_offset, y_offset, text, features = {})
    features.each { |feature, attribute|
      set_feature(feature, attribute)
    }
    # Double quotes automatically escaped in rails db. Refer to Rmagick doc for escaping stuff
    text = text.gsub(/['%]/, '%' => '%%', "'" => "\'")
    @d.annotate(@base_image, 0 ,0, x_offset, y_offset, text)
    height = @d.get_type_metrics(@base_image, text).ascent
    y_offset -= height / 2
    circle_xpos = x_offset - 10
    radius = 5
    @d.stroke_width(radius)
    @d.stroke features["fill"] unless features["fill"].nil?
    @d = @d.ellipse(circle_xpos, y_offset,
      radius / 2.0, radius / 2.0, 0, 400) # Need bigger overlap for smaller circle
  end

  def insert_text(x_offset, y_offset, text, features = {})
    features.each { |feature, attribute|
      set_feature(feature, attribute)
    }
    text = text.gsub(/['%]/, '%' => '%%', "'" => "\'")
    @d.annotate(@base_image, 0 ,0, x_offset, y_offset, text)
  end

  def draw
    total_sum = @aggregate.inject(:+) + 0.0 # Sum elements and make it a float
    if total_sum == 0
      @d.stroke_width(@pie_radius)
      @d = @d.stroke "#FFFFFF"
      @d = @d.ellipse(@pie_center_x, @pie_center_y,
                  @pie_radius / 2.0, @pie_radius / 2.0,
               -5, 360 + 1.0) # <= +0.5 'fudge factor' gets rid of the ugly gaps
      @d.draw(@base_image)
      # If we don't refresh draw, future "@d.draw(@base_image)" will redraw the circle,
      # overlapping on the text written below
      @d = Draw.new
      insert_text(@pie_center_x - 30, @pie_center_y, "No Data",
        @label_hash.merge({'fill'=> ' #000000', 'font_weight'=> 700 }))
      return
    end
    if @data.size > 0
      @d.stroke_width(@pie_radius)
      prev_degrees = 60.0
      @d.fill_opacity(0) # VERY IMPORTANT, otherwise undesired artifact can result.
      degrees = Array([0,0,0,0])
      label_offset_degrees =  Array([0,0,0,0])
      @aggregate.each_with_index do |data_row, index|
        degrees[index] = (data_row / total_sum) * 360.0
      end
      num_small_slices = 0
      small_slice_index = Array([0,0,0,0])
      for i in 0..3
        if degrees[i] != 0 and degrees[i] < 18.0
          num_small_slices += 1
          small_slice_index[i] = 1
        end
      end
      for i in 0..3 # First draw slices
        next if degrees[i] == 0
        @d = @d.stroke @colors[i]
        # ellipse will draw the the stroke centered on the first two parameters offset by the second two.
        # therefore, in order to draw a circle of the proper diameter we must center the stroke at
        # half the radius for both x and y
        @d = @d.ellipse(@pie_center_x, @pie_center_y,
                  @pie_radius / 2.0, @pie_radius / 2.0,
                  prev_degrees, prev_degrees + degrees[i] + 1.0) # <= +0.5 'fudge factor' gets rid of the ugly gaps
        prev_degrees += degrees[i]
      end
      # If less than two small slices, or there are two small slices that are not adjacent
      if num_small_slices < 2 or (num_small_slices == 2 and small_slice_index[0] == small_slice_index[2])
        #Do nothing
      # If two adjacent small slices, push them apart. Non-adjacent case is taken care of above.
      # I also push back the other labels too. The logic is condensed. To see original logic,
      # consult appendix.html
      elsif num_small_slices == 2
        if small_slice_index[1] == 1
          label_offset_degrees[0] = -15
          label_offset_degrees[2] = 15
        else
          label_offset_degrees[0] = 15
          label_offset_degrees[2] = -15
        end
        if small_slice_index[2] == 1
          label_offset_degrees[1] = -15
          label_offset_degrees[3] = 15
        else
          label_offset_degrees[1] = 15
          label_offset_degrees[3] = -15
        end
      # In this case, push apart only the outside small slices.
      elsif num_small_slices == 3
        if small_slice_index[0] == 0
          label_offset_degrees[1] = -15
          label_offset_degrees[3] = 15
        elsif small_slice_index[1] == 0
          label_offset_degrees[2] = -15
          label_offset_degrees[0] = 15
        elsif small_slice_index[2] == 0
          label_offset_degrees[3] = -15
          label_offset_degrees[1] = 15
        elsif small_slice_index[3] == 0
          label_offset_degrees[0] = -15
          label_offset_degrees[2] = 15
        end
      end
      prev_degrees = 60.0 # Now focus on labels
      @aggregate.each_with_index do |data_row, i|
        next if degrees[i] == 0
        half_angle = prev_degrees + degrees[i] / 2
        label_string = '$' + data_row.round(0).to_s
        draw_pie_label(@pie_center_x,@pie_center_y, half_angle + label_offset_degrees[i],
          @pie_radius, label_string, i)
        prev_degrees += degrees[i]
      end
    end
  end

  def write(filename='graph.png')
    draw
    draw_labels
    @base_image.write(filename)
  end

  def draw_labels
    @d.align = LeftAlign
    sorted_data = @data.sort_by{|key,value| -value[1]} # Sort by descending quality
    x_offset = @label_start_x + 15
    y_offset = @label_start_y
    for data in sorted_data
      has_data = false
      if data[1][0] > 0 # Amount > 0
        font_weight = 900 # Very Bold
        text = data[0]
        has_data = true
      else
        text = data[0]
        font_weight = 900 # Very Bold
      end
      if has_data
        case data[1][1]
        when 3
          # label_hash gets merged and overrided by fill and font_weight.
          insert_text_with_circle(x_offset, y_offset, text,
            @label_hash.merge({'fill'=> '#1E753B', 'font_weight'=> font_weight }))
        when 2
          insert_text_with_circle(x_offset, y_offset, text,
            @label_hash.merge({'fill'=> '#C1B630', 'font_weight'=> font_weight }))
        when 1
          insert_text_with_circle(x_offset, y_offset, text,
           @label_hash.merge({'fill'=> '#BE6428', 'font_weight'=> font_weight }))
        when 0
          insert_text_with_circle(x_offset, y_offset, text,
            @label_hash.merge({'fill'=> '#AD1F25', 'font_weight'=> font_weight }))
        end
      else
        case data[1][1]
        when 3
          # label_hash gets merged and overrided by fill and font_weight.
          insert_text(x_offset, y_offset, text,
            @label_hash.merge({'fill'=> '#1E753B', 'font_weight'=> font_weight }))
        when 2
          insert_text(x_offset, y_offset, text,
            @label_hash.merge({'fill'=> '#C1B630', 'font_weight'=> font_weight }))
        when 1
          insert_text(x_offset, y_offset, text,
           @label_hash.merge({'fill'=> '#BE6428', 'font_weight'=> font_weight }))
        when 0
          insert_text(x_offset, y_offset, text,
            @label_hash.merge({'fill'=> '#AD1F25', 'font_weight'=> font_weight }))
        end
      end
      y_offset += @label_offset
    end
    insert_text_with_circle(x_offset, y_offset, '= purchased by you',
      @label_hash.merge({'fill'=> '#252525', 'font_weight'=> 900 }))
  end

  def draw_pie_label(center_x, center_y, angle, radius, percent, index)
    #気を付けて、get_type_metrics depends on font and pointsize, image res, AND font_weight so need to set those first
    # See more at http://studio.imagemagick.org/RMagick/doc/draw.html#get_type_metrics
    @d.font = @pie_label_hash['font'] if @pie_label_hash['font']
    @d.pointsize = @pie_label_hash['pointsize'] if @pie_label_hash['pointsize']
    ascent =  @d.get_type_metrics(@base_image, percent.to_s).ascent
    descent =  @d.get_type_metrics(@base_image, percent.to_s).descent
    width = @d.get_type_metrics(@base_image, percent.to_s).width
    radians = angle * Math::PI / 180.0
    x = center_x +  radius * Math.cos(radians)
    # By default, text is centered at bottom, so need to shift vertically to center it
    y =  center_y + ascent / 2.0 + radius * Math.sin(radians)
    # Imagine the text box around the text
    # Shift text box so a corner is tangent to circle
    if x > center_x
      x += width / 2.0 + 6
    end
    if x < center_x
      x -= width / 2.0 + 6
    end
    if y > center_y
      y += ascent / 2.0 + 6
    end
    if y < center_y
      y -= ascent / 2.0 + 6
      # descent value retrieved is negative, so sub instead of add
    end
    @d.align = CenterAlign

    # Provide default fill of black
    insert_text(x, y, percent, {'fill'=> @colors[index]}.merge(@pie_label_hash))# {'fill'=> 'black', 'font_weight'=> 700, 'pointsize'=>48})
  end

  def set_feature(feature, attribute)
    begin
      case feature
        when 'fill'
          @d.fill = attribute
        when 'font'
          @d.font = attribute
        when 'font_family'
          @d.font_family = attribute
        when 'font_stretch'
          @d.font_stretch = attribute
        when 'font_style'
          @d.font_style = attribute
        when 'font_weight'
          @d.font_weight = attribute
        when 'stroke'
          @d.stroke = attribute
        when 'pointsize'
          @d.pointsize = attribute
        when 'text_undercolor'
          @d.undercolor = attribute
      end
    rescue
      puts "Tried to set #{feature} to #{attribute}"
      puts $!, $@
    end
  end
end