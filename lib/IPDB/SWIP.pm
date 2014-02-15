# -*- perl -*-

# Copyright (c) 2003 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Date: 2003-Nov-04 23:03 (EST)
# Function: swip functions
#
# $Id: SWIP.pm,v 1.8 2010/01/16 03:21:48 jaw Exp $

package IPDB::SWIP;

sub alloc {
    my $db  = shift;
    my $blk = shift;

    # fetch block data
    my $data = $db->select_1hashref('select * from mi_ipdb_block where block_id = ?', $blk);

    # no swip for internal or small blocks
    return if $data->{usage} eq 'internal';
    return if $data->{size} > 29;

    # calculate swipid
    unless( $data->{swip_id} ){
	my $tmpl = $db->select_scalar('select swipprefix from mi_ipdb_meta where meta_id = ?',
				      $data->{meta_id});
	$tmpl = uc($tmpl);
	my $name = uc($data->{cust_name}); # XXX
	$name  =~ s/[^A-Z0-9]//g;
	$name  = substr($name, 0, 8);
	
	if( !$name ){
	    # use last 2 octets of netblock
	    $name = $data->{netblock};
	    $name =~ s/^[^\.]*\.[^\.]*\.//;
	    $name =~ s/\./-/g;
	}

	my $key = "$tmpl-$name";
	
	# make sure not used

	$db->do('lock mi_ipdb_swip');
	my $n = $db->select_scalar('select MAX(index) from mi_ipdb_swip where label = ?',
				   $key );
	$n ||= 1;

	$db->insert_hash('mi_ipdb_swip',  { label => $key, index => $n } ); 
	$db->update_hash('mi_ipdb_block', { swip_id => "$key-$n" }, [block_id => $data->{block_id}] );
	$data->{swip_id} = "$key-$n";
	
	print STDERR "new swip id: $key-$n\n";
    }
    
    swip_block( $db, 'new', $blk, $data );

}

sub modify {
    my $db  = shift;
    my $blk = shift;

    # fetch block data
    my $data = $db->select_1hashref('select * from mi_ipdb_block where block_id = ?', $blk);

    return unless $data->{swip_id};
    
    if( $data->{status} eq 'available' ){
	swip_block($db, 'delete', $blk, $data);
    }else{
	swip_block($db, 'modify', $blk, $data);
    }
}

sub swip_block {
    my $db   = shift;
    my $mode = shift;
    my $blk  = shift;
    my $data = shift;

    return;

    return unless $data->{swipid};

    my $s = Talmud::sess();
    
    my $stmt = <<EOSQL;
select maintainer, email, handle
    from mi_ipdb_block inner join mi_ipdb_meta using (meta_id)
      inner join mi_ipdb_registry using (registry_id)
    where block_id = ?
EOSQL
    ;
    my( $mntr, $email, $handle
	) = $db->select_1array($stmt, $blk );

    # fetch config data from db
    my $config = { $db->select_2columns('select param, value from mi_ipdb_config where value is not null') };
    
    my $how = {new=>"N", modify=>"M", delete=>"R"}->{$mode} || return 0;
    
    # open SWIP, ">> swip";
    open SWIP, "| /usr/lib/sendmail -t";

    my $cc;
    $cc = "Cc: $config->{swip_cc_addr}\n" if $config->{swip_cc_addr};
    
    print SWIP <<EOS;
Subject: SWIP $mode $data->{swip_id} - $data->{netblock}/$data->{size}
To: $email
${cc}From: $config->{swip_from_addr}
X-IPDB-Info: $blk $s->{uid}

Template: ARIN-REASSIGN-SIMPLE-3.0
## As of June 2002
#####################################################################
1. Registration Action: $how
2. Network Name: $data->{swip_id}
3. IP Address and Prefix or Range: $data->{netblock}/$data->{size}
4. Customer Name:
5a. Customer Address:
5b. Customer Address:
5b. Customer Address:
6. Customer City:
7. Customer State/Province:
8. Customer Postal Code:
9. Customer Country Code:
10. Public Comments:

END OF TEMPLATE
-----------------------------CUT HERE ----------------------------------------

EOS
    ;
    close SWIP;
    1;
}

1;

