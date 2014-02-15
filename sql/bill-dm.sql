-- Copyright (c) 2003 by Jeff Weisberg
-- Author: Jeff Weisberg <jaw @ tcp4me.com>
-- Created: 2003-Nov-06 20:29 (EST)
-- Function: service billing
--
-- $Id: bill-dm.sql,v 1.2 2003/11/12 04:58:11 jaw Exp $

create table bill_freq (
       freq_id			char(1)			primary key,
       freq_intvl		interval		not null,
       descr			varchar(16),
       descr_adv		varchar(32)
);

-- the base product, one per type of thing we sell
create table bill_product (
       product_id		isa_object,
       freq_id			char(1)			not null references bill_freq,
       name			varchar(16)		not null,
       descr			varchar(64)		not null,
       price			numeric(9,2)		not null,
       setup_fee		numeric(9,2)		not null,
       available_p		bool			not null default true,

       unique( name, freq_id )
);

-- an instance of a sold product
create table bill_service (
       service_id		isa_object,
       product_id		refs(bill_product)	on delete set null,

       active_p			bool			not null default true,
       start_date		date			not null default now(),
       latest_end_date		date			not null default now(),
       canceled_date		date,
       locked_date		date,
       locked_reason		varchar(64),
       last_bill_date		date,

       price_override		numeric(9,2),
       setup_override		numeric(9,2)
);
create index bill_srvc_prod_idx on bill_service(product_id);

-- each type of service will extend bill_service (eg: username, passwd)


-- money!
-- payments are >0, charges <0
create table bill_transaction (
       transaction_id		isa_object,
       account_id		ref_object		on delete set null,
       refunded_id		ref_object		on delete set null,	-- original transaction

       total_amt		numeric(9,2)		not null,
       post_date		date			not null default now(),
       descr			varchar(64)		not null,

       -- service_charge, fee, cc_payment, check, credit
       type			varchar(16)		not null,

       sub_total		numeric(9,2),
       tax			numeric(9,2)
);
create index bill_trans_acct_idx   on bill_transaction(account_id);
create index bill_trans_refund_idx on bill_transaction(refunded_id);

-- extend transactions table for services
create table bill_trans_srvc (
       transaction_id		subclass(bill_transaction),
       service_id		refs(bill_service)	on delete set null,

       start_date		date			not null,
       end_date			date			not null,

       voided_p			bool			not null default false,
       refundable_p		bool			not null default true
);
create index bill_trans_srvc_srvc_idx on bill_trans_srvc(service_id);

create table bill_reconcile (
       reconcile_id		serial			primary key,
       payment_id		refs(bill_transaction)	not null,
       charge_id		refs(bill_transaction)	not null,
       amount			numeric(9,2)		not null
);
create index bill_recon_pay_idx on bill_reconcile(payment_id);
create index bill_recon_chg_idx on bill_reconcile(charge_id);

-- map trans -> cc_batch, cc_atempt
-- map trans -> check_batch

