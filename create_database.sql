-- ----------------------------------------------------------------------------
-- Drop tables
-- ----------------------------------------------------------------------------
drop table if exists MYNAB_DB.TRANSACTION;
drop table if exists MYNAB_DB.TRANSFER;
drop table if exists MYNAB_DB.ACCOUNT;
drop table if exists MYNAB_DB.PAYEE;
drop table if exists MYNAB_DB.PARENT_CATEGORY;
drop table if exists MYNAB_DB.CATEGORY;
drop table if exists MYNAB_DB.USER;

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
	constraint ACCOUNT_STATUS_VAL check (ACCOUNT_STATUS in (0, 1)),
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
	ID_PARENT_CATEGORY int not null auto_increment,
	ID_USER int not null,
	PARENT_CATEGORY_NAME varchar(70),
	primary key (ID_PARENT_CATEGORY),
	foreign key (ID_USER) references MYNAB_DB.USER(ID_USER)
);

-- ----------------------------------------------------------------------------
-- Table CATEGORY
-- ----------------------------------------------------------------------------
create table MYNAB_DB.CATEGORY (
	ID_CATEGORY int not null auto_increment,
	ID_USER int not null,
	ID_PARENT_CATEGORY int not null,
	CATEGORY_NAME varchar(70),
	primary key (ID_CATEGORY),
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

