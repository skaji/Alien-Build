use Test2::Bundle::Extended;
use Alien::Build;
use Path::Tiny qw( path );
use lib 't/lib';
use lib 'corpus/lib';
use Capture::Tiny qw( capture_merged );
use File::Temp qw( tempdir );
use MyTest;

subtest 'non struct alienfile' => sub {

  eval {
    alienfile q{
      use alienfile;
      my $foo = 'bar';
      @{ "${foo}::${foo}" } = ();
    };
  };
  my $error = $@;
  isnt $error, '', 'throws error';
  note "error = $error"; 

};

subtest 'warnings alienfile' => sub {

  my $warning = warning { 
    alienfile q{
      use alienfile;
      my $foo;
      my $bar = "$foo";
    };
  };
  
  ok $warning;
  note $warning;

};

subtest 'compile examples' => sub {

  skip_all 'todo';

  foreach my $alienfile (path('example')->children(qr/\.alienfile$/))
  {
    my $build = eval {
      Alien::Build->load("$alienfile");
    };
    is $@, '';
    isa_ok $build, 'Alien::Build';
  }

};

subtest 'plugin' => sub {

  subtest 'basic' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin 'RogerRamjet' => ();
    };
  
    is(
      $build->meta->prop,
      hash {
        field ramjet => 'roger';
        field foo    => 22;
        field bar    => 'something generated';
        field baz    => undef;
        etc;
      }
    );
  
  };
  
  subtest 'default argument' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin 'RogerRamjet' => 'starscream';
    };
  
    is(
      $build->meta->prop,
      hash {
        field ramjet => 'roger';
        field foo    => 22;
        field bar    => 'starscream';
        field baz    => undef;
        etc;
      }
    );
  
  };
  
  subtest 'other arguments' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin 'RogerRamjet' => (
        foo => 42,
        bar => 'skywarp',
        baz => 'megatron',
      );
    };
  
    is(
      $build->meta->prop,
      hash {
        field ramjet => 'roger';
        field foo    => 42;
        field bar    => 'skywarp';
        field baz    => 'megatron';
        etc;
      }
    );
  
  };

  subtest 'sub package' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin 'NesAdvantage::Controller' => ();
    };
    
    is($build->meta->prop->{nesadvantage}, 'controller');
  
  };
  
  subtest 'negotiate' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin 'NesAdvantage' => ();
    };
    
    is($build->meta->prop->{nesadvantage}, 'negotiate');
  
  };
  
  subtest 'fully qualified class' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin '=Alien::Build::Plugin::RogerRamjet' => ();
    };
  
    is(
      $build->meta->prop,
      hash {
        field ramjet => 'roger';
        field foo    => 22;
        field bar    => 'something generated';
        field baz    => undef;
        etc;
      }
    );
  
  };
  
};

subtest 'probe' => sub {

  subtest 'basic' => sub {

    my $build = alienfile q{
      use alienfile;
      probe sub {
        my($build) = @_;
        $build->install_prop->{called_probe} = 1;
        'share';
      };
    };
  
    is($build->probe, 'share');
    is($build->install_prop->{called_probe}, 1);
  };
  
  subtest 'wrong block' => sub {
  
    eval {
      alienfile q{
        use alienfile;
        sys {
          probe sub { };
        };
      };
    };
    
    like $@, qr/probe must not be in a system block/;
  
  };

};

subtest 'download' => sub {

  subtest 'basic' => sub {
    
    my $build = alienfile q{
      use alienfile;
      use Path::Tiny qw( path );
      probe sub { 'share' };
      share {
        download sub { path('xor-1.00.tar.gz')->touch };
      };
    };
    
    note capture_merged { $build->download; () };
    
    my $download = path($build->install_prop->{download});
    
    is(
      $download->basename,
      'xor-1.00.tar.gz',
    );
  };
  
  subtest 'wrong block' => sub {
  
    eval {
      alienfile q{
        use alienfile;
        sys {
          download sub {};
        };
      };
    };
    
    like $@, qr/download must be in a share block/;
  
  };

};

done_testing;
