# Provides the ability to scroll content, typically an array
# widget that includes may override on_enter_row and on_leave_row
# Caller should have
#   row_count()
#   scrollatrow() typically @height - 2 (unless a header row, then -3)
#   @current_index (row of current index, starting with 0 usually)
#   @toprow : set to 0 for starters, top row to be displayed
#   @pcol (used for horiz scrolling, starts at 0)
#
module ListScrollable
  attr_reader :search_found_ix, :find_offset, :find_offset1
  attr_accessor :show_caret # 2010-01-23 23:06 our own fake insertion point
  def previous_row num=(($multiplier.nil? or $multiplier == 0) ? 1 : $multiplier)
    #return :UNHANDLED if @current_index == 0 # EVIL
    return false if @current_index == 0 
    @oldrow = @current_index
    # NOTE that putting a multiplier inside, prevents an event from being triggered for each row's
    # on leave and on enter
    num.times { 
      @current_index -= 1 if @current_index > 0
    }
    bounds_check
    $multiplier = 0
  end
  alias :up :previous_row
  def next_row num=(($multiplier.nil? or $multiplier == 0) ? 1 : $multiplier)
    rc = row_count
    # returning unhandled was clever .. when user hits down arrow on last row the focus goes to
    # next field. however, in long lists when user scrolls the sudden jumping to next is very annoying.
    # In combos, if focus was on last row, the combo closed which is not accceptable.
    #return :UNHANDLED if @current_index == rc-1 # EVIL !!!
    return false if @current_index == rc-1 
    @oldrow = @current_index
    @current_index += 1*num if @current_index < rc
    bounds_check
    $multiplier = 0
  end
  alias :down :next_row
  def goto_bottom
    @oldrow = @current_index
    rc = row_count
    @current_index = rc -1
    bounds_check
  end
  alias :goto_end :goto_bottom
  def goto_top
    @oldrow = @current_index
    @current_index = 0
    bounds_check
  end
  alias :goto_start :goto_top
  def scroll_backward
    @oldrow = @current_index
    h = scrollatrow()
    m = $multiplier == 0? 1 : $multiplier
    @current_index -= h * m
    bounds_check
    $multiplier = 0
  end
  def scroll_forward
    @oldrow = @current_index
    h = scrollatrow()
    rc = row_count
    m = $multiplier == 0? 1 : $multiplier
    # more rows than box
    if h * m < rc
      @toprow += h+1 #if @current_index+h < rc
      @current_index = @toprow
    else
      # fewer rows than box
      @current_index = rc -1
    end
    #@current_index += h+1 #if @current_index+h < rc
    bounds_check
  end

  ##
  # please set oldrow before calling this. Store current_index as oldrow before changing. NOTE
  def bounds_check
    h = scrollatrow()
    rc = row_count

    @current_index = 0 if @current_index < 0  # not lt 0
    @current_index = rc-1 if @current_index >= rc && rc>0 # not gt rowcount
    @toprow = rc-h-1 if rc > h && @toprow > rc - h - 1 # toprow shows full page if possible
    # curr has gone below table,  move toprow forward
    if @current_index - @toprow > h
      @toprow = @current_index - h
    elsif @current_index < @toprow
      # curr has gone above table,  move toprow up
      @toprow = @current_index
    end
 
    if @oldrow != @current_index

      on_leave_row @oldrow if respond_to? :on_leave_row     # to be defined by widget that has included this
      on_enter_row @current_index   if respond_to? :on_enter_row  # to be defined by widget that has included this
    end
    set_form_row
    #set_form_col 0 # added 2009-02-15 23:33  # this works for lists but we don't want this in TextArea's
    @repaint_required = true
  end
  # the cursor should be appropriately positioned
  def set_form_row
    r,c = rowcol
    @rows_panned ||= 0
    
    win_row = 0 # 2010-02-07 21:44 now ext offset added by widget

    # when the toprow is set externally then cursor can be mispositioned since 
    # bounds_check has not been called
    if @current_index < @toprow
      # cursor is outside table
      @current_index = @toprow # ??? only if toprow 2010-10-19 12:56 
    end

    row = win_row + r + (@current_index-@toprow) + @rows_panned 
    #$log.debug " #{@name} set_form_row #{row} = ci #{@current_index} + r #{r} + winrow: #{win_row} - tr:#{@toprow} #{@toprow} + rowsp #{@rows_panned} "
    # row should not be < r or greater than r+height TODO FIXME

   
    
    setrowcol row, nil
    #show_caret_func
  end
  ## In many situations like placing a textarea or textview inside a splitpane 
  ##+ or scrollpane there have been issues getting the cursor at the right point, 
  ##+ since there are multiple buffers. Finally in tabbedpanes, i am pretty 
  ##+ lost getting the correct position, and i feel we should set the cursor 
  ##+ internally once and for all. So here's an attempt

  # paint the cursor ourselves on the widget, rather than rely on getting to the top window with
  # the correct coordinates. I do need to erase cursor too. Can be dicey, but is worth the attempt.
  # This works perfectly, except for when placed in a Tabbedpane since that prints the form with a row offset 
  #+ of 2 and the widget does not know of the offset. cursor gets it correct since the form has an add_row.
  def show_caret_func
      return unless @show_caret
      # trying highlighting cursor 2010-01-23 19:07 TABBEDPANE TRYING
      # TODO take into account rows_panned etc ? I don't think so.
      @rows_panned ||= 0
      r,c = rowcol
      yy = r + @current_index - @toprow - @win_top
      #xx = @form.col # how do we know what value has been set earlier ?
      yy = r + @current_index - @toprow #- @win_top
      yy = @row_offset + @current_index - @toprow #- @win_top
      xx = @col_offset + @curpos || 0
      #yy = @row_offset if yy < @row_offset # sometimes r is 0, we are missing something in tabbedpane+scroll
      #xx = @col_offset if xx < @col_offset
      #xx = 0 if xx < 0

      $log.debug " #{@name} printing CARET at #{yy},#{xx}: fwt:- #{@win_top} r:#{@row} tr:-#{@toprow}+ci:#{@current_index},+r #{r}  "
      if !@oldcursorrow.nil?
          @graphic.mvchgat(y=@oldcursorrow, x=@oldcursorcol, 1, Ncurses::A_NORMAL, $datacolor, NIL)
      end
      @oldcursorrow = yy
      @oldcursorcol = xx
      @graphic.mvchgat(y=yy, x=xx, 1, Ncurses::A_NORMAL, $reversecolor, nil)
      @buffer_modified = true
  end
  def scroll_right
    $log.debug " inside scroll_right "
    hscrollcols = $multiplier > 0 ? $multiplier : @width/2
    $log.debug " scroll_right  mult:#{$multiplier} , hscrollcols  #{hscrollcols}, w: #{@width} ll:#{@longest_line} "
    #blen = @buffer.rstrip.length
    blen = @longest_line
    @pcol += hscrollcols if @pcol + @width < blen 
    @repaint_required = true
  end
  def scroll_left
    hscrollcols = $multiplier > 0 ? $multiplier : @width/2
    @pcol -= hscrollcols if @pcol > 0
    @pcol = 0 if @pcol < 0
    @repaint_required = true
  end
  ## returns cursor to last row (if moving columns in same row, won't work)
  # Useful after a large move such as 12j, 20 C-n etc, Mapped to '' in textview
  def goto_last_position
    return unless @oldrow
    @current_index = @oldrow
    bounds_check
  end
  # not that saving content_rows is buggy since we add rows.
  ##
  # caution, this now uses winrow not prow
  ## for user to know which row is being focussed on
  def focussed_index
    @current_index # 2009-01-07 14:35 
  end
  # only to be used in single selection cases as focussed item FIXME.
  # best not to use, as can be implementation dep, use current_index
  def selected_item
    get_content()[focussed_index()]
  end
  #alias :current_index :focussed_index
  alias :selected_index :focussed_index
  
  # finds the next match for the char pressed
  # returning the index
  # If we are only checking first char, then why chomp ?
  # Please note that this is used now by tree, and list can have non-strings, so use to_s
  def next_match char
    data = get_content
    row = focussed_index + 1
    row.upto(data.length-1) do |ix|
      #val = data[ix].chomp rescue return  # 2010-01-05 15:28 crashed on trueclass
      val = data[ix].to_s rescue return  # 2010-01-05 15:28 crashed on trueclass
      #if val[0,1] == char #and val != currval
      if val[0,1].casecmp(char) == 0 #AND VAL != CURRval
        return ix
      end
    end
    row = focussed_index - 1
    0.upto(row) do |ix|
      #val = data[ix].chomp
      val = data[ix].to_s
      #if val[0,1] == char #and val != currval
      if val[0,1].casecmp(char) == 0 #and val != currval
        return ix
      end
    end
    return -1
  end
  ## 2008-12-18 18:03 
  # sets the selection to the next row starting with char
  def set_selection_for_char char
    @oldrow = @current_index
    @last_regex = "^#{char}"
    ix = next_match char
    @current_index = ix if ix && ix != -1
    @search_found_ix = @current_index
    bounds_check
    return ix
  end

  ##
  # ensures that the given row is focussed
  # new version of older one that was not perfect.
  # 2009-01-17 13:25 
  def set_focus_on arow
    @oldrow = @current_index
    @current_index = arow
    bounds_check if @oldrow != @current_index
  end
  ##
    def install_keys
