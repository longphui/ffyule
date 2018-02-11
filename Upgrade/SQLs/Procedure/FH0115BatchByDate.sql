USE [Ticket]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

if (exists (select 1 from sys.objects where name = N'FH0115BatchByDate'))
    drop proc FH0115BatchByDate
go

/*
	结算指定月份1号到15号的工资
	@fhdate: 结算日期
*/
CREATE PROCEDURE FH0115BatchByDate
@fhdate DateTime --工资结算日期
AS
BEGIN
	declare @num int, 
			@error int
			
	declare @contractId varchar(50)--临时变量，用来保存游标值
	declare @result varchar(200) --执行结果
	set @num=1 
	set @error=0
	
	BEGIN TRAN --申明事务
	--申明游标 为userid
	declare order_cursor CURSOR FOR SELECT Id FROM [N_UserContract] where Type=1 and isUsed=1 ORDER BY UserId ASC
	--打开游标
	open order_cursor
	WHILE @@FETCH_STATUS = 0 --返回被 FETCH  语句执行的最后游标的状态，而不是任何当前被连接打开的游标的状态。
		begin
			--开始循环游标变量
			FETCH NEXT FROM order_cursor INTO @contractId
			--执行sql操作
			exec FH0115OperByDate @contractId, @fhdate, @result output
		
		set @num=@num + 1
		set @error=@error + @@error --记录每次运行sql后 是否正确  0正确
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
