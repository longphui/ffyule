USE [Ticket]
GO
/****** Object:  StoredProcedure [dbo].[Task_AutoActGongZi_Group4]    Script Date: 2/9/2018 3:47:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--游标实例  利用游标循环表 根据userid赋值
ALTER PROCEDURE [dbo].[Task_AutoActGongZi_Group4]
AS
BEGIN
	/*** 20180210
		不区分用户组UserGroup
		只执行Task_AutoActGongZi_Group2
		清除Task_AutoActGongZi_Group3, Task_AutoActGongZi_Group4
	***/	
END
