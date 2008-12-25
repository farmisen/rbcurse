=begin
  * Name: InputDataEvent
  * Description: Event created when data modified in Field or TextEdit
  * Author: rkumar (arunachalesha)
  
  --------
  * Date:  2008-12-24 17:27 
  * License:
    Same as Ruby's License (http://www.ruby-lang.org/LICENSE.txt)

=end
require 'rubygems'

# Event created when data modified in Field or TextEdit
#  2008-12-24 17:54 
module RubyCurses
  class InputDataEvent
    attr_accessor :index0, :index1, :source, :type, :row, :text
    def initialize index0, index1, source, type, row, text
      @index0 = index0
      @index1 = index1
      @source = source
      @type = type
      @row = row
      @text = text
    end
    def to_s
      inspect
    end
    def inspect
      "#{@type.to_s}, #{@source}, #{@index0}, #{@index1}, #{@row}, #{@text}"
    end
  end
end