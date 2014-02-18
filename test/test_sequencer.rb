require 'test/unit'
require 'set'
require 'fileutils'
require File.dirname(__FILE__) + '/../lib/sequencer'

TEST_DIR = File.expand_path(File.dirname(__FILE__)) + "/tmp"

def emit_test_dirs
  start_f = 123
  end_f  = 568
  
  FileUtils.mkdir_p(TEST_DIR + "/sequence_and_sole_file")
  main_seq = TEST_DIR + "/sequence_and_sole_file/seq1.%06d.tif"
  sole_file = TEST_DIR + "/sequence_and_sole_file/somefile.tif"
  (start_f..end_f).each do | i |
    FileUtils.touch(main_seq % i)
  end
  FileUtils.touch(sole_file)
  
  broken_seq = TEST_DIR + "/sequence_and_sole_file/broken_seq.%06d.tif"
  
  (start_f..end_f).each do | i |
    FileUtils.touch(broken_seq % i)
  end
  
  ((end_f + 10)..(end_f + 134)).each do | i |
    FileUtils.touch(broken_seq % i)
  end
  
  single_file_seq = TEST_DIR + "/sequence_and_sole_file/single_file.002123154.tif"
  FileUtils.touch(single_file_seq)
  
  FileUtils.mkdir_p(TEST_DIR + "/natural_numbering")
  nat_seq = TEST_DIR + "/natural_numbering/somefiles %d.png"
  
  (5545142...5545172).each do | i |
    FileUtils.touch(nat_seq % i)
  end
  
  FileUtils.mkdir_p(TEST_DIR + "/many_seqs")
  (458..512).each do | i |
    FileUtils.touch(TEST_DIR + "/many_seqs/seq1.%d.tif" % i)
  end
  
  (228..312).each do | i |
    FileUtils.touch(TEST_DIR + "/many_seqs/anotherS %d.tif" % i)
  end
  FileUtils.touch(TEST_DIR + "/many_seqs/single.tif")
  
  FileUtils.mkdir_p(TEST_DIR + "/many_seqs/subdir")
  (445..471).each do | i |
    FileUtils.touch(TEST_DIR + "/many_seqs/subdir/in_subdir %d.tif" % i)
  end
  
end

def teardown_test_dirs
  FileUtils.rm_rf(TEST_DIR)
end

class Test_glob_and_padding_for < Test::Unit::TestCase
  
  def test_returns_proper_glob_pattern_padding_for_a_path_with_extension
    glob, pad = Sequencer.glob_and_padding_for("file.00001.gif")
    assert_equal "file.[0-9][0-9][0-9][0-9][0-9].gif", glob
    assert_equal 5, pad
  end
  
  def test_returns_proper_glob_pattern_and_padding_for_a_path_without_extension
    glob, pad = Sequencer.glob_and_padding_for("file.00001")
    assert_equal "file.[0-9][0-9][0-9][0-9][0-9]", glob
    assert_equal 5, pad
  end
  
  def return_nil_for_a_file_that_is_not_in_the_sequence
     glob, pad = Sequencer.glob_and_padding_for("file")
     assert_nil glob
  end
end

class Sequencer_entries_should < Test::Unit::TestCase
  def setup; emit_test_dirs; end
  def teardown; teardown_test_dirs; end
  
  def test_returns_entries_recursive_for_every_sequence_in_a_directory
    entries = Sequencer.recursive_entries(TEST_DIR + "/many_seqs")
    names = entries.map{|e| e.to_s }
    assert_equal ["anotherS [228..312].tif", "seq1.[458..512].tif", "single.tif", "in_subdir [445..471].tif"], names
  end
end

class Sequencer_from_enum_should < Test::Unit::TestCase
  def setup; emit_test_dirs; end
  def teardown; teardown_test_dirs; end
  
  def test_returns_entries_from_enum
    items = Dir.entries(TEST_DIR + '/many_seqs')
    entries = Sequencer.from_enumerable(items)
    names = entries.map{|e| e.to_s }
    assert_equal ["anotherS [228..312].tif", "seq1.[458..512].tif", "single.tif", "subdir"], names
  end
end

class A_Sequence_created_from_unpadded_files_should < Test::Unit::TestCase
  def setup; emit_test_dirs; end
  def teardown; teardown_test_dirs; end
  
  def test_properly_created
    s = Sequencer.from_single_file(TEST_DIR + "/natural_numbering/somefiles 5545168.png")
    assert_not_nil s
    assert_equal 30, s.expected_frames
    assert_equal 30, s.file_count
    assert_equal "somefiles %07d.png", s.pattern
  end
end

class A_Sequence_created_from_a_file_that_has_no_numbering_slot_should
  def setup; @single = Sequencer::Sequence.new("/tmp", ["foo.tif"]); end
  
  def test_report_a_pattern_that_is_the_name_as_filename
    assert_equal 'foo.tif', @single.pattern
    assert @single.single_file?
    assert_equal 1, @single.expected_frames
    assert_equal "#<foo.tif>", @single.inspect
  end
end

