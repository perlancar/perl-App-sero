package App::sero;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{':package'} = {
    summary => 'A suite of stock-related utilities',
    v => 1.1,
};

our $sch_date = ['date*', 'x.perl.coerce_to' => 'DateTime'];

our %args_common = (
    default_exchange => {
        schema => 'str*',
    },
);

our %args_db = (
    db_name => {
        schema => 'str*',
        req => 1,
        tags => ['category:database-connection'],
    },
    # XXX db_host
    # XXX db_port
    db_username => {
        schema => 'str*',
        tags => ['category:database-connection'],
    },
    db_password => {
        schema => 'str*',
        tags => ['category:database-connection'],
    },
);

our %args_filter_stocks = (
    stocks => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'stock',
        schema => ['array*', of=>'str*', 'x.perl.coerce_rules'=>['str_comma_sep']],
        tags => ['category:filtering'],
    },
);

our %args_filter_date = (
    date_start => {
        schema => ['date*', 'x.perl.coerce_to' => 'DateTime'],
        tags => ['category:filtering'],
        req => 1,
        pos => 0,
    },
    date_end => {
        schema => ['date*', 'x.perl.coerce_to' => 'DateTime'],
        tags => ['category:filtering'],
        req => 1,
        pos => 1,
    },
);

our %argo_detail = (
    detail => {
        schema => ['bool*', is=>1],
        cmdline_aliases => {l=>{}},
    },
);

our $db_schema_spec = {
    latest_v => 1,
    install => [

        'CREATE TABLE exchange (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             code VARCHAR(32) NOT NULL, UNIQUE(code),
             en_name VARCHAR(255) NOT NULL,
             local_name VARCHAR(255) NOT NULL,
             country_code CHAR(2) NOT NULL
         )',

        # list of securities (or indexes)
        # XXX publisher?
        # XXX start_date?
        q(CREATE TABLE security (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             code VARCHAR(32) NOT NULL, UNIQUE(code),
             currency VARCHAR(3) NOT NULL, -- '' for index
             type VARCHAR(32) NOT NULL, -- e.g. INDEX, STOCK, MF (mutual fund),
             local_name VARCHAR(255) NOT NULL,
             country_code CHAR(2) NOT NULL
         )),

        # XXX mutual fund-specific information, e.g. starting unit, type of
        # mutual fund (mixed, equity, fixed income, etc), fees, etc.

        "CREATE TABLE daily_price (
             id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
             exchange_id INT NOT NULL,
             date DATE NOT NULL,
             src VARCHAR(8) NOT NULL,
             code VARCHAR(12) NOT NULL, INDEX(code),
             UNIQUE(date, code, exchange_id, src),
             open DECIMAL(18,4) NOT NULL,
             high DECIMAL(18,4) NOT NULL,
             low DECIMAL(18,4) NOT NULL,
             close DECIMAL(18,4) NOT NULL,
             adjclose DECIMAL(18,4) NOT NULL,
             volume DECIMAL(18,4),
             note VARCHAR(255)
         ) ENGINE='MyISAM'",

        # XXX spot_price
    ],
};

sub _init {
    my $r = shift;

    require DBIx::Connect::MySQL;
    log_trace "Connecting to database ...";
    $r->{_dbh} = DBIx::Connect::MySQL->connect(
        "dbi:mysql:database=$r->{args}{db_name}",
        $r->{args}{db_username},
        $r->{args}{db_password},
        {RaiseError => 1},
    );
    my $dbh = $r->{_dbh};

    require SQL::Schema::Versioned;
    my $res = SQL::Schema::Versioned::create_or_update_db_schema(
        dbh => $r->{_dbh}, spec => $db_schema_spec,
    );
    die "Cannot run the application: cannot create/upgrade database schema: $res->[1]"
        unless $res->[0] == 200;

    # XXX move this to an importer
    $dbh->do("INSERT IGNORE INTO exchange (code, en_name, local_name, country_code) VALUES ('IDX', 'Indonesian Stock Exchange', 'Bursa Efek Indonesia', 'ID')");

    [200];
}

$SPEC{list_markets} = {
    v => 1.1,
    summary => 'List supported stock exchanges',
    args => {
        %args_common,
        %args_db,
        %argo_detail,
    },
};
sub list_markets {
    require Finance::SE::Catalog;
    require PERLANCAR::Module::List;

    my %args = @_;

    my $r = $args{-cmdline_r};
    _init($r);

    my $cat = Finance::SE::Catalog->new;
    my $mods = PERLANCAR::Module::List::list_modules(
        "App::sero::Exchange::", {list_modules=>1});
    my @rows;
    for my $mod (sort keys %$mods) {
        (my $code = $mod) =~ s/\AApp::sero::Exchange:://;
        my $row;
        eval { $row = $cat->by_code($code) };
        next if $@;
        push @rows, $row;
    }

    unless ($args{detail}) {
        @rows = map { $_->{code} } @rows;
    }

    [200, "OK", \@rows];
}

$SPEC{list_daily_prices} = {
    v => 1.1,
    summary => 'List daily stock prices',
    args => {
        %args_common,
        %args_db,
        %args_filter_stocks,
        %args_filter_date,
    },
};
sub list_daily_prices {
    my %args = @_;

    my $r = $args{-cmdline_r};
    _init($r);

    # XXX

    [200];
}

$SPEC{calc_returns} = {
    v => 1.1,
    summary => 'Calculate return between two dates',
    args => {
        %args_common,
        %args_db,
        %args_filter_stocks,
        %args_filter_date,
    },
};
sub calc_returns {
    my %args = @_;

    my $r = $args{-cmdline_r};
    _init($r);

    [200];
}

1;
# ABSTRACT:

=head1 SYNOPSIS

Please see included script L<sero>.


=head1 DESCRIPTION

About the name: I<sero> means stock/share. Two more common Indonesian terms
derived from this word are: I<perseroan> which means a (business) partnership,
and I<perseroan terbatas> which means a corporation.


=head1 SEE ALSO
