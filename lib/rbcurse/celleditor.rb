require 'rubygems'
require 'ncurses'
require 'logger'
#require 'lib/rbcurse/rwidget'
module RubyCurses
  class CellEditor
    include ConfigSetup
    include RubyCurses::Utils
    #dsl_accessor :justify     # :right, :left, :center  # added 2008-12-22 19:02 
    #dsl_accessor :display_length     #  please give this to ensure the we only print this much
    #dsl_accessor :height    # if you want a multiline label.
    #dsl_accessor :text    # text of label
    #dsl_accessor :color, :bgcolor
    #dsl_accessor :row, :col
    #dsl_accessor :parent    #usuall the table to get colors and other default info

    def initialize component, config={}, &block
      @component = component
      config_setup config # @config.each_pair { |k,v| variable_set(k,v) }
      instance_eval &block if block_given?
    end
    def getvalue
      @component.getvalue
    end
    def setvalue value
      @component.set_buffer value
    end
    def component
      @component
    end

    ##
    # XXX need to move wrapping etc up and done once. 
    def repaint graphic, r=@row,c=@col, value=@text, focussed=false, selected=false
        lablist = []
        value=value.to_s # ??
        if @height && @height > 1
          lablist = wrap_text(value, @display_length).split("\n")
        else
          # ensure we do not exceed
          if !@display_length.nil?
            if value.length > @display_length
              value = value[0..@display_length-1]
            end
          end
          lablist << value
        end
        len = @display_length || value.length
        acolor = get_color $datacolor
        #acolor =get_color $datacolor, @color || @parent.color, @bgcolor || @parent.bgcolor #unless @parent.nil?
        _attr = Ncurses::A_NORMAL
        if selected
          _attr = Ncurses::A_BOLD if selected
          acolor =get_color $selectedcolor, @parent.selected_color, @parent.selected_bgcolor unless @parent.nil?
        end
        if focussed 
          _attr |= Ncurses::A_REVERSE
        end
        #$log.debug "label :#{@text}, #{value}, #{r}, #{c} col= #{@color}, #{@bgcolor} acolor= #{acolor} j:#{@justify} dlL: #{@display_length} "
        _height = @height || 1
        str = @justify.to_sym == :right ? "%*s" : "%-*s"  # added 2008-12-22 19:05 
        # loop added for labels that are wrapped.
        # TODO clear separately since value can change in status like labels
        0.upto(_height-1) { |i| 
          graphic.printstring r+i, c, " " * len , acolor,_attr
        }
        lablist.each_with_index do |_value, ix|
          break if ix >= _height
          if @justify.to_sym == :center
            padding = (@display_length - _value.length)/2
            _value = " "*padding + _value + " "*padding # so its cleared if we change it midway
          end
          graphic.printstring r, c, str % [len, _value], acolor,_attr
          r += 1
        end
    end
  # ADD HERE LABEL
  end
end
