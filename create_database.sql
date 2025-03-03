-- ----------------------------------------------------------------------------
-- Drop tables
-- ----------------------------------------------------------------------------
drop table if exists MYNAB_DB.BUDGET_LINE;
drop table if exists MYNAB_DB.TRANSFER;
drop table if exists MYNAB_DB.TRANSACTION;
drop table if exists MYNAB_DB.PAYEE;
drop table if exists MYNAB_DB.CATEGORY;
drop table if exists MYNAB_DB.PARENT_CATEGORY;
drop table if exists MYNAB_DB.ACCOUNT;
drop table if exists MYNAB_DB.USER;
drop view if exists MYNAB_DB.EXPENSES;
drop view if exists MYNAB_DB.BUDGET_PERIOD;
drop view if exists MYNAB_DB.AVAILABLE_TO_BUDGET;

-- ----------------------------------------------------------------------------
-- Table USER
-- ----------------------------------------------------------------------------
create table MYNAB_DB.USER (
	ID_USER int not null auto_increment,
	FIRST_NAME varchar(50),
	LAST_NAME varchar(50),
	EMAIL_ADDRESS varchar(150) not null,
	PASSPHRASE_MD5 varchar(32) not null,
	primary key (ID_USER),
	unique(EMAIL_ADDRESS)
);

-- ----------------------------------------------------------------------------
-- Table ACCOUNT
-- ----------------------------------------------------------------------------
create table MYNAB_DB.ACCOUNT (
	ID_ACCOUNT int not null auto_increment,
	ID_USER int not null,
	ACCOUNT_TYPE int not null,
	ACCOUNT_NAME varchar(50) not null,
	ACCOUNT_STATUS int not null default 1,
	primary key (ID_ACCOUNT),
	foreign key (ID_USER) references MYNAB_DB.USER(ID_USER),
	constraint ACCOUNT_STATUS_VAL check (ACCOUNT_STATUS in (0, 1))
);

-- ----------------------------------------------------------------------------
-- Table PAYEE
-- ----------------------------------------------------------------------------
create table MYNAB_DB.PAYEE (
	ID_PAYEE int not null auto_increment,
	ID_USER int not null,
	PAYEE_NAME varchar(70),
	primary key (ID_PAYEE),
	foreign key (ID_USER) references MYNAB_DB.USER(ID_USER)
);

-- ----------------------------------------------------------------------------
-- Table PARENT_CATEGORY
-- ----------------------------------------------------------------------------
create table MYNAB_DB.PARENT_CATEGORY (
	ID_USER int not null,
	ID_PARENT_CATEGORY int not null,
	PARENT_CATEGORY_NAME varchar(70),
	PARENT_CATEGORY_POSITION int not null default 1,
	primary key (ID_USER, ID_PARENT_CATEGORY),
	foreign key (ID_USER) references MYNAB_DB.USER(ID_USER),
  index (ID_USER, ID_PARENT_CATEGORY)
);


-- ----------------------------------------------------------------------------
-- Table CATEGORY
-- ----------------------------------------------------------------------------
create table MYNAB_DB.CATEGORY (
	ID_USER int not null,
	ID_CATEGORY int not null,
	ID_PARENT_CATEGORY int not null,
	CATEGORY_NAME varchar(70),
	primary key (ID_USER, ID_CATEGORY),
	foreign key (ID_USER, ID_PARENT_CATEGORY) references MYNAB_DB.PARENT_CATEGORY(ID_USER, ID_PARENT_CATEGORY),
	index (ID_USER, ID_CATEGORY)
);

-- ----------------------------------------------------------------------------
-- Table TRANSACTION
-- ----------------------------------------------------------------------------
create table MYNAB_DB.TRANSACTION (
	ID_TRANSACTION int not null auto_increment,
	ID_USER int not null,
	ID_ACCOUNT int not null,
	ID_PAYEE int null,
	ID_CATEGORY int null,
	TRANSACTION_FLOW int not null default -1,
	TRANSACTION_AMOUNT int not null default 0,
	TRANSACTION_DATE date not null,
	TRANSACTION_MEMO varchar(400),
	IS_TRANSFER int not null default 0,
	primary key (ID_TRANSACTION),
	foreign key (ID_USER) references MYNAB_DB.USER(ID_USER),
	foreign key (ID_USER, ID_ACCOUNT) references MYNAB_DB.ACCOUNT(ID_USER, ID_ACCOUNT),
	foreign key (ID_USER, ID_PAYEE) references MYNAB_DB.PAYEE(ID_USER, ID_PAYEE),
	foreign key (ID_USER, ID_CATEGORY) references MYNAB_DB.CATEGORY(ID_USER, ID_CATEGORY),
	constraint TRANSACTION_PAYEE_OR_TRANSFER check (ID_PAYEE is not null or IS_TRANSFER = 1),
	constraint TRANSACTION_FLOW_VAL check (TRANSACTION_FLOW in (-1, 1)),
	constraint TRANSACTION_IS_TRANSFER_VAL check (IS_TRANSFER in (0, 1)),
	index (ID_USER, ID_TRANSACTION)
);

