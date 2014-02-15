# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Date: 2003-Oct-30 15:04 (EST)
# Function: 
#
# $Id: IPDB.pm,v 1.7 2010/01/16 03:21:46 jaw Exp $

# XXX only ipv4 for now...

package IPDB;

use IPDB::SWIP;

sub valid_inet {
    my $a = shift;

    print STDERR "validate $a?\n";
    
    ( $a =~ /^\d+\.\d+\.\d+\.\d+$/ ) ? 0 : 'invalid netblock';
}

sub valid_net_and_len {
    my $n = shift;
    my $l = shift;

    my $n1 = aton($n);
    my $n2 = $n1 & len_2_mask($l);

    print STDERR "valid $n/$l ? $n1 == $n2\n";
    ($n1 == $n2) ? 0 : 'invalid net + len';
}

sub aton {
    my $a = shift;
    my(@octet) = split /\./, $a;
    my($n);

    $n =  $octet[0]<<24
        | $octet[1]<<16
        | $octet[2]<<8
        | $octet[3];

}

sub ntoa {
    my($a) = shift;

    sprintf "%d.%d.%d.%d", ($a>>24) & 0xFF, ($a>>16) & 0xFF, ($a>>8) & 0xFF, $a & 0xFF;
}

sub len_2_mask {
    my $l = shift;
    my( $i, $r );

    $r = 2**32 - 2**(32-$l);
    $r;
}

sub len_2_count {
    my $l = shift;

    2 ** (32 - $l);
}

sub next_more_specific_routes {
    my $net = shift;
    my $sz  = shift;

    return () if $sz >= 32;
    
    return ( $net,                                         $sz + 1, 
	     $net | (len_2_mask($sz) ^ len_2_mask($sz+1)), $sz + 1 );
    
}


sub dist {
    my( $net0, $sz0, $net1, $sz1 ) = @_;

    my $b1 = $net1 & len_2_mask( $sz0 );
    $sz0 - (32 - int( log( $net0 ^ $b1 )/log(2) ) ) + 1;
}

sub metric {
    my( $want, $have ) = @_;

    my $d = $have - $want;
    $d = - $d if $d > 0;	# want $d < 0

    $m  = 4 ** $d;
}


sub find_and_alloc {
    my %p = @_;

    my $db   = $p{db};
    my $size = $p{size};
    my( $block );
    
    if( $p{block} ){
	# specific block requested - use it

	
    }
    
    # find a block - try exact match
    my $poolwh = $p{pool} ? 'pool = ?' : 'pool is null';
	
    $block = $db->select_scalar(<<EOSQL,
select block_id from mi_ipdb_block where size = ? and status = 'available' and $poolwh
EOSQL
	$size, ($p{pool} || ())  );
    
    return $block if $block;

    
    # otherwise find best larger block
    my($blk, $net, $sz) = find_best_available( %p );
    $net = aton($net);

    # print STDERR "found $blk, $net, $sz\n";
    die "no blocks available in pool\n" unless $blk;
    
    # - split block down to desired size
    while( $sz != $size ){
	my( $na, $sa, $nb, $sb ) = next_more_specific_routes( $net, $sz );

	print STDERR "splitting ", ntoa($net), "/$sz => ", ntoa($na), "/$sa + ", ntoa($nb), "/$sb\n";

	my $d = $db->select_1hashref('select * from mi_ipdb_block where block_id = ?', $blk );

	# create 2 new blocks, delete old one
	# (or modify one, create one)
	
	$db->update_hash( 'mi_ipdb_block', {
	    netblock => ntoa($na),
	    size     => $sa,
	    sort_low => $na,
	    sort_high=> $na | ~ len_2_mask($sa), 
	}, [block_id => $blk] );
	Talmud::touch_object( $db, $blk );
	
	$d->{block_id} = Talmud::create_object( $db, 'ipdb/block' );
	$d->{netblock} = ntoa($nb);
	$d->{size}     = $sb;
	$d->{sort_low} = $nb;
	$d->{sort_high}= $nb | ~ len_2_mask($sb);
	$db->insert_hash('mi_ipdb_block', $d );

	$net = $na;  $sz = $sa;
    }

    return $blk;

}

sub find_best_available {
    my %p = @_;

    my $db = $p{db};
    my( %avail, %alloc, %memo );
    
    # get available blocks
    my $poolwh = $p{pool} ? 'pool = ?' : 'pool is null';
    
    my($b, $n, $s) = $db->select_1array(
		     qq{select block_id, netblock, size from mi_ipdb_block
			    where size < ? and status = 'available' and $poolwh
			    order by size desc, netblock
				limit 1},
		     $p{size}, ($p{pool} ||()) );

    return ($b, $n, $s);
}

sub attempt_join {
    my $db  = shift;
    my $blk = shift;

    # get data on block
    my $da = $db->select_1hashref('select * from mi_ipdb_block where block_id = ?', $blk);
    return if $da->{size} == 0;
    
    while( 1 ){
	# get data on adjacent block

	my $n = aton( $da->{netblock} );
	my $s = $da->{size};
	my $n2 = $n ^ len_2_mask( $s - 1 ) ^ len_2_mask( $s );

	print STDERR "join: ", ntoa($n), "/$s + ", ntoa($n2), "/$s => $n2/$s\n";
	
	my $d2 = $db->select_1hashref('select * from mi_ipdb_block where netblock = '.
				      ' ? and size = ?',
				      ntoa($n2), $s );

	last unless $d2 && $d2->{block_id};
	
	# can they be joined?

	last if $d2->{status}  ne 'available';
	last if $da->{pool}    ne $d2->{pool};
	last if $da->{meta_id} ne $d2->{meta_id};

	# join

	print STDERR "deleting $d2->{block_id}\n";
	$db->do('delete from mi_ipdb_block where block_id = ?', $d2->{block_id});
	$da->{netblock} = ntoa( $n & len_2_mask($s - 1) );
	$da->{size}     = $s - 1;

	print STDERR "updating  => $da->{netblock} / $da->{size}\n";
	
	$db->update_hash('mi_ipdb_block', {
	    netblock	=> $da->{netblock},
	    size	=> $da->{size},
	    sort_low	=> aton( $da->{netblock} ),
	    sort_high	=> aton( $da->{netblock} ) | ~ len_2_mask( $da->{size} ),
	}, [block_id => $blk] );

    }
}

1;
