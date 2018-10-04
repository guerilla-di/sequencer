[![Build Status](https://travis-ci.org/guerilla-di/sequencer.svg?branch=master)](https://travis-ci.org/guerilla-di/sequencer)

Sequencer is the swiss army knife of image sequence management for Ruby. It helps with things like

* Collapsing multibillion-files directory listings to sequence lists with sane names and sane string representations
* Detecting gaps in image sequences
* Renaming sequences for filename uniformity, number uniformity and so on
* Managing image sequences as whole units for media management

## Usage

From the terminal - go to a directory, and then:

     $rseqls
     
        Fussball_Shot[1..1, 3..3].sni
        FinalLichtUitValSec_Shot1.[1..128].jpg
        Fussball_Shot3_v02.sni
        FinalLichtUitValSec_Shot1.0001.ifl
        FinalLichtUitValSec.0001.ifl
        FinalLichtUitValSec.[1..185].jpg

You also have `rseqpad` and `rseqrename` :-)

From Ruby code, when dealing with a single file

    require "sequencer"
    s = Sequencer.from_single_file("/RAID/Film/CONFORM.092183.dpx")
    s.file_count #=> 3201
    s.gaps? #=> true
    s.missing_frames #=> 15, somebody was careless
    s.pattern #=> "CONFORM.%06d.dpx", usable with printf right away

and when dealing with an `Enumerable` of filenames (not necessarily from a file system):

    require "sequencer"
    seqs = Sequencer.from_enumerable(["/RAID/Film/CONFORM.092184.dpx", "/RAID/Film/CONFORM.092183.dpx"])
    seqs.inspect #=> [Sequence], it is an array of sequences since the passed Enumerable might have contained multiple
    s = seqs.first
    s.file_count #=> 2
    s.gaps? #=> false
    s.missing_frames #=> 0
    s.pattern #=> "/RAID/Film/CONFORM.%06d.dpx", usable with printf right away

## Installation:

    $ gem install sequencer

## License

(The MIT License)

Copyright (c) 2010-2016 Julik Tarkhanov (me@julik.nl)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
