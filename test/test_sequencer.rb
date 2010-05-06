require 'test/unit'
require 'rubygems'
require 'test/spec'
require 'fileutils'
require File.dirname(__FILE__) + '/../lib/sequencer'

TEST_DIR = File.dirname(__FILE__) + "/tmp"

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

context "Sequencer.glob_and_padding_for should" do
  
  specify "return proper glob pattern and padding for a path with extension" do
    glob, pad = Sequencer.glob_and_padding_for("file.00001.gif")
    glob.should.equal "file.[0-9][0-9][0-9][0-9][0-9].gif"
    pad.should.equal 5
  end

  specify "return proper glob pattern and padding for a path without extension" do
    glob, pad = Sequencer.glob_and_padding_for("file.00001")
    glob.should.equal "file.[0-9][0-9][0-9][0-9][0-9]"
    pad.should.equal 5
  end
  
  specify "return nil for a file that is not a sequence" do
     glob, pad = Sequencer.glob_and_padding_for("file")
     glob.should.be.nil
  end
end

context "Sequencer.entries should" do
  before { emit_test_dirs }
  after { teardown_test_dirs }
  specify "return entries for every sequence in a directory" do
    entries = Sequencer.entries(TEST_DIR + "/many_seqs")
  end
end

context "A Sequence created from unpadded files should" do
  before { emit_test_dirs }
  after { teardown_test_dirs }
  
  specify "be properly created" do
    s = Sequencer.from_single_file(TEST_DIR + "/natural_numbering/somefiles 5545168.png")
    s.should.not.be.nil
    s.expected_frames.should.equal 30
    s.file_count.should.equal 30
    s.pattern.should.equal "somefiles %07d.png"
  end
end

context "A Sequence created from a file that has no numbering slot should" do
  before { @single = Sequencer::Sequence.new("/tmp", ["foo.tif"]) }
  
  specify "report a pattern that is the same as filename" do
    @single.pattern.should.equal "foo.tif"
    @single.should.be.single_file?
    @single.expected_frames.should.equal 1
    @single.inspect.should.equal "#<foo.tif>"
  end
end

context "A Sequence created from pad-numbered files should" do
  before do
    emit_test_dirs
    @gapless = Sequencer.from_single_file(TEST_DIR + "/sequence_and_sole_file/seq1.000245.tif")
    @with_gaps = Sequencer.from_single_file(TEST_DIR + "/sequence_and_sole_file/broken_seq.000245.tif")
    @single = Sequencer.from_single_file(TEST_DIR + "/sequence_and_sole_file/single_file.002123154.tif")
  end
  
  after { teardown_test_dirs }
  
  specify "initialize itself from one path to a file in the sequence without gaps" do
    @gapless.should.not.be.nil
    @gapless.should.be.kind_of(Sequencer::Sequence)
    @gapless.should.respond_to(:gaps?)
    @gapless.should.not.be.single_file?
    
    @gapless.should.blaming("this is a gapless sequence").not.be.gaps?
    @gapless.file_count.should.blaming("actual file count in sequence").equal(446)
    @gapless.length.should.blaming("actual file count in sequence").equal(446)
    @gapless.expected_frames.should.blaming("expected frame count in sequence").equal(446)
    @gapless.inspect.should.blaming("inspect itself").equal('#<seq1.[123..568].tif>')
    @gapless.pattern.should.equal 'seq1.%06d.tif'
    
    files = @gapless.to_a
    files.length.should.equal 446
    files[0].should.equal 'seq1.000123.tif'
    
    paths = @gapless.to_paths
    paths.length.should.equal 446
    paths[0].should.equal(File.dirname(__FILE__) + "/tmp/sequence_and_sole_file/seq1.000123.tif")
  end
  
  specify "initialize itself from one path to a file in the sequence with gaps" do
    @with_gaps.should.not.be.nil
    @with_gaps.should.be.kind_of(Sequencer::Sequence)
    @with_gaps.should.not.be.single_file?
    
    @with_gaps.should.be.gaps?
    @with_gaps.gap_count.should.equal 1
    @with_gaps.segment_count.should.equal 2
    @with_gaps.missing_frames.should.equal(9)
    @with_gaps.inspect.should.blaming("inspect itself").equal('#<broken_seq.[123..568, 578..702].tif>')
    @with_gaps.should.include("broken_seq.000123.tif")
    @with_gaps.should.not.include("bogus.123.tif")
  end
  
  specify "return subsequences without gaps" do
    subseqs = @with_gaps.to_sequences
    subseqs[0].should.be.kind_of(Sequencer::Sequence)
    subseqs[1].should.be.kind_of(Sequencer::Sequence)
    
    first_seq, second_seq = subseqs
    first_seq.first_frame_no.should.equal 123
    first_seq.last_frame_no.should.equal 568
    second_seq.first_frame_no.should.equal 578
    second_seq.last_frame_no.should.equal 702
    
    first_seq.directory.should.equal second_seq.directory
    first_seq.directory.should.equal @with_gaps.directory
  end
  
  specify "list all sequences in directory and subdirectories using the pattern" do
    s = Sequencer.from_glob(TEST_DIR + "/**/*.tif")
    inspected = '[#<single.tif>, #<seq1.[458..512].tif>, #<anotherS [228..312].tif>, #<in_subdir [445..471].tif>, #<seq1.[123..568].tif>, #<somefile.tif>, #<single_file.002123154.tif>, #<broken_seq.[123..568, 578..702].tif>]'
    s.inspect.should.equal inspected
  end
  
  specify "initialize itself from a single file" do
    @single.should.be.single_file?
    @single.inspect.should.equal '#<single_file.002123154.tif>'
    @single.should.not.be.gaps?
    @single.expected_frames.should.equal 1
    @single.file_count.should.equal 1
  end
  
end