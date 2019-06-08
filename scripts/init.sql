create database email_sender;

\c email_sender

CREATE TABLE email(
   id serial PRIMARY KEY,
   datahora TIMESTAMPTZ NOT NULL default current_timestamp,
   assunto VARCHAR (50) NOT NULL,
   mensagem VARCHAR (355) UNIQUE NOT NULL
);