=begin
      @KEY_ASK_FIND_FORWARD ||= ?\M-f.getbyte(0)
      @KEY_ASK_FIND_BACKWARD ||= ?\M-F.getbyte(0)
      @KEY_FIND_NEXT ||= ?\M-g.getbyte(0)
      @KEY_FIND_PREV ||= ?\M-G.getbyte(0)
=end
      @KEY_ASK_FIND ||= ?\M-f.getbyte(0)
      @KEY_FIND_MORE ||= ?\M-g.getbyte(0)
    end
    def ask_search
      options = ["Search backwards", "case insensitive", "Wrap around"]
      sel,regex,hash =  get_string_with_options("Enter regex to search", 20, @last_regex||"", "checkboxes"=>options, "checkbox_defaults"=>[@search_direction_prev,@search_case,@search_wrap])
      return if sel != 0
      @search_direction_prev =  hash[options[0]]
      @search_case = hash[options[1]]
      @search_wrap = hash[options[2]]
      if @search_direction_prev == true
        ix = _find_prev regex, @current_index
      else
        ix = _find_next regex, @current_index
      end
      if ix.nil?
        alert("No matching data for: #{regex}")
      else
        set_focus_on(ix)
        set_form_col @find_offset1
        @cell_editor.component.curpos = (@find_offset||0) if @cell_editing_allowed
      end
    end
    def find_more
      if @search_direction_prev 
        find_prev
      else
        find_next
      end
    end
    # find forwards
    # Using this to start a search or continue search
    def _find_next regex=@last_regex, start = @search_found_ix 
      #raise "No previous search" if regex.nil?
      warn "No previous search" and return if regex.nil?
      #$log.debug " _find_next #{@search_found_ix} : #{@current_index}"
      fend = @list.size-1
      if start != fend
      start += 1 unless start == fend
      @last_regex = regex
      @search_start_ix = start
      regex = Regexp.new(regex, Regexp::IGNORECASE) if @search_case
      start.upto(fend) do |ix| 
        row = @list[ix].to_s
        m=row.match(regex)
        if !m.nil?
          @find_offset = m.offset(0)[0]
          @find_offset1 = m.offset(0)[1]
          @search_found_ix = ix
          return ix 
        end
      end
      end
      fend = start-1
      start = 0
      if @search_wrap
        start.upto(fend) do |ix| 
          row = @list[ix].to_s
          m=row.match(regex)
          if !m.nil?
            @find_offset = m.offset(0)[0]
            @find_offset1 = m.offset(0)[1]
            @search_found_ix = ix
            return ix 
          end
        end
      end
      return nil
    end
    def find_next
      unless @last_regex
        alert("No previous search. Search first.")
        return
      end
        ix = _find_next
        regex = @last_regex 
        if ix.nil?
          alert("No more matching data for: #{regex}")
        else
          set_focus_on(ix) 
          set_form_col @find_offset1
        @cell_editor.component.curpos = (@find_offset||0) if @cell_editing_allowed
        end
    end
    def find_prev
      unless @last_regex
        alert("No previous search. Search first.")
        return
      end
        ix = _find_prev
        regex = @last_regex 
        if ix.nil?
          alert("No previous matching data for: #{regex}")
        else
          set_focus_on(ix)
          set_form_col @find_offset
          @cell_editor.component.curpos = (@find_offset||0) if @cell_editing_allowed
        end
    end
    ##
    # find backwards
    # Using this to start a search or continue search
    def _find_prev regex=@last_regex, start = @search_found_ix 
      #raise "No previous search" if regex.nil?
      warn "No previous search" and return if regex.nil?
      #$log.debug " _find_prev #{@search_found_ix} : #{@current_index}"
      if start != 0
      start -= 1 unless start == 0
      @last_regex = regex
      @search_start_ix = start
      regex = Regexp.new(regex, Regexp::IGNORECASE) if @search_case
      start.downto(0) do |ix| 
        row = @list[ix].to_s
        m=row.match(regex)
        if !m.nil?
          @find_offset = m.offset(0)[0]
          @find_offset1 = m.offset(0)[1]
          @search_found_ix = ix
          return ix 
        end
      end
      end
      fend = start-1
      start = @list.size-1
      if @search_wrap
        start.downto(fend) do |ix| 
          row = @list[ix].to_s
          m=row.match(regex)
          if !m.nil?
            @find_offset = m.offset(0)[0]
          @find_offset1 = m.offset(0)[1]
            @search_found_ix = ix
            return ix 
          end
        end
      end
      return nil
    end
    ##
    # goes to start of next word (or n words) - vi's w
    # NOTE: will not work if the list has different data from what is displayed
    # Nothing i can do about it.
    # Also does not work as expected if consecutive spaces FIXME
    #
    def forward_word
      $multiplier = 1 if !$multiplier || $multiplier == 0
      line = @current_index
      buff = @list[line].to_s
      pos = @curpos
      $multiplier.times {
        found = buff.index(/[[:punct:][:space:]]/, pos)
        if !found
          # if not found, we've lost a counter
          if line+1 < @list.length
            line += 1
          else
            return
          end
          buff = @list[line].to_s
          pos = 0
        else
          pos = found + 1
        end
        $log.debug " forward_word: pos #{pos} line #{line} buff: #{buff}"
      }
      @current_index = line
      @curpos = pos
      @buffer = @list[@current_index].to_s
      set_form_row
      set_form_col pos
      @repaint_required = true
    end
    ##
    # goes to  next occurence of <char> (or nth occurence)
    # Actually, we can club this with forward_word so no duplication
    # Or call one from the other
    #
    def forward_char char=nil
      if char.nil?
        $log.debug " XXX acceptng char"
        ch = @graphic.getchar
        return -1 if ch < 0 or ch > 255 # or 127 ???
        char = ch.chr
      end
      $log.debug " forward_char char:#{char}:"
      $multiplier = 1 if !$multiplier or $multiplier == 0
      line = @current_index
      buff = @list[line].to_s
      pos = @curpos
      $multiplier.times {
        found = false
        while !found
          found = buff.index(char, pos)
          if !found
            line += 1 # unless eof
            buff = @list[line].to_s
            pos = 0
          else
            pos = found + 1
          end
          break if line >= @list.size
          $log.debug " #{found} forward_word: pos #{pos} line #{line} buff: #{buff}"
        end
      }
      @current_index = line
      @curpos = pos
      @buffer = @list[@current_index].to_s
      set_form_row
      set_form_col pos
      @repaint_required = true
    end
    # takes a block, this way anyone extending this class can just pass a block to do his job
    # This modifies the string
    def sanitize content  #:nodoc:
      if content.is_a? String
        content.chomp!
        content.gsub!(/\t/, '  ') # don't display tab
        content.gsub!(/[^[:print:]]/, '')  # don't display non print characters
      else
        content
      end
    end
    # returns only the visible portion of string taking into account display length
    # and horizontal scrolling. MODIFIES STRING
    def truncate content  #:nodoc:
      maxlen = @maxlen || @width-2
      if !content.nil? 
        if content.length > maxlen # only show maxlen
          @longest_line = content.length if content.length > @longest_line
          #content = content[@pcol..@pcol+maxlen-1] 
          content.replace content[@pcol..@pcol+maxlen-1] 
        else
          # can this be avoided if pcol is 0 XXX
          content.replace content[@pcol..-1] if @pcol > 0
        end
      end
      content
    end
     

end
