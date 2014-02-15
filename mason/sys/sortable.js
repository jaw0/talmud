%# -*- mason -*-
%# Copyright (c) 2010 by Jeff Weisberg
%# Author: Jeff Weisberg <jaw @ tcp4me.com>
%# Created: 2010-Aug-19 16:47 (EDT)
%# Function: 
%#
%# $Id: sortable.js,v 1.5 2010/10/05 04:08:42 jaw Exp $


function set_border(n){

    // set style on sort col
    d = n.sort_dir;
    n.className = d ? 'sort-up' : 'sort-dn';
}

function sort_by_val(row, coln){

    var c = row.children[coln];

    if( c.hasAttribute('sortby')) return c.getAttribute('sortby');
    return c.innerText || c.textContent || '';
}


function head_click(table, headr, coln){

    if(headr.getAttribute('sortable') == 'no') return;

    // determine sort order
    headr.sort_dir = headr.sort_dir ? 0 : 1;

    // remove style from prev sort col
    if( table.sort_prev ){
        table.sort_prev.className = '';
    }
    set_border(headr);
    table.sort_prev = headr;

    // determine sort type
    var sortas = headr.getAttribute('sortas') || 'string';
    // get body rows
    var items = [];
    var body  = table.tBodies[0];

    for(var i=0; i<body.children.length; i++){
        var row = body.children[i];
        var sb  = sort_by_val(row, coln);
        if( sortas == 'int' ) sb = parseInt(sb);
        items.push( { sortby: sb, row: row } );
    }

    items = items.sort( function(a,b){
        if( a.sortby < b.sortby ) return -1;
        if( a.sortby > b.sortby ) return  1;
        return 0;
    } );

    if( ! headr.sort_dir ) items = items.reverse();

    // clear table
    while( body.childNodes[0] ){
        body.removeChild(body.childNodes[0]);
    }

    // rebuild table
    for(var i in items){
        var row = items[i].row;
        row.className = (i%2) ? 'oddrow' : 'evenrow';
        body.appendChild(row);
    }

}

function install_onclick(n, t,c){
    n.onclick = function(){ head_click(t, n, c) };
}

function init_table(id, initcol){
    var i;

    // get headers
    var t = document.getElementById(id);
    if(!t) return;

    var h = t.tHead;
    if(!h) return;

    var hr = h.rows[0];
    if(!hr) return;

    for(i=0; i<hr.children.length; i++){
        var n = hr.children[i];
        if( n.nodeName != 'TD' ) continue;

        // make clickable
        install_onclick(n, t, i);
    }

    // sort data, and set style
    head_click(t, hr.children[initcol], initcol);
}


%################################################################
<%flags>
    inherit => undef
</%flags>
%################################################################
<%init>
    $r->content_type('text/javascript; charset=utf-8');
</%init>
