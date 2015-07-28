require 'RMagick'

class AnalyticsCharts::CustomModule
  include Magick
  def initialize(image_path, text, output_path)
    @d = Draw.new

    @d.fill = 'white'
    @d.font = 'Helvetica'
    @pointsize = 14
    @d.pointsize = @pointsize
    @d.font_weight = 500
    @composite_image = Image.read(image_path)[0]
    @dummy_image = Image.new(1,1)
    @composite_columns = @composite_image.columns
    @composite_rows = @composite_image.rows
    begin
      @rows_of_text = tokenize_text_by_lines(text)
    rescue
      puts "Had some error in CustomModule, probably a nil calling each"
      return
    end

    num_separators = @rows_of_text.count {|row| row.empty? }
    @sep_offset = 7
    @height = @composite_rows + (@rows_of_text.size - num_separators) * @pointsize + num_separators * @sep_offset
    @base_image = Image.new(@composite_columns, @height) {
      self.background_color = "black"
    }
    @base_image.composite!(@composite_image,0,0,OverCompositeOp)
    @d = @d.stroke_color 'white'
    @d.stroke_width(1)
    @d = @d.line(0, @composite_rows, @composite_columns, @composite_rows)
    @d.draw(@base_image)
    y_offset = @pointsize + @composite_rows + @d.get_type_metrics(@dummy_image,"a").height / 2
    @rows_of_text.each do |text|
      text = text.gsub(/['%]/, '%' => '%%', "'" => "\'")
      if text.include? "@$$" # No paragraph break if we insert this uncommonly used word
        text.sub!("@$$", "")
        y_offset -= @sep_offset
        @d.annotate(@base_image, 0 ,0, @pointsize, y_offset, text)
        y_offset += @pointsize
        next
      else
        if text.empty?
          y_offset += @sep_offset
        else
          y_offset += @pointsize
          @d.annotate(@base_image, 0 ,0, @pointsize, y_offset, text)
        end
      end
    end
    @base_image.write(output_path)
  end
  def tokenize_text_by_lines(text)
    # First split the text by the line carriage element
    carriage_split_lines = text.split("\r\n")
    line_tokens = Array.new
    carriage_split_lines.each do |carriage_split_line|
      line_wrap_lines = line_wrap(carriage_split_line)
      line_wrap_lines.each { |line| line_tokens.push(line) }
      line_tokens.push("")
    end
    line_tokens
  end
  def line_wrap(text)
    tokens = text.split.reverse # Pop stuff off
    # Safety check, do not allow super long words.
    tokens.each {|token| return "" if not fits_in_a_line(token) }
    line_wrap_tokens = Array.new
    line_builder = ""
    while tokens.size != 0
      line_builder = tokens.pop # Pop the first word in a line
      while tokens.size != 0 and fits_in_a_line(line_builder + " " + tokens.last)
        line_builder += " " + tokens.pop
      end
      line_wrap_tokens.push(line_builder) # Add to list of lines
    end
    line_wrap_tokens
  end

  def fits_in_a_line(text)
    return @d.get_type_metrics(@dummy_image,text).width < @composite_image.columns - 36
  end
end
#Reference: Draw defaults[ font: "Helvetica", pointsize:12, x/y resolution 72 DPI, font_weight: 400]