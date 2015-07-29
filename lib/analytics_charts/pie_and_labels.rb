require 'RMagick'

class AnalyticsCharts::PieAndLabels < AnalyticsCharts::CustomPie
  include Magick
  def initialize(meme, num_labels, organization, disclaimer)
    @organization = organization
    @legend_data = Array.new(["","","",""])
    @thresholds = Array(["","","",""]) # Will populate with integer thresholds
    @composite_image = Image.read(meme)[0]
    @d = Draw.new
    @d.pointsize = 12
    @d.font_weight = 700
    @dummy_image = Image.new(1,1)
    @composite_columns = @composite_image.columns
    @composite_rows = @composite_image.rows
    organization = organization.gsub(/['%]/, '%' => '%%', "'" => "\'")
    @org_text_size = 14
    @org_height = @org_text_size + 1
    @org_texts = tokenize_text_by_lines(organization,
      {'fill' => '#FFFFFF', 'pointsize'=> @org_text_size, 'font_weight'=> 500  })
    org_text_offset = @org_texts.size * @org_height

    @label_size = 16
    self.label_attributes = {'pointsize' => @label_size, 'font_weight' => 900}
    recalibrate_metrics_for_labels
    self.label_height = @label_size + 1

    # (num_labels + 1) to account for white key on bottom of labels
    @height_with_no_disclaimer = [200 + 20, 20 + self.label_height * (num_labels + 1) + 20].max + @composite_rows + org_text_offset
    disclaimer = disclaimer.gsub(/['%]/, '%' => '%%', "'" => "\'")
    @disclaimer_texts = tokenize_text_by_lines(disclaimer)
    @height = @height_with_no_disclaimer + @disclaimer_texts.size * 12
    @data = Hash.new # Value is array with two items
    @aggregate = Array([0,0,0,0]) # Cluster brands into categories
    @label_hash = {'pointsize'=> @label_size,'font_weight'=> 700 }
    @pie_label_hash = {'pointsize'=> 14, 'font_weight' => 600 }
    set_pie_colors(%w(#AD1F25 #BE6428 #C1B630 #1E753B #FFFFFF))
   	@base_image = Image.new(@composite_columns, @height) {
      self.background_color = "black"
    }
    @base_image.composite!(@composite_image,0,0,OverCompositeOp)
    set_pie_geometry(315, 60+ @composite_rows, 50)
    set_label_values(22, 20+@composite_rows, @label_size)
    annotate_organization(org_text_offset)
    annotate_disclaimer
  end
  def annotate_organization(offset)
    y_offset = @height_with_no_disclaimer - offset
    @org_texts.each do |text|
      insert_text(22, y_offset ,text,
            @label_hash.merge({'fill' => '#FFFFFF', 'pointsize'=> @org_text_size, 'font_weight'=> 500  }))
      @d.annotate(@base_image, 0 ,0, 22, y_offset, text)
      y_offset += @org_height
    end
  end
  def annotate_disclaimer
    y_offset = @height_with_no_disclaimer + @d.get_type_metrics(@dummy_image,"a").height
    @disclaimer_texts.each do |text|
      if text.include? "@$$" # No paragraph break if we insert this uncommonly used word
        text.sub!("@$$", "")
        insert_text(22, y_offset ,text,
            @label_hash.merge({'fill' => '#FFFFFF', 'pointsize'=> 12 }))
        @d.annotate(@base_image, 0 ,0, 22, y_offset, text)
        next
      else
        insert_text(22, y_offset ,text,
            @label_hash.merge({'fill' => '#FFFFFF', 'pointsize'=> 12 }))
        y_offset += 12
      end
    end
  end

  def write(filename='graph.png')
    draw
    draw_labels
    draw_legend
    draw_line
    @d.draw(@base_image)
    @base_image.write(filename)
  end

  def insert_legend(label, quality, color)
    case color
    when "green"
      @legend_data[3] = label
      highest_score(3, quality)
    when "yellow"
      @legend_data[2] = label
      highest_score(2, quality)
    when "orange"
      @legend_data[1] = label
      highest_score(1, quality)
    when "red"
      @legend_data[0] = label
      highest_score(0, quality)
    end
  end

  def draw_legend
    y_offset = 180 + @composite_rows
    @d.fill_opacity(1)
    @d.stroke_width(0)
    @d = @d.stroke 'transparent'
    x_pos = 230
    side_length = 15
    @legend_data.each_with_index do |data, index|
      unless data.empty? # Allows us to use only three legends or less
        case index
          when 3
            insert_text(x_pos + 20, y_offset + 12, data,
              @label_hash.merge({'fill' => '#FFFFFF', 'pointsize'=> 10 }))
            @d.fill('#1E753B')
            @d.rectangle(x_pos,y_offset,x_pos + side_length, y_offset + side_length)
          when 2
            insert_text(x_pos + 20, y_offset + 12, data,
              @label_hash.merge({'fill' => '#FFFFFF', 'pointsize'=> 10 }))
            @d.fill('#C1B630')
            @d.rectangle(x_pos,y_offset,x_pos + side_length, y_offset + side_length)
          when 1
            insert_text(x_pos + 20, y_offset + 12, data,
             @label_hash.merge({'fill' => '#FFFFFF', 'pointsize'=> 10 }))
            @d.fill('#BE6428')
            @d.rectangle(x_pos,y_offset,x_pos + side_length, y_offset + side_length)
          when 0
            insert_text(x_pos + 20, y_offset + 12, data,
              @label_hash.merge({'fill' => '#FFFFFF', 'pointsize'=> 10 }))
            @d.fill('#AD1F25')
            @d.rectangle(x_pos,y_offset,x_pos + side_length, y_offset + side_length)
        end
        y_offset -= side_length
      end
    end
  end

  def draw_line
    @d.stroke('white')
    @d.stroke_width(1)
    @d.line(0,@height_with_no_disclaimer,@composite_columns,@height_with_no_disclaimer)
  end

  def tokenize_text_by_lines(text, features = {})
    features.each { |feature, attribute|
      set_feature(feature, attribute)
    }
    # First split the text by the line carriage element
    carriage_split_lines = text.split("\r\n")
    line_tokens = Array.new
    carriage_split_lines.each do |carriage_split_line|
      line_wrap_lines = line_wrap(carriage_split_line)
      begin
        line_wrap_lines.each { |line| line_tokens.push(line) }
        line_tokens.push("\r\n")
      rescue
      end
    end
    line_tokens
  end
  def line_wrap(text)
    tokens = text.split.reverse # Pop stuff off
    # Safety check, do not allow super long words.
    tokens.each {|token| return "" if not fits_in_a_line?(token) }
    line_wrap_tokens = Array.new
    line_builder = ""
    while tokens.size != 0
      line_builder = tokens.pop # Pop the first word in a line
      while tokens.size != 0 and fits_in_a_line?(line_builder + " " + tokens.last)
        line_builder += " " + tokens.pop
      end
      line_wrap_tokens.push(line_builder) # Add to list of lines
    end
    line_wrap_tokens
  end

  def fits_in_a_line?(text)
    return @d.get_type_metrics(@dummy_image,text).width < @composite_columns - 44
  end

end