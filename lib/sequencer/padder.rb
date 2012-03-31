class Sequencer::Padder
  def initialize(with_sequence, pad_length = nil)
    @sequence = with_sequence
    @padz = (pad_length || e.length.to_s.length).to_i
  end
  
  # Return an array of tuples containing /source/file/path and /destination/file/path
  # renames
  def get_renames
    @sequence.inject([]) do | renames, f |
      rep_name = f.gsub(/([\.\-\_]?)(\d+)\.(\w+)$/) do
        ".%0#{@padz}d.%s" % [$2.to_i, $3]
      end
      # Now this is a replaced name
      from_to =  [File.join(e.directory, f), File.join(e.directory, rep_name)]
      renames.push(from_to)
    end
  end
  
  def self.check_renames_for_dupes(renames)
    # Check for dupes
    destinations = renames.map{|e| e[1] }
    
    if (destinations.uniq.length != destinations.length)
      twice = destinations - destinations.uniq
      raise "Cannot rename - #{twice.join(', ')} will overwrite each other through mangled renames"
    end
  end
end