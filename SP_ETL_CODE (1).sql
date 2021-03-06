USE [master]
GO
/****** Object:  Database [SP_ETL]    Script Date: 24-May-20 5:55:19 PM ******/
CREATE DATABASE [SP_ETL]
 GO
USE [SP_ETL]
GO
/****** Object:  Table [dbo].[CUSTOMER_SRC]    Script Date: 24-May-20 5:55:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CUSTOMER_SRC](
	[CUSTOMERID] [int] IDENTITY(1,1) NOT NULL,
	[FULLNAME] [varchar](100) NULL,
	[BIRTHDATE] [datetime] NULL,
	[MARITALSTATUS] [varchar](100) NULL,
	[GENDER] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[CUSTOMERID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CUSTOMER_TRG]    Script Date: 24-May-20 5:55:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CUSTOMER_TRG](
	[CUSTOMERKEY] [int] IDENTITY(100,1) NOT NULL,
	[CUSTOMERID] [int] NULL,
	[FULLNAME] [varchar](100) NULL,
	[BIRTHDATE] [datetime] NULL,
	[MARITALSTATUS] [varchar](100) NULL,
	[GENDER] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[CUSTOMERKEY] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  StoredProcedure [dbo].[SP_ETL]    Script Date: 24-May-20 5:55:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

USE SP_ETL
GO
--Create procedure to load data from source table to target table
CREATE PROCEDURE [dbo].[SP_ETL_CODE]
AS
Begin

INSERT INTO SP_ETL.DBO.CUSTOMER_TRG  (E.CUSTOMERID,E.[FULLNAME]
           ,E.[BIRTHDATE]
           ,E.[MARITALSTATUS]
           ,E.[GENDER]
		  
          )
SELECT CUSTOMERID	,
FULLNAME	,
BIRTHDATE	,
MARITALSTATUS	,
GENDER
 FROM SP_ETL.DBO.CUSTOMER_SRC
 WHERE CUSTOMERID IN (
SELECT CUSTOMERID FROM (

SELECT E.CUSTOMERID,E.[FULLNAME]
           ,E.[MARITALSTATUS]
            FROM SP_ETL.DBO.CUSTOMER_SRC E

EXCEPT  --EXCEPT returns only rows, which are not available in the second SELECT statement,
        --Here we are comparing FULLNAME, MARITALSTATUS column os source and target table

SELECT  T.CUSTOMERID
            ,T.[FULLNAME]--SCD2
           ,T.[MARITALSTATUS]--SCD2
          
           FROM SP_ETL.DBO.CUSTOMER_TRG T
WHERE T.CUSTOMERKEY IN (SELECT MAX(T.CUSTOMERKEY) FROM SP_ETL.DBO.CUSTOMER_TRG T GROUP BY T.CUSTOMERID) AND T.CUSTOMERID IS NOT NULL) AS A) ;



PRINT 'New data Loaded @CUSTOMER_TRG from CUSTOMER_SRC'



UPDATE T
	SET 
T.GENDER=S.GENDER, --SCD1
T.BIRTHDATE=S.BIRTHDATE--SCD1

FROM
	SP_ETL.DBO.CUSTOMER_SRC S LEFT JOIN SP_ETL.DBO.CUSTOMER_TRG T ON T.CUSTOMERID = S.CUSTOMERID
WHERE

 T.CUSTOMERKEY IN 
(SELECT MAX (T.CUSTOMERKEY) 
FROM SP_ETL.DBO.CUSTOMER_TRG T GROUP BY T.CUSTOMERID) AND T.CUSTOMERID IS NOT NULL
AND T.GENDER<>S.GENDER OR
T.BIRTHDATE<>S.BIRTHDATE;
PRINT 'Modified data  Loaded @CUSTOMER_TRG from CUSTOMER_SRC'

end
GO
USE SP_ETL
GO
ALTER DATABASE [SP_ETL] SET  READ_WRITE 
GO
