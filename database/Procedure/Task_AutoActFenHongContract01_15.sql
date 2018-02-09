USE [Ticket]
GO
/****** Object:  StoredProcedure [dbo].[Task_AutoActFenHongContract01_15]    Script Date: 2/9/2018 3:47:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--游标实例  利用游标循环表 根据userid赋值
ALTER PROCEDURE [dbo].[Task_AutoActFenHongContract01_15]
AS
BEGIN
declare @a int,@error int
declare @temp varchar(50)--临时变量，用来保存游标值
declare @sqlstr varchar(200)
set @a=1 set @error=0
BEGIN TRAN --申明事务
--申明游标 为userid
declare order_cursor CURSOR FOR SELECT Id FROM [N_UserContract] where Type=1 and isUsed=1
--打开游标
open order_cursor
 WHILE @@FETCH_STATUS = 0 --返回被 FETCH  语句执行的最后游标的状态，而不是任何当前被连接打开的游标的状态。
  begin
   --开始循环游标变量
   FETCH NEXT FROM order_cursor INTO @temp
   --执行sql操作
	exec Act_FenHongContract01_15 @temp,@sqlstr output
   set @a=@a+1
   set @error=@error+@@error --记录每次运行sql后 是否正确  0正确
  end
if @error=0--没有错误 统一提交事务
 begin
  commit tran--提交
 end
else
 begin
     rollback tran--回滚
 end
CLOSE order_cursor--关闭游标
DEALLOCATE order_cursor--释放游标
END