-- ----------------------------------------------------------------------------
-- Table TRANSFER
-- ----------------------------------------------------------------------------
create table MYNAB_DB.TRANSFER (
	ID_TRANSFER int not null auto_increment,
	ID_USER int not null,
	ID_TRANSACTION_OUTFLOW int not null,
	ID_TRANSACTION_INFLOW int not null,
	primary key (ID_TRANSFER),
	foreign key (ID_USER) references MYNAB_DB.USER(ID_USER),
	foreign key (ID_USER, ID_TRANSACTION_OUTFLOW) references MYNAB_DB.TRANSACTION(ID_USER, ID_TRANSACTION),
	foreign key (ID_USER, ID_TRANSACTION_INFLOW) references MYNAB_DB.TRANSACTION(ID_USER, ID_TRANSACTION)
);

-- ----------------------------------------------------------------------------
-- Table BUDGET_LINE
-- ----------------------------------------------------------------------------
create table MYNAB_DB.BUDGET_LINE (
	ID_USER int not null,
	ID_CATEGORY int not null,
	BUDGET_LINE_YEAR int not null,
	BUDGET_LINE_MONTH int not null,
	BUDGET_LINE_AMOUNT  int not null default 0,
	primary key (ID_USER, ID_CATEGORY, BUDGET_LINE_YEAR, BUDGET_LINE_MONTH),
	foreign key (ID_USER) references MYNAB_DB.USER(ID_USER),
	foreign key (ID_USER, ID_CATEGORY) references MYNAB_DB.CATEGORY(ID_USER, ID_CATEGORY)
);

-- ----------------------------------------------------------------------------
-- View EXPENSES
-- ----------------------------------------------------------------------------
create or replace view MYNAB_DB.EXPENSES as 
select ID_USER, year(TRANSACTION_DATE) as EXP_YEAR, month(TRANSACTION_DATE) as EXP_MONTH, ID_CATEGORY, sum(TRANSACTION_AMOUNT * TRANSACTION_FLOW) as "EXP_AMOUNT"
from TRANSACTION
where ID_CATEGORY is not null
and ID_CATEGORY <> 0
group by ID_USER, year(TRANSACTION_DATE), month(TRANSACTION_DATE), ID_CATEGORY;

-- ----------------------------------------------------------------------------
-- View INCOME
-- ----------------------------------------------------------------------------
create or replace view MYNAB_DB.INCOME as 
select ID_USER, year(TRANSACTION_DATE) as INC_YEAR, month(TRANSACTION_DATE) as INC_MONTH, sum(TRANSACTION_AMOUNT * TRANSACTION_FLOW) as INC_AMOUNT
from TRANSACTION
where ID_CATEGORY = 0
group by ID_USER, year(TRANSACTION_DATE), month(TRANSACTION_DATE);

-- ----------------------------------------------------------------------------
-- View BUDGET_PERIOD
-- ----------------------------------------------------------------------------
create or replace view MYNAB_DB.BUDGET_PERIOD as 
select ID_USER, BUDGET_LINE_YEAR as year, BUDGET_LINE_MONTH as month
from BUDGET_LINE
union
select ID_USER, year(txn.TRANSACTION_DATE), month(txn.TRANSACTION_DATE)
from TRANSACTION txn;

-- ----------------------------------------------------------------------------
-- View AVAILABLE_TO_BUDGET
-- ----------------------------------------------------------------------------
create or replace view MYNAB_DB.AVAILABLE_TO_BUDGET as 
select p.ID_USER, p.YEAR, p.MONTH, 
  ifnull(i.INC_AMOUNT,0) - sum(ifnull(BUDGET_LINE_AMOUNT, 0)) as available
from BUDGET_PERIOD p
left join INCOME i
	on i.ID_USER = p.ID_USER and i.INC_YEAR = p.YEAR and i.INC_MONTH = p.MONTH
left join BUDGET_LINE bl
	on bl.ID_USER = p.ID_USER and bl.BUDGET_LINE_YEAR = p.YEAR and bl.BUDGET_LINE_MONTH = p.MONTH
group by p.ID_USER, p.YEAR, p.MONTH;
