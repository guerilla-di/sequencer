module Sequencer
  VERSION = '1.0.0'
  NUMBERS_AT_END = /(\d+)([^\d]+)?$/
  
  extend self
  
  # Detects sequences in the passed directory (same as Dir.entries but returns Sequence objects).
  # Single files will be upgraded to single-frame Sequences
  def entries(of_dir)
    actual_files = Dir.entries(of_dir)[2..-1]
    groups = {}
    
    actual_files.each do | e |
      if e =~ NUMBERS_AT_END
        base = e[0...-([$1, $2].join.length)]
        key = [base, $2]
        groups[key] ||= []
        groups[key] << e
      else
        groups[e] = [e]
      end
    end
    
    groups.map do | key, filenames |
      Sequence.new(of_dir, filenames)
    end
  end
  
  # Detect a Sequence from a single file and return a handle to it
  def from_single_file(path_to_single_file)
    File.stat(path_to_single_file)
    frame_number = path_to_single_file.scan(NUMBERS_AT_END).flatten.shift
    if frame_number =~ /^0/ # Assume that the input is padded and take the glob path
      sequence_via_glob(path_to_single_file)
    else # Take the slower path by pattern-matching on entries
      sequence_via_patterns(path_to_single_file)
    end
  end
  
  # Get a glob pattern and padding offset for a file in a sequence
  def glob_and_padding_for(path)
    plen = 0
    glob_pattern = path.gsub(NUMBERS_AT_END) do
      plen = $1.length
      ('[0-9]' * plen) + $2.to_s
    end
    return nil if glob_pattern == path
    
    [glob_pattern, plen]
  end
  
  private 
  
  def sequence_via_glob(path_to_single_file)
    glob, padding = glob_and_padding_for(path_to_single_file)
    seq_glob = File.join(File.dirname(path_to_single_file), File.basename(glob))
    files = Dir.glob(seq_glob).map {|f| File.basename(f) }
    
    Sequence.new(File.expand_path(File.dirname(path_to_single_file)), files)
  end
  
  def sequence_via_patterns(path_to_single_file)
    base_glob_pattern = path_to_single_file.gsub(NUMBERS_AT_END, '*')
    closing_element = $2
    matching_paths = Dir.glob(base_glob_pattern).select do | p |
      number, closer = p.scan(NUMBERS_AT_END).flatten
      closer == closing_element
    end
    files = matching_paths.map {|f| File.basename(f) }
    Sequence.new(File.expand_path(File.dirname(path_to_single_file)), files)
  end
  
  public
  
  class Sequence
    include Enumerable
    attr_reader :pattern
    
    def initialize(directory, filenames)
      raise "Can't sequence nothingness" if filenames.empty?
      @directory, @filenames = directory, natural_sort(filenames)
      @directory.freeze
      @filenames.freeze
      detect_gaps!
      detect_pattern!
    end
    
    # Returns true if the files in the sequence can have numbers
    def numbered?
      @numbered ||= !!(@filenames[0] =~ NUMBERS_AT_END)
    end
    
    # Returns true if this sequence has gaps
    def gaps?
      @ranges.length > 1
    end
    
    # Tells whether this is a single frame sequence
    def single_file?
      @filenames.length == 1
    end
    
    def inspect
      '#<%s>' % to_s
    end
    
    def to_s
      return @filenames[0] if (!numbered? || single_file?)
      
      printable = unless single_file?
        @ranges.map do | r |
          "%d..%d" % [r.begin, r.end]
        end.join(', ')
      else
        @ranges[0].begin
      end
      @inspect_pattern % "[#{printable}]"
    end
    
    def expected_frames
      @expected_frames ||= ((@ranges[-1].end - @ranges[0].begin) + 1)
    end
    
    def gap_count
      @ranges.length - 1
    end
    
    # Returns the number of frames that the sequence should contain to be continuous
    def missing_frames
      expected_frames - file_count
    end
    
    # Returns the actual file count in the sequence
    def file_count
      @file_count ||= @filenames.length
    end
    
    # Check if this sequencer includes a file
    def include?(base_filename)
      @filenames.include?(base_filename)
    end
    
    # Yield each filename in the sequence to the block
    def each
      @filenames.each {|f| yield(f) }
    end
    
    # Yield each absolute path to a file in the sequence to the block
    def each_path
      @filenames.each{|f| yield(File.join(@directory, f))}
    end
    
    private
    
    def natural_sort(ar)
      ar.sort_by {|e| e.scan(NUMBERS_AT_END).flatten.shift.to_i }
    end
    
    def detect_pattern!
      
      unless numbered?
        @inspect_pattern = "%s"
        @pattern = @filenames[0]
      else
        @inspect_pattern = @filenames[0].gsub(NUMBERS_AT_END) do
          ["%s", $2].join
        end
      
        highest_padding = nil
        @pattern = @filenames[-1].gsub(NUMBERS_AT_END) do
          highest_padding = $1.length
          ["%0#{$1.length}d", $2].join
        end
      
        # Look at the first file in the sequence. If it has a lesser number of 
        lowest_padding = @filenames[0].scan(NUMBERS_AT_END).flatten.shift.length
        if lowest_padding < highest_padding # Natural numbering
          @pattern = @filenames[0].gsub(NUMBERS_AT_END) do
            ["%d", $2].join
          end
        end
      end
      
      @inspect_pattern.freeze
      @pattern.freeze
    end
    
    def detect_gaps!
      only_numbers = @filenames.map do | f |
        f.scan(NUMBERS_AT_END).flatten.shift.to_i
      end
      @ranges = to_ranges(only_numbers)
    end
    
    def to_ranges(array)
      array.compact.sort.uniq.inject([]) do | result, elem |
        result = [elem..elem] if result.length.zero?
        if [result[-1].end, result[-1].end.succ].include?(elem)
          result[-1] = result[-1].begin..elem
        else
          result.push(elem..elem)
        end
        result
      end
    end
  end
  
end
