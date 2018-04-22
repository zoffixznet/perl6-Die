unit class GCT is DateTime;

# 198.14/07:106GCT = 1524361376.925148
my constant catastrophe = DateTime.new: '1964-01-22T01:42:56.925148Z';
my regex sign    { <.ws>? <[-−+]>? }
my regex cycle   { \d**{1..*} <.ws>? }
my regex day     { <.ws>? \d**{1..2} <.ws>? }
my regex segment { <.ws>? \d**{1..2} <.ws>? }
my regex unit    { <.ws>? \d**{1..3} <.ws>? }
my regex gct-re {
  ^
    :i [$<rel>='D']? [ [<sign> <cycle> '.']? <day> ]?
    '/' <segment> ':' <unit> ['GCT' <.ws>?]?
  $
}
my $formatter = my method {
    my $Δ = (self - catastrophe).Rat;
    my \neg      := $Δ < 0;
    my \cycles   := ($Δ = $Δ.abs / 100/24/60/60).Int;
    my \days     := (($Δ -= cycles.abs) *= 100).Int;
    my \segments := (($Δ -= days  ) *= 100).Int;
    my \units    := round ($Δ - segments) * 1000;
    sprintf ('-' if neg) ~ "%03d.%02d/%02d:%03d GCT",
        cycles, days, segments, units;
}

proto method new (|) {*}
multi method new (|c) {
    (try self.DateTime::new: |c, :$formatter) // die "Invalid arguments to"
      ~ " {::?CLASS.perl}.new. Use any valid DateTime.new arguments, a GCT"
      ~ " time (e.g. `198.14/07:106 GCT`) or GCT duration"
      ~ " (e.g `D3/00:000 GCT`)\n\nCapture of the args you gave: {c.perl}"
}
multi method new (Str:D $_ --> ::?CLASS:D) {
    when &gct-re {
      my \Δ := (($<sign>//'') eq '-' || ($<sign>//'') eq '−' ?? -1 !! 1)
        * ((($<cycle>//0)*100 + ($<day>//0) + $<segment>/100)*24*60*60
        + $<unit>*.864);
      self.new: ($<rel> ?? now !! catastrophe.Instant) + Δ, :$formatter
    }
    nextsame
}

# We do manual .later because of  https://github.com/rakudo/rakudo/issues/1762
multi method later (:cycle(:$cycles)!) {
    self.new: self.Instant + $cycles*100*24*60*60,   :formatter(self.formatter)
}
multi method later (:segment(:$segments)!) {
    self.new: self.Instant + $segments/100*24*60*60, :formatter(self.formatter)
}
multi method later (:unit(:$units)!) {
    self.new: self.Instant + $units*0.864,           :formatter(self.formatter)
}
multi method later (|c) {
    self.DateTime::later: |c;
}

# We do manual .earlier because of  https://github.com/rakudo/rakudo/issues/1762
multi method earlier (:cycle(:$cycles)!) {
    self.new: self.Instant - $cycles*100*24*60*60,   :formatter(self.formatter)
}
multi method earlier (:segment(:$segments)!) {
    self.new: self.Instant - $segments/100*24*60*60, :formatter(self.formatter)
}
multi method earlier (:unit(:$units)!) {
    self.new: self.Instant - $units*0.864,           :formatter(self.formatter)
}
multi method earlier (|c) {
    self.DateTime::earlier: |c;
}

method OE {
    self.clone: :formatter(DateTime.now.formatter);
}
method OldEarth {
    self.OE
}
method DateTime {
    DateTime.new: self.Instant;
}