class Sequencer_bulk_rename_should < Test::Unit::TestCase
  def setup
    emit_test_dirs
    @with_gaps = Sequencer.from_single_file(TEST_DIR + "/sequence_and_sole_file/broken_seq.000245.tif")
  end
  
  def teardown
    teardown_test_dirs
  end
  
  def test_return_a_new_Sequencer_with_right_parameters
    res = @with_gaps.bulk_rename("another_base")
    assert_equal @with_gaps.length, res.length
    assert_equal @with_gaps.directory, res.directory
    assert_equal "another_base.%03d.tif", res.pattern
    
    assert File.exist?(res.to_paths[0])
    assert File.exist?(res.to_paths[-1])
  end
end

class A_Sequence_created_from_pad_numbered_files_should < Test::Unit::TestCase
  def setup
    emit_test_dirs
    @gapless = Sequencer.from_single_file(TEST_DIR + "/sequence_and_sole_file/seq1.000245.tif")
    @with_gaps = Sequencer.from_single_file(TEST_DIR + "/sequence_and_sole_file/broken_seq.000245.tif")
    @single = Sequencer.from_single_file(TEST_DIR + "/sequence_and_sole_file/single_file.002123154.tif")
  end
  
  def teardown
    teardown_test_dirs
  end
  
  def test_initialize_itself_from_one_path_to_a_file_in_the_sequence_without_gaps
    assert_not_nil @gapless
    assert_kind_of Sequencer::Sequence, @gapless
    assert_respond_to @gapless, :gaps?
    assert !@gapless.single_file?
    
    assert !@gapless.gaps?, "this is a gapless sequence"
    assert_equal 446, @gapless.file_count, "actual file count in sequence"
    assert_equal 446, @gapless.length, "actual file count in sequence"
    assert_equal 446, @gapless.expected_frames, "expected frame count in sequence"
    assert_equal '#<seq1.[123..568].tif>', @gapless.inspect
    
    files = @gapless.to_a
    assert_equal 446, files.length
    assert_equal 'seq1.000123.tif', files[0] 
    
    paths = @gapless.to_paths
    assert_equal 446, paths.length
    assert_equal File.expand_path(File.dirname(__FILE__)) + "/tmp/sequence_and_sole_file/seq1.000123.tif", paths[0]
  end
  
  def test_initialize_itself_from_one_path_to_a_file_in_the_sequence_with_gaps
    assert_not_nil @with_gaps
    assert_kind_of Sequencer::Sequence, @with_gaps
    assert !@with_gaps.single_file?
    
    assert @with_gaps.gaps?
    assert_equal 1, @with_gaps.gap_count
    assert_equal 2, @with_gaps.segment_count
    assert_equal 9, @with_gaps.missing_frames
    assert_equal '#<broken_seq.[123..568, 578..702].tif>', @with_gaps.inspect
    assert @with_gaps.include?("broken_seq.000123.tif")
    assert !@with_gaps.include?("bogus.123.tif")
  end
  
  def test_equals_another
    assert_not_nil @with_gaps
    another = Sequencer.from_single_file(TEST_DIR + "/sequence_and_sole_file/broken_seq.000245.tif")
    assert_equal @with_gaps, another
  end
  
  def test_equals_with_same_initialization
    one = Sequencer.from_single_file(TEST_DIR + "/sequence_and_sole_file/broken_seq.000246.tif")
    another = Sequencer.from_single_file(TEST_DIR + "/sequence_and_sole_file/broken_seq.000245.tif")
    assert_equal one, another
  end
  
  def test_return_subsequences_without_gaps
    subseqs = @with_gaps.to_sequences
    assert_kind_of Sequencer::Sequence, subseqs[0]
    assert_kind_of Sequencer::Sequence, subseqs[1]
    
    first_seq, second_seq = subseqs
    assert_equal 123, first_seq.first_frame_no
    assert_equal 568, first_seq.last_frame_no
    assert_equal 578, second_seq.first_frame_no
    assert_equal 702, second_seq.last_frame_no
    
    assert_equal second_seq.directory, first_seq.directory
    assert_equal @with_gaps.directory, first_seq.directory 
  end
  
  def test_list_all_sequences_in_directory_and_subdirectories_using_the_pattern
    s = Sequencer.from_glob(TEST_DIR + "/**/*.tif")
    # Here we need to use a Set since Ruby does not sort the globbed results
    # in a cross-platform way
    ref_set = Set.new([
      "#<anotherS [228..312].tif>",
      "#<seq1.[458..512].tif>",
      "#<single.tif>",
      "#<in_subdir [445..471].tif>",
      "#<broken_seq.[123..568, 578..702].tif>",
      "#<seq1.[123..568].tif>",
      "#<single_file.002123154.tif>",
      "#<somefile.tif>"
    ])
    output_sequences = Set.new(s.map{|sequence| sequence.inspect })
    assert_equal ref_set, output_sequences
  end
  
  def test_initialize_itself_from_a_single_file
    assert @single.single_file?
    assert_equal '#<single_file.002123154.tif>', @single.inspect 
    assert !@single.gaps?
    assert_equal 1, @single.expected_frames
    assert_equal 1, @single.file_count
  end
  
end