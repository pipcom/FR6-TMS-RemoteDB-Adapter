# FR6-TMS-RemoteDB-Adapter
This project is about an addon to add TMS RemoteDB client to Fast Reports 6 VCL.

The project is created in context of https://www.fast-report.com/en/contest-2020/

Without having any database drivers installed you can use  SQL in Fast Reports through TMS RemoteDB. The access is password protected and transport encryption can be implemented through https. Using TMS RemoteDB you need at least a TMS Business Subscription https://www.tmssoftware.com/site/bipack.asp where TMS RemoteDB is a part of.

For testeing purpose i added the basic sample programm that comes with TMS RemoteDB Product to be able to provide a datasource of any ado or odbc datasource.

To setup a database server connection you have to do the following steps:

1.) Register your http TMS RemoteDB service using Sparkle registration util TMSHttpConfig.exe

TMS RemoteDB is using Windows http.sys kernel which is also used by IIS Web Server. You do not need to install IIS Webserver Rolle to use TMS RemoteDB.

Start  TMSHttpConfig.exe, click on add and enter Url Prefix http://+:2001/tms/ together with permission Everyone

2.) Start RemoteDBServer.exe and configure a database using data connection properties. 

The preconfigured datasource is prepared to use a Postgres connection with Datasource PostgreSQL30 which i created by installing Northwind Sample from the following site.

https://dzone.com/articles/how-to-the-northwind-postgresql-sample-database-ru

You have to install databse together with 32bit odbc driver. Setup an odbc source using northwind database with credentials

But you can use any other Database connection configured on your machine.

When developing a server engine you also can use any other FireDAC connection using its components.

From client site it does not matter what for a databse you use because you are connecting against TMS RemoteDB.

Click on Start button when defining connection string is ready.

3.) Verify connection using RemoteDBClient.exe client.

Start Client program and click on check TMS RemoteDB Url. If you did not connecting to http://localhost:2001/tms/remotedb you need to change the URL.

click on Connect. You should not see any errors.

if you are using postgres northwind or mssql northwind databse you can enter select

"select * from customers"

for example. 

Click on "Open SQL" to query the result.

4.) Using EmbedDesigner.exe to create a report.

I prepared the EmbedDesigner demo that comes with FastReport by simply adding "TfrxTmsRdbComponents" component to the designer.

That is all.

When executing you can drop TmsRdbDatabase Database component on the data page. 
(Sorry about the component icons, i reused ado image index to have some icons for the components)

Enter "http://localhost:2001/tms/remotedb" into server Uri and press enter.

Click on Connected.

5.) Now you can add some query components 

In my example i added three query objects from northwind database.

"select * from customers", "select * from orders" and "select * from order_details"

Note that where clause is automatically added when add a master detail relation between to query objects

Simple select the mater object and setup the mater fields.

In case of customers <> orders the oders the following where clause is added.

WHERE (customer_id=:customer_id)

6.) Execure the report. Now you should see the master detail detail result.

